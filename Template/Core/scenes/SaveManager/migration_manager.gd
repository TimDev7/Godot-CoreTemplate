extends Node
class_name MigrationManager

const CURRENT_VERSION:int = 0

func run_migrations(game_data:Dictionary) -> void:
	var data_ver:int = game_data.get("data_ver",0)
	
	while data_ver < CURRENT_VERSION:
		match data_ver:
			0: pass #_migrate_v0_to_v1(game_data)
		data_ver += 1
	
	game_data["data_ver"] = data_ver


#func _migrate_v0_to_v1(data:Dictionary) -> void:
	## Example
	## data["hp"] = data["health"]
	## data.erase("health")
	#pass 
