extends Node
class_name CoreSaveManager

const DATA_SAVEPATH:String = "user://game_data.json"

var data_handler:Node
@onready var auto_save_timer = $AutoSaveTimer

func initialize(_data_handler:Node) -> void:
	data_handler = _data_handler

func load_data() -> void:
	data_handler.load_default_data()
	
	if not FileAccess.file_exists(DATA_SAVEPATH):
		save_data()
		Core.event_bus.emit_signal("game_data_loaded", int(Time.get_unix_time_from_system()))
		return
	
	var file = FileAccess.open(DATA_SAVEPATH, FileAccess.READ)
	var content = file.get_as_text() 
	file.close()
	
	var loaded_data = JSON.parse_string(content)
	
	if typeof(loaded_data) != TYPE_DICTIONARY:
		push_error("Save file is corrupted! Starting with default data.")
		Core.event_bus.emit_signal("game_data_loaded", int(Time.get_unix_time_from_system()))
		return
		
	data_handler.dict_to_game_data(loaded_data)
	Core.event_bus.emit_signal("game_data_loaded", loaded_data.get("save_time", int(Time.get_unix_time_from_system())))


func save_data() -> void:
	if auto_save_timer:
		auto_save_timer.start()
	
	var data:Dictionary = data_handler.game_data_to_dict()
	data["save_time"] = int(Time.get_unix_time_from_system())
	
	var json_data = JSON.stringify(data, "\t")
	var file = FileAccess.open(DATA_SAVEPATH, FileAccess.WRITE)
	file.store_string(json_data)
	file.close()


func _on_AutoSaveTimer_timeout() -> void:
	save_data()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_data()
	
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_data()
