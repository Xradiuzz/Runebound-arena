extends CharacterBody3D
class_name ArenaActor

signal health_changed(current: float, maximum: float)
signal actor_died(actor: ArenaActor)

const BLUE := 0
const RED := 1

var team := BLUE
var hp := 100.0
var max_hp := 100.0
var speed := 5.0
var attack_damage := 15.0
var attack_range := 2.2
var attack_cooldown := 0.0
var target_scan_timer := 0.0
var player_attack_order := false
var attack_rate := 0.8
var target: Node3D
var is_player := false
var is_minion := false
var minion_role := "melee"
var minion_wave_scale := 1.0
var alive := true
var label := "Hero"
var hero_id := "warden"
var lane_index := 1
var lane_x := 0.0
var team_role := "mid"
var lane_goal_z := 0.0
var gold_reward := 35
var xp_reward := 50
var respawn_timer := 0.0
var respawn_delay := 10.0
var spawn_position := Vector3.ZERO
var game: Node
var bot_brain: Node

var body_mesh: MeshInstance3D
var hp_fill: MeshInstance3D
var visual_root: Node3D
var shield_aura: MeshInstance3D
var _visual_clock := 0.0

var active_statuses: Array[Dictionary] = []
var shield_points := 0.0
var shield_time := 0.0
var dash_remaining := 0.0
var dash_direction := Vector3.ZERO
var dash_target: ArenaActor
var dash_damage := 0.0
var dash_stun := 0.0
var dash_hit := false
var passive_attack_count := 0
var innate_hit_count := 0

# Runtime bonuses supplied by the six-slot item inventory.
var bonus_attack_damage := 0.0
var bonus_armor := 0.0
var bonus_attack_speed := 0.0
var bonus_move_speed := 0.0
var bonus_spell_power := 0.0
var bonus_lifesteal := 0.0
var bonus_on_hit_slow := 0.0
var team_blessing_remaining := 0.0
var team_blessing_active := false

func setup(
    actor_name: String,
    actor_team: int,
    player := false,
    minion := false,
    lane := 1,
    game_node: Node = null,
    selected_hero_id := "warden",
    selected_minion_role := "melee",
    wave_scale := 1.0,
    selected_actor_hero_id := "ash_knight",
    selected_team_role := "mid"
) -> void:
    label = actor_name
    team = actor_team
    is_player = player
    is_minion = minion
    minion_role = selected_minion_role if minion else "melee"
    minion_wave_scale = maxf(1.0, wave_scale)
    hero_id = "minion" if minion else (selected_hero_id if player else selected_actor_hero_id)
    team_role = selected_team_role if not minion else "minion"
    lane_index = clampi(lane, 0, 2)
    game = game_node

    if is_minion:
        if minion_role == "ranged":
            max_hp = 58.0
            speed = 2.55
            attack_damage = 13.0
            attack_range = 6.4
            attack_rate = 1.65
            gold_reward = 22
            xp_reward = 30
        elif minion_role == "siege":
            max_hp = 360.0
            speed = 1.82
            attack_damage = 46.0
            attack_range = 8.4
            attack_rate = 2.2
            gold_reward = 42
            xp_reward = 50
        elif minion_role == "super":
            max_hp = 260.0
            speed = 2.42
            attack_damage = 29.0
            attack_range = 2.15
            attack_rate = 0.98
            gold_reward = 30
            xp_reward = 40
        else:
            max_hp = 72.0
            speed = 2.8
            attack_damage = 9.0
            attack_range = 1.7
            attack_rate = 1.15
            gold_reward = 18
            xp_reward = 24
        max_hp *= minion_wave_scale
        attack_damage *= minion_wave_scale
        respawn_delay = 0.0
    elif is_player:
        gold_reward = 0
        xp_reward = 0
        if hero_id == "nyxara":
            max_hp = 570.0
            speed = 5.9
            attack_damage = 49.0
            attack_range = 7.2
            attack_rate = 0.88
        elif hero_id == "grom":
            max_hp = 850.0
            speed = 5.0
            attack_damage = 74.0
            attack_range = 2.8
            attack_rate = 0.86
        elif hero_id == "elyra":
            max_hp = 650.0
            speed = 5.2
            attack_damage = 42.0
            attack_range = 6.6
            attack_rate = 1.02
        elif hero_id == "vaelis":
            max_hp = 640.0
            speed = 6.35
            attack_damage = 54.0
            attack_range = 2.75
            attack_rate = 0.84
        else:
            max_hp = 700.0
            speed = 5.6
            attack_damage = 62.0
            attack_range = 2.7
            attack_rate = 0.72
    else:
        gold_reward = 180
        xp_reward = 220
        respawn_delay = 18.0
        match hero_id:
            "warden":
                max_hp = 690.0
                speed = 5.25
                attack_damage = 58.0
                attack_range = 2.7
                attack_rate = 0.82
            "nyxara":
                max_hp = 555.0
                speed = 5.7
                attack_damage = 43.0
                attack_range = 7.1
                attack_rate = 0.96
            "grom":
                max_hp = 810.0
                speed = 4.95
                attack_damage = 69.0
                attack_range = 2.8
                attack_rate = 0.88
            "elyra":
                max_hp = 620.0
                speed = 5.05
                attack_damage = 40.0
                attack_range = 6.5
                attack_rate = 1.08
            "vaelis":
                max_hp = 620.0
                speed = 6.2
                attack_damage = 52.0
                attack_range = 2.7
                attack_rate = 0.86
            _:
                max_hp = 620.0
                speed = 4.2
                attack_damage = 38.0
                attack_range = 2.2
                attack_rate = 0.95

    hp = max_hp
    _build_visuals()

