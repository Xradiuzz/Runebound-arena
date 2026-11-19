extends Node
class_name ArenaTargeting

# Screen-space target selection avoids requiring physics colliders on towers and
# neutral monsters. The query is performed only on a deliberate tap, not per frame.

const TAP_MAX_DRIFT := 14.0
const HERO_PICK_RADIUS := 48.0
const MINION_PICK_RADIUS := 34.0
const STRUCTURE_PICK_RADIUS := 54.0
const NEUTRAL_PICK_RADIUS := 46.0

var game: Node
var hud: CanvasLayer
var player: ArenaActor
var camera: Camera3D
var selected_target: Node3D
var selection_ring: MeshInstance3D

var target_panel: Panel
var target_title: Label
var target_health: Label
var target_health_bar: ProgressBar
var attack_button: Button

var _refresh_timer := 0.0
var _touch_index := -1
var _touch_start := Vector2.ZERO
var _touch_moved := false
var _mouse_pending := false
var _mouse_start := Vector2.ZERO
var _mouse_moved := false


func setup(game_node: Node, hud_layer: CanvasLayer) -> void:
    game = game_node
    hud = hud_layer
    player = game.get("player") as ArenaActor
    camera = game.get("game_camera") as Camera3D
    attack_button = game.get("attack_button") as Button
    _build_target_panel()
    set_process(true)


func _build_target_panel() -> void:
    if not is_instance_valid(hud):
        return

    target_panel = Panel.new()
    target_panel.name = "TargetPanel"
    target_panel.position = Vector2(252.0, 574.0)
    target_panel.size = Vector2(360.0, 98.0)
    target_panel.visible = false
    target_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    target_panel.add_theme_stylebox_override("panel", _panel_style())
    hud.add_child(target_panel)

    target_title = Label.new()
    target_title.position = Vector2(14.0, 8.0)
    target_title.size = Vector2(250.0, 25.0)
    target_title.add_theme_font_size_override("font_size", 17)
    target_title.add_theme_color_override("font_color", Color("#F3F7FF"))
    target_panel.add_child(target_title)

    target_health = Label.new()
    target_health.position = Vector2(14.0, 35.0)
    target_health.size = Vector2(250.0, 20.0)
    target_health.add_theme_font_size_override("font_size", 12)
    target_health.add_theme_color_override("font_color", Color("#BFD0E5"))
    target_panel.add_child(target_health)

    target_health_bar = ProgressBar.new()
    target_health_bar.position = Vector2(14.0, 62.0)
    target_health_bar.size = Vector2(250.0, 16.0)
    target_health_bar.show_percentage = false
    target_health_bar.max_value = 100.0
    target_health_bar.value = 100.0
    target_health_bar.add_theme_stylebox_override("background", _bar_background())
    target_health_bar.add_theme_stylebox_override("fill", _bar_fill())
    target_panel.add_child(target_health_bar)

    var clear_button := Button.new()
    clear_button.text = "CLEAR"
    clear_button.position = Vector2(278.0, 20.0)
    clear_button.size = Vector2(68.0, 48.0)
    clear_button.add_theme_font_size_override("font_size", 12)
    clear_button.add_theme_color_override("font_color", Color.WHITE)
    clear_button.add_theme_stylebox_override("normal", _clear_button_style(Color("#344A66")))
    clear_button.add_theme_stylebox_override("hover", _clear_button_style(Color("#486487")))
    clear_button.add_theme_stylebox_override("pressed", _clear_button_style(Color("#26384E")))
    clear_button.pressed.connect(clear_target)
    target_panel.add_child(clear_button)


func handle_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            if _is_world_tap(touch.position):
                _touch_index = touch.index
                _touch_start = touch.position
                _touch_moved = false
        elif touch.index == _touch_index:
            if not _touch_moved and _is_world_tap(touch.position):
                _select_target_at_screen(touch.position)
            _touch_index = -1
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == _touch_index and drag.position.distance_to(_touch_start) > TAP_MAX_DRIFT:
            _touch_moved = true
    elif event is InputEventMouseButton:
        var mouse_button := event as InputEventMouseButton
        if mouse_button.button_index != MOUSE_BUTTON_LEFT:
            return
        if mouse_button.pressed:
            _mouse_pending = _is_world_tap(mouse_button.position)
            _mouse_start = mouse_button.position
            _mouse_moved = false
        elif _mouse_pending:
            if not _mouse_moved and mouse_button.position.distance_to(_mouse_start) <= TAP_MAX_DRIFT:
                _select_target_at_screen(mouse_button.position)
            _mouse_pending = false
    elif event is InputEventMouseMotion and _mouse_pending:
        var motion := event as InputEventMouseMotion
        if motion.position.distance_to(_mouse_start) > TAP_MAX_DRIFT:
            _mouse_moved = true


