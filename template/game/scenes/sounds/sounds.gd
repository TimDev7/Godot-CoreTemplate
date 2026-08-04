extends Node
class_name Sounds

var music_mute: bool = false
var sfx_mute: bool = false


func serialize() -> Dictionary:
	var dict:Dictionary = {}
	
	dict["music_mute"] = music_mute
	dict["sfx_mute"] = sfx_mute
	
	return dict


func deserialize(dict:Dictionary) -> void:
	music_mute = dict.get("music_mute",false)
	sfx_mute = dict.get("sfx_mute",false)


func load_default_data() -> void:
	music_mute = false
	sfx_mute = false
