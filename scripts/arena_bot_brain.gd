extends Node
class_name ArenaBotBrain

# Shared tactical controller for every non-player hero. Ash Knight keeps its
# bespoke spell kit; allied and rival heroes use their own registered ability kit.

const HOME_POSITION := Vector3(0.0, 0.0, -10.4)
const THINK_INTERVAL := 0.18
const RETREAT_THRESHOLD := 0.30
const RESUME_THRESHOLD := 0.68

var actor: ArenaActor
var game: Node
var team_director: ArenaTeamDirector
var ability_kit: Node
var _last_bot_level := 1
var _last_rank_level := 0
var escort_target: ArenaActor
var mana := 320.0
var max_mana := 320.0
var mana_regen := 7.5
var cooldowns := {"Q": 0.0, "W": 0.0, "E": 0.0, "R": 0.0}
var _think_timer := 0.0
var _retreating := false


func _ready() -> void:
    actor = get_parent() as ArenaActor
    if actor == null:
        set_process(false)
        push_error("ArenaBotBrain must be a child of ArenaActor.")
        return
    game = actor.game
    if is_instance_valid(game):
        team_director = game.get("team_director") as ArenaTeamDirector
    ability_kit = actor.get_node_or_null("WardenAbilities")
    if not is_instance_valid(ability_kit):
        ability_kit = actor.get_node_or_null("ArenaHeroKit")
    if actor.hero_id != "ash_knight":
        _sync_bot_progression()


func update_brain(delta: float) -> void:
    if not is_instance_valid(actor) or not actor.alive:
        return

    _sync_actor_level()
    if actor.hero_id != "ash_knight":
        _update_team_bot(delta)
        return

    mana = minf(max_mana, mana + mana_regen * delta)
    for slot in ["Q", "W", "E", "R"]:
        cooldowns[slot] = maxf(0.0, float(cooldowns[slot]) - delta)

    _think_timer -= delta
    if _think_timer <= 0.0:
        _think_timer = THINK_INTERVAL
        _think()

    if _retreating:
        _move_to(HOME_POSITION, delta)
        _recover_at_base(delta)
    elif is_instance_valid(actor.target) and actor._valid_target():
        actor._approach_or_attack(actor.target, delta)
    else:
        _push_lane(delta)


func _think() -> void:
    if actor.hero_id != "ash_knight":
        _think_team_bot()
        return
    var health_ratio := actor.hp / maxf(1.0, actor.max_hp)

    if health_ratio <= RETREAT_THRESHOLD:
        _retreating = true
    elif _retreating and health_ratio >= RESUME_THRESHOLD:
        _retreating = false

    if _retreating:
        actor.target = _nearest_enemy(7.0)
        if health_ratio <= 0.72:
            _cast_w()
        if _count_enemies_near(actor.global_position, 5.8) >= 2:
            _cast_r(true)
        return

    actor.target = _choose_combat_target()
    if health_ratio <= 0.64:
        _cast_w()
    var target_actor := actor.target as ArenaActor
    if target_actor == null:
        return

    var distance := actor.global_position.distance_to(target_actor.global_position)

    if _count_enemies_near(actor.global_position, 7.0) >= 2:
        if _cast_r(false):
            return

    if _count_enemies_near(actor.global_position, 4.8) >= 2:
        if _cast_e():
            return

    if target_actor.is_player and distance <= 8.8 and distance >= 3.0:
        if _cast_q(target_actor):
            return

    if target_actor.is_player and distance <= 6.0:
        _cast_r(false)


func _update_team_bot(delta: float) -> void:
    if is_instance_valid(ability_kit):
        _sync_bot_progression()
    _think_timer -= delta
    if _think_timer <= 0.0:
        _think_timer = THINK_INTERVAL
        _think_team_bot()

    if _retreating:
        escort_target = null
        _move_to(_home_position(), delta)
        _recover_at_base(delta)
    elif is_instance_valid(escort_target) and escort_target.alive:
        if actor.global_position.distance_to(escort_target.global_position) > 3.2:
            _move_to(escort_target.global_position, delta)
        else:
            actor.velocity.x = move_toward(actor.velocity.x, 0.0, actor.speed * 7.0 * delta)
            actor.velocity.z = move_toward(actor.velocity.z, 0.0, actor.speed * 7.0 * delta)
    elif is_instance_valid(actor.target) and actor._valid_target():
        actor._approach_or_attack(actor.target, delta)
    else:
        _push_lane(delta)


