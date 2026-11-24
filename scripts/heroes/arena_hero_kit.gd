extends Node
class_name ArenaHeroKit

signal state_changed

const SLOTS := ["Q", "W", "E", "R"]
const ULTIMATE_LEVELS := [6, 12, 18]

var hero: ArenaActor
var game: Node
var hero_id := ""
var definitions: Dictionary = {}
var ranks := {"Q": 0, "W": 0, "E": 0, "R": 0}
var cooldowns := {"Q": 0.0, "W": 0.0, "E": 0.0, "R": 0.0}
var mana := 360.0
var max_mana := 360.0
var mana_regen := 8.0
var _ui_timer := 0.0
var _successful_casts := 0


func _ready() -> void:
    hero = get_parent() as ArenaActor
    if hero == null:
        set_process(false)
        push_error("ArenaHeroKit must be a child of ArenaActor.")
        return

    game = hero.game
    hero_id = hero.hero_id
    definitions = HeroAbilityKitCatalog.build(hero_id)
    if definitions.is_empty():
        set_process(false)
        push_error("No ability kit registered for hero: %s" % hero_id)
        return

    max_mana = 420.0 if hero_id in ["nyxara", "elyra"] else (280.0 if hero_id == "vaelis" else 300.0)
    mana = max_mana
    mana_regen = 10.0 if hero_id == "nyxara" else (11.0 if hero_id == "elyra" else 6.5)
    state_changed.emit()


func _process(delta: float) -> void:
    if not is_instance_valid(hero):
        return

    for slot in SLOTS:
        cooldowns[slot] = maxf(0.0, float(cooldowns[slot]) - delta)

    if hero.alive:
        mana = minf(max_mana, mana + mana_regen * delta)

    if hero.is_player:
        if Input.is_action_just_pressed("cast_q"):
            cast("Q")
        if Input.is_action_just_pressed("cast_w"):
            cast("W")
        if Input.is_action_just_pressed("cast_e"):
            cast("E")
        if Input.is_action_just_pressed("cast_r"):
            cast("R")

    _ui_timer += delta
    if _ui_timer >= 0.10:
        _ui_timer = 0.0
        state_changed.emit()


func get_rank(slot: String) -> int:
    return int(ranks.get(slot, 0))


func get_cooldown(slot: String) -> float:
    return float(cooldowns.get(slot, 0.0))


func get_title(slot: String) -> String:
    var definition: ArenaAbilityDefinition = definitions.get(slot)
    return definition.display_name if definition != null else slot


func get_skill_points() -> int:
    return int(game.get("skill_points")) if is_instance_valid(game) else 0


func can_upgrade(slot: String) -> bool:
    if not definitions.has(slot) or not is_instance_valid(hero):
        return false

    var definition: ArenaAbilityDefinition = definitions[slot]
    var current_rank := get_rank(slot)
    if current_rank >= definition.max_rank or get_skill_points() <= 0:
        return false

    var hero_level := int(game.get("player_level")) if is_instance_valid(game) else 1
    var required_level := current_rank + 1
    if slot == "R":
        if current_rank >= ULTIMATE_LEVELS.size():
            return false
        required_level = ULTIMATE_LEVELS[current_rank]

    return hero_level >= required_level


func upgrade_ability(slot: String) -> bool:
    if not can_upgrade(slot):
        return false

    ranks[slot] = get_rank(slot) + 1
    game.set("skill_points", get_skill_points() - 1)
    _show_message("%s upgraded to rank %d" % [get_title(slot), get_rank(slot)])
    state_changed.emit()
    return true


