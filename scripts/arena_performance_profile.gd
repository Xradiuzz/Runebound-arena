extends Node
class_name ArenaPerformanceProfile

const QUALITY_LOW := 0
const QUALITY_BALANCED := 1
const QUALITY_HIGH := 2

const SETTINGS_PATH := "user://runebound_settings.cfg"

var game: Node
var quality := QUALITY_BALANCED
var _quality_names := ["LOW", "BALANCED", "HIGH"]
var _settings := ConfigFile.new()


func setup(game_node: Node) -> void:
    game = game_node
    var default_quality := QUALITY_BALANCED
    if _settings.load(SETTINGS_PATH) == OK:
        default_quality = int(_settings.get_value("graphics", "quality", QUALITY_BALANCED))
    set_quality(default_quality, false)


func set_quality(value: int, persist := true) -> void:
    quality = clampi(value, QUALITY_LOW, QUALITY_HIGH)
    var viewport := get_viewport()

    match quality:
        QUALITY_LOW:
            viewport.msaa_3d = Viewport.MSAA_DISABLED
            Engine.max_fps = 30
        QUALITY_BALANCED:
            viewport.msaa_3d = Viewport.MSAA_2X
            Engine.max_fps = 60
        QUALITY_HIGH:
            viewport.msaa_3d = Viewport.MSAA_4X
            Engine.max_fps = 60

    var shadows_enabled := quality != QUALITY_LOW
    for node in get_tree().get_nodes_in_group("arena_quality_lights"):
        if node is DirectionalLight3D:
            (node as DirectionalLight3D).shadow_enabled = shadows_enabled

    if persist:
        _settings.set_value("graphics", "quality", quality)
        var save_error := _settings.save(SETTINGS_PATH)
        if save_error != OK:
            push_warning("Could not save Runebound Arena graphics settings: %s" % error_string(save_error))


func get_quality_name() -> String:
    return _quality_names[quality]


func get_quality_description() -> String:
    match quality:
        QUALITY_LOW:
            return "Shadows off • MSAA off • 30 FPS cap"
        QUALITY_BALANCED:
            return "Shadows on • 2x MSAA • 60 FPS cap"
        _:
            return "Shadows on • 4x MSAA • 60 FPS cap"