func _ready() -> void:
    spawn_position = global_position
    add_to_group("arena_actors")
    health_changed.emit(hp, max_hp)

func _build_visuals() -> void:
    visual_root = Node3D.new()
    visual_root.name = "VisualRoot"
    add_child(visual_root)

    var body_material := StandardMaterial3D.new()
    body_material.albedo_color = Color("#245078") if team == BLUE else Color("#742F3D")
    body_material.metallic = 0.42
    body_material.roughness = 0.32

    var accent_material := StandardMaterial3D.new()
    accent_material.albedo_color = Color("#57D7FF") if team == BLUE else Color("#FF795E")
    accent_material.emission_enabled = true
    accent_material.emission = accent_material.albedo_color
    accent_material.emission_energy_multiplier = 1.15

    var capsule := CapsuleMesh.new()
    capsule.radius = 0.48 if not is_minion else 0.31
    capsule.height = 1.65 if not is_minion else 1.05
    body_mesh = MeshInstance3D.new()
    body_mesh.name = "Body"
    body_mesh.mesh = capsule
    body_mesh.material_override = body_material
    body_mesh.position.y = 0.82 if not is_minion else 0.52
    visual_root.add_child(body_mesh)

    var shoulder := SphereMesh.new()
    shoulder.radius = 0.22 if not is_minion else 0.13
    shoulder.height = 0.42 if not is_minion else 0.25
    var shoulder_mesh := MeshInstance3D.new()
    shoulder_mesh.mesh = shoulder
    shoulder_mesh.material_override = accent_material
    shoulder_mesh.position = Vector3(0.0, 1.25 if not is_minion else 0.78, -0.28)
    visual_root.add_child(shoulder_mesh)

    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.48 if not is_minion else 0.31
    shape.height = 1.65 if not is_minion else 1.05
    collision.shape = shape
    collision.position.y = 0.82 if not is_minion else 0.52
    add_child(collision)

    var bar_back := MeshInstance3D.new()
    var back_mesh := BoxMesh.new()
    back_mesh.size = Vector3(1.15, 0.10, 0.07) if not is_minion else Vector3(0.72, 0.07, 0.06)
    bar_back.mesh = back_mesh
    bar_back.position.y = 2.35 if not is_minion else 1.35
    var back_mat := StandardMaterial3D.new()
    back_mat.albedo_color = Color("#101722")
    bar_back.material_override = back_mat
    add_child(bar_back)

    hp_fill = MeshInstance3D.new()
    var fill_mesh := BoxMesh.new()
    fill_mesh.size = Vector3(1.08, 0.065, 0.075) if not is_minion else Vector3(0.67, 0.045, 0.065)
    hp_fill.mesh = fill_mesh
    hp_fill.position.y = 2.36 if not is_minion else 1.36
    var fill_mat := StandardMaterial3D.new()
    fill_mat.albedo_color = Color("#59E28B")
    fill_mat.emission_enabled = true
    fill_mat.emission = Color("#1B7D4B")
    fill_mat.emission_energy_multiplier = 0.45
    hp_fill.material_override = fill_mat
    add_child(hp_fill)

    var aura_mesh := SphereMesh.new()
    aura_mesh.radius = 0.78
    aura_mesh.height = 1.95
    shield_aura = MeshInstance3D.new()
    shield_aura.name = "ShieldAura"
    shield_aura.mesh = aura_mesh
    shield_aura.position.y = 0.96
    var aura_material := StandardMaterial3D.new()
    aura_material.albedo_color = Color("#68DFFF", 0.14)
    aura_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    aura_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    aura_material.emission_enabled = true
    aura_material.emission = Color("#39BFFF")
    aura_material.emission_energy_multiplier = 0.9
    shield_aura.material_override = aura_material
    shield_aura.visible = false
    visual_root.add_child(shield_aura)

    if is_minion:
        _build_minion_role_visuals()
    else:
        if hero_id == "nyxara":
            _build_nyxara_visuals()
        elif hero_id == "grom":
            _build_grom_visuals()
        elif hero_id == "elyra":
            _build_elyra_visuals()
        elif hero_id == "vaelis":
            _build_vaelis_visuals()
        else:
            _build_hero_armor()