func _think_team_bot() -> void:
    var health_ratio := actor.hp / maxf(1.0, actor.max_hp)
    if health_ratio <= RETREAT_THRESHOLD:
        _retreating = true
    elif _retreating and health_ratio >= RESUME_THRESHOLD:
        _retreating = false

    if _retreating:
        actor.target = _nearest_enemy(5.5)
        if health_ratio <= 0.70:
            _try_cast_hero_ability("W")
        if _count_enemies_near(actor.global_position, 5.5) >= 2:
            _try_cast_hero_ability("R")
        return

    var order: Dictionary = {}
    if is_instance_valid(team_director):
        order = team_director.get_order_for(actor)

    var mode := str(order.get("mode", "lane"))
    if mode != "escort":
        escort_target = null
    if mode == "boss" and is_instance_valid(order.get("boss")):
        actor.target = order.get("boss") as Node3D
    elif mode == "engage" and is_instance_valid(order.get("focus")):
        actor.target = order.get("focus") as Node3D
    elif mode == "escort" and is_instance_valid(order.get("escort")):
        escort_target = order.get("escort") as ArenaActor
        actor.target = null
    elif mode == "rotate" and actor.team_role == "roamer":
        var roam_lane := clampi(int(order.get("lane", 1)), 0, 2)
        actor.lane_index = roam_lane
        if is_instance_valid(team_director):
            actor.lane_x = team_director.lane_x_for_role(roam_lane, actor.team_role)
        actor.target = null
    else:
        escort_target = null
        actor.target = _choose_role_target()

    var enemies_close := _count_enemies_near(actor.global_position, 6.5)
    if actor.team_role == "support":
        var wounded_nearby := _count_wounded_allies(0.82, 9.5)
        var wounded_team := _count_wounded_allies(0.82, 100.0)
        if wounded_team >= 2 and _try_cast_hero_ability("R"):
            return
        if wounded_nearby >= 1 and _try_cast_hero_ability("Q"):
            return
        if (health_ratio <= 0.62 or _count_wounded_allies(0.72, 6.0) >= 2) and _try_cast_hero_ability("W"):
            return
        if enemies_close >= 1 and _try_cast_hero_ability("E"):
            return

    if actor.team_role == "roamer":
        var roam_target := actor.target as ArenaActor
        if is_instance_valid(roam_target) and roam_target.alive:
            var roam_distance := actor.global_position.distance_to(roam_target.global_position)
            if roam_distance <= 12.0 and _try_cast_hero_ability("W"):
                return
            if roam_distance <= 10.0 and roam_distance >= 2.4 and _try_cast_hero_ability("Q"):
                return

    if health_ratio <= 0.62:
        _try_cast_hero_ability("W")

    if enemies_close >= 2:
        if _try_cast_hero_ability("R"):
            return
        if _try_cast_hero_ability("E"):
            return

    if actor.target is ArenaAncientBoss:
        var boss_distance := actor.global_position.distance_to(actor.target.global_position)
        if boss_distance <= 8.8 and _try_cast_hero_ability("Q"):
            return
        if boss_distance <= 7.0:
            _try_cast_hero_ability("E")
        return

    var target_actor := actor.target as ArenaActor
    if is_instance_valid(target_actor) and target_actor.alive:
        var distance := actor.global_position.distance_to(target_actor.global_position)
        if distance <= 8.8 and distance >= 2.0:
            if _try_cast_hero_ability("Q"):
                return
        if distance <= 5.6 and enemies_close >= 1:
            _try_cast_hero_ability("E")


func _choose_role_target() -> Node3D:
    var chosen: ArenaActor
    var best_score := INF
    var is_carry := actor.team_role == "carry"
    var scan_range := 8.0 if is_carry else 11.0

    for node in get_tree().get_nodes_in_group("arena_actors"):
        if not (node is ArenaActor):
            continue
        var candidate := node as ArenaActor
        if candidate.team == actor.team or not candidate.alive:
            continue
        var distance := actor.global_position.distance_to(candidate.global_position)
        if distance > scan_range:
            continue

        var score := distance
        if candidate.is_minion:
            score += 1.8 if is_carry else 3.2
            if candidate.minion_role == "siege":
                score -= 3.0
            elif candidate.minion_role == "ranged":
                score -= 1.2
            if candidate.lane_index != actor.lane_index:
                score += 3.5
        else:
            if is_carry:
                score += 1.0
            else:
                score -= 2.0
            var health_ratio := candidate.hp / maxf(1.0, candidate.max_hp)
            score -= (1.0 - health_ratio) * 2.5
            if is_carry and health_ratio > 0.45:
                score += 3.5
        if score < best_score:
            best_score = score
            chosen = candidate

    if is_instance_valid(chosen):
        return chosen
    return _find_lane_objective()