func cast(slot: String) -> bool:
    if not SLOTS.has(slot) or not definitions.has(slot):
        return false
    if not is_instance_valid(hero) or not hero.alive:
        return false
    if is_instance_valid(game) and bool(game.get("game_over")):
        return false
    if get_rank(slot) <= 0 or get_cooldown(slot) > 0.0:
        return false

    var definition: ArenaAbilityDefinition = definitions[slot]
    var rank := get_rank(slot)
    var cost := definition.value(definition.mana_cost, rank)
    if mana < cost:
        _show_message("Not enough mana.")
        return false

    var success := false
    if hero_id == "nyxara":
        success = _cast_nyxara(definition, rank)
    elif hero_id == "grom":
        success = _cast_grom(definition, rank)
    elif hero_id == "elyra":
        success = _cast_elyra(definition, rank)
    elif hero_id == "vaelis":
        success = _cast_vaelis(definition, rank)

    if not success:
        return false

    mana -= cost
    cooldowns[slot] = definition.value(definition.cooldown, rank)
    _successful_casts += 1

    # Nyxara's passive: every third spell empowers her next basic attack.
    if hero_id == "nyxara" and _successful_casts % 3 == 0:
        hero.set_meta("nyxara_echo_ready", true)
        _show_message("Rift Echo ready • next attack empowered")

    state_changed.emit()
    return true


func _cast_nyxara(definition: ArenaAbilityDefinition, rank: int) -> bool:
    match definition.id:
        &"rift_step":
            var target := _find_enemy_node(definition.cast_range)
            if target == null:
                _show_message("No target in Rift Step range.")
                return false
            var away := hero.global_position - target.global_position
            away.y = 0.0
            if away.length_squared() < 0.001:
                away = Vector3.FORWARD
            var landing := target.global_position + away.normalized() * 2.1
            hero.global_position = landing
            hero.velocity = Vector3.ZERO
            target.call("take_damage", _scaled_damage(definition, rank), hero.team, false)
            if target.has_method("apply_status"):
                target.call("apply_status", &"slow", 0.7, 0.25, hero.team)
            _spawn_pulse(landing, Color("#65E8FF"), 2.7)
            return true

        &"astral_snare":
            var target := _find_enemy_node(definition.cast_range)
            if target == null:
                _show_message("No target in Astral Snare range.")
                return false
            target.call("take_damage", _scaled_damage(definition, rank), hero.team, false)
            if target.has_method("apply_status"):
                target.call("apply_status", &"root", definition.value(definition.duration, rank), 0.0, hero.team)
            _spawn_pulse(target.global_position, Color("#A7A0FF"), 2.3)
            return true

        &"starfall":
            var target := _find_enemy(definition.cast_range)
            if target == null:
                _show_message("No target in Starfall range.")
                return false
            var hits := _damage_area_at(
                target.global_position,
                definition.radius,
                _scaled_damage(definition, rank),
                &"slow",
                definition.value(definition.duration, rank),
                definition.value(definition.magnitude, rank)
            )
            if hits <= 0:
                return false
            _spawn_pulse(target.global_position, Color("#D18CFF"), definition.radius)
            return true

        &"void_eclipse":
            var gale_hits := _damage_area_at(
                hero.global_position,
                definition.radius,
                _scaled_damage(definition, rank),
                &"stun",
                definition.value(definition.duration, rank),
                0.0
            )
            if gale_hits <= 0:
                _show_message("No enemies inside Void Eclipse.")
                return false
            _spawn_pulse(hero.global_position, Color("#9B70FF"), definition.radius)
            return true

    return false