func _build_minion_role_visuals() -> void:
    var accent := Color("#6BDFFF") if team == BLUE else Color("#FF826F")
    if minion_role == "ranged":
        var staff := MeshInstance3D.new()
        var staff_mesh := CylinderMesh.new()
        staff_mesh.top_radius = 0.045
        staff_mesh.bottom_radius = 0.07
        staff_mesh.height = 0.92
        staff.mesh = staff_mesh
        staff.position = Vector3(0.38, 0.55, 0.12)
        staff.rotation_degrees.z = -12.0
        var staff_material := StandardMaterial3D.new()
        staff_material.albedo_color = Color("#A9B8C9")
        staff_material.metallic = 0.65
        staff.material_override = staff_material
        visual_root.add_child(staff)

        var crystal := MeshInstance3D.new()
        var crystal_mesh := SphereMesh.new()
        crystal_mesh.radius = 0.16
        crystal_mesh.height = 0.32
        crystal.mesh = crystal_mesh
        crystal.position = Vector3(0.38, 1.03, 0.12)
        var crystal_material := StandardMaterial3D.new()
        crystal_material.albedo_color = accent
        crystal_material.emission_enabled = true
        crystal_material.emission = accent
        crystal_material.emission_energy_multiplier = 2.0
        crystal.material_override = crystal_material
        visual_root.add_child(crystal)
    elif minion_role == "siege":
        body_mesh.scale = Vector3(1.42, 1.18, 1.35)
        var chassis := MeshInstance3D.new()
        var chassis_mesh := BoxMesh.new()
        chassis_mesh.size = Vector3(1.05, 0.48, 1.18)
        chassis.mesh = chassis_mesh
        chassis.position = Vector3(0.0, 0.43, -0.08)
        var metal := StandardMaterial3D.new()
        metal.albedo_color = Color("#596474")
        metal.metallic = 0.72
        metal.roughness = 0.38
        chassis.material_override = metal
        visual_root.add_child(chassis)

        var barrel := MeshInstance3D.new()
        var barrel_mesh := CylinderMesh.new()
        barrel_mesh.top_radius = 0.15
        barrel_mesh.bottom_radius = 0.22
        barrel_mesh.height = 0.92
        barrel.mesh = barrel_mesh
        barrel.position = Vector3(0.0, 0.88, 0.42)
        barrel.rotation_degrees.x = 90.0
        barrel.material_override = metal
        visual_root.add_child(barrel)

        var core := MeshInstance3D.new()
        var core_mesh := SphereMesh.new()
        core_mesh.radius = 0.18
        core_mesh.height = 0.36
        core.mesh = core_mesh
        core.position = Vector3(0.0, 0.78, 0.86)
        var core_material := StandardMaterial3D.new()
        core_material.albedo_color = Color("#E7C47B")
        core_material.emission_enabled = true
        core_material.emission = Color("#E7A94D")
        core_material.emission_energy_multiplier = 1.8
        core.material_override = core_material
        visual_root.add_child(core)
    elif minion_role == "super":
        body_mesh.scale = Vector3(1.22, 1.15, 1.18)
        var crest := MeshInstance3D.new()
        var crest_mesh := PrismMesh.new()
        crest_mesh.size = Vector3(0.42, 0.62, 0.32)
        crest.mesh = crest_mesh
        crest.position = Vector3(0.0, 1.18, -0.08)
        var crest_material := StandardMaterial3D.new()
        crest_material.albedo_color = accent
        crest_material.emission_enabled = true
        crest_material.emission = accent
        crest_material.emission_energy_multiplier = 1.2
        crest.material_override = crest_material
        visual_root.add_child(crest)


func _build_hero_armor() -> void:
    var armor_material := StandardMaterial3D.new()
    armor_material.albedo_color = Color("#315C80") if team == BLUE else Color("#713847")
    armor_material.metallic = 0.62
    armor_material.roughness = 0.3

    var trim_material := StandardMaterial3D.new()
    trim_material.albedo_color = Color("#C9A765")
    trim_material.metallic = 0.78
    trim_material.roughness = 0.25

    var glow_material := StandardMaterial3D.new()
    glow_material.albedo_color = Color("#68DFFF") if team == BLUE else Color("#FF816F")
    glow_material.emission_enabled = true
    glow_material.emission = glow_material.albedo_color
    glow_material.emission_energy_multiplier = 1.55

    var dark_material := StandardMaterial3D.new()
    dark_material.albedo_color = Color("#182535") if team == BLUE else Color("#291C28")
    dark_material.roughness = 0.82

    var cape_mesh := BoxMesh.new()
    cape_mesh.size = Vector3(0.78, 0.96, 0.10)
    _add_hero_detail(cape_mesh, Vector3(0.0, 1.02, -0.36), dark_material)

    var chest_mesh := BoxMesh.new()
    chest_mesh.size = Vector3(0.82, 0.62, 0.28)
    _add_hero_detail(chest_mesh, Vector3(0.0, 1.04, 0.34), armor_material)

    var chest_trim := BoxMesh.new()
    chest_trim.size = Vector3(0.88, 0.08, 0.32)
    _add_hero_detail(chest_trim, Vector3(0.0, 1.37, 0.34), trim_material)

    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.27
    head_mesh.height = 0.52
    _add_hero_detail(head_mesh, Vector3(0.0, 1.73, 0.02), armor_material)

    var helmet_band := BoxMesh.new()
    helmet_band.size = Vector3(0.62, 0.12, 0.48)
    _add_hero_detail(helmet_band, Vector3(0.0, 1.91, 0.02), trim_material)

    var crest_mesh := CylinderMesh.new()
    crest_mesh.top_radius = 0.035
    crest_mesh.bottom_radius = 0.13
    crest_mesh.height = 0.34
    _add_hero_detail(crest_mesh, Vector3(0.0, 2.12, -0.02), glow_material)

    var shoulder_mesh := SphereMesh.new()
    shoulder_mesh.radius = 0.25
    shoulder_mesh.height = 0.42
    for side in [-1.0, 1.0]:
        _add_hero_detail(
            shoulder_mesh,
            Vector3(side * 0.47, 1.34, 0.0),
            trim_material,
            Vector3(1.0, 0.82, 1.12)
        )

        var gauntlet := BoxMesh.new()
        gauntlet.size = Vector3(0.22, 0.42, 0.25)
        _add_hero_detail(
            gauntlet,
            Vector3(side * 0.52, 0.86, 0.16),
            armor_material
        )

        var boot := CylinderMesh.new()
        boot.top_radius = 0.19
        boot.bottom_radius = 0.23
        boot.height = 0.20
        _add_hero_detail(
            boot,
            Vector3(side * 0.22, 0.12, 0.04),
            dark_material
        )

    var weapon_shaft := CylinderMesh.new()
    weapon_shaft.top_radius = 0.055
    weapon_shaft.bottom_radius = 0.075
    weapon_shaft.height = 0.82
    _add_hero_detail(
        weapon_shaft,
        Vector3(0.78, 0.93, 0.10),
        trim_material,
        Vector3.ONE,
        Vector3(0.0, 0.0, -0.12)
    )

    var hammer_head := BoxMesh.new()
    hammer_head.size = Vector3(0.48, 0.23, 0.27)
    _add_hero_detail(hammer_head, Vector3(0.78, 1.38, 0.10), armor_material)

    var hammer_core := SphereMesh.new()
    hammer_core.radius = 0.14
    hammer_core.height = 0.24
    _add_hero_detail(hammer_core, Vector3(0.78, 1.39, 0.25), glow_material)


