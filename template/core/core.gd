@icon("res://Template/Core/CoreNodeIcon.svg")
extends Node

@onready var event_bus:CoreEventBus = $EventBus
@onready var save_manager:CoreSaveManager = $SaveManager
@onready var sound_manager:CoreSoundManager = $SoundManager


func _ready():
	randomize()


func register_game(data_handler:Node) -> void:
	save_manager.initialize(data_handler)


func toggle_pause(turn_on:bool) -> void:
	get_tree().paused = turn_on
	
