extends Node3D
class_name ArenaTower

var team := 0
var hp := 520.0
var max_hp := 520.0
var attack_range := 8.5
var damage := 32.0
var cooldown := 0.0
var core := false
var lane_index := 1
var game: Node
var hp_fill: MeshInstance3D

func setup(owner_team: int, game_node: Node, is_core := false, lane := 1) -> void:
    team = owner_team
    game = game_node
    core = is_core
    lane_index = clampi(lane, 0, 2)
    max_hp = 1450.0 if core else 620.0
    hp = max_hp
    attack_range = 9.0 if not core else 10.0
    damage = 38.0 if not core else 46.0

func _ready() -> void:
    _build_visuals()
    add_to_group("arena_structures")

func _build_visuals() -> void:
    var main_color := Color("#287DBA") if team == 0 else Color("#B83E4B")
    var glow_color := Color("#62DFFF") if team == 0 else Color("#FF806B")

    var stone := StandardMaterial3D.new()
    stone.albedo_color = Color("#344052")
    stone.metallic = 0.38
    stone.roughness = 0.48

    var team_material := StandardMaterial3D.new()
    team_material.albedo_color = main_color
    team_material.metallic = 0.52
    team_material.roughness = 0.3

    var glow := StandardMaterial3D.new()
    glow.albedo_color = glow_color
    glow.emission_enabled = true
    glow.emission = glow_color
    glow.emission_energy_multiplier = 2.2
    glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

    _add_mesh(CylinderMesh.new(), Vector3(0.0, 0.42, 0.0), Vector3(2.5, 0.85, 2.5), stone)

    var shaft := CylinderMesh.new()
    shaft.top_radius = 0.72 if not core else 1.0
    shaft.bottom_radius = 1.05 if not core else 1.35
    shaft.height = 2.1 if not core else 2.7
    _add_mesh(shaft, Vector3(0.0, 1.75 if not core else 2.0, 0.0), Vector3.ONE, team_material)

    var crystal := SphereMesh.new()
    crystal.radius = 0.58 if not core else 0.88
    crystal.height = 1.15 if not core else 1.75
    _add_mesh(crystal, Vector3(0.0, 3.0 if not core else 3.65, 0.0), Vector3.ONE, glow)

    var ring_mesh := TorusMesh.new()
    ring_mesh.inner_radius = 0.78
    ring_mesh.outer_radius = 0.92
    _add_mesh(ring_mesh, Vector3(0.0, 0.12, 0.0), Vector3.ONE, glow)

    var back := MeshInstance3D.new()
    var back_box := BoxMesh.new()
    back_box.size = Vector3(1.7, 0.13, 0.09)
    back.mesh = back_box
    back.position = Vector3(0.0, 4.15 if not core else 4.8, 0.0)
    var back_mat := StandardMaterial3D.new()
    back_mat.albedo_color = Color("#101722")
    back.material_override = back_mat
    add_child(back)

    hp_fill = MeshInstance3D.new()
    var fill_box := BoxMesh.new()
    fill_box.size = Vector3(1.58, 0.085, 0.1)
    hp_fill.mesh = fill_box
    hp_fill.position = Vector3(0.0, 4.16 if not core else 4.81, -0.01)
    var fill_mat := StandardMaterial3D.new()
    fill_mat.albedo_color = Color("#65E69A")
    fill_mat.emission_enabled = true
    fill_mat.emission = Color("#23834D")
    fill_mat.emission_energy_multiplier = 0.55
    hp_fill.material_override = fill_mat
    add_child(hp_fill)

func _add_mesh(
    mesh: Mesh,
    mesh_position: Vector3,
    mesh_scale: Vector3,
    material: Material
) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.position = mesh_position
    instance.scale = mesh_scale
    instance.material_override = material
    add_child(instance)
    return instance

func _process(delta: float) -> void:
    if is_instance_valid(game) and bool(game.get("game_over")):
        return
    if hp <= 0.0:
        return

    if core and game != null and not bool(game.call("all_towers_destroyed", team)):
        return

    cooldown = maxf(0.0, cooldown - delta)
    if cooldown > 0.0 or get_parent() == null:
        return

    var chosen: ArenaActor
    var chosen_priority := 999
    var chosen_distance := INF

    # A lane tower protects its own lane. It must not shoot at units fighting
    # in a neighboring lane just because they happen to enter its radius.
    for node in get_parent().get_children():
        if not (node is ArenaActor):
            continue
        var candidate := node as ArenaActor
        if candidate.team == team or not candidate.alive:
            continue

        var offset := candidate.global_position - global_position
        offset.y = 0.0
        var distance := offset.length()
        if distance > attack_range:
            continue
        if not core and candidate.lane_index != lane_index:
            continue

        var priority := 2
        if candidate.is_minion:
            # Siege engines are the most dangerous lane units; regular creeps
            # absorb tower shots before heroes can be selected.
            priority = 0 if candidate.minion_role == "siege" else 1

        var score := float(priority) * 100.0 + distance
        var current_score := float(chosen_priority) * 100.0 + chosen_distance
        if score < current_score:
            chosen = candidate
            chosen_priority = priority
            chosen_distance = distance

    if is_instance_valid(chosen):
        chosen.take_damage(damage, team, false)
        cooldown = 1.25 if not core else 1.0

func take_damage(
    amount: float,
    attacker_team := -1,
    attacker_is_minion := false
) -> void:
    if hp <= 0.0 or amount <= 0.0 or attacker_team == team:
        return

    if core and game != null and not bool(game.call("all_towers_destroyed", team)):
        return

    hp = maxf(0.0, hp - amount)
    _update_health_bar()

    if hp <= 0.0:
        if game != null and game.has_method("on_structure_destroyed"):
            game.call("on_structure_destroyed", team, core, lane_index)
        queue_free()

func _update_health_bar() -> void:
    if not is_instance_valid(hp_fill):
        return
    var ratio := clampf(hp / max_hp, 0.0, 1.0)
    hp_fill.scale.x = maxf(0.001, ratio)
    hp_fill.position.x = -0.79 * (1.0 - ratio)
