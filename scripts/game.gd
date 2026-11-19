extends Node3D

const LANE_X := [-10.0, 0.0, 10.0]
const BLUE := 0
const RED := 1
const BOSS_POSITION := Vector3(6.6, 0.0, 0.0)
const BOSS_FIRST_SPAWN := 120.0
const BOSS_RESPAWN_DELAY := 180.0
const TEAM_BLESSING_DURATION := 90.0
const NEUTRAL_CAMP_LAYOUT := [
    {"id": "blue_grove", "name": "Blue Grove", "position": Vector3(-14.0, 0.0, 6.5), "kind": "stalker"},
    {"id": "blue_quarry", "name": "Blue Quarry", "position": Vector3(14.0, 0.0, 6.5), "kind": "brute"},
    {"id": "red_grove", "name": "Red Grove", "position": Vector3(-14.0, 0.0, -6.5), "kind": "stalker"},
    {"id": "red_quarry", "name": "Red Quarry", "position": Vector3(14.0, 0.0, -6.5), "kind": "brute"}
]

var player: ArenaActor
var enemy: ArenaActor
var team_director: ArenaTeamDirector
var targeting: ArenaTargeting
var mobile_layout: ArenaMobileLayout
var performance_profile: ArenaPerformanceProfile
var game_camera: Camera3D
var team_status_label: Label
var hud: CanvasLayer
var status_label: Label
var message_label: Label
var joystick_origin := Vector2(145.0, 600.0)
var joystick_touch := -1
var joystick_vector := Vector2.ZERO
var joystick_base: Panel
var joystick_knob: Panel
var attack_button: Button
var mana_label: Label
var ability_buttons: Dictionary = {}
var upgrade_buttons: Dictionary = {}
var hero_abilities: Node
var item_inventory: ArenaItemInventory
var shop_button: Button
var shop_panel: Panel
var shop_gold_label: Label
var shop_status_label: Label
var shop_sell_mode_button: Button
var shop_sell_mode := false
var shop_buy_buttons: Dictionary = {}
var inventory_buttons: Array[Button] = []
var minimap: ArenaMinimap
var wave_director: ArenaWaveDirector
var wave_status_label: Label
var wave_status_refresh := 0.0
var neutral_camps: Array[ArenaNeutralCamp] = []
var ancient_boss: ArenaAncientBoss
var boss_spawn_timer := BOSS_FIRST_SPAWN
var boss_status_label: Label
var blue_blessing_remaining := 0.0
var red_blessing_remaining := 0.0
var talent_system: ArenaTalentSystem
var talent_button: Button
var talent_panel: Panel
var talent_tier_labels: Dictionary = {}
var talent_choice_buttons: Dictionary = {}
var settings_button: Button
var settings_panel: Panel
var settings_quality_label: Label
var settings_description_label: Label
var settings_fps_label: Label
var settings_refresh_timer := 0.0
var camera_zoom := 1.0
var _active_touch_positions: Dictionary = {}
var _pinch_distance := 0.0
var economy_timer := 0.0
var shop_refresh_timer := 0.0
var selection_layer: CanvasLayer
var selected_hero_id := "warden"
var match_started := false

var match_time := 0.0
var player_gold := 500
var player_xp := 0
var player_level := 1
var skill_points := 1
var game_over := false

var blue_towers: Array[ArenaTower] = []
var red_towers: Array[ArenaTower] = []
var blue_core: ArenaTower
var red_core: ArenaTower

func _ready() -> void:
    _setup_input()
    _make_world()
    _spawn_structures()
    _spawn_hero_select()
    mobile_layout = ArenaMobileLayout.new()
    mobile_layout.name = "ArenaMobileLayout"
    add_child(mobile_layout)
    mobile_layout.set_layers(selection_layer, null)

func _setup_input() -> void:
    for action in [
        "move_up", "move_down", "move_left", "move_right", "attack",
        "cast_q", "cast_w", "cast_e", "cast_r",
        "item_1", "item_2", "item_3", "item_4", "item_5", "item_6"
    ]:
        if not InputMap.has_action(action):
            InputMap.add_action(action)

    _add_key("move_up", KEY_W)
    _add_key("move_up", KEY_UP)
    _add_key("move_down", KEY_S)
    _add_key("move_down", KEY_DOWN)
    _add_key("move_left", KEY_A)
    _add_key("move_left", KEY_LEFT)
    _add_key("move_right", KEY_D)
    _add_key("move_right", KEY_RIGHT)
    _add_key("attack", KEY_SPACE)
    _add_key("cast_q", KEY_1)
    _add_key("cast_w", KEY_2)
    _add_key("cast_e", KEY_3)
    _add_key("cast_r", KEY_4)
    _add_key("item_1", KEY_F)
    _add_key("item_2", KEY_G)
    _add_key("item_3", KEY_H)
    _add_key("item_4", KEY_J)
    _add_key("item_5", KEY_K)
    _add_key("item_6", KEY_L)

func _add_key(action: String, keycode: int) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = keycode
    InputMap.action_add_event(action, event)

func _make_world() -> void:
    var environment_node := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#101A2B")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#8299B8")
    environment.ambient_light_energy = 0.72
    environment_node.environment = environment
    add_child(environment_node)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
    sun.light_energy = 1.35
    sun.shadow_enabled = true
    sun.add_to_group("arena_quality_lights")
    add_child(sun)

    _add_box("Arena Ground", Vector3(0.0, -0.45, 0.0), Vector3(42.0, 0.9, 30.0), Color("#244632"))

    for lane in range(3):
        var x: float = LANE_X[lane]
        _add_box("Lane %d" % lane, Vector3(x, 0.025, 0.0), Vector3(4.5, 0.07, 27.0), Color("#77736A"))
        _add_box("Lane edge left", Vector3(x - 2.32, 0.07, 0.0), Vector3(0.12, 0.09, 27.0), Color("#B6A77E"))
        _add_box("Lane edge right", Vector3(x + 2.32, 0.07, 0.0), Vector3(0.12, 0.09, 27.0), Color("#B6A77E"))

        for mark in range(7):
            var z := -11.0 + float(mark) * 3.65
            _add_box("Lane rune", Vector3(x, 0.085, z), Vector3(0.28, 0.025, 0.72), Color("#C6B77E"))

    _add_box("Blue base platform", Vector3(0.0, 0.08, 12.0), Vector3(30.0, 0.18, 3.0), Color("#263F5D"))
    _add_box("Red base platform", Vector3(0.0, 0.08, -12.0), Vector3(30.0, 0.18, 3.0), Color("#5C303B"))

    _make_forest_decoration()
    _build_boss_altar()

    var camera := Camera3D.new()
    camera.name = "MobaCamera"
    camera.position = Vector3(0.0, 26.0, 23.0)
    camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
    camera.current = true
    camera.fov = 48.0
    add_child(camera)
    game_camera = camera

func _add_box(
    object_name: String,
    position: Vector3,
    size: Vector3,
    color: Color
) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.name = object_name
    var mesh := BoxMesh.new()
    mesh.size = size
    instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.88
    instance.material_override = material
    instance.position = position
    add_child(instance)
    return instance

func _make_forest_decoration() -> void:
    var trunk_material := StandardMaterial3D.new()
    trunk_material.albedo_color = Color("#493B32")
    var leaf_material := StandardMaterial3D.new()
    leaf_material.albedo_color = Color("#28533F")
    leaf_material.roughness = 1.0

    for side in [-1.0, 1.0]:
        for x_abs in [15.0, 18.0]:
            for z in [-10.0, -5.0, 0.0, 5.0, 10.0]:
                var tree_position := Vector3(side * x_abs, 0.0, z)
                var overlaps_camp := false
                for camp_data in NEUTRAL_CAMP_LAYOUT:
                    var camp_position: Vector3 = camp_data["position"]
                    if Vector2(tree_position.x, tree_position.z).distance_to(
                        Vector2(camp_position.x, camp_position.z)
                    ) < 2.8:
                        overlaps_camp = true
                        break
                if overlaps_camp:
                    continue
                var tree := Node3D.new()
                tree.position = tree_position
                add_child(tree)

                var trunk := MeshInstance3D.new()
                var trunk_mesh := CylinderMesh.new()
                trunk_mesh.top_radius = 0.18
                trunk_mesh.bottom_radius = 0.28
                trunk_mesh.height = 1.8
                trunk.mesh = trunk_mesh
                trunk.position.y = 0.9
                trunk.material_override = trunk_material
                tree.add_child(trunk)

                var crown := MeshInstance3D.new()
                var crown_mesh := SphereMesh.new()
                crown_mesh.radius = 1.0
                crown_mesh.height = 1.8
                crown.mesh = crown_mesh
                crown.scale = Vector3(1.0, 1.25, 1.0)
                crown.position.y = 2.1
                crown.material_override = leaf_material
                tree.add_child(crown)