func _cast_grom(definition: ArenaAbilityDefinition, rank: int) -> bool:
    match definition.id:
        &"savage_leap":
            var target := _find_enemy(definition.cast_range)
            if target == null:
                _show_message("No target in Savage Leap range.")
                return false
            var started := hero.start_charge(
                target,
                definition.value(definition.magnitude, rank),
                _scaled_damage(definition, rank),
                definition.value(definition.duration, rank)
            )
            if started:
                _spawn_pulse(hero.global_position, Color("#FF9B62"), 2.5)
            return started

        &"blood_howl":
            var heal := hero.max_hp * definition.value(definition.magnitude, rank)
            hero.hp = minf(hero.max_hp, hero.hp + heal)
            hero.grant_shield(definition.value(definition.damage, rank), definition.value(definition.duration, rank))
            hero.health_changed.emit(hero.hp, hero.max_hp)
            hero.call("_update_health_bar")
            _spawn_pulse(hero.global_position, Color("#FF5D63"), 3.0)
            _show_message("Blood Howl • restored %d health" % int(heal))
            return true

        &"cleaving_arc":
            var hits := _damage_area_at(
                hero.global_position,
                definition.radius,
                _scaled_damage(definition, rank),
                &"bleed",
                definition.value(definition.duration, rank),
                definition.value(definition.magnitude, rank)
            )
            if hits <= 0:
                _show_message("No enemies in Cleaving Arc.")
                return false
            _spawn_pulse(hero.global_position, Color("#FF7A52"), definition.radius)
            return true

        &"warpath":
            var now := float(Time.get_ticks_msec()) / 1000.0
            hero.set_meta("grom_warpath_bonus", definition.value(definition.magnitude, rank))
            hero.set_meta("grom_warpath_until", now + definition.value(definition.duration, rank))
            _spawn_pulse(hero.global_position, Color("#FF4B45"), 3.8)
            _show_message("WARPATH • damage and movement increased")
            return true

    return false


func _cast_elyra(definition: ArenaAbilityDefinition, rank: int) -> bool:
    match definition.id:
        &"mending_ray":
            var ray_ally := _find_lowest_health_ally(definition.cast_range)
            if not is_instance_valid(ray_ally):
                return false
            var ray_heal := definition.value(definition.magnitude, rank)
            if ray_ally.hp >= ray_ally.max_hp - 4.0 and ray_ally.shield_points >= 45.0:
                return false
            _heal_ally(ray_ally, ray_heal, 38.0 + float(rank) * 14.0, definition.value(definition.duration, rank))
            _spawn_pulse(ray_ally.global_position, Color("#F5D88C"), 2.5)
            return true

        &"sanctuary":
            var sanctuary_heal := definition.value(definition.magnitude, rank)
            var sanctuary_hits := 0
            for node in get_tree().get_nodes_in_group("arena_actors"):
                if not (node is ArenaActor):
                    continue
                var sanctuary_ally := node as ArenaActor
                if sanctuary_ally.team != hero.team or not sanctuary_ally.alive or sanctuary_ally.is_minion:
                    continue
                if hero.global_position.distance_to(sanctuary_ally.global_position) > definition.radius:
                    continue
                if sanctuary_ally.hp >= sanctuary_ally.max_hp - 4.0 and sanctuary_ally.shield_points >= 55.0:
                    continue
                _heal_ally(sanctuary_ally, sanctuary_heal, 42.0 + float(rank) * 16.0, definition.value(definition.duration, rank))
                sanctuary_hits += 1
            if sanctuary_hits <= 0:
                return false
            _spawn_pulse(hero.global_position, Color("#F5D88C"), definition.radius)
            return true

        &"binding_light":
            var binding_target := _find_enemy_node(definition.cast_range)
            if not is_instance_valid(binding_target):
                return false
            var binding_hits := _damage_area_at(
                binding_target.global_position,
                definition.radius,
                _scaled_damage(definition, rank),
                &"root",
                definition.value(definition.duration, rank),
                0.0
            )
            if binding_hits <= 0:
                return false
            _spawn_pulse(binding_target.global_position, Color("#FFE7A3"), definition.radius)
            return true

        &"dawn_chorus":
            var chorus_heal := definition.value(definition.magnitude, rank)
            var chorus_hits := 0
            for node in get_tree().get_nodes_in_group("arena_actors"):
                if not (node is ArenaActor):
                    continue
                var chorus_ally := node as ArenaActor
                if chorus_ally.team != hero.team or not chorus_ally.alive or chorus_ally.is_minion:
                    continue
                if chorus_ally.hp >= chorus_ally.max_hp - 4.0 and chorus_ally.shield_points >= 80.0:
                    continue
                _heal_ally(chorus_ally, chorus_heal, 85.0 + float(rank) * 25.0, definition.value(definition.duration, rank))
                chorus_hits += 1
            if chorus_hits <= 0:
                return false
            _spawn_pulse(hero.global_position, Color("#FFF0B7"), 8.5)
            return true
    return false


