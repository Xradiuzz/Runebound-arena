extends Node
class_name ArenaWaveDirector

signal wave_started(wave_number: int, siege_wave: bool, stat_scale: float)

const WAVE_INTERVAL := 22.0
const MAX_STAT_SCALE := 1.35
const SCALE_STEP := 0.07
const SCALE_EVERY_WAVES := 4

var game: Node
var wave_number := 0
var time_to_next_wave := WAVE_INTERVAL
var running := false


func _ready() -> void:
    set_process(true)


func setup(game_node: Node) -> void:
    game = game_node


func start() -> void:
    if running or not is_instance_valid(game):
        return
    running = true
    _spawn_next_wave()
    time_to_next_wave = WAVE_INTERVAL


func _process(delta: float) -> void:
    if not running or not is_instance_valid(game):
        return
    if bool(game.get("game_over")):
        return

    time_to_next_wave = maxf(0.0, time_to_next_wave - delta)
    if time_to_next_wave <= 0.0:
        _spawn_next_wave()
        time_to_next_wave = WAVE_INTERVAL


func _spawn_next_wave() -> void:
    wave_number += 1
    var siege_wave := wave_number % 3 == 0
    var scaling_steps := floori(float(wave_number - 1) / float(SCALE_EVERY_WAVES))
    var stat_scale := minf(1.0 + float(scaling_steps) * SCALE_STEP, MAX_STAT_SCALE)
    if game.has_method("spawn_lane_wave"):
        game.call("spawn_lane_wave", wave_number, siege_wave, stat_scale)
    wave_started.emit(wave_number, siege_wave, stat_scale)


func get_status_text() -> String:
    if wave_number <= 0:
        return "FIRST WAVE INCOMING"
    var suffix := "  •  SIEGE" if wave_number % 3 == 0 else ""
    return "WAVE %02d  •  NEXT %02dS%s" % [wave_number, int(ceil(time_to_next_wave)), suffix]
