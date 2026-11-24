extends Node
class_name ArenaAudioDirector

const MUSIC_PATH := "res://assets/audio/ambient_loop.wav"
const SOUND_PATHS := {
    "ui": "res://assets/audio/ui_select.wav",
    "attack": "res://assets/audio/sword_hit.wav",
    "spell": "res://assets/audio/spell_cast.wav",
    "death": "res://assets/audio/hero_death.wav",
    "structure": "res://assets/audio/structure_break.wav"
}

var music_player: AudioStreamPlayer
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _muted := false

func _ready() -> void:
    music_player = AudioStreamPlayer.new()
    music_player.name = "ArenaMusic"
    music_player.bus = "Master"
    music_player.volume_db = -18.0
    var music := load(MUSIC_PATH) as AudioStreamWAV
    if music != null:
        music.loop_mode = AudioStreamWAV.LOOP_FORWARD
        music.loop_begin = 0
        music.loop_end = int(music.data.size() / 2)
        music_player.stream = music
    add_child(music_player)

    for index in range(8):
        var player := AudioStreamPlayer.new()
        player.name = "ArenaSFX_%d" % index
        player.bus = "Master"
        player.volume_db = -7.0
        add_child(player)
        _players.append(player)

func start_music() -> void:
    if not _muted and is_instance_valid(music_player) and music_player.stream != null and not music_player.playing:
        music_player.play()

func stop_music() -> void:
    if is_instance_valid(music_player):
        music_player.stop()

func play_sfx(key: String, pitch := 1.0) -> void:
    if _muted or not SOUND_PATHS.has(key) or _players.is_empty():
        return
    var stream := load(str(SOUND_PATHS[key])) as AudioStream
    if stream == null:
        return
    var player := _players[_next_player]
    _next_player = (_next_player + 1) % _players.size()
    if player.playing:
        player.stop()
    player.stream = stream
    player.pitch_scale = clampf(pitch, 0.75, 1.35)
    player.play()

func set_muted(value: bool) -> void:
    _muted = value
    if _muted:
        stop_music()
    else:
        start_music()