func _build_nyxara_visuals() -> void:
    var robe_material := StandardMaterial3D.new()
    robe_material.albedo_color = Color("#283A70") if team == BLUE else Color("#522D65")
    robe_material.metallic = 0.28
    robe_material.roughness = 0.42

    var trim_material := StandardMaterial3D.new()
    trim_material.albedo_color = Color("#B9A7F5")
    trim_material.metallic = 0.55

    var glow_material := StandardMaterial3D.new()
    glow_material.albedo_color = Color("#65E8FF") if team == BLUE else Color("#FF79D8")
    glow_material.emission_enabled = true
    glow_material.emission = glow_material.albedo_color
    glow_material.emission_energy_multiplier = 2.0

    var robe := CylinderMesh.new()
    robe.top_radius = 0.25
    robe.bottom_radius = 0.58
    robe.height = 1.12
    _add_hero_detail(robe, Vector3(0.0, 0.68, 0.0), robe_material)

    var chest := SphereMesh.new()
    chest.radius = 0.39
    chest.height = 0.72
    _add_hero_detail(chest, Vector3(0.0, 1.15, 0.08), robe_material, Vector3(1.0, 1.0, 0.82))

    var hood := SphereMesh.new()
    hood.radius = 0.31
    hood.height = 0.58
    _add_hero_detail(hood, Vector3(0.0, 1.72, 0.0), trim_material, Vector3(1.0, 1.15, 0.9))

    var face := SphereMesh.new()
    face.radius = 0.19
    face.height = 0.30
    var face_material := StandardMaterial3D.new()
    face_material.albedo_color = Color("#11182B")
    _add_hero_detail(face, Vector3(0.0, 1.68, 0.22), face_material)

    var orbit := TorusMesh.new()
    orbit.inner_radius = 0.66
    orbit.outer_radius = 0.72
    _add_hero_detail(orbit, Vector3(0.0, 1.03, 0.0), glow_material, Vector3(1.0, 0.62, 1.0))

    var staff := CylinderMesh.new()
    staff.top_radius = 0.045
    staff.bottom_radius = 0.065
    staff.height = 1.55
    _add_hero_detail(staff, Vector3(0.72, 0.91, 0.08), trim_material, Vector3.ONE, Vector3(0.0, 0.0, -0.12))

    var crystal := SphereMesh.new()
    crystal.radius = 0.22
    crystal.height = 0.46
    _add_hero_detail(crystal, Vector3(0.72, 1.78, 0.08), glow_material)

    for side in [-1.0, 1.0]:
        var shard := PrismMesh.new()
        shard.size = Vector3(0.28, 0.52, 0.22)
        _add_hero_detail(
            shard,
            Vector3(side * 0.72, 1.25, -0.16),
            glow_material,
            Vector3.ONE,
            Vector3(0.0, 0.0, side * -0.22)
        )


func _build_grom_visuals() -> void:
    var hide_material := StandardMaterial3D.new()
    hide_material.albedo_color = Color("#315C4B") if team == BLUE else Color("#733C3C")
    hide_material.roughness = 0.88

    var iron_material := StandardMaterial3D.new()
    iron_material.albedo_color = Color("#485361")
    iron_material.metallic = 0.72
    iron_material.roughness = 0.3

    var ember_material := StandardMaterial3D.new()
    ember_material.albedo_color = Color("#FF7650")
    ember_material.emission_enabled = true
    ember_material.emission = Color("#FF4C36")
    ember_material.emission_energy_multiplier = 1.8

    var chest := BoxMesh.new()
    chest.size = Vector3(0.94, 0.76, 0.48)
    _add_hero_detail(chest, Vector3(0.0, 1.05, 0.12), hide_material)

    var head := SphereMesh.new()
    head.radius = 0.36
    head.height = 0.68
    _add_hero_detail(head, Vector3(0.0, 1.72, 0.12), hide_material)

    for side in [-1.0, 1.0]:
        var horn := CylinderMesh.new()
        horn.top_radius = 0.015
        horn.bottom_radius = 0.13
        horn.height = 0.58
        _add_hero_detail(
            horn,
            Vector3(side * 0.27, 2.08, 0.02),
            iron_material,
            Vector3.ONE,
            Vector3(0.0, 0.0, side * -0.55)
        )

        var pauldron := SphereMesh.new()
        pauldron.radius = 0.31
        pauldron.height = 0.43
        _add_hero_detail(pauldron, Vector3(side * 0.53, 1.39, 0.0), iron_material)

        var bracer := BoxMesh.new()
        bracer.size = Vector3(0.24, 0.46, 0.30)
        _add_hero_detail(bracer, Vector3(side * 0.52, 0.86, 0.20), hide_material)

    var axe_handle := CylinderMesh.new()
    axe_handle.top_radius = 0.055
    axe_handle.bottom_radius = 0.075
    axe_handle.height = 1.32
    _add_hero_detail(
        axe_handle,
        Vector3(0.83, 0.91, 0.12),
        hide_material,
        Vector3.ONE,
        Vector3(0.0, 0.0, -0.18)
    )

    var axe_blade := PrismMesh.new()
    axe_blade.size = Vector3(0.78, 0.62, 0.20)
    _add_hero_detail(axe_blade, Vector3(0.91, 1.54, 0.12), iron_material)

    var rune := SphereMesh.new()
    rune.radius = 0.12
    rune.height = 0.18
    _add_hero_detail(rune, Vector3(0.91, 1.54, 0.25), ember_material)


