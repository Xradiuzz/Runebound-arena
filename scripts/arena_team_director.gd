extends Node
class_name ArenaTeamDirector

# Lightweight team coordinator. It refreshes shared orders at a low cadence so
# nine bot brains in the ten-hero match do not scan the whole field every frame.

const TEAM_BLUE := 0
const TEAM_RED := 1
const LANE_X := [-10.0, 0.0, 10.0]
const ROLE_LANES := {
    "offlane": 2,
    "mid": 1,
    "carry": 0,
    "support": 0,
    "roamer": 1
}
const ROLE_LANE_OFFSETS := {
    "offlane": -0.35,
    "mid": 0.0,
    "carry": -0.62,
    "support": 0.62,
    "roamer": 0.78
}
const THINK_INTERVAL := 0.42
const HERO_SCAN_RANGE := 13.0

var game: Node
var team_rosters: Dictionary = {}
var team_focus: Dictionary = {}
var roamer_lane_by_team: Dictionary = {}
var _refresh_timer := 0.0
var _roamer_refresh_timer := 0.0


func setup(game_node: Node) -> void:
    game = game_node
    team_rosters[TEAM_BLUE] = []
    team_rosters[TEAM_RED] = []
    team_focus[TEAM_BLUE] = null
    team_focus[TEAM_RED] = null
    roamer_lane_by_team[TEAM_BLUE] = 1
    roamer_lane_by_team[TEAM_RED] = 1
    set_process(true)


func register_actor(actor: ArenaActor, role: String) -> void:
    if not is_instance_valid(actor) or actor.is_minion:
        return
    actor.team_role = role if ROLE_LANES.has(role) else "mid"
    actor.lane_index = lane_for_role(actor.team_role)
    actor.lane_x = LANE_X[actor.lane_index] + float(ROLE_LANE_OFFSETS.get(actor.team_role, 0.0))
    if not team_rosters.has(actor.team):
        team_rosters[actor.team] = []
    var roster: Array = team_rosters[actor.team]
    if not roster.has(actor):
        roster.append(actor)
    team_rosters[actor.team] = roster


func lane_for_role(role: String) -> int:
    return int(ROLE_LANES.get(role, 1))


func lane_x_for_role(lane: int, role: String) -> float:
    var safe_lane := clampi(lane, 0, 2)
    return LANE_X[safe_lane] + float(ROLE_LANE_OFFSETS.get(role, 0.0))


func get_roster(team: int) -> Array:
    return team_rosters.get(team, []).duplicate()


func get_roster_summary(team: int) -> String:
    var roster: Array = team_rosters.get(team, [])
    var labels := PackedStringArray()
    for actor_variant in roster:
        if not is_instance_valid(actor_variant):
            continue
        var actor := actor_variant as ArenaActor
        labels.append(_role_short(actor.team_role))
    return "/".join(labels)


func get_alive_hero_count(team: int) -> int:
    var count := 0
    var roster: Array = team_rosters.get(team, [])
    for actor_variant in roster:
        if is_instance_valid(actor_variant):
            var actor := actor_variant as ArenaActor
            if actor.alive:
                count += 1
    return count


func get_order_for(actor: ArenaActor) -> Dictionary:
    if not is_instance_valid(actor):
        return {"mode": "lane", "focus": null, "boss": null}

    var order := {
        "mode": "lane",
        "focus": null,
        "boss": null,
        "lane": lane_for_role(actor.team_role),
        "escort": null
    }

    var boss := _get_active_boss()
    if is_instance_valid(boss) and _should_contest_boss(boss):
        var distance_to_boss := actor.global_position.distance_to(boss.global_position)
        var role_can_rotate := actor.team_role == "mid" or actor.team_role == "roamer"
        var boss_is_low := boss.hp / maxf(1.0, boss.max_hp) <= 0.34
        if role_can_rotate or (boss_is_low and distance_to_boss <= 16.0):
            order["mode"] = "boss"
            order["boss"] = boss
            return order

    var focus: ArenaActor = team_focus.get(actor.team) as ArenaActor
    if is_instance_valid(focus) and focus.alive:
        var distance_to_focus := actor.global_position.distance_to(focus.global_position)
        if distance_to_focus <= HERO_SCAN_RANGE + 3.0:
            order["mode"] = "engage"
            order["focus"] = focus
            return order

    if actor.team_role == "support":
        var escort := _find_ally_to_escort(actor)
        if is_instance_valid(escort):
            order["mode"] = "escort"
            order["escort"] = escort

    if actor.team_role == "roamer":
        var roam_target := _find_roam_target(actor)
        if is_instance_valid(roam_target):
            order["mode"] = "engage"
            order["focus"] = roam_target
        else:
            order["mode"] = "rotate"
            order["lane"] = int(roamer_lane_by_team.get(actor.team, 1))

    return order


func _process(delta: float) -> void:
    _refresh_timer -= delta
    if _refresh_timer > 0.0:
        return
    _refresh_timer = THINK_INTERVAL
    _refresh_team_focus(TEAM_BLUE)
    _refresh_team_focus(TEAM_RED)
    _roamer_refresh_timer += THINK_INTERVAL
    if _roamer_refresh_timer >= 8.0:
        _roamer_refresh_timer = 0.0
        _refresh_roamer_lane(TEAM_BLUE)
        _refresh_roamer_lane(TEAM_RED)