func _build_boss_altar() -> void:
    var altar := Node3D.new()
    altar.name = "ElderRiftwardenAltar"
    altar.position = BOSS_POSITION
    add_child(altar)

    var platform := MeshInstance3D.new()
    var platform_mesh := CylinderMesh.new()
    platform_mesh.top_radius = 2.0
    platform_mesh.bottom_radius = 2.35
    platform_mesh.height = 0.32
    platform.mesh = platform_mesh
    platform.position.y = 0.16
    var stone := StandardMaterial3D.new()
    stone.albedo_color = Color("#344451")
    stone.roughness = 0.92
    platform.material_override = stone
    altar.add_child(platform)

    var rune_ring := MeshInstance3D.new()
    var ring_mesh := TorusMesh.new()
    ring_mesh.inner_radius = 1.62
    ring_mesh.outer_radius = 1.78
    rune_ring.mesh = ring_mesh
    rune_ring.rotation_degrees.x = 90.0
    rune_ring.position.y = 0.34
    var rune_material := StandardMaterial3D.new()
    rune_material.albedo_color = Color("#65CFE2")
    rune_material.emission_enabled = true
    rune_material.emission = Color("#3CAFCB")
    rune_material.emission_energy_multiplier = 1.5
    rune_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    rune_ring.material_override = rune_material
    altar.add_child(rune_ring)

    for index in range(4):
        var shard := MeshInstance3D.new()
        var shard_mesh := PrismMesh.new()
        shard_mesh.size = Vector3(0.48, 1.15, 0.48)
        shard.mesh = shard_mesh
        var angle := TAU * float(index) / 4.0
        shard.position = Vector3(cos(angle) * 1.35, 0.68, sin(angle) * 1.35)
        shard.rotation.y = angle
        shard.material_override = rune_material
        altar.add_child(shard)


func _spawn_structure(
    structure_name: String,
    position: Vector3,
    owner_team: int,
    is_core := false,
    lane := 1
) -> ArenaTower:
    var structure := ArenaTower.new()
    structure.name = structure_name
    structure.setup(owner_team, self, is_core, lane)
    structure.position = position
    add_child(structure)
    return structure

func _spawn_structures() -> void:
    for lane in range(3):
        var x: float = LANE_X[lane]
        blue_towers.append(_spawn_structure(
            "Blue Tower %d" % lane, Vector3(x, 0.0, 8.0), BLUE, false, lane
        ))
        red_towers.append(_spawn_structure(
            "Red Tower %d" % lane, Vector3(x, 0.0, -8.0), RED, false, lane
        ))

    blue_core = _spawn_structure("Blue Ancient", Vector3(0.0, 0.0, 12.7), BLUE, true, 1)
    red_core = _spawn_structure("Red Ancient", Vector3(0.0, 0.0, -12.7), RED, true, 1)

func _spawn_actor(
    actor_name: String,
    actor_team: int,
    position: Vector3,
    is_player := false,
    is_minion := false,
    lane := 1,
    hero_id := "warden",
    minion_role := "melee",
    wave_scale := 1.0,
    actor_hero_id := "ash_knight",
    actor_role := "mid"
) -> ArenaActor:
    var actor := ArenaActor.new()
    actor.name = actor_name
    actor.setup(
        actor_name, actor_team, is_player, is_minion, lane, self, hero_id,
        minion_role, wave_scale, actor_hero_id, actor_role
    )
    actor.position = position
    actor.lane_x = LANE_X[clampi(lane, 0, 2)]
    actor.lane_goal_z = -8.0 if actor_team == BLUE else 8.0
    if actor_team == BLUE and blue_blessing_remaining > 0.0:
        actor.apply_team_blessing(blue_blessing_remaining)
    elif actor_team == RED and red_blessing_remaining > 0.0:
        actor.apply_team_blessing(red_blessing_remaining)
    add_child(actor)
    return actor


func _spawn_heroes() -> void:
    var role_by_hero := {
        "warden": "offlane",
        "nyxara": "mid",
        "grom": "carry",
        "elyra": "support",
        "vaelis": "roamer"
    }
    var hero_by_role := {
        "offlane": "warden",
        "mid": "nyxara",
        "carry": "grom",
        "support": "elyra",
        "roamer": "vaelis"
    }
    var name_by_hero := {
        "warden": "Warden",
        "nyxara": "Nyxara",
        "grom": "Grom",
        "elyra": "Elyra",
        "vaelis": "Vaelis",
        "ash_knight": "Ash Knight"
    }
    var role_x_offsets := {
        "offlane": -0.35,
        "mid": 0.0,
        "carry": -0.62,
        "support": 0.62,
        "roamer": 0.78
    }
    var active_roles := ["offlane", "mid", "carry", "support", "roamer"]
    var player_role := str(role_by_hero.get(selected_hero_id, "mid"))
    var player_lane := team_director.lane_for_role(player_role) if is_instance_valid(team_director) else 1
    var player_x := LANE_X[player_lane] + float(role_x_offsets.get(player_role, 0.0))

    player = _spawn_actor(
        str(name_by_hero.get(selected_hero_id, "Warden")),
        BLUE,
        Vector3(player_x, 0.0, 6.0),
        true,
        false,
        player_lane,
        selected_hero_id,
        "melee",
        1.0,
        selected_hero_id,
        player_role
    )
    if is_instance_valid(team_director):
        team_director.register_actor(player, player_role)

    for role_variant in active_roles:
        var blue_role := str(role_variant)
        if blue_role == player_role:
            continue
        var ally_hero_id := str(hero_by_role[blue_role])
        var ally_lane := team_director.lane_for_role(blue_role) if is_instance_valid(team_director) else 1
        var ally_x := LANE_X[ally_lane] + float(role_x_offsets.get(blue_role, 0.0))
        var ally := _spawn_actor(
            "Blue %s" % str(name_by_hero[ally_hero_id]),
            BLUE,
            Vector3(ally_x, 0.0, 6.8 + float(active_roles.find(blue_role)) * 0.12),
            false,
            false,
            ally_lane,
            "warden",
            "melee",
            1.0,
            ally_hero_id,
            blue_role
        )
        if is_instance_valid(team_director):
            team_director.register_actor(ally, blue_role)
        _attach_bot_brain(ally)

    # The red side mirrors all five roles; Ash Knight is its signature offlaner.
    for role_variant in active_roles:
        var red_role := str(role_variant)
        var red_hero_id := "ash_knight" if red_role == "offlane" else str(hero_by_role[red_role])
        var red_lane := team_director.lane_for_role(red_role) if is_instance_valid(team_director) else 1
        var red_x := LANE_X[red_lane] + float(role_x_offsets.get(red_role, 0.0))
        var red_actor := _spawn_actor(
            str(name_by_hero[red_hero_id]),
            RED,
            Vector3(red_x, 0.0, -6.0 - float(active_roles.find(red_role)) * 0.12),
            false,
            false,
            red_lane,
            "warden",
            "melee",
            1.0,
            red_hero_id,
            red_role
        )
        if is_instance_valid(team_director):
            team_director.register_actor(red_actor, red_role)
        _attach_bot_brain(red_actor)
        if red_hero_id == "ash_knight":
            enemy = red_actor

    if selected_hero_id == "warden":
        hero_abilities = WardenAbilities.new()
        hero_abilities.name = "WardenAbilities"
    else:
        hero_abilities = ArenaHeroKit.new()
        hero_abilities.name = "ArenaHeroKit"
    player.add_child(hero_abilities)


func _attach_bot_brain(actor: ArenaActor) -> void:
    if not is_instance_valid(actor) or actor.is_player or actor.is_minion:
        return
    if actor.hero_id == "warden":
        var warden_kit := WardenAbilities.new()
        warden_kit.name = "WardenAbilities"
        actor.add_child(warden_kit)
    elif actor.hero_id in ["nyxara", "grom", "elyra", "vaelis"]:
        var hero_kit := ArenaHeroKit.new()
        hero_kit.name = "ArenaHeroKit"
        actor.add_child(hero_kit)

    var loadout := ArenaBotLoadout.new()
    loadout.name = "ArenaBotLoadout"
    actor.add_child(loadout)

    var brain := ArenaBotBrain.new()
    brain.name = "%sBrain" % actor.hero_id.capitalize()
    actor.add_child(brain)
    actor.bot_brain = brain