func _build_elyra_visuals() -> void:
    var robe_material := StandardMaterial3D.new()
    robe_material.albedo_color = Color("#D7D4C3") if team == BLUE else Color("#765A69")
    robe_material.roughness = 0.72
    var gold_material := StandardMaterial3D.new()
    gold_material.albedo_color = Color("#D9B96F")
    gold_material.metallic = 0.62
    var glow_material := StandardMaterial3D.new()
    glow_material.albedo_color = Color("#FFE6A0") if team == BLUE else Color("#FF9A83")
    glow_material.emission_enabled = true
    glow_material.emission = glow_material.albedo_color
    glow_material.emission_energy_multiplier = 2.2

    var mantle := CylinderMesh.new()
    mantle.top_radius = 0.22
    mantle.bottom_radius = 0.56
    mantle.height = 1.18
    _add_hero_detail(mantle, Vector3(0.0, 0.67, 0.0), robe_material)

    var chest := SphereMesh.new()
    chest.radius = 0.36
    chest.height = 0.64
    _add_hero_detail(chest, Vector3(0.0, 1.18, 0.08), robe_material)

    var halo := TorusMesh.new()
    halo.inner_radius = 0.32
    halo.outer_radius = 0.39
    _add_hero_detail(halo, Vector3(0.0, 2.0, 0.0), glow_material, Vector3(1.0, 0.78, 1.0))

    var staff := CylinderMesh.new()
    staff.top_radius = 0.035
    staff.bottom_radius = 0.06
    staff.height = 1.48
    _add_hero_detail(staff, Vector3(0.67, 0.88, 0.04), gold_material, Vector3.ONE, Vector3(0.0, 0.0, -0.10))

    var crystal := PrismMesh.new()
    crystal.size = Vector3(0.34, 0.54, 0.30)
    _add_hero_detail(crystal, Vector3(0.67, 1.72, 0.04), glow_material)

    for side in [-1.0, 1.0]:
        var wing := PrismMesh.new()
        wing.size = Vector3(0.34, 0.82, 0.16)
        _add_hero_detail(wing, Vector3(side * 0.58, 1.22, -0.34), glow_material, Vector3(1.0, 1.0, 0.72), Vector3(0.0, 0.0, side * -0.28))


func _build_vaelis_visuals() -> void:
    var leather_material := StandardMaterial3D.new()
    leather_material.albedo_color = Color("#24483F") if team == BLUE else Color("#633B43")
    leather_material.roughness = 0.82
    var steel_material := StandardMaterial3D.new()
    steel_material.albedo_color = Color("#687C82")
    steel_material.metallic = 0.76
    var glow_material := StandardMaterial3D.new()
    glow_material.albedo_color = Color("#64E2C0") if team == BLUE else Color("#FF8A79")
    glow_material.emission_enabled = true
    glow_material.emission = glow_material.albedo_color
    glow_material.emission_energy_multiplier = 1.8

    var hood := SphereMesh.new()
    hood.radius = 0.37
    hood.height = 0.68
    _add_hero_detail(hood, Vector3(0.0, 1.73, 0.02), leather_material, Vector3(1.0, 1.18, 0.92))

    var cloak := BoxMesh.new()
    cloak.size = Vector3(0.78, 1.0, 0.18)
    _add_hero_detail(cloak, Vector3(0.0, 0.92, -0.36), leather_material)

    var mask := BoxMesh.new()
    mask.size = Vector3(0.42, 0.22, 0.12)
    _add_hero_detail(mask, Vector3(0.0, 1.64, 0.32), steel_material)

    for side in [-1.0, 1.0]:
        var blade := PrismMesh.new()
        blade.size = Vector3(0.16, 0.88, 0.10)
        _add_hero_detail(blade, Vector3(side * 0.62, 0.95, 0.20), steel_material, Vector3.ONE, Vector3(0.0, 0.0, side * -0.18))
        var rune := SphereMesh.new()
        rune.radius = 0.12
        rune.height = 0.20
        _add_hero_detail(rune, Vector3(side * 0.34, 1.38, 0.20), glow_material)

    var shoulder := SphereMesh.new()
    shoulder.radius = 0.25
    shoulder.height = 0.38
    for side in [-1.0, 1.0]:
        _add_hero_detail(shoulder, Vector3(side * 0.48, 1.32, 0.0), leather_material)


func _add_hero_detail(
    mesh: Mesh,
    detail_position: Vector3,
    material: Material,
    detail_scale: Vector3 = Vector3.ONE,
    detail_rotation: Vector3 = Vector3.ZERO
) -> void:
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.position = detail_position
    instance.scale = detail_scale
    instance.rotation = detail_rotation
    instance.material_override = material
    visual_root.add_child(instance)