func _refresh_roamer_lane(team: int) -> void:
    if not is_instance_valid(game) or not game.has_method("get_lane_pressure"):
        return
    var current_lane := int(roamer_lane_by_team.get(team, 1))
    var chosen_lane := 0
    var weakest_pressure := INF
    for lane in [0, 2]:
        var pressure := float(game.call("get_lane_pressure", team, lane))
        if pressure < weakest_pressure:
            weakest_pressure = pressure
            chosen_lane = lane
    var current_pressure := float(game.call("get_lane_pressure", team, current_lane))
    if current_lane in [0, 2] and current_pressure <= weakest_pressure + 2.0:
        return
    roamer_lane_by_team[team] = chosen_lane


func _refresh_team_focus(team: int) -> void:
    var roster: Array = team_rosters.get(team, [])
    var living_allies: Array[ArenaActor] = []
    for actor_variant in roster:
        if not is_instance_valid(actor_variant):
            continue
        var ally := actor_variant as ArenaActor
        if ally.alive:
            living_allies.append(ally)

    if living_allies.size() < 2:
        team_focus[team] = null
        return

    var best_target: ArenaActor
    var best_score := INF
    for node in get_tree().get_nodes_in_group("arena_actors"):
        if not (node is ArenaActor):
            continue
        var candidate := node as ArenaActor
        if candidate.team == team or candidate.is_minion or not candidate.alive:
            continue

        var nearest_distance := INF
        var nearby_allies := 0
        var nearby_enemies := 0
        for ally in living_allies:
            var distance := ally.global_position.distance_to(candidate.global_position)
            nearest_distance = minf(nearest_distance, distance)
            if distance <= 8.5:
                nearby_allies += 1
        for other in get_tree().get_nodes_in_group("arena_actors"):
            if not (other is ArenaActor):
                continue
            var enemy_ally := other as ArenaActor
            if enemy_ally != candidate and enemy_ally.team != team and not enemy_ally.is_minion and enemy_ally.alive:
                if enemy_ally.global_position.distance_to(candidate.global_position) <= 8.5:
                    nearby_enemies += 1

        if nearby_allies < 2 or nearest_distance > HERO_SCAN_RANGE:
            continue
        var health_ratio := candidate.hp / maxf(1.0, candidate.max_hp)
        var score := nearest_distance - (1.0 - health_ratio) * 4.0
        score += float(nearby_enemies) * 1.5
        score -= float(nearby_allies) * 0.8
        if score < best_score:
            best_score = score
            best_target = candidate

    team_focus[team] = best_target


func _get_active_boss() -> ArenaAncientBoss:
    if not is_instance_valid(game):
        return null
    var boss = game.get("ancient_boss")
    if boss is ArenaAncientBoss and boss.alive:
        return boss as ArenaAncientBoss
    return null


func _should_contest_boss(boss: ArenaAncientBoss) -> bool:
    if not is_instance_valid(game) or not is_instance_valid(boss):
        return false
    var match_time := float(game.get("match_time"))
    if match_time < 120.0:
        return false
    var boss_ratio := boss.hp / maxf(1.0, boss.max_hp)
    if boss_ratio > 0.72:
        return false
    return true


func _find_ally_to_escort(actor: ArenaActor) -> ArenaActor:
    var wounded_choice: ArenaActor
    var wounded_score := INF
    var carry_choice: ArenaActor
    var carry_distance := INF
    var roster: Array = team_rosters.get(actor.team, [])
    for ally_variant in roster:
        if not is_instance_valid(ally_variant):
            continue
        var ally := ally_variant as ArenaActor
        if ally == actor or not ally.alive:
            continue
        var health_ratio := ally.hp / maxf(1.0, ally.max_hp)
        var distance := actor.global_position.distance_to(ally.global_position)
        if distance > 13.0:
            continue
        if health_ratio <= 0.82:
            var score := health_ratio * 10.0 + distance * 0.15
            if ally.team_role == "carry":
                score -= 1.2
            if score < wounded_score:
                wounded_score = score
                wounded_choice = ally
        elif ally.team_role == "carry" and distance < carry_distance:
            carry_distance = distance
            carry_choice = ally

    if is_instance_valid(wounded_choice):
        return wounded_choice
    return carry_choice


func _find_roam_target(actor: ArenaActor) -> ArenaActor:
    var chosen: ArenaActor
    var best_score := INF
    for node in get_tree().get_nodes_in_group("arena_actors"):
        if not (node is ArenaActor):
            continue
        var candidate := node as ArenaActor
        if candidate.team == actor.team or candidate.is_minion or not candidate.alive:
            continue
        var distance := actor.global_position.distance_to(candidate.global_position)
        if distance > 18.0:
            continue
        var health_ratio := candidate.hp / maxf(1.0, candidate.max_hp)
        var score := distance - (1.0 - health_ratio) * 5.0
        if score < best_score:
            best_score = score
            chosen = candidate
    return chosen


func _role_short(role: String) -> String:
    match role:
        "offlane":
            return "OFF"
        "mid":
            return "MID"
        "carry":
            return "CAR"
        "support":
            return "SUP"
        "roamer":
            return "ROAM"
    return "MID"