func cancel_pending_touch() -> void:
    _touch_index = -1
    _touch_moved = true


func _is_world_tap(position: Vector2) -> bool:
    var design_position := position
    if is_instance_valid(game):
        var layout := game.get("mobile_layout") as ArenaMobileLayout
        if is_instance_valid(layout):
            design_position = layout.to_design_position(position)
    # Modal panels consume the whole world-selection gesture, even where the
    # panel itself does not cover the battlefield.
    if _is_modal_open():
        return false
    # Design-space exclusion zones remain stable across phone aspect ratios,
    # safe-area insets and the centered HUD transform.
    var inside_world_zone := (
        design_position.x >= 243.0
        and design_position.x <= 1024.0
        and design_position.y >= 158.0
        and design_position.y <= 511.0
    )
    if not inside_world_zone:
        return false
    return true


func _is_modal_open() -> bool:
    for property_name in ["shop_panel", "talent_panel", "settings_panel"]:
        var panel := game.get(property_name) as Control
        if is_instance_valid(panel) and panel.visible:
            return true
    return false


func _point_inside_visible_panel(property_name: String, position: Vector2) -> bool:
    if not is_instance_valid(game):
        return false
    var panel := game.get(property_name) as Control
    return is_instance_valid(panel) and panel.visible and panel.get_global_rect().has_point(position)


func _select_target_at_screen(screen_position: Vector2) -> void:
    if not is_instance_valid(player) or not player.alive or not is_instance_valid(camera):
        return

    var best_candidate: Node3D
    var best_score := INF
    for node in get_tree().get_nodes_in_group("arena_actors"):
        if node is ArenaActor:
            var actor := node as ArenaActor
            if actor.team == player.team or not actor.alive or actor.hp <= 0.0:
                continue
            var radius := MINION_PICK_RADIUS if actor.is_minion else HERO_PICK_RADIUS
            var actor_score := _screen_pick_score(actor, screen_position, Vector3.UP * (0.75 if actor.is_minion else 1.1), radius, 0.0 if not actor.is_minion else 5.0)
            if actor_score < best_score:
                best_score = actor_score
                best_candidate = actor

    for node in get_tree().get_nodes_in_group("arena_structures"):
        if node is ArenaTower:
            var tower := node as ArenaTower
            if tower.team == player.team or tower.hp <= 0.0:
                continue
            if tower.core and not bool(game.call("all_towers_destroyed", tower.team)):
                continue
            var tower_score := _screen_pick_score(tower, screen_position, Vector3.UP * 2.2, STRUCTURE_PICK_RADIUS, 9.0)
            if tower_score < best_score:
                best_score = tower_score
                best_candidate = tower

    for node in get_tree().get_nodes_in_group("arena_neutral_monsters"):
        if node is ArenaNeutralMonster:
            var monster := node as ArenaNeutralMonster
            if not monster.alive or monster.hp <= 0.0:
                continue
            var monster_score := _screen_pick_score(monster, screen_position, Vector3.UP * 1.2, NEUTRAL_PICK_RADIUS, 12.0)
            if monster_score < best_score:
                best_score = monster_score
                best_candidate = monster

    if is_instance_valid(best_candidate):
        _set_selected_target(best_candidate)
        player.target = best_candidate
        player.player_attack_order = false
    else:
        clear_target()


func _screen_pick_score(
    candidate: Node3D,
    screen_position: Vector2,
    world_offset: Vector3,
    pick_radius: float,
    priority_bias: float
) -> float:
    var anchor := candidate.global_position + world_offset
    if camera.is_position_behind(anchor):
        return INF
    var projected := camera.unproject_position(anchor)
    var pixel_distance := projected.distance_to(screen_position)
    if pixel_distance > pick_radius:
        return INF
    return pixel_distance + priority_bias