func spawn_lane_wave(wave_number: int, siege_wave: bool, stat_scale: float) -> void:
    var safe_scale := clampf(stat_scale, 1.0, 1.35)
    for lane in range(3):
        var lane_x: float = LANE_X[lane]
        for team_index in range(2):
            var team := BLUE if team_index == 0 else RED
            var spawn_z := 5.35 if team == BLUE else -5.35
            var direction := 1.0 if team == BLUE else -1.0
            var enemy_towers: Array[ArenaTower] = red_towers if team == BLUE else blue_towers
            var enemy_tower_destroyed := false
            if lane < enemy_towers.size():
                var enemy_tower := enemy_towers[lane]
                enemy_tower_destroyed = (
                    not is_instance_valid(enemy_tower) or enemy_tower.hp <= 0.0
                )

            # Priority reinforcements spawn before the regular wave so the
            # per-lane cap cannot silently suppress siege / super units.
            if siege_wave:
                _spawn_lane_minion(
                    "Blue Siege Engine" if team == BLUE else "Red Siege Engine",
                    team,
                    lane,
                    Vector3(lane_x + 0.35, 0.0, spawn_z + direction * 1.55),
                    "siege",
                    safe_scale,
                    wave_number
                )
            if enemy_tower_destroyed:
                _spawn_lane_minion(
                    "Blue Lane Vanguard" if team == BLUE else "Red Lane Vanguard",
                    team,
                    lane,
                    Vector3(lane_x - 0.38, 0.0, spawn_z + direction * 0.95),
                    "super",
                    safe_scale,
                    wave_number
                )

            for index in range(3):
                var offset := float(index - 1) * 0.78
                _spawn_lane_minion(
                    "Sentinel" if team == BLUE else "Raider",
                    team,
                    lane,
                    Vector3(lane_x + offset, 0.0, spawn_z + direction * float(index % 2) * 0.24),
                    "melee",
                    safe_scale,
                    wave_number
                )
            _spawn_lane_minion(
                "Sentinel Arcanist" if team == BLUE else "Raider Arcanist",
                team,
                lane,
                Vector3(lane_x, 0.0, spawn_z + direction * 1.15),
                "ranged",
                safe_scale,
                wave_number
            )

    if is_instance_valid(message_label):
        if siege_wave:
            message_label.text = "Wave %d • Siege engines deployed on all lanes" % wave_number
        else:
            message_label.text = "Wave %d • Reinforcements have reached the lanes" % wave_number

func _spawn_lane_minion(
    actor_name: String,
    actor_team: int,
    lane: int,
    spawn_position: Vector3,
    role: String,
    stat_scale: float,
    wave_number: int
) -> void:
    if count_lane_minions(actor_team, lane) >= 10:
        return
    _spawn_actor(
        "%s W%d" % [actor_name, wave_number],
        actor_team,
        spawn_position,
        false,
        true,
        lane,
        "warden",
        role,
        stat_scale
    )


func count_lane_minions(actor_team: int, lane: int) -> int:
    var count := 0
    for node in get_tree().get_nodes_in_group("arena_actors"):
        if not (node is ArenaActor):
            continue
        var actor := node as ArenaActor
        if actor.alive and actor.is_minion and actor.team == actor_team and actor.lane_index == lane:
            count += 1
    return count


func get_lane_pressure(actor_team: int, lane: int) -> int:
    return count_lane_minions(actor_team, lane) - count_lane_minions(1 - actor_team, lane)


func get_lane_goal_z(actor_team: int, lane: int) -> float:
    var safe_lane := clampi(lane, 0, 2)
    var enemy_towers: Array[ArenaTower] = red_towers if actor_team == BLUE else blue_towers
    if safe_lane < enemy_towers.size():
        var enemy_tower := enemy_towers[safe_lane]
        if is_instance_valid(enemy_tower) and enemy_tower.hp > 0.0:
            return -8.0 if actor_team == BLUE else 8.0
    if all_towers_destroyed(1 - actor_team):
        return -11.4 if actor_team == BLUE else 11.4
    return -10.25 if actor_team == BLUE else 10.25

func _spawn_neutral_camps() -> void:
    for existing_camp in neutral_camps:
        if is_instance_valid(existing_camp):
            existing_camp.queue_free()
    neutral_camps.clear()

    for camp_data in NEUTRAL_CAMP_LAYOUT:
        var kind := str(camp_data["kind"])
        var is_brute := kind == "brute"
        var camp := ArenaNeutralCamp.new()
        camp.name = str(camp_data["name"]).replace(" ", "")
        camp.setup(
            self,
            str(camp_data["id"]),
            str(camp_data["name"]),
            kind,
            520.0 if is_brute else 285.0,
            29.0 if is_brute else 18.0,
            2.65 if is_brute else 3.1,
            16.0 if is_brute else 8.0,
            86 if is_brute else 50,
            96 if is_brute else 58,
            58.0 if is_brute else 44.0
        )
        camp.position = camp_data["position"]
        add_child(camp)
        neutral_camps.append(camp)


func _spawn_hero_select() -> void:
    selection_layer = CanvasLayer.new()
    selection_layer.layer = 20
    add_child(selection_layer)

    var backdrop := ColorRect.new()
    backdrop.name = "SelectionBackdrop"
    backdrop.color = Color("#07111F", 0.94)
    backdrop.size = Vector2(1280.0, 720.0)
    selection_layer.add_child(backdrop)

    var title := Label.new()
    title.text = "CHOOSE YOUR CHAMPION"
    title.position = Vector2(0.0, 42.0)
    title.size = Vector2(1280.0, 58.0)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 38)
    title.add_theme_color_override("font_color", Color("#F2F6FF"))
    selection_layer.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Five roles. Two armies. One war for the Ancients."
    subtitle.position = Vector2(0.0, 105.0)
    subtitle.size = Vector2(1280.0, 32.0)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 18)
    subtitle.add_theme_color_override("font_color", Color("#AFC4DF"))
    selection_layer.add_child(subtitle)

    var roster := [
        {
            "id": "warden",
            "name": "WARDEN",
            "role": "OFFLANE  •  INITIATOR",
            "icon": "✦",
            "color": Color("#3C9BC5"),
            "description": "An iron oathkeeper who turns enemy pressure into protection.",
            "skills": "Q Runic Charge\nW Aegis Ward\nE Hammerfall\nR Chrono Bastion",
            "stats": "TANK  █████  CONTROL  ████"
        },
        {
            "id": "nyxara",
            "name": "NYXARA",
            "role": "MID  •  CONTROL MAGE",
            "icon": "✧",
            "color": Color("#8C75D8"),
            "description": "A veilwalker who bends distance and binds foes in starlight.",
            "skills": "Q Rift Step\nW Astral Snare\nE Starfall\nR Void Eclipse",
            "stats": "MAGIC  █████  MOBILITY  ████"
        },
        {
            "id": "grom",
            "name": "GROM",
            "role": "CARRY  •  BERSERKER",
            "icon": "⚔",
            "color": Color("#C66C4E"),
            "description": "A relentless warbeast whose wounds fuel a brutal frenzy.",
            "skills": "Q Savage Leap\nW Blood Howl\nE Cleaving Arc\nR Warpath",
            "stats": "DAMAGE  █████  DURABILITY  ████"
        },
        {
            "id": "elyra",
            "name": "ELYRA",
            "role": "SUPPORT  •  WARDEN OF DAWN",
            "icon": "☼",
            "color": Color("#D8BD79"),
            "description": "A radiant keeper who heals allies, shields carries and binds pursuers.",
            "skills": "Q Mending Ray\nW Sanctuary\nE Binding Light\nR Dawn Chorus",
            "stats": "HEALING  █████  CONTROL  ███"
        },
        {
            "id": "vaelis",
            "name": "VAELIS",
            "role": "ROAMER  •  SHADOW HUNTER",
            "icon": "◈",
            "color": Color("#55BFA0"),
            "description": "A swift skirmisher who hunts isolated targets and opens team fights.",
            "skills": "Q Shadow Pounce\nW Hunter's Mark\nE Gale Cut\nR Nightfall",
            "stats": "MOBILITY  █████  PICKOFF  ████"
        }
    ]

    for index in range(roster.size()):
        var hero_data: Dictionary = roster[index]
        var hero_color: Color = hero_data["color"]
        var card := Panel.new()
        card.position = Vector2(34.0 + float(index) * 242.0, 175.0)
        card.size = Vector2(220.0, 455.0)
        card.add_theme_stylebox_override(
            "panel",
            _panel_style(Color("#17263B"), 0.98, 22)
        )
        selection_layer.add_child(card)

        var accent := ColorRect.new()
        accent.color = hero_color
        accent.position = Vector2(14.0, 18.0)
        accent.size = Vector2(192.0, 5.0)
        card.add_child(accent)

        var icon := Label.new()
        icon.text = str(hero_data["icon"])
        icon.position = Vector2(14.0, 31.0)
        icon.size = Vector2(192.0, 68.0)
        icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        icon.add_theme_font_size_override("font_size", 48)
        icon.add_theme_color_override("font_color", hero_color.lightened(0.25))
        card.add_child(icon)

        var name_label := Label.new()
        name_label.text = str(hero_data["name"])
        name_label.position = Vector2(12.0, 103.0)
        name_label.size = Vector2(196.0, 36.0)
        name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        name_label.add_theme_font_size_override("font_size", 23)
        name_label.add_theme_color_override("font_color", Color("#F4F7FF"))
        card.add_child(name_label)

        var role_label := Label.new()
        role_label.text = str(hero_data["role"])
        role_label.position = Vector2(10.0, 140.0)
        role_label.size = Vector2(200.0, 26.0)
        role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        role_label.add_theme_font_size_override("font_size", 10)
        role_label.add_theme_color_override("font_color", hero_color.lightened(0.25))
        card.add_child(role_label)

        var description := Label.new()
        description.text = str(hero_data["description"])
        description.position = Vector2(16.0, 173.0)
        description.size = Vector2(188.0, 66.0)
        description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        description.add_theme_font_size_override("font_size", 12)
        description.add_theme_color_override("font_color", Color("#D0DDED"))
        card.add_child(description)

        var skills := Label.new()
        skills.text = str(hero_data["skills"])
        skills.position = Vector2(16.0, 244.0)
        skills.size = Vector2(188.0, 108.0)
        skills.add_theme_font_size_override("font_size", 12)
        skills.add_theme_color_override("font_color", Color("#B8CBE2"))
        card.add_child(skills)

        var stats := Label.new()
        stats.text = str(hero_data["stats"])
        stats.position = Vector2(12.0, 360.0)
        stats.size = Vector2(196.0, 28.0)
        stats.add_theme_font_size_override("font_size", 8)
        stats.add_theme_color_override("font_color", Color("#93A8C2"))
        card.add_child(stats)

        var choose_button := _make_button(
            "SELECT " + String(hero_data["name"]),
            Vector2(12.0, 407.0),
            Vector2(196.0, 40.0),
            hero_color
        )
        choose_button.add_theme_font_size_override("font_size", 13)
        choose_button.pressed.connect(_start_match.bind(String(hero_data["id"])))
        card.add_child(choose_button)

    var footer := Label.new()
    footer.text = "RUN BOUND ARENA   •   GODOT 4   •   ANDROID / DESKTOP PROTOTYPE"
    footer.position = Vector2(0.0, 666.0)
    footer.size = Vector2(1280.0, 24.0)
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size", 12)
    footer.add_theme_color_override("font_color", Color("#6F87A4"))
    selection_layer.add_child(footer)


