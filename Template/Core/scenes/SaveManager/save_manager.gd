extends Node
class_name CoreSaveManager

# [Х] Малая связность 
# [Х] Защита через контрольные суммы
# [Х] Атомарные сохранения
# [Х] Система бэкапов
# [ ] Поточное сохранение
# [ ] Миграции данных

const AUTO_SAVE_WAIT_TIME:float = 5.0

var data_handler:Node
var save_manager:Node
var auto_save_timer:Timer

func initialize(_data_handler:Node) -> void:
	data_handler = _data_handler
	_set_save_manager()
	
	save_manager.initialize(data_handler)
	save_manager.load_data()
	
	_create_auto_save_timer()
	Core.event_bus.connect("game_data_saved",_on_game_data_saved)


func load_data() -> void:
	save_manager.load_data()


func save_data() -> void:
	save_manager.save_data()


func _set_save_manager() -> void:
	if OS.has_feature("editor"):
		save_manager = CoreDSaveManager.new()
	else:
		save_manager = CoreRSaveManager.new()
	add_child(save_manager)


func _create_auto_save_timer() -> void:
	var timer:Timer = Timer.new()
	timer.wait_time = AUTO_SAVE_WAIT_TIME
	timer.autostart = true
	timer.ignore_time_scale = true
	add_child(timer)
	
	auto_save_timer = timer
	auto_save_timer.connect("timeout",_on_AutoSaveTimer_timeout)


func _on_AutoSaveTimer_timeout():
	save_data()


func _on_game_data_saved():
	auto_save_timer.start()


func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_data()
	
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_data()
		get_tree().quit()