func _process(delta: float) -> void:
    _visual_clock += delta
    if is_instance_valid(visual_root) and alive:
        var horizontal_speed := Vector2(velocity.x, velocity.z).length()
        var moving := horizontal_speed > 0.35
        var bob_amplitude := 0.038 if moving else 0.018
        var bob_frequency := 8.5 if moving else 2.2
        visual_root.position.y = sin(_visual_clock * bob_frequency) * bob_amplitude
        visual_root.rotation.z = sin(_visual_clock * 4.8) * 0.018 if moving else 0.0

    if not team_blessing_active:
        return
    team_blessing_remaining = maxf(0.0, team_blessing_remaining - delta)
    if team_blessing_remaining <= 0.0:
        team_blessing_active = false
        bonus_attack_damage = maxf(0.0, bonus_attack_damage - 12.0)
        bonus_spell_power = maxf(0.0, bonus_spell_power - 0.10)
        bonus_move_speed = maxf(0.0, bonus_move_speed - 0.45)


func apply_team_blessing(duration: float) -> void:
    if duration <= 0.0:
        return
    if not team_blessing_active:
        team_blessing_active = true
        bonus_attack_damage += 12.0
        bonus_spell_power += 0.10
        bonus_move_speed += 0.45
    team_blessing_remaining = maxf(team_blessing_remaining, duration)


func _physics_process(delta: float) -> void:
    if is_instance_valid(game) and bool(game.get("game_over")):
        velocity = Vector3.ZERO
        return
    if not alive:
        respawn_timer -= delta
        if respawn_timer <= 0.0 and not is_minion:
            respawn()
        return

    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    _tick_statuses(delta)
    if not alive:
        return
    shield_time = maxf(0.0, shield_time - delta)
    if shield_time <= 0.0:
        shield_points = 0.0
    if is_instance_valid(shield_aura):
        shield_aura.visible = shield_points > 0.0

    if is_stunned():
        velocity.x = move_toward(velocity.x, 0.0, speed * 12.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, speed * 12.0 * delta)
        move_and_slide()
        return

    if dash_remaining > 0.0:
        _process_dash(delta)
        return

    if is_player:
        _player_control(delta)
    elif is_minion:
        _minion_brain(delta)
    else:
        _hero_brain(delta)

    move_and_slide()

func _player_control(delta: float) -> void:
    var input_dir := Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    )

    if is_rooted():
        player_attack_order = false
        velocity.x = move_toward(velocity.x, 0.0, speed * 10.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, speed * 10.0 * delta)
    elif input_dir.length() > 0.08:
        # Direct movement always overrides an attack-move order.
        player_attack_order = false
        input_dir = input_dir.normalized()
        var direction := Vector3(input_dir.x, 0.0, input_dir.y)
        var move_speed := _effective_speed()
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
        _face_direction(direction, delta)
    elif player_attack_order and _valid_target():
        _approach_or_attack(target, delta)
    else:
        player_attack_order = false
        velocity.x = move_toward(velocity.x, 0.0, speed * 6.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, speed * 6.0 * delta)

    if Input.is_action_just_pressed("attack"):
        request_attack()

func _hero_brain(delta: float) -> void:
    if not is_player and is_instance_valid(bot_brain):
        bot_brain.call("update_brain", delta)
        return

    if not _valid_target():
        _find_target(15.0)

    if not _valid_target():
        velocity.x = move_toward(velocity.x, 0.0, speed * 3.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, speed * 3.0 * delta)
        return

    _approach_or_attack(target, delta)

func _minion_brain(delta: float) -> void:
    if is_rooted():
        velocity.x = move_toward(velocity.x, 0.0, speed * 10.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, speed * 10.0 * delta)
        if _valid_target() and global_position.distance_to(target.global_position) <= attack_range:
            try_attack()
        return

    target_scan_timer = maxf(0.0, target_scan_timer - delta)
    if not _valid_target() and target_scan_timer <= 0.0:
        _find_target(maxf(4.5, attack_range + 1.8))
        target_scan_timer = 0.22

    if _valid_target():
        _approach_or_attack(target, delta)
        return

    var goal_z := lane_goal_z
    if game != null and game.has_method("get_lane_goal_z"):
        goal_z = float(game.call("get_lane_goal_z", team, lane_index))
    elif game != null and game.has_method("all_towers_destroyed"):
        if bool(game.call("all_towers_destroyed", 1 - team)):
            goal_z = -11.4 if team == BLUE else 11.4

    var goal_x := lane_x
    if game != null and game.has_method("all_towers_destroyed"):
        if bool(game.call("all_towers_destroyed", 1 - team)):
            goal_x = 0.0
    var goal := Vector3(goal_x, global_position.y, goal_z)
    var difference := goal - global_position
    difference.y = 0.0

    if difference.length() > 1.25:
        var direction := difference.normalized()
        var move_speed := _effective_speed()
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
        _face_direction(direction, delta)
    else:
        velocity.x = 0.0
        velocity.z = 0.0

func _approach_or_attack(node: Node3D, delta: float) -> void:
    var difference := node.global_position - global_position
    difference.y = 0.0
    var distance := difference.length()

    if is_rooted():
        velocity.x = move_toward(velocity.x, 0.0, speed * 10.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, speed * 10.0 * delta)
        if distance <= attack_range:
            try_attack()
        return

    if distance > attack_range:
        var direction := difference.normalized()
        var move_speed := _effective_speed()
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
        _face_direction(direction, delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, speed * 8.0 * delta)
        try_attack()

func _face_direction(direction: Vector3, delta: float) -> void:
    if direction.length_squared() < 0.001:
        return
    var desired_yaw := atan2(direction.x, direction.z)
    visual_root.rotation.y = lerp_angle(
        visual_root.rotation.y,
        desired_yaw,
        clampf(delta * 10.0, 0.0, 1.0)
    )

func _valid_target() -> bool:
    if not is_instance_valid(target):
        target = null
        return false
    if target is ArenaActor:
        return target.alive and target.hp > 0.0 and target.team != team
    if target is ArenaTower:
        return target.hp > 0.0 and target.team != team
    if target is ArenaNeutralMonster:
        return target.alive and target.hp > 0.0
    return false