func _start_match(hero_id: String) -> void:
    if match_started:
        return
    selected_hero_id = hero_id
    match_started = true
    if is_instance_valid(selection_layer):
        selection_layer.queue_free()
    selection_layer = null
    team_director = ArenaTeamDirector.new()
    team_director.name = "ArenaTeamDirector"
    add_child(team_director)
    team_director.setup(self)
    _spawn_heroes()
    _spawn_neutral_camps()
    item_inventory = ArenaItemInventory.new()
    item_inventory.name = "ArenaItemInventory"
    player.add_child(item_inventory)
    talent_system = ArenaTalentSystem.new()
    talent_system.name = "ArenaTalentSystem"
    player.add_child(talent_system)
    performance_profile = ArenaPerformanceProfile.new()
    performance_profile.name = "ArenaPerformanceProfile"
    add_child(performance_profile)
    performance_profile.setup(self)
    _spawn_hud()
    targeting = ArenaTargeting.new()
    targeting.name = "ArenaTargeting"
    add_child(targeting)
    targeting.setup(self, hud)
    wave_director = ArenaWaveDirector.new()
    wave_director.name = "ArenaWaveDirector"
    wave_director.setup(self)
    add_child(wave_director)
    wave_director.start()
    message_label.text = "%s enters the arena. Destroy the enemy towers!" % player.label

func _spawn_hud() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    if is_instance_valid(mobile_layout):
        mobile_layout.set_layers(null, hud)

    var top_panel := Panel.new()
    top_panel.position = Vector2(20.0, 18.0)
    top_panel.size = Vector2(520.0, 92.0)
    top_panel.add_theme_stylebox_override("panel", _panel_style(Color("#111D30"), 0.88))
    hud.add_child(top_panel)

    status_label = Label.new()
    status_label.position = Vector2(18.0, 12.0)
    status_label.size = Vector2(490.0, 35.0)
    status_label.add_theme_font_size_override("font_size", 20)
    status_label.add_theme_color_override("font_color", Color("#EAF4FF"))
    top_panel.add_child(status_label)

    message_label = Label.new()
    message_label.position = Vector2(18.0, 49.0)
    message_label.size = Vector2(490.0, 28.0)
    message_label.add_theme_font_size_override("font_size", 15)
    message_label.add_theme_color_override("font_color", Color("#F4D58D"))
    message_label.text = "Destroy all enemy towers to expose the Ancient."
    top_panel.add_child(message_label)

    var hint := Label.new()
    hint.text = "Tap enemy to lock • ATTACK to chase • pinch to zoom • QWER abilities"
    hint.position = Vector2(24.0, 118.0)
    hint.add_theme_font_size_override("font_size", 14)
    hint.add_theme_color_override("font_color", Color("#C3D4EA"))
    hud.add_child(hint)

    minimap = ArenaMinimap.new()
    minimap.name = "ArenaMinimap"
    minimap.position = Vector2(1038.0, 18.0)
    minimap.size = Vector2(222.0, 184.0)
    minimap.setup(self)
    hud.add_child(minimap)

    wave_status_label = Label.new()
    wave_status_label.position = Vector2(560.0, 30.0)
    wave_status_label.size = Vector2(360.0, 30.0)
    wave_status_label.add_theme_font_size_override("font_size", 16)
    wave_status_label.add_theme_color_override("font_color", Color("#F0D69A"))
    wave_status_label.text = "WAVE 01  •  NEXT 22S"
    hud.add_child(wave_status_label)

    team_status_label = Label.new()
    team_status_label.position = Vector2(560.0, 58.0)
    team_status_label.size = Vector2(460.0, 28.0)
    team_status_label.add_theme_font_size_override("font_size", 12)
    team_status_label.add_theme_color_override("font_color", Color("#B8D8F0"))
    team_status_label.text = "BLUE 5/5 [OFF/MID/CAR/SUP/ROAM]  VS  RED 5/5"
    hud.add_child(team_status_label)

    boss_status_label = Label.new()
    boss_status_label.position = Vector2(1038.0, 208.0)
    boss_status_label.size = Vector2(222.0, 28.0)
    boss_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    boss_status_label.add_theme_font_size_override("font_size", 13)
    boss_status_label.add_theme_color_override("font_color", Color("#A7E9F2"))
    hud.add_child(boss_status_label)

    joystick_base = Panel.new()
    joystick_base.position = Vector2(60.0, 515.0)
    joystick_base.size = Vector2(170.0, 170.0)
    joystick_base.add_theme_stylebox_override("panel", _panel_style(Color("#152A42"), 0.48, 85))
    hud.add_child(joystick_base)

    joystick_knob = Panel.new()
    joystick_knob.position = Vector2(57.0, 57.0)
    joystick_knob.size = Vector2(56.0, 56.0)
    joystick_knob.add_theme_stylebox_override("panel", _panel_style(Color("#83DFFF"), 0.82, 28))
    joystick_base.add_child(joystick_knob)

    mana_label = Label.new()
    mana_label.position = Vector2(635.0, 548.0)
    mana_label.size = Vector2(430.0, 28.0)
    mana_label.add_theme_font_size_override("font_size", 17)
    mana_label.add_theme_color_override("font_color", Color("#8DE4FF"))
    hud.add_child(mana_label)

    var slots := ["Q", "W", "E", "R"]
    var slot_colors := [
        Color("#287BA6"),
        Color("#286D9A"),
        Color("#967044"),
        Color("#674D9F")
    ]
    if selected_hero_id == "nyxara":
        slot_colors = [
            Color("#5266A9"),
            Color("#7259B4"),
            Color("#925BBE"),
            Color("#563B91")
        ]
    elif selected_hero_id == "grom":
        slot_colors = [
            Color("#A34D3F"),
            Color("#9B5A38"),
            Color("#B16A36"),
            Color("#793A35")
        ]
    elif selected_hero_id == "elyra":
        slot_colors = [
            Color("#C9AE69"),
            Color("#D6BE7A"),
            Color("#A88E58"),
            Color("#E1C98A")
        ]
    elif selected_hero_id == "vaelis":
        slot_colors = [
            Color("#347F70"),
            Color("#3E9C83"),
            Color("#286B62"),
            Color("#22574F")
        ]

    for index in range(slots.size()):
        var slot: String = slots[index]
        var button_position := Vector2(635.0 + float(index) * 104.0, 585.0)
        var ability_button := _make_button(
            slot + "\nLEARN",
            button_position,
            Vector2(96.0, 94.0),
            slot_colors[index]
        )
        ability_button.add_theme_font_size_override("font_size", 14)
        ability_button.pressed.connect(_on_ability_pressed.bind(slot))
        hud.add_child(ability_button)
        ability_buttons[slot] = ability_button

        var upgrade_button := _make_button(
            "+",
            button_position + Vector2(70.0, -12.0),
            Vector2(28.0, 28.0),
            Color("#B68B42")
        )
        upgrade_button.add_theme_font_size_override("font_size", 18)
        upgrade_button.pressed.connect(_on_upgrade_pressed.bind(slot))
        hud.add_child(upgrade_button)
        upgrade_buttons[slot] = upgrade_button

    attack_button = _make_button("ATTACK", Vector2(1090.0, 575.0), Vector2(150.0, 112.0), Color("#245E91"))
    attack_button.pressed.connect(_player_attack)
    hud.add_child(attack_button)

    if is_instance_valid(hero_abilities):
        hero_abilities.connect("state_changed", _update_ability_hud)
    _build_inventory_ui()
    _build_shop_ui()
    _build_talent_ui()
    _build_settings_ui()
    if is_instance_valid(talent_system):
        talent_system.connect("state_changed", _refresh_talent_ui)
        talent_system.connect("state_changed", _update_ability_hud)
    _update_ability_hud()
    _refresh_talent_ui()