func _count_wounded_allies(max_health_ratio: float, search_range: float) -> int:
    var count := 0
    for node in get_tree().get_nodes_in_group("arena_actors"):
        if not (node is ArenaActor):
            continue
        var ally := node as ArenaActor
        if ally.team != actor.team or not ally.alive or ally.is_minion:
            continue
        if ally.hp / maxf(1.0, ally.max_hp) > max_health_ratio:
            continue
        if actor.global_position.distance_to(ally.global_position) <= search_range:
            count += 1
    return count


func _sync_actor_level() -> void:
    if not is_instance_valid(actor) or not is_instance_valid(game):
        return
    var level := clampi(1 + int(float(game.get("match_time")) / 45.0), 1, 18)
    while _last_bot_level < level:
        actor.apply_level_up()
        _last_bot_level += 1


func _sync_bot_progression() -> void:
    if not is_instance_valid(ability_kit) or not is_instance_valid(game):
        return
    _sync_actor_level()
    var level := clampi(1 + int(float(game.get("match_time")) / 45.0), 1, 18)
    if level == _last_rank_level:
        return
    _last_rank_level = level
    var basic_rank := clampi(1 + int((level - 1) / 5), 1, 4)
    var ultimate_rank := clampi(int(level / 6), 0, 3)
    ability_kit.set("ranks", {
        "Q": basic_rank,
        "W": basic_rank,
        "E": basic_rank,
        "R": ultimate_rank
    })


func _try_cast_hero_ability(slot: String) -> bool:
    if not is_instance_valid(ability_kit) or not ability_kit.has_method("cast"):
        return false
    var ranks: Dictionary = ability_kit.get("ranks")
    if int(ranks.get(slot, 0)) <= 0:
        return false
    var cooldowns: Dictionary = ability_kit.get("cooldowns")
    if float(cooldowns.get(slot, 0.0)) > 0.0:
        return false
    return bool(ability_kit.call("cast", slot))


func _home_position() -> Vector3:
    return Vector3(0.0, 0.0, 10.4 if actor.team == ArenaActor.BLUE else -10.4)


func _choose_combat_target() -> Node3D:
    if is_instance_valid(team_director):
        var order := team_director.get_order_for(actor)
        var boss = order.get("boss")
        if str(order.get("mode", "")) == "boss" and is_instance_valid(boss):
            return boss as Node3D
        var focus = order.get("focus")
        if is_instance_valid(focus) and focus is ArenaActor and focus.alive:
            return focus as ArenaActor
    var chosen: ArenaActor
    var best_score := INF
    for node in get_tree().get_nodes_in_group("arena_actors"):
        if not (node is ArenaActor):
            continue
        var candidate := node as ArenaActor
        if candidate == actor or candidate.team == actor.team or not candidate.alive:
            continue
        var distance := actor.global_position.distance_to(candidate.global_position)
        if distance > 14.0:
            continue

        var score := distance
        if candidate.is_player:
            score -= 3.0
        elif candidate.is_minion:
            score += 2.0
            if candidate.minion_role == "siege":
                score -= 5.0
        var candidate_health := candidate.hp / maxf(1.0, candidate.max_hp)
        if candidate_health < 0.40:
            score -= 2.0
        if candidate.is_player and candidate_health < 0.30:
            score -= 3.0
        if score < best_score:
            best_score = score
            chosen = candidate

    if is_instance_valid(chosen):
        return chosen
    return _find_lane_objective()


func _find_lane_objective() -> Node3D:
    var chosen: ArenaTower
    var best_score := INF
    for node in get_tree().get_nodes_in_group("arena_structures"):
        if not (node is ArenaTower):
            continue
        var structure := node as ArenaTower
        if structure.team == actor.team or structure.hp <= 0.0:
            continue
        if structure.core and game != null:
            if not bool(game.call("all_towers_destroyed", structure.team)):
                continue
        var escort_radius := 10.0 if structure.core else 7.5
        var escort_lane := -1 if structure.core else structure.lane_index
        if _count_allied_minions_near(structure.global_position, escort_lane, escort_radius) <= 0:
            continue
        var lane_penalty := 0.0 if structure.lane_index == actor.lane_index else 2.5
        var pressure := 0
        if is_instance_valid(game) and game.has_method("get_lane_pressure"):
            pressure = int(game.call("get_lane_pressure", actor.team, structure.lane_index))
        var pressure_bonus := clampf(float(pressure), -6.0, 6.0) * 0.85
        var tower_health_ratio := structure.hp / maxf(1.0, structure.max_hp)
        var finish_bonus := (1.0 - tower_health_ratio) * 3.0
        var score := (
            actor.global_position.distance_to(structure.global_position)
            + lane_penalty - pressure_bonus - finish_bonus
        )
        if score < best_score:
            best_score = score
            chosen = structure
    return chosen