func _find_target(search_range: float) -> void:
    target = null
    if get_parent() == null:
        return

    var best_score := INF
    for node in get_parent().get_children():
        if node == self or not is_instance_valid(node):
            continue

        var priority := 999
        if node is ArenaActor:
            if node.team == team or not node.alive:
                continue
            if is_minion:
                if node.is_minion:
                    priority = 0 if minion_role == "siege" and node.minion_role == "siege" else 1
                else:
                    priority = 2
            else:
                priority = 0 if not node.is_minion else 1
        elif node is ArenaTower:
            if node.team == team or node.hp <= 0.0:
                continue
            if node.core:
                if game == null or not bool(game.call("all_towers_destroyed", node.team)):
                    continue
                priority = 4
            else:
                if is_minion and node.lane_index != lane_index:
                    continue
                priority = 2
        else:
            continue

        var distance := global_position.distance_to(node.global_position)
        if distance > search_range:
            continue

        var score := float(priority) * 100.0 + distance
        if score < best_score:
            best_score = score
            target = node

    # Neutral camps are optional jungle targets for the player's hero only.
    if is_player and not is_minion:
        for node in get_tree().get_nodes_in_group("arena_neutral_monsters"):
            if not (node is ArenaNeutralMonster):
                continue
            var monster := node as ArenaNeutralMonster
            if not monster.alive:
                continue
            var monster_distance := global_position.distance_to(monster.global_position)
            if monster_distance > search_range:
                continue
            var monster_score := 300.0 + monster_distance
            if monster.is_in_group("arena_ancient_bosses"):
                monster_score = 120.0 + monster_distance
            if monster_score < best_score:
                best_score = monster_score
                target = monster

func request_attack() -> void:
    if not _valid_target():
        _find_target(attack_range + 3.0)
        target_scan_timer = 0.22
    if is_player:
        player_attack_order = _valid_target()
    try_attack()

func try_attack() -> void:
    if attack_cooldown > 0.0 or is_stunned() or not _valid_target():
        return

    var distance := global_position.distance_to(target.global_position)
    if distance > attack_range + 0.45:
        return

    if target.has_method("take_damage"):
        if not is_minion and is_instance_valid(game) and game.has_method("play_arena_sound"):
            game.call("play_arena_sound", "attack")
        var final_damage := attack_damage + bonus_attack_damage
        var effective_attack_rate := attack_rate / (1.0 + maxf(0.0, bonus_attack_speed))

        if hero_id == "warden":
            passive_attack_count += 1
            if passive_attack_count >= 4:
                passive_attack_count = 0
                final_damage += 35.0
                grant_shield(25.0, 3.0)

        elif hero_id == "nyxara":
            if bool(get_meta("nyxara_echo_ready", false)):
                final_damage += 55.0
                set_meta("nyxara_echo_ready", false)
                if target.has_method("apply_status"):
                    target.call("apply_status", &"slow", 1.2, 0.30, team)

        elif hero_id == "grom":
            passive_attack_count += 1
            var warpath_until := float(get_meta("grom_warpath_until", 0.0))
            var now := float(Time.get_ticks_msec()) / 1000.0
            if now < warpath_until:
                final_damage *= 1.0 + float(get_meta("grom_warpath_bonus", 0.0))
                effective_attack_rate *= 0.78
            if max_hp > 0.0 and hp / max_hp <= 0.35:
                final_damage *= 1.18
                effective_attack_rate *= 0.78
            if passive_attack_count >= 3:
                passive_attack_count = 0
                if target.has_method("apply_status"):
                    target.call("apply_status", &"bleed", 3.0, 11.0, team)

        if is_minion and (minion_role == "ranged" or minion_role == "siege"):
            if target is ArenaTower and minion_role == "siege":
                final_damage *= 1.70
            _fire_minion_projectile(final_damage)
            attack_cooldown = maxf(0.30, effective_attack_rate)
            return

        var damage_dealt := final_damage
        if target is ArenaActor or target is ArenaNeutralMonster:
            damage_dealt = float(target.call("take_damage", final_damage, team, is_minion))
            if bonus_on_hit_slow > 0.0 and target.has_method("apply_status"):
                target.call("apply_status", &"slow", 1.1, bonus_on_hit_slow, team)
            if bonus_lifesteal > 0.0 and damage_dealt > 0.0:
                hp = minf(max_hp, hp + damage_dealt * bonus_lifesteal)
                health_changed.emit(hp, max_hp)
                _update_health_bar()
        else:
            target.call("take_damage", final_damage, team, is_minion)

        attack_cooldown = maxf(0.30, effective_attack_rate)

func _fire_minion_projectile(hit_damage: float) -> void:
    if not is_instance_valid(game) or not is_instance_valid(target):
        return
    var projectile := ArenaProjectile.new()
    var tint := Color("#E9C879") if minion_role == "siege" else (
        Color("#67DFFF") if team == BLUE else Color("#FF8B79")
    )
    projectile.setup(
        team,
        target,
        hit_damage,
        9.5 if minion_role == "siege" else 15.0,
        true,
        tint,
        game
    )
    game.add_child(projectile)
    projectile.global_position = global_position + Vector3(0.0, 0.88, 0.0)


func _effective_speed() -> float:
    var multiplier := movement_multiplier()
    if hero_id == "grom":
        var now := float(Time.get_ticks_msec()) / 1000.0
        if now < float(get_meta("grom_warpath_until", 0.0)):
            multiplier *= 1.22
    return maxf(1.0, speed + bonus_move_speed) * multiplier


