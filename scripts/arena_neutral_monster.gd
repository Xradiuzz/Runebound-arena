extends CharacterBody3D
class_name ArenaNeutralMonster

var camp: ArenaNeutralCamp
var game: Node
var monster_id := ""
var label := "Neutral"
var kind := "stalker"
var max_hp := 260.0
var hp := 260.0
var move_speed := 3.0
var attack_damage := 18.0
var attack_range := 1.9
var attack_rate := 1.35
var attack_cooldown := 0.0
var aggro_range := 5.8
var leash_range := 10.5
var gold_reward := 48
var xp_reward := 58
var armor := 8.0
var alive := true
var home_position := Vector3.ZERO
var target: ArenaActor
var last_hit_team := -1
var active_statuses: Array[Dictionary] = []
var hp_fill: MeshInstance3D
var visual_root: Node3D


func setup(
    camp_node: ArenaNeutralCamp,
    game_node: Node,
    id: String,
    monster_name: String,
    monster_kind: String,
    health: float,
    damage: float,
    speed: float,
    reward_gold: int,
    reward_xp: int,
    reward_armor: float,
    aggro: float,
    leash: float
) -> void:
    camp = camp_node
    game = game_node
    monster_id = id
    label = monster_name
    kind = monster_kind
    max_hp = health
    hp = health
    attack_damage = damage
    move_speed = speed
    gold_reward = reward_gold
    xp_reward = reward_xp
    armor = reward_armor
    aggro_range = aggro
    leash_range = leash
    attack_range = 1.9 if kind == "stalker" else 2.2
    attack_rate = 1.35 if kind == "stalker" else 1.55


func _ready() -> void:
    home_position = global_position
    collision_layer = 0
    collision_mask = 0
    add_to_group("arena_neutral_monsters")
    _build_visuals()


func _build_visuals() -> void:
    visual_root = Node3D.new()
    visual_root.name = "VisualRoot"
    add_child(visual_root)

    var main_color := Color("#4F9169") if kind == "stalker" else Color("#665744")
    var accent_color := Color("#A8F0A4") if kind == "stalker" else Color("#D9A85E")

    var body_material := StandardMaterial3D.new()
    body_material.albedo_color = main_color
    body_material.roughness = 0.62
    body_material.metallic = 0.08 if kind == "stalker" else 0.28

    var accent_material := StandardMaterial3D.new()
    accent_material.albedo_color = accent_color
    accent_material.emission_enabled = true
    accent_material.emission = accent_color
    accent_material.emission_energy_multiplier = 0.8

    var body := MeshInstance3D.new()
    var body_mesh := CapsuleMesh.new()
    body_mesh.radius = 0.58 if kind == "stalker" else 0.72
    body_mesh.height = 1.35 if kind == "stalker" else 1.65
    body.mesh = body_mesh
    body.position.y = 0.72 if kind == "stalker" else 0.86
    body.material_override = body_material
    visual_root.add_child(body)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.42 if kind == "stalker" else 0.50
    head_mesh.height = 0.78 if kind == "stalker" else 0.92
    head.mesh = head_mesh
    head.position = Vector3(0.0, 1.43 if kind == "stalker" else 1.67, -0.12)
    head.material_override = body_material
    visual_root.add_child(head)

    for side in [-1.0, 1.0]:
        var horn := MeshInstance3D.new()
        var horn_mesh := CylinderMesh.new()
        horn_mesh.top_radius = 0.0
        horn_mesh.bottom_radius = 0.16 if kind == "stalker" else 0.21
        horn_mesh.height = 0.62 if kind == "stalker" else 0.48
        horn.mesh = horn_mesh
        horn.position = Vector3(side * 0.31, 1.72 if kind == "stalker" else 1.95, -0.18)
        horn.rotation_degrees.z = side * -24.0
        horn.material_override = accent_material
        visual_root.add_child(horn)

    var core := MeshInstance3D.new()
    var core_mesh := SphereMesh.new()
    core_mesh.radius = 0.22 if kind == "stalker" else 0.28
    core_mesh.height = 0.44 if kind == "stalker" else 0.56
    core.mesh = core_mesh
    core.position = Vector3(0.0, 1.02 if kind == "stalker" else 1.2, 0.43)
    core.material_override = accent_material
    visual_root.add_child(core)

    var collision := CollisionShape3D.new()
    var capsule_shape := CapsuleShape3D.new()
    capsule_shape.radius = 0.52 if kind == "stalker" else 0.66
    capsule_shape.height = 1.35 if kind == "stalker" else 1.6
    collision.shape = capsule_shape
    collision.position.y = 0.72 if kind == "stalker" else 0.82
    add_child(collision)

    var bar_back := MeshInstance3D.new()
    var back_mesh := BoxMesh.new()
    back_mesh.size = Vector3(1.25, 0.10, 0.07)
    bar_back.mesh = back_mesh
    bar_back.position = Vector3(0.0, 2.45, 0.0)
    var back_material := StandardMaterial3D.new()
    back_material.albedo_color = Color("#111923")
    bar_back.material_override = back_material
    add_child(bar_back)

    hp_fill = MeshInstance3D.new()
    var fill_mesh := BoxMesh.new()
    fill_mesh.size = Vector3(1.16, 0.075, 0.08)
    hp_fill.mesh = fill_mesh
    hp_fill.position = Vector3(0.0, 2.46, -0.015)
    var fill_material := StandardMaterial3D.new()
    fill_material.albedo_color = Color("#8BE39B")
    fill_material.emission_enabled = true
    fill_material.emission = Color("#3B9C63")
    fill_material.emission_energy_multiplier = 0.5
    hp_fill.material_override = fill_material
    add_child(hp_fill)