func _cast_vaelis(definition: ArenaAbilityDefinition, rank: int) -> bool:
    match definition.id:
        &"shadow_pounce":
            var pounce_target := _find_enemy_node(definition.cast_range)
            if not is_instance_valid(pounce_target):
                return false
            var pounce_direction := pounce_target.global_position - hero.global_position
            pounce_direction.y = 0.0
            if pounce_direction.length_squared() > 0.001:
                hero.global_position = pounce_target.global_position - pounce_direction.normalized() * 2.4
            hero.velocity = Vector3.ZERO
            pounce_target.call("take_damage", _scaled_damage(definition, rank), hero.team, false)
            if pounce_target.has_method("apply_status"):
                pounce_target.call("apply_status", &"slow", definition.value(definition.duration, rank), definition.value(definition.magnitude, rank), hero.team)
            _spawn_pulse(hero.global_position, Color("#72E5C1"), 2.8)
            return true

        &"hunters_mark":
            var mark_target := _find_enemy_node(definition.cast_range)
            if not is_instance_valid(mark_target):
                return false
            mark_target.call("take_damage", _scaled_damage(definition, rank), hero.team, false)
            if mark_target.has_method("apply_status"):
                mark_target.call("apply_status", &"slow", definition.value(definition.duration, rank), definition.value(definition.magnitude, rank), hero.team)
                mark_target.call("apply_status", &"bleed", definition.value(definition.duration, rank), 8.0 + float(rank) * 3.0, hero.team)
            _spawn_pulse(mark_target.global_position, Color("#72E5C1"), 2.2)
            return true

        &"gale_cut":
            var gale_hits := _damage_area_at(
                hero.global_position,
                definition.radius,
                _scaled_damage(definition, rank),
                &"slow",
                definition.value(definition.duration, rank),
                definition.value(definition.magnitude, rank)
            )
            if gale_hits <= 0:
                return false
            _spawn_pulse(hero.global_position, Color("#72E5C1"), definition.radius)
            return true

        &"nightfall":
            var nightfall_target := _find_enemy_node(definition.cast_range)
            if not is_instance_valid(nightfall_target):
                return false
            var nightfall_direction := nightfall_target.global_position - hero.global_position
            nightfall_direction.y = 0.0
            if nightfall_direction.length_squared() > 0.001:
                hero.global_position = nightfall_target.global_position - nightfall_direction.normalized() * 2.8
            hero.velocity = Vector3.ZERO
            var nightfall_hits := _damage_area_at(
                hero.global_position,
                definition.radius,
                _scaled_damage(definition, rank),
                &"stun",
                definition.value(definition.duration, rank),
                0.0
            )
            if nightfall_hits <= 0:
                nightfall_target.call("take_damage", _scaled_damage(definition, rank), hero.team, false)
            _spawn_pulse(hero.global_position, Color("#3FD4B0"), definition.radius)
            return true
    return false


func _find_lowest_health_ally(search_range: float) -> ArenaActor:
    var chosen: ArenaActor
    var best_score := INF
    for node in get_tree().get_nodes_in_group("arena_actors"):
        if not (node is ArenaActor):
            continue
        var ally := node as ArenaActor
        if ally.team != hero.team or not ally.alive or ally.is_minion:
            continue
        var distance := hero.global_position.distance_to(ally.global_position)
        if ally != hero and distance > search_range:
            continue
        var health_ratio := ally.hp / maxf(1.0, ally.max_hp)
        var score := health_ratio * 10.0 + distance * 0.08
        if ally == hero:
            score += 0.45
        if score < best_score:
            best_score = score
            chosen = ally
    return chosen


func _heal_ally(ally: ArenaActor, amount: float, shield: float, shield_duration: float) -> void:
    if not is_instance_valid(ally) or not ally.alive:
        return
    ally.hp = minf(ally.max_hp, ally.hp + amount)
    ally.grant_shield(shield, shield_duration)
    ally.health_changed.emit(ally.hp, ally.max_hp)
    ally.call("_update_health_bar")