func _build_inventory_ui() -> void:
    var inventory_title := Label.new()
    inventory_title.text = "ITEMS  •  F / G / H / J / K / L"
    inventory_title.position = Vector2(260.0, 562.0)
    inventory_title.size = Vector2(350.0, 24.0)
    inventory_title.add_theme_font_size_override("font_size", 13)
    inventory_title.add_theme_color_override("font_color", Color("#C8D7E8"))
    hud.add_child(inventory_title)

    inventory_buttons.clear()
    for index in range(ArenaItemInventory.MAX_SLOTS):
        var button := _make_button(
            "%d\n—" % (index + 1),
            Vector2(255.0 + float(index) * 60.0, 590.0),
            Vector2(54.0, 82.0),
            Color("#354B63")
        )
        button.add_theme_font_size_override("font_size", 12)
        button.pressed.connect(_on_inventory_slot_pressed.bind(index))
        hud.add_child(button)
        inventory_buttons.append(button)

    _refresh_inventory_ui()


func _build_shop_ui() -> void:
    shop_button = _make_button(
        "SHOP",
        Vector2(550.0, 20.0),
        Vector2(112.0, 54.0),
        Color("#9A743A")
    )
    shop_button.pressed.connect(_toggle_shop)
    hud.add_child(shop_button)

    shop_panel = Panel.new()
    shop_panel.position = Vector2(770.0, 105.0)
    shop_panel.size = Vector2(480.0, 500.0)
    shop_panel.visible = false
    shop_panel.add_theme_stylebox_override("panel", _panel_style(Color("#101D31"), 0.98, 18))
    hud.add_child(shop_panel)

    var title := Label.new()
    title.text = "FIELD ARMORY"
    title.position = Vector2(16.0, 10.0)
    title.size = Vector2(300.0, 30.0)
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color("#F1D79C"))
    shop_panel.add_child(title)

    var close_button := _make_button(
        "×",
        Vector2(424.0, 8.0),
        Vector2(42.0, 38.0),
        Color("#713D4A")
    )
    close_button.pressed.connect(_toggle_shop)
    shop_panel.add_child(close_button)

    shop_gold_label = Label.new()
    shop_gold_label.position = Vector2(18.0, 42.0)
    shop_gold_label.size = Vector2(430.0, 24.0)
    shop_gold_label.add_theme_font_size_override("font_size", 15)
    shop_gold_label.add_theme_color_override("font_color", Color("#F5D27B"))
    shop_panel.add_child(shop_gold_label)

    var scroll := ScrollContainer.new()
    scroll.position = Vector2(12.0, 72.0)
    scroll.size = Vector2(456.0, 326.0)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    shop_panel.add_child(scroll)

    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 7)
    scroll.add_child(list)

    shop_buy_buttons.clear()
    for item in ArenaItemCatalog.all_items():
        var item_id := str(item.get("id", ""))
        var row := Panel.new()
        row.custom_minimum_size = Vector2(430.0, 66.0)
        row.add_theme_stylebox_override("panel", _panel_style(Color("#263A50"), 0.96, 12))
        list.add_child(row)

        var line := HBoxContainer.new()
        line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        line.add_theme_constant_override("separation", 8)
        row.add_child(line)

        var text_column := VBoxContainer.new()
        text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        text_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        line.add_child(text_column)

        var item_title := Label.new()
        item_title.text = "%s  •  %d G" % [str(item.get("name", item_id)), int(item.get("price", 0))]
        item_title.add_theme_font_size_override("font_size", 15)
        item_title.add_theme_color_override("font_color", Color("#F1F5FA"))
        text_column.add_child(item_title)

        var description := Label.new()
        description.text = str(item.get("description", ""))
        description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        description.add_theme_font_size_override("font_size", 11)
        description.add_theme_color_override("font_color", Color("#B8C9DC"))
        text_column.add_child(description)

        var buy_button := _make_button(
            "BUY",
            Vector2.ZERO,
            Vector2(96.0, 48.0),
            Color("#397C68")
        )
        buy_button.custom_minimum_size = Vector2(96.0, 48.0)
        buy_button.add_theme_font_size_override("font_size", 14)
        buy_button.pressed.connect(_on_buy_item.bind(item_id))
        line.add_child(buy_button)
        shop_buy_buttons[item_id] = buy_button

    shop_sell_mode_button = _make_button(
        "SELL MODE: OFF",
        Vector2(16.0, 406.0),
        Vector2(150.0, 38.0),
        Color("#8B5947")
    )
    shop_sell_mode_button.add_theme_font_size_override("font_size", 12)
    shop_sell_mode_button.pressed.connect(_toggle_sell_mode)
    shop_panel.add_child(shop_sell_mode_button)

    shop_status_label = Label.new()
    shop_status_label.position = Vector2(16.0, 450.0)
    shop_status_label.size = Vector2(448.0, 38.0)
    shop_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    shop_status_label.add_theme_font_size_override("font_size", 12)
    shop_status_label.add_theme_color_override("font_color", Color("#B9CDE0"))
    shop_status_label.text = "Six inventory slots • active artifacts can be tapped or used with F–L."
    shop_panel.add_child(shop_status_label)

    _refresh_shop_ui()


func _build_talent_ui() -> void:
    talent_button = _make_button(
        "TALENTS",
        Vector2(680.0, 20.0),
        Vector2(132.0, 54.0),
        Color("#66518F")
    )
    talent_button.add_theme_font_size_override("font_size", 15)
    talent_button.pressed.connect(_toggle_talents)
    hud.add_child(talent_button)

    talent_panel = Panel.new()
    talent_panel.position = Vector2(365.0, 145.0)
    talent_panel.size = Vector2(540.0, 430.0)
    talent_panel.visible = false
    talent_panel.add_theme_stylebox_override("panel", _panel_style(Color("#111B30"), 0.98, 20))
    hud.add_child(talent_panel)

    var title := Label.new()
    title.text = "HERO TALENTS"
    title.position = Vector2(20.0, 12.0)
    title.size = Vector2(390.0, 32.0)
    title.add_theme_font_size_override("font_size", 23)
    title.add_theme_color_override("font_color", Color("#E9D5FF"))
    talent_panel.add_child(title)

    var close_button := _make_button(
        "×",
        Vector2(484.0, 8.0),
        Vector2(42.0, 38.0),
        Color("#713D4A")
    )
    close_button.pressed.connect(_toggle_talents)
    talent_panel.add_child(close_button)

    for tier in [1, 2]:
        var y := 62.0 if tier == 1 else 244.0
        var tier_label := Label.new()
        tier_label.position = Vector2(20.0, y)
        tier_label.size = Vector2(490.0, 25.0)
        tier_label.add_theme_font_size_override("font_size", 14)
        tier_label.add_theme_color_override("font_color", Color("#AFC4DE"))
        talent_panel.add_child(tier_label)
        talent_tier_labels[tier] = tier_label

        var options := talent_system.get_options(tier) if is_instance_valid(talent_system) else []
        for index in range(options.size()):
            var option: Dictionary = options[index]
            var button := _make_button(
                "%s\n%s" % [str(option.get("name", "Talent")), str(option.get("description", ""))],
                Vector2(20.0 + float(index) * 250.0, y + 30.0),
                Vector2(238.0, 108.0),
                Color("#3D466F") if tier == 1 else Color("#57436F")
            )
            button.add_theme_font_size_override("font_size", 13)
            var talent_id := str(option.get("id", ""))
            button.pressed.connect(_on_talent_choice_pressed.bind(tier, talent_id))
            talent_panel.add_child(button)
            talent_choice_buttons[talent_id] = button

    var footer := Label.new()
    footer.text = "Choose one talent per tier. Choices are permanent for this match."
    footer.position = Vector2(20.0, 402.0)
    footer.size = Vector2(500.0, 20.0)
    footer.add_theme_font_size_override("font_size", 11)
    footer.add_theme_color_override("font_color", Color("#8299B4"))
    talent_panel.add_child(footer)