func _count_allied_minions_near(center: Vector3, lane: int, radius: float) -> int:
    var count := 0
    for node in get_tree().get_nodes_in_group("arena_actors"):
        if not (node is ArenaActor):
            continue
        var candidate := node as ArenaActor
        if not candidate.alive or not candidate.is_minion:
            continue
        if candidate.team != actor.team:
            continue
        if lane >= 0 and candidate.lane_index != lane:
            continue
        if candidate.global_position.distance_to(center) <= radius:
            count += 1
    return count


func _nearest_enemy(search_range: float) -> ArenaActor:
    var chosen: ArenaActor
    var best_distance := search_range
    for node in get_tree().get_nodes_in_group("arena_actors"):
        if not (node is ArenaActor):
            continue
        var candidate := node as ArenaActor
        if candidate == actor or candidate.team == actor.team or not candidate.alive:
            continue
        var distance := actor.global_position.distance_to(candidate.global_position)
        if distance < best_distance:
            best_distance = distance
            chosen = candidate
    return chosen


func _count_enemies_near(center: Vector3, radius: float) -> int:
    var count := 0
    for node in get_tree().get_nodes_in_group("arena_actors"):
        if not (node is ArenaActor):
            continue
        var candidate := node as ArenaActor
        if candidate == actor or candidate.team == actor.team or not candidate.alive:
            continue
        if center.distance_to(candidate.global_position) <= radius:
            count += 1
    return count


func _bot_level() -> int:
    if not is_instance_valid(game):
        return 1
    return clampi(1 + int(float(game.get("match_time")) / 45.0), 1, 18)


func _rank(slot: String) -> int:
    var level := _bot_level()
    if slot == "R":
        return clampi(int(level / 6), 0, 3)
    return clampi(1 + int((level - 1) / 5), 1, 4)


func _can_cast(slot: String, cost: float) -> bool:
    return (
        float(cooldowns[slot]) <= 0.0
        and mana >= cost
        and actor.alive
        and not actor.is_stunned()
    )


func _spend(slot: String, cost: float, cooldown: float) -> void:
    mana -= cost
    cooldowns[slot] = cooldown


func _cast_q(target_actor: ArenaActor) -> bool:
    var rank := _rank("Q")
    var cost := 55.0 + float(rank - 1) * 5.0
    if not _can_cast("Q", cost):
        return false
    var started := actor.start_charge(
        target_actor,
        6.0 + float(rank) * 0.55,
        95.0 + float(rank) * 24.0,
        0.55 + float(rank) * 0.05
    )
    if started:
        _spend("Q", cost, maxf(6.0, 12.0 - float(rank)))
        _pulse(actor.global_position, Color("#FF8B69"), 2.7)
    return started


func _cast_w() -> bool:
    var rank := _rank("W")
    var cost := 75.0 + float(rank - 1) * 5.0
    if not _can_cast("W", cost):
        return false
    var heal := minf(actor.max_hp - actor.hp, actor.max_hp * (0.13 + float(rank) * 0.025))
    actor.hp = minf(actor.max_hp, actor.hp + heal)
    actor.grant_shield(55.0 + float(rank) * 18.0, 3.5 + float(rank) * 0.35)
    actor.health_changed.emit(actor.hp, actor.max_hp)
    actor.call("_update_health_bar")
    _spend("W", cost, maxf(10.0, 24.0 - float(rank) * 2.0))
    _pulse(actor.global_position, Color("#E98B69"), 3.0)
    return true


