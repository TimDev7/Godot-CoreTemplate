extends GutTest

const SAVE_PATH:String = "user://test_saves/test_save.json"
var data_handler:Node = Game.game_data


func before_all():
	pass


func before_each():
	add_child_autoqfree(CoreDSaveManager)
	


func after_each():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
