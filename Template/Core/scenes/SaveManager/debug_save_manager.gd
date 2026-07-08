extends Node
class_name CoreDSaveManager

const DEFAULT_DATA_SAVEPATH:String = "user://game_data.json"
const SAVE_SECRET_CODE:String = "HelloMyLittleHacker:)"

var data_handler:Node
var migration_manager:MigrationManager


func initialize(_date_handler:Node, _migration_manager:MigrationManager) -> void:
	data_handler = _date_handler
	migration_manager = _migration_manager
	Core.event_bus.connect("game_data_saved",_on_game_data_saved)


func load_data(path:String = DEFAULT_DATA_SAVEPATH) -> void:
	var success:bool = false
	var backup_used:bool = false
	var default_save_time:int = int(Time.get_unix_time_from_system())
	
	data_handler.load_default_data()
	if not FileAccess.file_exists(path):
		save_data()
	
	var loaded_data:Dictionary = _load_data_from_file(path)
	var backup_path:String = path + ".bak"
	if loaded_data.is_empty():
		backup_used = true
		loaded_data = _load_data_from_file(backup_path)
	if loaded_data.is_empty():
		success = false
	else:
		success = true
		_migrate_data(loaded_data)
		data_handler.dict_to_game_data(loaded_data)
	
	Core.event_bus.emit_signal("game_data_loaded", success, backup_used, loaded_data.get("save_time", default_save_time))


func save_data(path:String = DEFAULT_DATA_SAVEPATH) -> void:
	_save_data_in_file(_get_data_for_save(),path)


func _on_game_data_saved(success:bool,desc:String) -> void:
	print("success: %s |\tdesc: %s" % [success, desc])


func _load_data_from_file(path:String) -> Dictionary:
	var file:FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("Failed to open data file! Error: %s\tPath: %s:" % [error_string(FileAccess.get_open_error()),path])
		return {}
	var content:String = file.get_as_text()
	file.close()
	
	var parse_result = JSON.parse_string(content)
	if not parse_result:
		print("Failed to parse content json!")
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


func _is_checksum_valid(json:Dictionary) -> bool:
	var json_string:String = str(json["data"])
	var checksum:String = json["signature"]
	
	var current_checksum:String = (json_string + SAVE_SECRET_CODE).sha256_text()
	
	if current_checksum == checksum:
		return true
	
	print("%s != %s" % [current_checksum,checksum])
	return false


func _save_data_in_file(data:String, path:String) -> Error:
	var temp_path:String = _create_temp_file(data)
	if temp_path.is_empty():
		print("Failed to create temp file!")
		Core.event_bus.emit_signal("game_data_saved",false,"Failed to create temp file!")
		return Error.FAILED
	
	var backup_error = _create_backup_file(data,path)
	if backup_error != OK:
		print("Failed to create backup file!")
		Core.event_bus.emit_signal("game_data_saved",false,"Failed to create backup file!")
		return Error.FAILED
	
	var rename_error = DirAccess.open("user://").rename(temp_path,path)
	if rename_error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		print("Failed to rename file!")
		Core.event_bus.emit_signal("game_data_saved",false,"Failed to rename file!")
		return Error.FAILED
	
	Core.event_bus.emit_signal("game_data_saved",true,"Saved successfuly!")
	return Error.OK


func _get_data_for_save() -> String:
	var data:Dictionary[String,Variant] = data_handler.game_data_to_dict()
	data["save_time"] = int(Time.get_unix_time_from_system())
	data.sort()
	var json_string = JSON.stringify(data,"\t")
	
	
	var checksum:String = (json_string + SAVE_SECRET_CODE).sha256_text()
	var save_package:Dictionary[String,Variant] = {
		"data": json_string, 									# ПОФИКСИ СТРОЧКУ!!! ЭТО ВЫГЛЯДИТ УЖАСНО В JSON!!!
		"signature": checksum, 
	}
	var data_string:String = JSON.stringify(save_package,"\t")
	return data_string


func _create_temp_file(data:String) -> String:
	var temp_file:FileAccess = FileAccess.create_temp(FileAccess.WRITE,"save","tmp",true)
	var temp_path:String = temp_file.get_path()
	if not temp_file:
		print("Failed to create temp file! Error: %s\tPath:%s" % [error_string(FileAccess.get_open_error()),temp_path])
		return ""
	
	temp_file.store_string(data)
	temp_file.flush()
	temp_file.close()
	return temp_path


func _create_backup_file(data:String, path:String = DEFAULT_DATA_SAVEPATH) -> Error:
	var dir:DirAccess = DirAccess.open("user://")
	if not dir:
		print("Failed to open user dir! Error: %s" % error_string(DirAccess.get_open_error()))
		return Error.FAILED
	
	var old_backup_path:String = path + ".bak"
	var new_backup_path:String = old_backup_path + ".tmp"
	var file = FileAccess.open(new_backup_path, FileAccess.WRITE)
	if not file:
		print("Failed to open backup file! Error: %s\tPath:%s" % error_string(FileAccess.get_open_error()),new_backup_path)
		return Error.FAILED
	file.store_string(data)
	file.close()
	
	var rename_error = dir.rename(new_backup_path,old_backup_path)
	if rename_error != OK:
		print("Failed to rename backup file! Error: %s\tPath:%s" % [error_string(rename_error),new_backup_path])
		return Error.FAILED
	return Error.OK


func _migrate_data(data:Dictionary) -> void:
	migration_manager.run_migrations(data)
