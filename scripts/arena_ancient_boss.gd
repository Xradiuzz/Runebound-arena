extends ArenaNeutralMonster
class_name ArenaAncientBoss

signal phase_changed(phase: int)

const BOSS_TEAM := -1
const PHASE_THRESHOLDS := [0.65, 0.30]

var boss_phase := 1
var base_attack_damage := 44.0
var base_armor := 24.0
var special_cooldown := 7.0
var telegraph_remaining := 0.0
var slam_center := Vector3.ZERO
var slam_radius := 4.2
var slam_damage := 62.0
var boss_core: MeshInstance3D


func setup_boss(game_node: Node) -> void:
    super.setup(
        null,
        game_node,
        "elder_riftwarden",
        "Elder Riftwarden",
        "brute",
        3200.0,
        base_attack_damage,
        3.35,
        320,
        260,
        base_armor,
        13.0,
        20.0
    )
    kind = "boss"
    attack_range = 2.8
    attack_rate = 1.45
    special_cooldown = 7.0


func _ready() -> void:
    super._ready()
    add_to_group("arena_ancient_bosses")


func _build_visuals() -> void:
    visual_root = Node3D.new()
    visual_root.name = "RiftwardenVisuals"
    add_child(visual_root)

    var stone := _material(Color("#39485C"), 0.88, 0.12)
    var dark_stone := _material(Color("#202C3B"), 0.92, 0.18)
    var crystal := _material(Color("#78D8E8"), 0.3, 0.25, Color("#43C9E8"))
    var gold := _material(Color("#D8B66F"), 0.45, 0.55, Color("#C89B48"))

    _add_sphere(visual_root, Vector3(0.0, 1.72, 0.0), Vector3(1.42, 1.28, 1.12), stone, 1.0)
    _add_sphere(visual_root, Vector3(0.0, 2.78, 0.20), Vector3(0.88, 0.82, 0.82), dark_stone, 0.72)
    _add_sphere(visual_root, Vector3(-1.05, 2.20, 0.0), Vector3(0.72, 0.78, 0.72), stone, 0.72)
    _add_sphere(visual_root, Vector3(1.05, 2.20, 0.0), Vector3(0.72, 0.78, 0.72), stone, 0.72)
    _add_sphere(visual_root, Vector3(-0.53, 0.63, 0.0), Vector3(0.48, 0.78, 0.52), dark_stone, 0.55)
    _add_sphere(visual_root, Vector3(0.53, 0.63, 0.0), Vector3(0.48, 0.78, 0.52), dark_stone, 0.55)

    for side in [-1.0, 1.0]:
        var horn := MeshInstance3D.new()
        var horn_mesh := CylinderMesh.new()
        horn_mesh.top_radius = 0.0
        horn_mesh.bottom_radius = 0.31
        horn_mesh.height = 1.35
        horn.mesh = horn_mesh
        horn.position = Vector3(side * 0.57, 3.46, 0.10)
        horn.rotation_degrees = Vector3(0.0, 0.0, side * -28.0)
        horn.material_override = gold
        visual_root.add_child(horn)

        var arm := MeshInstance3D.new()
        var arm_mesh := CylinderMesh.new()
        arm_mesh.top_radius = 0.27
        arm_mesh.bottom_radius = 0.42
        arm_mesh.height = 1.25
        arm.mesh = arm_mesh
        arm.position = Vector3(side * 1.25, 1.45, 0.12)
        arm.rotation_degrees.z = side * -18.0
        arm.material_override = dark_stone
        visual_root.add_child(arm)

        var shoulder_crystal := MeshInstance3D.new()
        var crystal_mesh := PrismMesh.new()
        crystal_mesh.size = Vector3(0.48, 0.92, 0.48)
        shoulder_crystal.mesh = crystal_mesh
        shoulder_crystal.position = Vector3(side * 1.08, 2.65, 0.04)
        shoulder_crystal.rotation_degrees.z = side * 14.0
        shoulder_crystal.material_override = crystal
        visual_root.add_child(shoulder_crystal)

    boss_core = MeshInstance3D.new()
    var core_mesh := SphereMesh.new()
    core_mesh.radius = 0.43
    core_mesh.height = 0.86
    boss_core.mesh = core_mesh
    boss_core.position = Vector3(0.0, 1.85, 0.94)
    boss_core.material_override = crystal
    visual_root.add_child(boss_core)

    var back_shard := MeshInstance3D.new()
    var back_mesh := PrismMesh.new()
    back_mesh.size = Vector3(0.72, 1.65, 0.55)
    back_shard.mesh = back_mesh
    back_shard.position = Vector3(0.0, 2.85, -0.70)
    back_shard.rotation_degrees.x = -16.0
    back_shard.material_override = gold
    visual_root.add_child(back_shard)

    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 1.12
    capsule.height = 3.7
    collision.shape = capsule
    collision.position.y = 1.82
    add_child(collision)

    var bar_back := MeshInstance3D.new()
    var back_bar_mesh := BoxMesh.new()
    back_bar_mesh.size = Vector3(2.85, 0.15, 0.09)
    bar_back.mesh = back_bar_mesh
    bar_back.position = Vector3(0.0, 4.15, 0.0)
    bar_back.material_override = _material(Color("#101925"), 1.0, 0.0)
    add_child(bar_back)

    hp_fill = MeshInstance3D.new()
    var fill_mesh := BoxMesh.new()
    fill_mesh.size = Vector3(2.68, 0.105, 0.10)
    hp_fill.mesh = fill_mesh
    hp_fill.position = Vector3(0.0, 4.16, -0.01)
    hp_fill.material_override = _material(Color("#67D9E8"), 1.0, 0.0, Color("#3CA9D2"))
    add_child(hp_fill)