func movement_multiplier() -> float:
    var multiplier := 1.0
    for status in active_statuses:
        if StringName(status.get("kind", &"")) == &"slow":
            multiplier = minf(
                multiplier,
                1.0 - clampf(float(status.get("magnitude", 0.0)), 0.0, 0.85)
            )
    return multiplier


func is_stunned() -> bool:
    for status in active_statuses:
        if StringName(status.get("kind", &"")) == &"stun":
            return true
    return false


func is_rooted() -> bool:
    for status in active_statuses:
        var kind := StringName(status.get("kind", &""))
        if kind == &"root" or kind == &"stun":
            return true
    return false


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
        hp = maxf(0.0, hp - bleed_damage)
        _update_health_bar()
        health_changed.emit(hp, max_hp)
        if hp <= 0.0:
            _die(bleed_source_team)


func grant_shield(amount: float, duration: float) -> void:
    if amount <= 0.0 or duration <= 0.0:
        return
    shield_points += amount
    shield_time = maxf(shield_time, duration)
    if is_instance_valid(shield_aura):
        shield_aura.visible = true


func start_charge(
    target_actor: ArenaActor,
    max_distance: float,
    damage: float,
    stun_duration: float
) -> bool:
    if not alive or is_rooted() or not is_instance_valid(target_actor):
        return false
    if target_actor.team == team or not target_actor.alive:
        return false

    var difference := target_actor.global_position - global_position
    difference.y = 0.0
    var distance := difference.length()
    if distance < 0.05:
        return false

    dash_direction = difference.normalized()
    dash_target = target_actor
    dash_damage = damage
    dash_stun = stun_duration
    dash_hit = false

    var travel := minf(max_distance, maxf(0.0, distance - 1.9))
    if travel <= 0.12:
        target_actor.take_damage(dash_damage, team, false)
        target_actor.apply_status(&"stun", dash_stun)
        dash_hit = true
        return true

    dash_remaining = maxf(0.12, travel / 20.0)
    return true


func _process_dash(delta: float) -> void:
    velocity.x = dash_direction.x * 20.0
    velocity.z = dash_direction.z * 20.0
    move_and_slide()
    dash_remaining -= delta

    if not dash_hit and is_instance_valid(dash_target) and dash_target.alive:
        if global_position.distance_to(dash_target.global_position) <= 2.35:
            dash_target.take_damage(dash_damage, team, false)
            dash_target.apply_status(&"stun", dash_stun)
            dash_hit = true

    if dash_remaining <= 0.0 or dash_hit:
        dash_remaining = 0.0
        velocity = Vector3.ZERO
        dash_target = null


func take_damage(
    amount: float,
    attacker_team := -1,
    attacker_is_minion := false
) -> float:
    if not alive or amount <= 0.0:
        return 0.0
    if attacker_team == team:
        return 0.0

    var remaining_damage := amount
    var absorbed := minf(shield_points, remaining_damage)
    shield_points -= absorbed
    remaining_damage -= absorbed
    if shield_points <= 0.0:
        shield_points = 0.0
        shield_time = 0.0
    if is_instance_valid(shield_aura):
        shield_aura.visible = shield_points > 0.0

    if hero_id == "warden":
        innate_hit_count += 1
        if innate_hit_count >= 3:
            innate_hit_count = 0
            grant_shield(45.0, 3.5)

    var actual_health_damage := 0.0
    if remaining_damage > 0.0:
        remaining_damage *= 100.0 / (100.0 + maxf(0.0, bonus_armor))
        actual_health_damage = minf(hp, remaining_damage)
        hp = maxf(0.0, hp - actual_health_damage)
        _update_health_bar()
        health_changed.emit(hp, max_hp)

    if hp <= 0.0:
        _die(attacker_team)

    return actual_health_damage

func _update_health_bar() -> void:
    if not is_instance_valid(hp_fill):
        return
    var ratio := clampf(hp / max_hp, 0.0, 1.0)
    var full_width := 1.08 if not is_minion else 0.67
    hp_fill.scale.x = maxf(0.001, ratio)
    hp_fill.position.x = -full_width * 0.5 * (1.0 - ratio)

func _die(killer_team: int) -> void:
    alive = false
    active_statuses.clear()
    shield_points = 0.0
    shield_time = 0.0
    dash_remaining = 0.0
    dash_target = null
    if is_instance_valid(shield_aura):
        shield_aura.visible = false
    actor_died.emit(self)
    if game != null and game.has_method("on_actor_killed"):
        game.call("on_actor_killed", self, killer_team)

    if is_minion:
        queue_free()
        return

    respawn_timer = respawn_delay
    visible = false
    collision_layer = 0
    collision_mask = 0
    target = null
    player_attack_order = false
    velocity = Vector3.ZERO

func respawn() -> void:
    alive = true
    hp = max_hp
    attack_cooldown = 0.0
    active_statuses.clear()
    shield_points = 0.0
    shield_time = 0.0
    dash_remaining = 0.0
    dash_target = null
    target = null
    player_attack_order = false
    if is_instance_valid(shield_aura):
        shield_aura.visible = false
    global_position = spawn_position
    velocity = Vector3.ZERO
    visible = true
    collision_layer = 1
    collision_mask = 1
    _update_health_bar()
    health_changed.emit(hp, max_hp)

func apply_level_up() -> void:
    max_hp += 32.0
    hp = minf(max_hp, hp + 48.0)
    attack_damage += 3.5
    speed += 0.035
    health_changed.emit(hp, max_hp)
    _update_health_bar()