func _physics_process(delta: float) -> void:
    if is_instance_valid(game) and bool(game.get("game_over")):
        velocity = Vector3.ZERO
        return
    if not alive:
        return

    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    _tick_statuses(delta)
    if not alive:
        return

    if is_stunned():
        velocity.x = move_toward(velocity.x, 0.0, move_speed * 12.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * 12.0 * delta)
        move_and_slide()
        return

    if not _valid_target():
        target = _acquire_target()

    if is_instance_valid(target):
        var home_distance := _flat_distance(global_position, home_position)
        if home_distance > leash_range:
            target = null
            _move_home(delta)
        else:
            _fight_target(delta)
    else:
        _move_home(delta)

    move_and_slide()


func _acquire_target() -> ArenaActor:
    var chosen: ArenaActor
    var best_score := INF

    for node in get_tree().get_nodes_in_group("arena_actors"):
        if not (node is ArenaActor):
            continue
        var candidate := node as ArenaActor
        if not candidate.alive:
            continue

        var distance := _flat_distance(global_position, candidate.global_position)
        if distance > aggro_range:
            continue

        var priority := 0.0 if not candidate.is_minion else 2.0
        var score := distance + priority
        if score < best_score:
            best_score = score
            chosen = candidate

    return chosen


func _valid_target() -> bool:
    return is_instance_valid(target) and target.alive and target.hp > 0.0


func _fight_target(delta: float) -> void:
    if not _valid_target():
        target = null
        return

    var difference := target.global_position - global_position
    difference.y = 0.0
    var distance := difference.length()

    if distance > attack_range:
        var direction := difference.normalized()
        var speed_multiplier := _movement_multiplier()
        velocity.x = direction.x * move_speed * speed_multiplier
        velocity.z = direction.z * move_speed * speed_multiplier
        _face_direction(direction, delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * 8.0 * delta)
        if attack_cooldown <= 0.0:
            target.take_damage(attack_damage, -1, false)
            attack_cooldown = attack_rate


func _move_home(delta: float) -> void:
    var difference := home_position - global_position
    difference.y = 0.0

    if difference.length() > 0.55:
        var direction := difference.normalized()
        velocity.x = direction.x * move_speed * 0.82
        velocity.z = direction.z * move_speed * 0.82
        _face_direction(direction, delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * 8.0 * delta)
        hp = minf(max_hp, hp + max_hp * 0.035 * delta)
        _update_health_bar()


func _face_direction(direction: Vector3, delta: float) -> void:
    if direction.length_squared() < 0.001 or not is_instance_valid(visual_root):
        return
    var desired_yaw := atan2(direction.x, direction.z)
    visual_root.rotation.y = lerp_angle(
        visual_root.rotation.y,
        desired_yaw,
        clampf(delta * 8.0, 0.0, 1.0)
    )


func _flat_distance(a: Vector3, b: Vector3) -> float:
    var difference := a - b
    difference.y = 0.0
    return difference.length()


func apply_status(
    kind: StringName,
    duration: float,
    magnitude: float = 0.0,
    source_team: int = -1
) -> void:
    if duration <= 0.0:
        return
    active_statuses.append({
        "kind": kind,
        "remaining": duration,
        "magnitude": magnitude,
        "source_team": source_team,
        "tick_remaining": 1.0
    })


func _tick_statuses(delta: float) -> void:
    var bleed_damage := 0.0
    var bleed_source_team := -1

    for index in range(active_statuses.size() - 1, -1, -1):
        var status: Dictionary = active_statuses[index]
        status["remaining"] = float(status.get("remaining", 0.0)) - delta

        if StringName(status.get("kind", &"")) == &"bleed":
            status["tick_remaining"] = float(status.get("tick_remaining", 1.0)) - delta
            if float(status["tick_remaining"]) <= 0.0:
                bleed_damage += float(status.get("magnitude", 0.0))
                bleed_source_team = int(status.get("source_team", -1))
                status["tick_remaining"] = 1.0

        if float(status["remaining"]) <= 0.0:
            active_statuses.remove_at(index)
        else:
            active_statuses[index] = status

    if bleed_damage > 0.0 and alive:
        take_damage(bleed_damage, bleed_source_team, false)


func is_stunned() -> bool:
    for status in active_statuses:
        if StringName(status.get("kind", &"")) == &"stun":
            return true
    return false


func _movement_multiplier() -> float:
    var multiplier := 1.0
    for status in active_statuses:
        if StringName(status.get("kind", &"")) == &"slow":
            multiplier = minf(
                multiplier,
                1.0 - clampf(float(status.get("magnitude", 0.0)), 0.0, 0.85)
            )
    return multiplier


func take_damage(
    amount: float,
    attacker_team: int = -1,
    attacker_is_minion: bool = false
) -> float:
    if not alive or amount <= 0.0:
        return 0.0

    var actual_damage := amount * 100.0 / (100.0 + maxf(0.0, armor))
    actual_damage = minf(hp, actual_damage)
    hp = maxf(0.0, hp - actual_damage)
    if attacker_team >= 0:
        last_hit_team = attacker_team

    _update_health_bar()
    if hp <= 0.0:
        _die(last_hit_team)

    return actual_damage


func _die(killer_team: int) -> void:
    if not alive:
        return
    alive = false
    active_statuses.clear()
    velocity = Vector3.ZERO
    if is_instance_valid(camp):
        camp.notify_monster_defeated(self, killer_team)
    queue_free()


func _update_health_bar() -> void:
    if not is_instance_valid(hp_fill):
        return
    var ratio := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
    hp_fill.scale.x = maxf(0.001, ratio)
    hp_fill.position.x = -0.58 * (1.0 - ratio)
