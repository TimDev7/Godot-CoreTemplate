extends Node
class_name CoreSoundManager

const _BUS_LAYOUT:AudioBusLayout = preload("uid://cnlrydd82c856")

const _SFX_POOL_MAX_SIZE:int = 50
var _sfx_pool: Array = []
var _idx:int = 0

var _music_player:AudioStreamPlayer
 

func _ready():
	for _i in range(_SFX_POOL_MAX_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_pool.append(player)
	
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"


func set_bus_mute(bus_name:String, is_muted:bool) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, is_muted)


func set_bus_volume(bus_name:String, db_linear:float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(db_linear))


func play_sfx(stream:AudioStream, linear_db:float = 1.0, pitch_var:float = 0.0) -> void:
	var player:AudioStreamPlayer = _sfx_pool[_idx]
	
	player.stream = stream
	player.volume_db = linear_to_db(linear_db)
	player.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var)
	player.play()
	
	_idx = (_idx + 1) % _SFX_POOL_MAX_SIZE


func play_music(stream:AudioStream, linear_db:float = 1.0) -> void:
	_music_player.stream = stream
	_music_player.volume_db = linear_to_db(linear_db)
	_music_player.play()
