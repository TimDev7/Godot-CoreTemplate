extends Node
class_name CoreRSaveManager

const DATA_SAVEPATH:String = "user://game_data.dat"
const SAVE_SECRET_CODE:String = "HelloMyLittleHacker:)"

var data_handler:Node
@export var auto_save_timer:Timer


func initialize(_date_handler:Node) -> void:
	data_handler = _date_handler


func load_data() -> void:
	pass


func save_data() -> void:
	pass


func _on_AutoSaveTimer_timeout() -> void:
	save_data()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_data()
	
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_data()