func _find_enemy_node(search_range: float) -> Node3D:
    var chosen: Node3D = _find_enemy(search_range)
    var best_score := INF
    if is_instance_valid(chosen):
        best_score = hero.global_position.distance_to(chosen.global_position)

    for node in get_tree().get_nodes_in_group("arena_neutral_monsters"):
        if not (node is ArenaNeutralMonster):
            continue
        var monster := node as ArenaNeutralMonster
        if not monster.alive:
            continue
        var distance := hero.global_position.distance_to(monster.global_position)
        if distance > search_range:
            continue
        var score := 18.0 + distance
        if score < best_score:
            best_score = score
            chosen = monster
    return chosen


func _find_enemy(search_range: float) -> ArenaActor:
    var chosen: ArenaActor
    var best_score := INF
    for node in get_tree().get_nodes_in_group("arena_actors"):
        if not (node is ArenaActor):
            continue
        var candidate := node as ArenaActor
        if candidate == hero or candidate.team == hero.team or not candidate.alive:
            continue
        var distance := hero.global_position.distance_to(candidate.global_position)
        if distance > search_range:
            continue
        var priority := 0.0 if not candidate.is_minion else 20.0
        var score := priority + distance
        if score < best_score:
            best_score = score
            chosen = candidate
    return chosen


func _damage_area_at(
    center: Vector3,
    radius: float,
    damage: float,
    status_kind: StringName,
    duration: float,
    magnitude: float
) -> int:
    var hit_count := 0
    for node in get_tree().get_nodes_in_group("arena_actors"):
        if not (node is ArenaActor):
            continue
        var target := node as ArenaActor
        if target == hero or target.team == hero.team or not target.alive:
            continue
        if center.distance_to(target.global_position) > radius:
            continue
        target.take_damage(damage, hero.team, false)
        if status_kind != &"":
            target.apply_status(status_kind, duration, magnitude, hero.team)
        hit_count += 1

    for node in get_tree().get_nodes_in_group("arena_neutral_monsters"):
        if not (node is ArenaNeutralMonster):
            continue
        var monster := node as ArenaNeutralMonster
        if not monster.alive:
            continue
        if center.distance_to(monster.global_position) > radius:
            continue
        monster.take_damage(damage, hero.team, false)
        if status_kind != &"":
            monster.apply_status(status_kind, duration, magnitude, hero.team)
        hit_count += 1

    return hit_count


func _spawn_pulse(position: Vector3, color: Color, radius: float) -> void:
    if not is_instance_valid(game):
        return
    var ring := MeshInstance3D.new()
    ring.name = "HeroAbilityPulse"
    var mesh := TorusMesh.new()
    mesh.inner_radius = 0.82
    mesh.outer_radius = 1.0
    ring.mesh = mesh
    ring.rotation_degrees.x = 90.0
    ring.position = position + Vector3(0.0, 0.15, 0.0)
    ring.scale = Vector3(0.22, 1.0, 0.22)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(color.r, color.g, color.b, 0.88)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = 1.9
    ring.material_override = material
    game.add_child(ring)
    var tween := create_tween()
    tween.tween_property(ring, "scale", Vector3(radius, 1.0, radius), 0.5)
    tween.parallel().tween_property(
        material,
        "albedo_color",
        Color(color.r, color.g, color.b, 0.0),
        0.5
    )
    tween.tween_callback(ring.queue_free)


func _scaled_damage(definition: ArenaAbilityDefinition, rank: int) -> float:
    var base_damage := definition.value(definition.damage, rank)
    return base_damage * (1.0 + maxf(0.0, hero.bonus_spell_power))


func _show_message(message: String) -> void:
    if not is_instance_valid(game) or not is_instance_valid(hero) or not hero.is_player:
        return
    var label = game.get("message_label")
    if label is Label:
        label.text = message