func _material(color: Color, roughness: float, metallic: float, glow: Color = Color.BLACK) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    material.metallic = metallic
    if glow != Color.BLACK:
        material.emission_enabled = true
        material.emission = glow
        material.emission_energy_multiplier = 1.4
    return material


func _add_sphere(
    parent: Node3D,
    local_position: Vector3,
    local_scale: Vector3,
    material: Material,
    radius: float
) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    instance.mesh = mesh
    instance.position = local_position
    instance.scale = local_scale
    instance.material_override = material
    parent.add_child(instance)
    return instance


func _physics_process(delta: float) -> void:
    if is_instance_valid(game) and bool(game.get("game_over")):
        velocity = Vector3.ZERO
        return
    super._physics_process(delta)
    if not alive:
        return

    special_cooldown = maxf(0.0, special_cooldown - delta)
    _update_boss_phase()

    if telegraph_remaining > 0.0:
        telegraph_remaining = maxf(0.0, telegraph_remaining - delta)
        if telegraph_remaining <= 0.0:
            _execute_slam()
    elif not is_stunned() and special_cooldown <= 0.0 and _valid_target():
        var distance := _flat_distance(global_position, target.global_position)
        if distance <= 9.0:
            _begin_slam_telegraph(target.global_position)

    if is_instance_valid(boss_core):
        var pulse := 1.0 + sin(float(Time.get_ticks_msec()) * 0.004) * 0.08
        boss_core.scale = Vector3.ONE * pulse


func _fight_target(delta: float) -> void:
    if _has_root_status():
        velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * 8.0 * delta)
        if _valid_target() and _flat_distance(global_position, target.global_position) <= attack_range and attack_cooldown <= 0.0:
            target.take_damage(attack_damage, BOSS_TEAM, false)
            attack_cooldown = attack_rate
        return
    super._fight_target(delta)


func _has_root_status() -> bool:
    for status in active_statuses:
        if StringName(status.get("kind", &"")) == &"root":
            return true
    return false


func _update_boss_phase() -> void:
    var health_ratio := hp / maxf(1.0, max_hp)
    var next_phase := 1
    if health_ratio <= PHASE_THRESHOLDS[1]:
        next_phase = 3
    elif health_ratio <= PHASE_THRESHOLDS[0]:
        next_phase = 2

    if next_phase == boss_phase:
        return

    boss_phase = next_phase
    attack_damage = base_attack_damage * (1.0 + 0.22 * float(boss_phase - 1))
    attack_rate = 1.45 - 0.12 * float(boss_phase - 1)
    armor = base_armor + 5.0 * float(boss_phase - 1)
    special_cooldown = minf(special_cooldown, 2.5)
    phase_changed.emit(boss_phase)

    if is_instance_valid(game) and game.has_method("on_boss_phase_changed"):
        game.call("on_boss_phase_changed", boss_phase)