func _build_settings_ui() -> void:
    settings_button = _make_button(
        "SETTINGS",
        Vector2(920.0, 105.0),
        Vector2(102.0, 44.0),
        Color("#53647A")
    )
    settings_button.add_theme_font_size_override("font_size", 13)
    settings_button.pressed.connect(_toggle_settings)
    hud.add_child(settings_button)

    settings_panel = Panel.new()
    settings_panel.name = "SettingsPanel"
    settings_panel.position = Vector2(390.0, 160.0)
    settings_panel.size = Vector2(500.0, 360.0)
    settings_panel.visible = false
    settings_panel.add_theme_stylebox_override("panel", _panel_style(Color("#101D31"), 0.98, 20))
    hud.add_child(settings_panel)

    var title := Label.new()
    title.text = "ANDROID / GRAPHICS SETTINGS"
    title.position = Vector2(20.0, 16.0)
    title.size = Vector2(390.0, 32.0)
    title.add_theme_font_size_override("font_size", 21)
    title.add_theme_color_override("font_color", Color("#F0F5FF"))
    settings_panel.add_child(title)

    var close_button := _make_button(
        "X", Vector2(438.0, 12.0), Vector2(48.0, 42.0), Color("#744A4A")
    )
    close_button.pressed.connect(_toggle_settings)
    settings_panel.add_child(close_button)

    settings_quality_label = Label.new()
    settings_quality_label.position = Vector2(22.0, 78.0)
    settings_quality_label.size = Vector2(450.0, 30.0)
    settings_quality_label.add_theme_font_size_override("font_size", 18)
    settings_quality_label.add_theme_color_override("font_color", Color("#F1D69A"))
    settings_panel.add_child(settings_quality_label)

    var quality_options := [
        {"name": "LOW", "value": ArenaPerformanceProfile.QUALITY_LOW, "color": Color("#47616F")},
        {"name": "BALANCED", "value": ArenaPerformanceProfile.QUALITY_BALANCED, "color": Color("#386D83")},
        {"name": "HIGH", "value": ArenaPerformanceProfile.QUALITY_HIGH, "color": Color("#79603D")}
    ]
    for index in range(quality_options.size()):
        var option: Dictionary = quality_options[index]
        var button := _make_button(
            str(option["name"]),
            Vector2(22.0 + float(index) * 154.0, 132.0),
            Vector2(142.0, 66.0),
            option["color"]
        )
        button.add_theme_font_size_override("font_size", 15)
        button.pressed.connect(_set_graphics_quality.bind(int(option["value"])))
        settings_panel.add_child(button)

    settings_description_label = Label.new()
    settings_description_label.position = Vector2(22.0, 218.0)
    settings_description_label.size = Vector2(450.0, 42.0)
    settings_description_label.add_theme_font_size_override("font_size", 13)
    settings_description_label.add_theme_color_override("font_color", Color("#B8CBE2"))
    settings_panel.add_child(settings_description_label)

    settings_fps_label = Label.new()
    settings_fps_label.position = Vector2(22.0, 262.0)
    settings_fps_label.size = Vector2(450.0, 20.0)
    settings_fps_label.add_theme_font_size_override("font_size", 12)
    settings_fps_label.add_theme_color_override("font_color", Color("#8DE4FF"))
    settings_panel.add_child(settings_fps_label)

    var reset_camera_button := _make_button(
        "RESET CAMERA ZOOM",
        Vector2(22.0, 294.0),
        Vector2(210.0, 48.0),
        Color("#42566D")
    )
    reset_camera_button.add_theme_font_size_override("font_size", 13)
    reset_camera_button.pressed.connect(_reset_camera_zoom)
    settings_panel.add_child(reset_camera_button)
    _refresh_settings_ui()


func _set_graphics_quality(value: int) -> void:
    if is_instance_valid(performance_profile):
        performance_profile.set_quality(value)
    _refresh_settings_ui()


func _refresh_settings_ui() -> void:
    if not is_instance_valid(performance_profile):
        return
    if is_instance_valid(settings_quality_label):
        settings_quality_label.text = "GRAPHICS: %s" % performance_profile.get_quality_name()
    if is_instance_valid(settings_description_label):
        settings_description_label.text = performance_profile.get_quality_description()


func _toggle_settings() -> void:
    if not is_instance_valid(settings_panel):
        return
    var opening := not settings_panel.visible
    if opening:
        if is_instance_valid(shop_panel):
            shop_panel.visible = false
        if is_instance_valid(talent_panel):
            talent_panel.visible = false
        if is_instance_valid(shop_button):
            shop_button.text = "SHOP"
        if is_instance_valid(talent_button):
            talent_button.text = "TALENTS"
    settings_panel.visible = opening
    if is_instance_valid(settings_button):
        settings_button.text = "CLOSE" if opening else "SETTINGS"
    var another_modal_open := (
        (is_instance_valid(shop_panel) and shop_panel.visible)
        or (is_instance_valid(talent_panel) and talent_panel.visible)
    )
    if is_instance_valid(minimap):
        minimap.visible = not opening and not another_modal_open
    if opening:
        _refresh_settings_ui()


func _reset_camera_zoom() -> void:
    camera_zoom = 1.0
    _pinch_distance = 0.0


func _toggle_talents() -> void:
    if not is_instance_valid(talent_panel):
        return
    if is_instance_valid(shop_panel) and shop_panel.visible:
        shop_panel.visible = false
        if is_instance_valid(shop_button):
            shop_button.text = "SHOP"
    if is_instance_valid(settings_panel) and settings_panel.visible:
        settings_panel.visible = false
        if is_instance_valid(settings_button):
            settings_button.text = "SETTINGS"
    talent_panel.visible = not talent_panel.visible
    if is_instance_valid(minimap):
        minimap.visible = not talent_panel.visible and not shop_panel.visible and not settings_panel.visible
    if is_instance_valid(talent_button):
        talent_button.text = "CLOSE" if talent_panel.visible else "TALENTS"
    _refresh_talent_ui()


func _on_talent_choice_pressed(tier: int, talent_id: String) -> void:
    if is_instance_valid(talent_system):
        talent_system.choose_talent(tier, talent_id)
    _refresh_talent_ui()
    _update_ability_hud()


func _refresh_talent_ui() -> void:
    if not is_instance_valid(talent_system):
        return

    var ready_to_choose := false
    for tier in [1, 2]:
        var required_level := talent_system.get_required_level(tier)
        var selected_id := talent_system.get_selected_id(tier)
        var can_choose := talent_system.can_choose(tier)
        if can_choose:
            ready_to_choose = true

        var tier_label: Label = talent_tier_labels.get(tier)
        if is_instance_valid(tier_label):
            if not selected_id.is_empty():
                tier_label.text = "TIER %d  •  SELECTED: %s" % [tier, talent_system.get_selected_name(tier)]
            elif talent_system.current_level < required_level:
                tier_label.text = "TIER %d  •  UNLOCKS AT LEVEL %d" % [tier, required_level]
            else:
                tier_label.text = "TIER %d  •  CHOOSE ONE TALENT" % tier

        for option in talent_system.get_options(tier):
            var talent_id := str(option.get("id", ""))
            if not talent_choice_buttons.has(talent_id):
                continue
            var button: Button = talent_choice_buttons[talent_id]
            var is_selected := selected_id == talent_id
            button.disabled = not can_choose
            if is_selected:
                button.text = "SELECTED\n%s" % str(option.get("name", talent_id))
                button.disabled = true
            else:
                button.text = "%s\n%s" % [str(option.get("name", talent_id)), str(option.get("description", ""))]

    if is_instance_valid(talent_button):
        talent_button.disabled = game_over
        talent_button.text = "TALENTS • READY" if ready_to_choose and not talent_panel.visible else ("CLOSE" if talent_panel.visible else "TALENTS")


func _toggle_shop() -> void:
    if not is_instance_valid(shop_panel):
        return
    shop_panel.visible = not shop_panel.visible
    if shop_panel.visible and is_instance_valid(settings_panel):
        settings_panel.visible = false
        if is_instance_valid(settings_button):
            settings_button.text = "SETTINGS"
    if shop_panel.visible and is_instance_valid(talent_panel):
        talent_panel.visible = false
        if is_instance_valid(talent_button):
            talent_button.text = "TALENTS"
    if is_instance_valid(minimap):
        minimap.visible = not shop_panel.visible and not talent_panel.visible and not settings_panel.visible
    if not shop_panel.visible:
        shop_sell_mode = false
        _refresh_inventory_ui()
    if is_instance_valid(shop_button):
        shop_button.text = "CLOSE" if shop_panel.visible else "SHOP"
    if shop_panel.visible:
        _refresh_shop_ui()


func _toggle_sell_mode() -> void:
    shop_sell_mode = not shop_sell_mode
    _refresh_shop_ui()
    _refresh_inventory_ui()


func _on_buy_item(item_id: String) -> void:
    if not is_instance_valid(item_inventory):
        return
    if item_inventory.buy_item(item_id):
        _refresh_shop_ui()
        _refresh_inventory_ui()


func _on_inventory_slot_pressed(index: int) -> void:
    if not is_instance_valid(item_inventory):
        return
    if shop_sell_mode:
        item_inventory.sell_slot(index)
        _refresh_shop_ui()
    else:
        item_inventory.activate_slot(index)
    _refresh_inventory_ui()


func _refresh_shop_ui() -> void:
    if not is_instance_valid(item_inventory):
        return
    if is_instance_valid(shop_button):
        shop_button.disabled = game_over
    if is_instance_valid(shop_gold_label):
        shop_gold_label.text = "GOLD  %d     •     INVENTORY  %d / %d" % [
            player_gold,
            item_inventory.get_item_count(),
            ArenaItemInventory.MAX_SLOTS
        ]

    for item_id in shop_buy_buttons.keys():
        var button: Button = shop_buy_buttons[item_id]
        var item := ArenaItemCatalog.get_item(str(item_id))
        var recipe: Array = item.get("recipe", [])
        button.text = ("COMBINE %d" if not recipe.is_empty() else "BUY %d") % int(item.get("price", 0))
        button.disabled = not item_inventory.can_purchase(str(item_id))

    if is_instance_valid(shop_sell_mode_button):
        shop_sell_mode_button.text = "SELL MODE: ON" if shop_sell_mode else "SELL MODE: OFF"
    if is_instance_valid(shop_status_label):
        shop_status_label.text = "Tap an inventory slot to sell it for 60% value." if shop_sell_mode else "Recipes consume their listed components and one combine fee."


