extends Node
class_name CoreDSaveManager

const DEFAULT_DATA_SAVEPATH:String = "user://game_data.json"
const BACKUP_DATA_SAVEPATH:String = "user://backup_game_data.json"
const SAVE_SECRET_CODE:String = "HelloMyLittleHacker:)"
const AUTO_SAVE_WAIT_TIME:float = 5.0

var data_handler:Node
@export var auto_save_timer:Timer


func initialize(_date_handler:Node) -> void:
	get_tree().set_auto_accept_quit(false)
	data_handler = _date_handler
	
	if !auto_save_timer:
		_create_auto_save_timer()
	if !auto_save_timer.is_connected("timeout",_on_AutoSaveTimer_timeout):
		auto_save_timer.connect("timeout",_on_AutoSaveTimer_timeout)


func load_data(path:String = DEFAULT_DATA_SAVEPATH) -> void:
	var success:bool = false
	var backup_used:bool = false
	var default_save_time:int = int(Time.get_unix_time_from_system())
	data_handler.load_default_data()
	
	if !FileAccess.file_exists(path):
		save_data(path)
	
	var loaded_data:Dictionary = _load_data_from_file(path)
	
	if loaded_data.is_empty():
		backup_used = true
		loaded_data = _load_data_from_file(BACKUP_DATA_SAVEPATH)
	if loaded_data.is_empty():
		success = false
	else:
		success = true
		data_handler.dict_to_game_data(loaded_data)
		_save_data_in_file(BACKUP_DATA_SAVEPATH)
	
	Core.event_bus.emit_signal("game_data_loaded", success, backup_used, loaded_data.get("save_time", default_save_time))


func save_data(path:String = DEFAULT_DATA_SAVEPATH) -> void:
	auto_save_timer.start()
	_save_data_in_file(path)


func _create_auto_save_timer() -> void:
	var timer:Timer = Timer.new()
	timer.wait_time = AUTO_SAVE_WAIT_TIME
	timer.autostart = true
	timer.ignore_time_scale = true
	add_child(timer)
	
	auto_save_timer = timer


func _load_data_from_file(path:String) -> Dictionary:
	var file:FileAccess = FileAccess.open(path, FileAccess.READ)
	var content:String = file.get_as_text()
	file.close()
	
	var parse_result = JSON.parse_string(content)
	if !parse_result:
		push_error("Error while parsing json!")
		return {}
	
	var loaded_data:Dictionary = parse_result
	return loaded_data


func _save_data_in_file(path:String) -> void:
	var file:FileAccess = FileAccess.open(path,FileAccess.WRITE)
	FileAccess.create_temp(FileAccess.WRITE,"","",true)
	var data:Dictionary[String,Variant] = data_handler.game_data_to_dict()
	data["save_time"] = int(Time.get_unix_time_from_system())
	var json_string = JSON.stringify(data)
	
	var checksum:String = (json_string + SAVE_SECRET_CODE).sha256_text()
	var save_package:Dictionary[String,Variant] = {
		"data": data,
		"signature": checksum, 
	}
	var data_string:String = JSON.stringify(save_package,"\t")
	
	
	file.store_string(data_string)
	file.close()


func _on_AutoSaveTimer_timeout():
	save_data()


func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_data()
	
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_data()
		get_tree().quit()