func _cast_e() -> bool:
    var rank := _rank("E")
    var cost := 70.0 + float(rank - 1) * 5.0
    if not _can_cast("E", cost):
        return false
    var hits := 0
    var radius := 4.8
    for node in get_tree().get_nodes_in_group("arena_actors"):
        if not (node is ArenaActor):
            continue
        var target_actor := node as ArenaActor
        if target_actor == actor or target_actor.team == actor.team or not target_actor.alive:
            continue
        if actor.global_position.distance_to(target_actor.global_position) > radius:
            continue
        target_actor.take_damage(65.0 + float(rank) * 27.0, actor.team, false)
        target_actor.apply_status(&"slow", 1.7 + float(rank) * 0.15, 0.25 + float(rank) * 0.025)
        hits += 1
    if hits <= 0:
        return false
    _spend("E", cost, maxf(7.0, 14.0 - float(rank)))
    _pulse(actor.global_position, Color("#FF704F"), radius)
    return true


func _cast_r(defensive: bool) -> bool:
    var rank := _rank("R")
    if rank <= 0:
        return false
    var cost := 145.0 + float(rank - 1) * 20.0
    if not _can_cast("R", cost):
        return false
    var radius := 7.2
    var hits := 0
    for node in get_tree().get_nodes_in_group("arena_actors"):
        if not (node is ArenaActor):
            continue
        var target_actor := node as ArenaActor
        if target_actor == actor or target_actor.team == actor.team or not target_actor.alive:
            continue
        if actor.global_position.distance_to(target_actor.global_position) > radius:
            continue
        target_actor.take_damage(135.0 + float(rank) * 65.0, actor.team, false)
        target_actor.apply_status(&"stun", 0.8 + float(rank) * 0.18)
        hits += 1
    if hits <= 0:
        return false
    _spend("R", cost, maxf(45.0, 105.0 - float(rank) * 10.0))
    _pulse(actor.global_position, Color("#B978FF") if not defensive else Color("#FFB06D"), radius)
    return true


func _move_to(destination: Vector3, delta: float) -> void:
    if actor.is_rooted():
        actor.velocity.x = move_toward(actor.velocity.x, 0.0, actor.speed * 10.0 * delta)
        actor.velocity.z = move_toward(actor.velocity.z, 0.0, actor.speed * 10.0 * delta)
        return
    var difference := destination - actor.global_position
    difference.y = 0.0
    if difference.length() <= 0.9:
        actor.velocity.x = move_toward(actor.velocity.x, 0.0, actor.speed * 8.0 * delta)
        actor.velocity.z = move_toward(actor.velocity.z, 0.0, actor.speed * 8.0 * delta)
        return
    var direction := difference.normalized()
    var move_speed := actor._effective_speed()
    actor.velocity.x = direction.x * move_speed
    actor.velocity.z = direction.z * move_speed
    actor._face_direction(direction, delta)


func _push_lane(delta: float) -> void:
    var objective := _find_lane_objective()
    if is_instance_valid(objective):
        actor.target = objective
        if objective is ArenaTower:
            actor.lane_index = objective.lane_index
            actor.lane_x = objective.global_position.x
        actor._approach_or_attack(objective, delta)
        return
    # Hold outside tower aggro until the allied wave reaches the structure.
    var lane_goal_z := 1.5 if actor.team == ArenaActor.BLUE else -1.5
    var lane_goal := Vector3(actor.lane_x, actor.global_position.y, lane_goal_z)
    _move_to(lane_goal, delta)


func _recover_at_base(delta: float) -> void:
    if actor.global_position.distance_to(_home_position()) > 3.8:
        return
    var recovery := actor.max_hp * 0.045 * delta
    actor.hp = minf(actor.max_hp, actor.hp + recovery)
    actor.health_changed.emit(actor.hp, actor.max_hp)
    actor.call("_update_health_bar")


func _pulse(position: Vector3, color: Color, radius: float) -> void:
    if not is_instance_valid(game):
        return
    var ring := MeshInstance3D.new()
    var mesh := TorusMesh.new()
    mesh.inner_radius = 0.82
    mesh.outer_radius = 1.0
    ring.mesh = mesh
    ring.rotation_degrees.x = 90.0
    ring.position = position + Vector3(0.0, 0.16, 0.0)
    ring.scale = Vector3(0.25, 1.0, 0.25)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(color.r, color.g, color.b, 0.86)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = 1.6
    ring.material_override = material
    game.add_child(ring)
    var tween := create_tween()
    tween.tween_property(ring, "scale", Vector3(radius, 1.0, radius), 0.4)
    tween.parallel().tween_property(material, "albedo_color", Color(color.r, color.g, color.b, 0.0), 0.4)
    tween.tween_callback(ring.queue_free)
