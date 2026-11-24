extends Node3D
class_name ArenaNeutralCamp

var game: Node
var camp_id := ""
var camp_name := "Neutral Camp"
var monster_name := "Mossfang Stalker"
var monster_kind := "stalker"
var monster_health := 260.0
var monster_damage := 18.0
var monster_speed := 3.0
var monster_armor := 8.0
var monster_gold := 48
var monster_xp := 58
var monster_aggro := 5.8
var monster_leash := 10.5
var respawn_delay := 42.0
var respawn_remaining := 0.0
var monster: ArenaNeutralMonster
var ring_material: StandardMaterial3D


func setup(
    game_node: Node,
    id: String,
    display_name: String,
    kind: String,
    health: float,
    damage: float,
    speed: float,
    armor: float,
    reward_gold: int,
    reward_xp: int,
    respawn_seconds: float
) -> void:
    game = game_node
    camp_id = id
    camp_name = display_name
    monster_kind = kind
    monster_name = "Mossfang Stalker" if kind == "stalker" else "Stonehide Brute"
    monster_health = health
    monster_damage = damage
    monster_speed = speed
    monster_armor = armor
    monster_gold = reward_gold
    monster_xp = reward_xp
    respawn_delay = respawn_seconds
    # Neutral camps should defend a compact clearing, not trail the player across the map.
    monster_aggro = 4.2 if kind == "stalker" else 4.6
    monster_leash = 7.2 if kind == "stalker" else 7.8


func _ready() -> void:
    add_to_group("arena_neutral_camps")
    _build_camp_marker()
    _spawn_monster()


func _process(delta: float) -> void:
    if is_instance_valid(game) and bool(game.get("game_over")):
        return
    if is_instance_valid(monster):
        return
    if respawn_remaining <= 0.0:
        return

    respawn_remaining = maxf(0.0, respawn_remaining - delta)
    if respawn_remaining <= 0.0:
        _spawn_monster()


func _build_camp_marker() -> void:
    var accent := Color("#8CD88F") if monster_kind == "stalker" else Color("#E5C47B")
    ring_material = StandardMaterial3D.new()
    ring_material.albedo_color = Color(accent.r, accent.g, accent.b, 0.76)
    ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    ring_material.emission_enabled = true
    ring_material.emission = accent
    ring_material.emission_energy_multiplier = 1.25

    var ring := MeshInstance3D.new()
    var ring_mesh := TorusMesh.new()
    ring_mesh.inner_radius = 1.15
    ring_mesh.outer_radius = 1.32
    ring.mesh = ring_mesh
    ring.rotation_degrees.x = 90.0
    ring.position.y = 0.10
    ring.material_override = ring_material
    add_child(ring)

    var altar := MeshInstance3D.new()
    var altar_mesh := CylinderMesh.new()
    altar_mesh.top_radius = 0.62
    altar_mesh.bottom_radius = 0.82
    altar_mesh.height = 0.38
    altar.mesh = altar_mesh
    altar.position.y = 0.19
    var stone := StandardMaterial3D.new()
    stone.albedo_color = Color("#3A4650")
    stone.roughness = 0.9
    altar.material_override = stone
    add_child(altar)

    for index in range(3):
        var shard := MeshInstance3D.new()
        var shard_mesh := PrismMesh.new()
        shard_mesh.size = Vector3(0.34, 0.82 + float(index % 2) * 0.24, 0.34)
        shard.mesh = shard_mesh
        var angle := TAU * float(index) / 3.0
        shard.position = Vector3(cos(angle) * 0.62, 0.50, sin(angle) * 0.62)
        shard.rotation.y = angle
        shard.material_override = ring_material
        add_child(shard)


func _spawn_monster() -> void:
    if is_instance_valid(monster):
        return

    respawn_remaining = 0.0
    monster = ArenaNeutralMonster.new()
    monster.name = monster_name.replace(" ", "") + "_" + camp_id
    monster.setup(
        self,
        game,
        camp_id,
        monster_name,
        monster_kind,
        monster_health,
        monster_damage,
        monster_speed,
        monster_gold,
        monster_xp,
        monster_armor,
        monster_aggro,
        monster_leash
    )
    add_child(monster)
    monster.position = Vector3.ZERO


func notify_monster_defeated(defeated_monster: ArenaNeutralMonster, killer_team: int) -> void:
    if monster != defeated_monster:
        return

    monster = null
    respawn_remaining = respawn_delay
    if is_instance_valid(game) and game.has_method("on_neutral_monster_killed"):
        game.call("on_neutral_monster_killed", defeated_monster, killer_team)


func is_monster_alive() -> bool:
    return is_instance_valid(monster) and monster.alive
