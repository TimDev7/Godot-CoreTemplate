extends Node
class_name CoreSaveManager

var data_handler:Node
var save_manager:Node


func initialize(_data_handler:Node) -> void:
	data_handler = _data_handler
	set_save_manager()
	save_manager.initialize(data_handler)
	save_manager.load_data()


func set_save_manager() -> void:
	if OS.has_feature("editor"):
		save_manager = CoreDSaveManager.new()
	else:
		save_manager = CoreRSaveManager.new()
	add_child(save_manager)
	


func load_data() -> void:
	save_manager.load_data()


func save_data() -> void:
	save_manager.save_data()