func _set_selected_target(candidate: Node3D) -> void:
    if is_instance_valid(selection_ring):
        selection_ring.queue_free()
    selection_ring = null
    selected_target = candidate
    if not is_instance_valid(candidate):
        return

    selection_ring = MeshInstance3D.new()
    selection_ring.name = "PlayerTargetRing"
    var ring_mesh := TorusMesh.new()
    ring_mesh.inner_radius = 0.64
    ring_mesh.outer_radius = 0.78
    ring_mesh.rings = 24
    ring_mesh.ring_segments = 8
    selection_ring.mesh = ring_mesh
    selection_ring.rotation_degrees.x = 90.0
    selection_ring.position = Vector3(0.0, 0.13, 0.0)
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = Color("#FFD36B")
    material.emission_enabled = true
    material.emission = Color("#E6A83F")
    material.emission_energy_multiplier = 1.4
    selection_ring.material_override = material
    candidate.add_child(selection_ring)


func clear_target() -> void:
    if is_instance_valid(player):
        if selected_target != null and player.target == selected_target:
            player.target = null
        player.player_attack_order = false
    if is_instance_valid(selection_ring):
        selection_ring.queue_free()
    selection_ring = null
    selected_target = null
    if is_instance_valid(target_panel):
        target_panel.visible = false
    if is_instance_valid(attack_button):
        attack_button.text = "ATTACK"


func _process(delta: float) -> void:
    _refresh_timer -= delta
    if _refresh_timer > 0.0:
        return
    _refresh_timer = 0.12
    if not _is_valid_selected_target():
        if is_instance_valid(target_panel) and target_panel.visible:
            clear_target()
        return
    _refresh_target_panel()


func _is_valid_selected_target() -> bool:
    if not is_instance_valid(player) or not is_instance_valid(selected_target):
        return false
    if selected_target is ArenaActor:
        var actor := selected_target as ArenaActor
        return actor.alive and actor.hp > 0.0 and actor.team != player.team
    if selected_target is ArenaTower:
        var tower := selected_target as ArenaTower
        if tower.team == player.team or tower.hp <= 0.0:
            return false
        return not tower.core or bool(game.call("all_towers_destroyed", tower.team))
    if selected_target is ArenaNeutralMonster:
        var monster := selected_target as ArenaNeutralMonster
        return monster.alive and monster.hp > 0.0
    return false


func _refresh_target_panel() -> void:
    if not is_instance_valid(target_panel) or not is_instance_valid(selected_target):
        return
    var target_name := "Target"
    var current_hp := 0.0
    var maximum_hp := 1.0
    if selected_target is ArenaActor:
        var actor := selected_target as ArenaActor
        target_name = actor.label
        current_hp = actor.hp
        maximum_hp = actor.max_hp
    elif selected_target is ArenaTower:
        var tower := selected_target as ArenaTower
        target_name = "ANCIENT" if tower.core else "TOWER • LANE %d" % (tower.lane_index + 1)
        current_hp = tower.hp
        maximum_hp = tower.max_hp
    elif selected_target is ArenaNeutralMonster:
        var monster := selected_target as ArenaNeutralMonster
        target_name = monster.label
        current_hp = monster.hp
        maximum_hp = monster.max_hp

    target_panel.visible = true
    target_title.text = target_name.to_upper()
    target_health.text = "HP  %d / %d" % [int(current_hp), int(maximum_hp)]
    target_health_bar.max_value = maxf(1.0, maximum_hp)
    target_health_bar.value = clampf(current_hp, 0.0, maximum_hp)
    if is_instance_valid(attack_button):
        attack_button.text = "ATTACK\nCHASE" if is_instance_valid(player) and player.player_attack_order else "ATTACK\nLOCKED"


func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#101D30", 0.94)
    style.border_color = Color("#C69A4D", 0.88)
    style.set_border_width_all(2)
    style.set_corner_radius_all(12)
    style.content_margin_left = 8.0
    style.content_margin_right = 8.0
    style.content_margin_top = 6.0
    style.content_margin_bottom = 6.0
    return style


func _bar_background() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#26364A")
    style.set_corner_radius_all(5)
    return style


func _bar_fill() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#D36B65")
    style.set_corner_radius_all(5)
    return style


func _clear_button_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(8)
    style.content_margin_left = 5.0
    style.content_margin_right = 5.0
    return style