func _begin_slam_telegraph(center: Vector3) -> void:
    slam_center = center
    var phase_scale := float(boss_phase - 1)
    slam_radius = 4.2 + phase_scale * 0.75
    slam_damage = 62.0 + phase_scale * 24.0
    telegraph_remaining = 1.15 - phase_scale * 0.18
    special_cooldown = [11.0, 9.0, 7.0][boss_phase - 1]
    _spawn_warning_ring()


func _spawn_warning_ring() -> void:
    var warning := MeshInstance3D.new()
    warning.name = "RiftwardenSlamWarning"
    var mesh := TorusMesh.new()
    mesh.inner_radius = 0.92
    mesh.outer_radius = 1.0
    warning.mesh = mesh
    warning.rotation_degrees.x = 90.0
    warning.position = slam_center + Vector3(0.0, 0.13, 0.0)
    warning.scale = Vector3(slam_radius, 1.0, slam_radius)

    var material := StandardMaterial3D.new()
    material.albedo_color = Color("#FF765F", 0.82)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.emission_enabled = true
    material.emission = Color("#FF4F45")
    material.emission_energy_multiplier = 1.8
    warning.material_override = material
    get_parent().add_child(warning)

    var tween := game.create_tween()
    tween.tween_property(material, "albedo_color", Color("#FF765F", 0.0), telegraph_remaining)
    tween.tween_callback(warning.queue_free)


func _execute_slam() -> void:
    var hit_count := 0
    var stun_duration := 0.48 + float(boss_phase - 1) * 0.12
    for node in get_tree().get_nodes_in_group("arena_actors"):
        if not (node is ArenaActor):
            continue
        var actor := node as ArenaActor
        if not actor.alive:
            continue
        if _flat_distance(slam_center, actor.global_position) > slam_radius:
            continue
        actor.take_damage(slam_damage, BOSS_TEAM, false)
        if actor.alive:
            actor.apply_status(&"stun", stun_duration, 0.0, BOSS_TEAM)
        hit_count += 1

    _spawn_slam_pulse()
    if hit_count > 0 and is_instance_valid(game) and game.has_method("on_boss_slam"):
        game.call("on_boss_slam", hit_count, boss_phase)


func _spawn_slam_pulse() -> void:
    var pulse := MeshInstance3D.new()
    var mesh := TorusMesh.new()
    mesh.inner_radius = 0.82
    mesh.outer_radius = 1.0
    pulse.mesh = mesh
    pulse.rotation_degrees.x = 90.0
    pulse.position = slam_center + Vector3(0.0, 0.18, 0.0)
    pulse.scale = Vector3(0.25, 1.0, 0.25)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("#FFB16C", 0.9)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.emission_enabled = true
    material.emission = Color("#FF6A4A")
    material.emission_energy_multiplier = 2.0
    pulse.material_override = material
    get_parent().add_child(pulse)
    var tween := game.create_tween()
    tween.tween_property(pulse, "scale", Vector3(slam_radius, 1.0, slam_radius), 0.38)
    tween.parallel().tween_property(material, "albedo_color", Color("#FFB16C", 0.0), 0.38)
    tween.tween_callback(pulse.queue_free)


func apply_status(
    status_kind: StringName,
    duration: float,
    magnitude: float = 0.0,
    source_team: int = -1
) -> void:
    var adjusted_duration := duration
    var adjusted_magnitude := magnitude
    if status_kind == &"stun" or status_kind == &"root":
        adjusted_duration *= 0.35
    elif status_kind == &"slow":
        adjusted_magnitude *= 0.35
    super.apply_status(status_kind, adjusted_duration, adjusted_magnitude, source_team)


func _update_health_bar() -> void:
    if not is_instance_valid(hp_fill):
        return
    var ratio := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
    hp_fill.scale.x = maxf(0.001, ratio)
    hp_fill.position.x = -1.34 * (1.0 - ratio)


func _die(killer_team: int) -> void:
    if not alive:
        return
    if is_instance_valid(game) and game.has_method("on_boss_killed"):
        game.call("on_boss_killed", self, killer_team)
    super._die(killer_team)
