extends Node
class_name CoreDSaveManager

const DEFAULT_DATA_SAVEPATH:String = "user://saves/game_data.json"
const SAVE_SECRET_CODE:String = "HelloMyLittleHacker:)"

var data_handler:Node


func initialize(_date_handler:Node) -> void:
	get_tree().set_auto_accept_quit(false)
	data_handler = _date_handler


func load_data(path:String = DEFAULT_DATA_SAVEPATH) -> void:
	var success:bool = false
	var backup_used:bool = false
	var default_save_time:int = int(Time.get_unix_time_from_system())
	
	data_handler.load_default_data()
	
	var loaded_data:Dictionary = _load_data_from_file(path)
	var backup_path:String = path + ".bak"
	if loaded_data.is_empty():
		backup_used = true
		loaded_data = _load_data_from_file(backup_path)
	if loaded_data.is_empty():
		success = false
	else:
		success = true
		data_handler.dict_to_game_data(loaded_data)
	
	Core.event_bus.emit_signal("game_data_loaded", success, backup_used, loaded_data.get("save_time", default_save_time))


func save_data(path:String = DEFAULT_DATA_SAVEPATH) -> void:
	var error = _save_data_in_file(path)
	if error != OK:
		pass
	Core.event_bus.emit_signal("game_data_saved")


func _load_data_from_file(path:String) -> Dictionary:
	var file:FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("Failed to open file! Error: %s" % FileAccess.get_open_error())
		return {}
	var content:String = file.get_as_text()
	file.close()
	
	var parse_result = JSON.parse_string(content)
	if not parse_result:
		push_error("Failed to parse content json!")
		return {}
	
	var loaded_content:Dictionary = parse_result
	
	if not _is_checksum_valid(loaded_content):
		print("Checksums didn't match!")
		return {}

	var data_parse_result = JSON.parse_string(loaded_content["data"])
	if not data_parse_result:
		print("Failed to parse data json!")
		return {}
	
	var loaded_data:Dictionary = data_parse_result
	
	return loaded_data


func _is_checksum_valid(data:Dictionary) -> bool:
	var string_data:String = data["data"]
	var checksum:String = data["signature"]
	var current_checksum = (string_data + SAVE_SECRET_CODE).sha256_text()
	
	if current_checksum == checksum:
		return true
	
	return false


func _save_data_in_file(path:String) -> Error:
	var data:String = _get_data_for_save()
	
	var temp_path:String = _create_temp_file(data)
	if temp_path.is_empty():
		print("Failed to create temp file!")
		return Error.FAILED
	
	var backup_error = _create_backup_file(path)
	if backup_error != OK:
		print("Failed to create backup file!")
	
	var rename_error = DirAccess.open("user://").rename(temp_path,path)
	if rename_error != OK:
		print("Failed to rename file!")
		return Error.FAILED
	
	return Error.OK


func _get_data_for_save() -> String:
	var data:Dictionary[String,Variant] = data_handler.game_data_to_dict()
	data["save_time"] = int(Time.get_unix_time_from_system())
	var json_string = JSON.stringify(data)
	
	var checksum:String = (json_string + SAVE_SECRET_CODE).sha256_text()
	var save_package:Dictionary[String,Variant] = {
		"signature": checksum, 
		"data": data,
	}
	var data_string:String = JSON.stringify(save_package,"\t")
	return data_string


func _create_temp_file(data:String) -> String:
	var temp_file:FileAccess = FileAccess.create_temp(FileAccess.WRITE,"save","tmp",true)
	if not temp_file:
		print("Failed to create temp file! Error: %s" % FileAccess.get_open_error())
		return ""
	
	var temp_path:String = temp_file.get_path()
	temp_file.store_string(data)
	temp_file.flush()
	temp_file.close()
	return temp_path


func _create_backup_file(data:String, path:String = DEFAULT_DATA_SAVEPATH) -> Error:
	var dir:DirAccess = DirAccess.open("user://")
	if not dir:
		print("Failed to open dir! Error: %s" % DirAccess.get_open_error())
		return Error.FAILED
	
	var old_backup_path:String = path + ".bak"
	var new_backup_path:String = old_backup_path + ".new"
	var file = FileAccess.open(new_backup_path, FileAccess.WRITE)
	if not file:
		print("Failed to open file! Erorr: %s" % FileAccess.get_open_error())
	file.store_string(data)
	file.close()
	
	if not dir.file_exists(old_backup_path):
		return Error.ERR_FILE_NOT_FOUND
	
	var rename_error = dir.rename(old_backup_path,new_backup_path)
	if rename_error != OK:
		print("Failed to rename backup file! Error: %s" % rename_error)
		return Error.FAILED
	return Error.OK
