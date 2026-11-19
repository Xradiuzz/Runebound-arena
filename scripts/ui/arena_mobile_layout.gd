extends Node
class_name ArenaMobileLayout

const DESIGN_SIZE := Vector2(1280.0, 720.0)

var selection_layer: CanvasLayer
var hud_layer: CanvasLayer
var _ui_transform := Transform2D.IDENTITY
var _safe_rect := Rect2(Vector2.ZERO, DESIGN_SIZE)


func _ready() -> void:
    get_viewport().size_changed.connect(_apply_layout)
    call_deferred("_apply_layout")


func set_layers(selection: CanvasLayer, hud: CanvasLayer) -> void:
    selection_layer = selection
    hud_layer = hud
    call_deferred("_apply_layout")


func to_design_position(viewport_position: Vector2) -> Vector2:
    var active_layer: CanvasLayer
    if is_instance_valid(hud_layer):
        active_layer = hud_layer
    elif is_instance_valid(selection_layer):
        active_layer = selection_layer
    if is_instance_valid(active_layer):
        return active_layer.get_final_transform().affine_inverse() * viewport_position
    return _ui_transform.affine_inverse() * viewport_position


func get_safe_rect() -> Rect2:
    return _safe_rect


func get_ui_scale() -> float:
    return _ui_transform.x.length()


func _apply_layout() -> void:
    var viewport_size := get_viewport().get_visible_rect().size
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        return
    _safe_rect = _get_safe_rect(viewport_size)

    var scale_x := _safe_rect.size.x / DESIGN_SIZE.x
    var scale_y := _safe_rect.size.y / DESIGN_SIZE.y
    var uniform_scale := maxf(0.1, minf(scale_x, scale_y))
    var content_size := DESIGN_SIZE * uniform_scale
    var origin := _safe_rect.position + (_safe_rect.size - content_size) * 0.5
    _ui_transform = Transform2D(
        Vector2(uniform_scale, 0.0),
        Vector2(0.0, uniform_scale),
        origin
    )

    if is_instance_valid(selection_layer):
        selection_layer.transform = _ui_transform
        _fit_selection_backdrop(viewport_size, uniform_scale, origin)
    if is_instance_valid(hud_layer):
        hud_layer.transform = _ui_transform


func _get_safe_rect(viewport_size: Vector2) -> Rect2:
    if not OS.has_feature("android") and not OS.has_feature("ios"):
        return Rect2(Vector2.ZERO, viewport_size)

    var screen_size := DisplayServer.screen_get_size()
    if screen_size.x <= 0 or screen_size.y <= 0:
        return Rect2(Vector2.ZERO, viewport_size)

    var safe_area := DisplayServer.get_display_safe_area()
    if safe_area.size.x <= 0 or safe_area.size.y <= 0:
        return Rect2(Vector2.ZERO, viewport_size)

    var ratio := viewport_size / Vector2(screen_size)
    var safe_position := Vector2(safe_area.position) * ratio
    var safe_size := Vector2(safe_area.size) * ratio
    safe_position.x = clampf(safe_position.x, 0.0, viewport_size.x)
    safe_position.y = clampf(safe_position.y, 0.0, viewport_size.y)
    safe_size.x = clampf(safe_size.x, 0.0, viewport_size.x - safe_position.x)
    safe_size.y = clampf(safe_size.y, 0.0, viewport_size.y - safe_position.y)

    if safe_size.x < 320.0 or safe_size.y < 180.0:
        return Rect2(Vector2.ZERO, viewport_size)
    return Rect2(safe_position, safe_size)


func _fit_selection_backdrop(
    viewport_size: Vector2,
    uniform_scale: float,
    origin: Vector2
) -> void:
    if not is_instance_valid(selection_layer):
        return
    var backdrop := selection_layer.get_node_or_null("SelectionBackdrop") as ColorRect
    if not is_instance_valid(backdrop):
        return
    backdrop.position = -origin / uniform_scale
    backdrop.size = viewport_size / uniform_scale