func _refresh_inventory_ui() -> void:
    if not is_instance_valid(item_inventory):
        return
    for index in range(inventory_buttons.size()):
        var button := inventory_buttons[index]
        var item := item_inventory.get_item_at(index)
        if item.is_empty():
            button.text = "%d\n—" % (index + 1)
            button.disabled = true
            continue

        var short_name := str(item.get("short_name", "ITEM"))
        if shop_sell_mode:
            button.text = short_name + "\nSELL"
            button.disabled = not is_instance_valid(player) or not player.alive
            continue
        var active := not str(item.get("active", "")).is_empty()
        if not is_instance_valid(player) or not player.alive:
            button.disabled = true
            continue
        var cooldown := item_inventory.get_slot_cooldown(index)
        if active and cooldown > 0.05:
            button.text = "%s\n%.0fs" % [short_name, cooldown]
        elif active:
            button.text = "%s\nREADY" % short_name
        else:
            button.text = short_name
        button.disabled = false


func _panel_style(color: Color, alpha: float, radius := 16) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(color.r, color.g, color.b, alpha)
    style.set_corner_radius_all(radius)
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.border_color = Color("#8DC9E8", 0.42)
    return style

func _make_button(
    caption: String,
    position: Vector2,
    size: Vector2,
    color: Color
) -> Button:
    var button := Button.new()
    button.text = caption
    button.position = position
    button.size = size
    button.add_theme_font_size_override("font_size", 20)
    button.add_theme_color_override("font_color", Color("#FFFFFF"))
    button.add_theme_stylebox_override("normal", _panel_style(color, 0.94, 18))
    button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.18), 1.0, 18))
    button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.2), 1.0, 18))
    return button

func _player_attack() -> void:
    if is_instance_valid(player) and player.alive:
        player.request_attack()

func _on_ability_pressed(slot: String) -> void:
    if is_instance_valid(hero_abilities):
        hero_abilities.call("cast", slot)
    _update_ability_hud()


func _on_upgrade_pressed(slot: String) -> void:
    if is_instance_valid(hero_abilities):
        hero_abilities.call("upgrade_ability", slot)
    _update_ability_hud()


func _update_ability_hud() -> void:
    if not is_instance_valid(hero_abilities):
        return

    if is_instance_valid(mana_label):
        mana_label.text = "MANA  %.0f / %.0f     •     SKILL POINTS  %d" % [
            float(hero_abilities.get("mana")),
            float(hero_abilities.get("max_mana")),
            skill_points
        ]

    for slot in ["Q", "W", "E", "R"]:
        if not ability_buttons.has(slot) or not upgrade_buttons.has(slot):
            continue

        var button: Button = ability_buttons[slot]
        var upgrade_button: Button = upgrade_buttons[slot]
        var rank := int(hero_abilities.call("get_rank", slot))
        var cooldown := float(hero_abilities.call("get_cooldown", slot))
        var title := String(hero_abilities.call("get_title", slot))

        if rank <= 0:
            button.text = "%s\n%s\nUNLEARNED" % [slot, title]
            button.disabled = true
        elif cooldown > 0.05:
            button.text = "%s • %d\n%.1fs" % [slot, rank, cooldown]
            button.disabled = true
        else:
            button.text = "%s • %d\n%s" % [slot, rank, title]
            button.disabled = not player.alive

        upgrade_button.visible = bool(hero_abilities.call("can_upgrade", slot))
        upgrade_button.disabled = not upgrade_button.visible

func _input(event: InputEvent) -> void:
    if not match_started:
        return
    if is_instance_valid(targeting):
        targeting.handle_input(event)

    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            _active_touch_positions[touch.index] = touch.position
            if _active_touch_positions.size() >= 2 and is_instance_valid(targeting):
                targeting.cancel_pending_touch()
            _refresh_pinch_baseline()
            var design_position := _to_design_position(touch.position)
            if joystick_touch == -1 and design_position.x < 240.0 and design_position.y > 350.0:
                joystick_touch = touch.index
                _update_joystick(design_position)
        else:
            _active_touch_positions.erase(touch.index)
            if touch.index == joystick_touch:
                joystick_touch = -1
                joystick_vector = Vector2.ZERO
                _apply_joystick()
                _update_joystick_visual()
            if _active_touch_positions.size() < 2:
                _pinch_distance = 0.0
            else:
                _refresh_pinch_baseline()
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if _active_touch_positions.has(drag.index):
            _active_touch_positions[drag.index] = drag.position
            _apply_camera_pinch()
        if drag.index == joystick_touch:
            _update_joystick(_to_design_position(drag.position))
    elif event is InputEventMouseButton:
        var mouse_button := event as InputEventMouseButton
        if not _is_modal_ui_open() and mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP:
            camera_zoom = clampf(camera_zoom * 0.92, 0.78, 1.42)
        elif not _is_modal_ui_open() and mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            camera_zoom = clampf(camera_zoom * 1.08, 0.78, 1.42)


func _to_design_position(viewport_position: Vector2) -> Vector2:
    if is_instance_valid(mobile_layout):
        return mobile_layout.to_design_position(viewport_position)
    return viewport_position


func _refresh_pinch_baseline() -> void:
    if _active_touch_positions.size() != 2:
        _pinch_distance = 0.0
        return
    var points: Array[Vector2] = []
    for raw_position in _active_touch_positions.values():
        var design_position := _to_design_position(raw_position)
        if not _is_camera_pinch_zone(design_position):
            _pinch_distance = 0.0
            return
        points.append(design_position)
    if points.size() == 2:
        _pinch_distance = points[0].distance_to(points[1])


func _apply_camera_pinch() -> void:
    if _active_touch_positions.size() != 2:
        return
    var points: Array[Vector2] = []
    for raw_position in _active_touch_positions.values():
        var design_position := _to_design_position(raw_position)
        if not _is_camera_pinch_zone(design_position):
            _pinch_distance = 0.0
            return
        points.append(design_position)
    if points.size() != 2:
        return
    var current_distance := points[0].distance_to(points[1])
    if _pinch_distance <= 0.0:
        _pinch_distance = current_distance
        return
    if current_distance > 1.0 and absf(current_distance - _pinch_distance) > 0.8:
        camera_zoom = clampf(camera_zoom * current_distance / _pinch_distance, 0.78, 1.42)
        _pinch_distance = current_distance


func _is_modal_ui_open() -> bool:
    return (
        (is_instance_valid(settings_panel) and settings_panel.visible)
        or (is_instance_valid(shop_panel) and shop_panel.visible)
        or (is_instance_valid(talent_panel) and talent_panel.visible)
    )


func _is_camera_pinch_zone(position: Vector2) -> bool:
    if _is_modal_ui_open():
        return false
    return position.x >= 250.0 and position.x <= 1030.0 and position.y >= 150.0 and position.y <= 535.0

func _update_joystick(touch_position: Vector2) -> void:
    joystick_vector = ((touch_position - joystick_origin) / 78.0).limit_length(1.0)
    _apply_joystick()
    _update_joystick_visual()

func _update_joystick_visual() -> void:
    if is_instance_valid(joystick_knob):
        joystick_knob.position = Vector2(57.0, 57.0) + joystick_vector * 47.0

func _apply_joystick() -> void:
    for action in ["move_up", "move_down", "move_left", "move_right"]:
        Input.action_release(action)

    if joystick_vector.y < -0.18:
        Input.action_press("move_up", absf(joystick_vector.y))
    if joystick_vector.y > 0.18:
        Input.action_press("move_down", absf(joystick_vector.y))
    if joystick_vector.x < -0.18:
        Input.action_press("move_left", absf(joystick_vector.x))
    if joystick_vector.x > 0.18:
        Input.action_press("move_right", absf(joystick_vector.x))

func all_towers_destroyed(owner_team: int) -> bool:
    var towers: Array[ArenaTower] = blue_towers if owner_team == BLUE else red_towers
    for tower in towers:
        if is_instance_valid(tower) and tower.hp > 0.0:
            return false
    return true

func on_actor_killed(actor: ArenaActor, killer_team: int) -> void:
    if killer_team != BLUE and killer_team != RED:
        return
    if actor.gold_reward > 0:
        _distribute_bot_gold(killer_team, maxi(1, int(floor(float(actor.gold_reward) / 10.0))))
    if killer_team == BLUE:
        _grant_player_rewards(actor.gold_reward, actor.xp_reward, actor.label)


