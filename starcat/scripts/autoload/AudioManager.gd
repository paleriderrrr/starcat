extends Node

const SOUND_PATHS: Dictionary = {
	"ui_tick": "res://assets/audio/sfx/ui_tick.ogg",
	"ui_confirm": "res://assets/audio/sfx/ui_confirm.ogg",
	"ui_panel": "res://assets/audio/sfx/ui_panel.ogg",
	"fleet_select": "res://assets/audio/sfx/fleet_select.ogg",
	"fleet_move": "res://assets/audio/sfx/fleet_move.ogg",
	"turn_ready": "res://assets/audio/sfx/turn_ready.ogg",
	"combat_alert": "res://assets/audio/sfx/combat_alert.ogg",
}

const DEFAULT_BUS: String = "Master"

var enabled: bool = true
var _players: Dictionary = {}


func _ready() -> void:
	for key: Variant in SOUND_PATHS.keys():
		var event_name: String = str(key)
		var player: AudioStreamPlayer = _make_player(str(SOUND_PATHS[event_name]))
		_players[event_name] = player


func set_enabled(value: bool) -> void:
	enabled = value


func play_event(event_name: String) -> void:
	if not enabled or not _players.has(event_name):
		return
	var player: AudioStreamPlayer = _players[event_name] as AudioStreamPlayer
	if player == null or player.stream == null:
		return
	player.stop()
	player.play()


func _make_player(sound_path: String) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.bus = DEFAULT_BUS
	player.stream = ResourceLoader.load(sound_path) as AudioStream
	add_child(player)
	return player
