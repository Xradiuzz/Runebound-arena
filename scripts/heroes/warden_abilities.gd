extends Node
class_name WardenAbilities

signal state_changed

const SLOTS := ["Q", "W", "E", "R"]

var hero: ArenaActor
var game: Node
var definitions: Dictionary = {}
var ranks := {"Q": 0, "W": 0, "E": 0, "R": 0}
var cooldowns := {"Q": 0.0, "W": 0.0, "E": 0.0, "R": 0.0}

var mana := 360.0
var max_mana := 360.0
var mana_regen := 8.0
var _ui_timer := 0.0


func _ready() -> void:
    hero = get_parent() as ArenaActor
    if hero == null:
        set_process(false)
        push_error("WardenAbilities must be a child of ArenaActor.")
        return

    game = hero.game
    definitions = WardenAbilityCatalog.build()
    _ensure_input_actions()
    state_changed.emit()


func _ensure_input_actions() -> void:
    var key_map := {
        "cast_q": KEY_1,
        "cast_w": KEY_2,
        "cast_e": KEY_3,
        "cast_r": KEY_4
    }

    for action in key_map:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        if InputMap.action_get_events(action).is_empty():
            var event := InputEventKey.new()
            event.physical_keycode = key_map[action]
            InputMap.action_add_event(action, event)


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
        var ultimate_levels := [6, 12, 18]
        required_level = ultimate_levels[current_rank]
    else:
        required_level = current_rank + 1

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
    if get_rank(slot) <= 0:
        _show_message("Learn %s first." % get_title(slot))
        return false
    if get_cooldown(slot) > 0.0:
        return false

    var definition: ArenaAbilityDefinition = definitions[slot]
    var rank := get_rank(slot)
    var cost := definition.value(definition.mana_cost, rank)
    if mana < cost:
        _show_message("Not enough mana.")
        return false

    var success := false
    match definition.id:
        &"runic_charge":
            success = _cast_runic_charge(definition, rank)
        &"aegis_ward":
            success = _cast_aegis_ward(definition, rank)
        &"hammerfall":
            success = _cast_hammerfall(definition, rank)
        &"chrono_bastion":
            success = _cast_chrono_bastion(definition, rank)

    if not success:
        return false

    mana -= cost
    cooldowns[slot] = definition.value(definition.cooldown, rank)
    state_changed.emit()
    return true


func _cast_runic_charge(definition: ArenaAbilityDefinition, rank: int) -> bool:
    var target := _find_enemy_hero_or_minion(definition.cast_range)
    if target == null:
        _show_message("No enemy in Runic Charge range.")
        return false

    var started := hero.start_charge(
        target,
        definition.value(definition.magnitude, rank),
        _scaled_damage(definition, rank),
        definition.value(definition.duration, rank)
    )
    if started:
        _spawn_pulse(hero.global_position, Color("#53D7FF"), 2.4)
    return started


func _cast_aegis_ward(definition: ArenaAbilityDefinition, rank: int) -> bool:
    var shield := definition.value(definition.magnitude, rank)
    var duration := definition.value(definition.duration, rank)
    hero.grant_shield(shield, duration)
    _spawn_pulse(hero.global_position, Color("#69E8FF"), 2.8)
    _show_message("Aegis Ward • %d shield" % int(shield))
    return true


func _cast_hammerfall(definition: ArenaAbilityDefinition, rank: int) -> bool:
    var hits := _damage_area(
        definition.radius,
        _scaled_damage(definition, rank),
        &"slow",
        definition.value(definition.duration, rank),
        definition.value(definition.magnitude, rank)
    )
    if hits <= 0:
        _show_message("No enemies in Hammerfall range.")
        return false

    _spawn_pulse(hero.global_position, Color("#E9BD72"), definition.radius)
    _show_message("Hammerfall • %d targets hit" % hits)
    return true


func _cast_chrono_bastion(definition: ArenaAbilityDefinition, rank: int) -> bool:
    var hits := _damage_area(
        definition.radius,
        _scaled_damage(definition, rank),
        &"stun",
        definition.value(definition.duration, rank),
        0.0
    )
    if hits <= 0:
        _show_message("No enemies in Chrono Bastion range.")
        return false

    _spawn_pulse(hero.global_position, Color("#A58AFF"), definition.radius)
    _show_message("Chrono Bastion • %d targets caught" % hits)
    return true


func _find_enemy_hero_or_minion(search_range: float) -> ArenaActor:
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


func _damage_area(
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

        if hero.global_position.distance_to(target.global_position) > radius:
            continue

        target.take_damage(damage, hero.team, false)
        target.apply_status(status_kind, duration, magnitude, hero.team)
        hit_count += 1

    for node in get_tree().get_nodes_in_group("arena_neutral_monsters"):
        if not (node is ArenaNeutralMonster):
            continue
        var monster := node as ArenaNeutralMonster
        if not monster.alive:
            continue
        if hero.global_position.distance_to(monster.global_position) > radius:
            continue
        monster.take_damage(damage, hero.team, false)
        monster.apply_status(status_kind, duration, magnitude, hero.team)
        hit_count += 1

    return hit_count


func _spawn_pulse(position: Vector3, color: Color, radius: float) -> void:
    if not is_instance_valid(game):
        return

    var ring := MeshInstance3D.new()
    ring.name = "AbilityPulse"

    var mesh := TorusMesh.new()
    mesh.inner_radius = 0.82
    mesh.outer_radius = 1.0
    ring.mesh = mesh
    ring.rotation_degrees.x = 90.0
    ring.position = position + Vector3(0.0, 0.14, 0.0)
    ring.scale = Vector3(0.22, 1.0, 0.22)

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(color.r, color.g, color.b, 0.88)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = 1.8
    ring.material_override = material

    game.add_child(ring)

    var tween := create_tween()
    tween.tween_property(ring, "scale", Vector3(radius, 1.0, radius), 0.48)
    tween.parallel().tween_property(
        material,
        "albedo_color",
        Color(color.r, color.g, color.b, 0.0),
        0.48
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