func on_neutral_monster_killed(monster: ArenaNeutralMonster, killer_team: int) -> void:
    if killer_team != BLUE and killer_team != RED:
        return
    if monster.gold_reward > 0:
        _distribute_bot_gold(killer_team, maxi(1, int(floor(float(monster.gold_reward) / 12.0))))
    if killer_team == BLUE:
        _grant_player_rewards(
            monster.gold_reward,
            monster.xp_reward,
            "Jungle camp defeated"
        )


func _distribute_bot_gold(team: int, amount_per_bot: int) -> void:
    if not is_instance_valid(team_director) or amount_per_bot <= 0:
        return
    for actor_variant in team_director.get_roster(team):
        if not is_instance_valid(actor_variant):
            continue
        var teammate := actor_variant as ArenaActor
        if teammate.is_player:
            continue
        var loadout := teammate.get_node_or_null("ArenaBotLoadout")
        if is_instance_valid(loadout) and loadout.has_method("add_gold"):
            loadout.call("add_gold", amount_per_bot)


func _grant_player_rewards(gold_amount: int, xp_amount: int, source_label: String) -> void:
    player_gold += gold_amount
    player_xp += xp_amount
    var levels_gained := 0

    while player_xp >= player_level * 100:
        player_xp -= player_level * 100
        player_level += 1
        skill_points += 1
        levels_gained += 1
        if is_instance_valid(player):
            player.apply_level_up()
        if is_instance_valid(talent_system):
            talent_system.set_level(player_level)
        _update_ability_hud()
        _refresh_talent_ui()

    if is_instance_valid(message_label):
        if levels_gained > 0:
            message_label.text = "LEVEL %d • +%d G • +%d XP • %d skill point(s)" % [
                player_level, gold_amount, xp_amount, levels_gained
            ]
        else:
            message_label.text = "%s • +%d G • +%d XP" % [
                source_label, gold_amount, xp_amount
            ]
    _refresh_shop_ui()

func _spawn_ancient_boss() -> void:
    if is_instance_valid(ancient_boss):
        return
    ancient_boss = ArenaAncientBoss.new()
    ancient_boss.name = "ElderRiftwarden"
    ancient_boss.setup_boss(self)
    ancient_boss.position = BOSS_POSITION
    add_child(ancient_boss)
    boss_spawn_timer = 0.0
    if is_instance_valid(message_label):
        message_label.text = "ELDER RIFTWARDEN AWAKENS • contest the central altar!"


func on_boss_phase_changed(phase: int) -> void:
    if is_instance_valid(message_label):
        message_label.text = "RIFTWARDEN PHASE %d • its attacks grow stronger!" % phase


func on_boss_slam(hit_count: int, phase: int) -> void:
    if is_instance_valid(message_label):
        message_label.text = "Riftwarden slam • %d unit(s) struck • phase %d" % [hit_count, phase]


func on_boss_killed(boss: ArenaAncientBoss, killer_team: int) -> void:
    ancient_boss = null
    boss_spawn_timer = BOSS_RESPAWN_DELAY
    _apply_team_blessing(killer_team, TEAM_BLESSING_DURATION)

    if killer_team == BLUE:
        _grant_player_rewards(320, 260, "Elder Riftwarden slain")
        if is_instance_valid(message_label):
            message_label.text = "RIFTWARDEN SLAIN • +320 G / +260 XP • BLUE BLESSING 90s"
    else:
        if is_instance_valid(message_label):
            message_label.text = "RIFTWARDEN SLAIN • RED TEAM CLAIMS THE 90s BLESSING"


func _apply_team_blessing(team: int, duration: float) -> void:
    if team == BLUE:
        blue_blessing_remaining = maxf(blue_blessing_remaining, duration)
    elif team == RED:
        red_blessing_remaining = maxf(red_blessing_remaining, duration)
    else:
        return

    for node in get_tree().get_nodes_in_group("arena_actors"):
        if not (node is ArenaActor):
            continue
        var actor := node as ArenaActor
        if actor.team == team:
            actor.apply_team_blessing(duration)


func on_structure_destroyed(owner_team: int, is_core: bool, lane: int) -> void:
    if is_core:
        game_over = true
        message_label.text = "BLUE VICTORY!" if owner_team == RED else "RED VICTORY!"
        if is_instance_valid(shop_panel):
            shop_panel.visible = false
        if is_instance_valid(minimap):
            minimap.visible = true
        if is_instance_valid(shop_button):
            shop_button.disabled = true
            shop_button.text = "MATCH END"
        if is_instance_valid(talent_button):
            talent_button.disabled = true
        if is_instance_valid(talent_panel):
            talent_panel.visible = false
        if is_instance_valid(settings_panel):
            settings_panel.visible = false
        if is_instance_valid(settings_button):
            settings_button.disabled = true
            settings_button.text = "MATCH END"
    else:
        var team_name := "BLUE" if owner_team == BLUE else "RED"
        if owner_team == RED:
            player_gold += 100
            _distribute_bot_gold(BLUE, 20)
            message_label.text = "Enemy tower destroyed • +100 gold"
        else:
            _distribute_bot_gold(RED, 20)
            message_label.text = "%s tower destroyed • lane %d" % [team_name, lane + 1]
        if all_towers_destroyed(owner_team):
            message_label.text = "%s Ancient exposed!" % team_name
        _refresh_shop_ui()

func _process(delta: float) -> void:
    if not match_started or game_over:
        return

    match_time += delta
    economy_timer += delta
    shop_refresh_timer += delta
    blue_blessing_remaining = maxf(0.0, blue_blessing_remaining - delta)
    red_blessing_remaining = maxf(0.0, red_blessing_remaining - delta)
    if not is_instance_valid(ancient_boss):
        boss_spawn_timer = maxf(0.0, boss_spawn_timer - delta)
        if boss_spawn_timer <= 0.0:
            _spawn_ancient_boss()
    while economy_timer >= 1.0:
        economy_timer -= 1.0
        player_gold += 2
    if shop_refresh_timer >= 0.25:
        shop_refresh_timer = 0.0
        _refresh_shop_ui()
        _refresh_inventory_ui()

    wave_status_refresh += delta
    if wave_status_refresh >= 0.2:
        wave_status_refresh = 0.0
        if is_instance_valid(wave_status_label) and is_instance_valid(wave_director):
            wave_status_label.text = wave_director.get_status_text()

    if is_instance_valid(settings_panel) and settings_panel.visible:
        settings_refresh_timer += delta
        if settings_refresh_timer >= 0.5:
            settings_refresh_timer = 0.0
            if is_instance_valid(settings_fps_label):
                var ui_scale := mobile_layout.get_ui_scale() if is_instance_valid(mobile_layout) else 1.0
                settings_fps_label.text = "FPS %d  •  UI SCALE %.2fx" % [int(Engine.get_frames_per_second()), ui_scale]

    if is_instance_valid(player) and is_instance_valid(game_camera):
        var camera_offset := Vector3(0.0, 25.5, 20.5) * camera_zoom
        var camera_target := player.global_position + camera_offset
        var follow_weight := 1.0 - exp(-delta * 3.6)
        game_camera.global_position = game_camera.global_position.lerp(camera_target, follow_weight)
        game_camera.look_at(player.global_position + Vector3(0.0, 0.45, 0.0), Vector3.UP)

    if is_instance_valid(team_status_label) and is_instance_valid(team_director):
        team_status_label.text = "BLUE %d/5 [%s]   VS   RED %d/5 [%s]" % [
            team_director.get_alive_hero_count(BLUE),
            team_director.get_roster_summary(BLUE),
            team_director.get_alive_hero_count(RED),
            team_director.get_roster_summary(RED)
        ]

    var player_hp := int(player.hp) if is_instance_valid(player) else 0
    var enemy_hp := int(enemy.hp) if is_instance_valid(enemy) else 0
    var blue_towers_left := _count_alive_towers(blue_towers)
    var red_towers_left := _count_alive_towers(red_towers)

    status_label.text = (
        "%s %d HP  •  ASH KNIGHT %d HP  •  LV %d  •  %d GOLD  •  %02d:%02d"
        % [player.label.to_upper(), player_hp, enemy_hp, player_level, player_gold,
        int(match_time) / 60, int(match_time) % 60]
    )

    if blue_towers_left == 0:
        message_label.text = "Blue Ancient is exposed!"
    elif red_towers_left == 0:
        message_label.text = "Red Ancient is exposed!"

    if is_instance_valid(boss_status_label):
        if is_instance_valid(ancient_boss) and ancient_boss.alive:
            boss_status_label.text = "RIFTWARDEN • P%d • %d HP" % [ancient_boss.boss_phase, int(ancient_boss.hp)]
        elif boss_spawn_timer > 0.0:
            boss_status_label.text = "RIFTWARDEN IN %02d:%02d" % [int(int(boss_spawn_timer) / 60), int(boss_spawn_timer) % 60]
        else:
            boss_status_label.text = "RIFTWARDEN AWAKENING..."

func _count_alive_towers(towers: Array[ArenaTower]) -> int:
    var count := 0
    for tower in towers:
        if is_instance_valid(tower) and tower.hp > 0.0:
            count += 1
    return count
