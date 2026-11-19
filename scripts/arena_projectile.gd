extends Node3D
class_name ArenaProjectile

var source_team := 0
var source_is_minion := false
var target: Node3D
var damage := 10.0
var travel_speed := 14.0
var projectile_color := Color("#68DFFF")
var impact_radius := 0.62
var life_remaining := 5.0
var _visual: MeshInstance3D


func setup(
    owner_team: int,
    target_node: Node3D,
    hit_damage: float,
    speed_value: float,
    from_minion: bool,
    tint: Color
) -> void:
    source_team = owner_team
    target = target_node
    damage = maxf(0.0, hit_damage)
    travel_speed = maxf(1.0, speed_value)
    source_is_minion = from_minion
    projectile_color = tint


func _ready() -> void:
    set_process(true)
    _build_visual()


func _build_visual() -> void:
    _visual = MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.16 if not source_is_minion else 0.20
    mesh.height = mesh.radius * 2.0
    _visual.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = projectile_color
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.emission_enabled = true
    material.emission = projectile_color
    material.emission_energy_multiplier = 2.0
    _visual.material_override = material
    add_child(_visual)


func _process(delta: float) -> void:
    life_remaining -= delta
    if life_remaining <= 0.0 or not is_instance_valid(target):
        queue_free()
        return
    if target is ArenaActor:
        var actor_target := target as ArenaActor
        if not actor_target.alive or actor_target.hp <= 0.0:
            queue_free()
            return
    elif target is ArenaTower:
        var tower_target := target as ArenaTower
        if tower_target.hp <= 0.0:
            queue_free()
            return
    elif target is ArenaNeutralMonster:
        var monster_target := target as ArenaNeutralMonster
        if not monster_target.alive or monster_target.hp <= 0.0:
            queue_free()
            return

    var aim_position := target.global_position + Vector3(0.0, _target_height(), 0.0)
    var difference := aim_position - global_position
    var distance := difference.length()
    if distance <= impact_radius:
        _impact()
        return

    var step := minf(distance, travel_speed * delta)
    if distance > 0.001:
        global_position += difference / distance * step


func _target_height() -> float:
    if target is ArenaTower:
        return 2.55 if not target.core else 3.15
    if target is ArenaActor:
        return 0.82 if target.is_minion else 1.05
    if target is ArenaNeutralMonster:
        return 1.25
    return 0.8


func _impact() -> void:
    if not is_instance_valid(target):
        queue_free()
        return
    if target is ArenaActor or target is ArenaNeutralMonster:
        target.call("take_damage", damage, source_team, source_is_minion)
    elif target is ArenaTower:
        target.call("take_damage", damage, source_team, source_is_minion)
    queue_free()
