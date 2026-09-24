@icon("res://template/Core/CoreNodeIcon.svg")
extends Node

@onready var event_bus:CoreEventBus = $EventBus
@onready var save_manager:CoreSaveManager = $SaveManager
@onready var sound_manager:CoreSoundManager = $SoundManager


func _ready():
	randomize()


func register_game(data_handler:Node) -> void:
	save_manager.initialize(data_handler)


## Which independent callers currently want the tree paused (source name ->
## true) - e.g. the player's own Pause menu and an ad flow (see
## template/sdk/sdk.gd's _begin_ad_pause()/_end_ad_pause()) can both want it
## at once. A plain last-write-wins boolean would let one unpause the
## other's reason out from under it (e.g. an ad closing while the player
## still has the Pause menu open would have silently resumed gameplay
## behind that still-open overlay) - the tree stays paused as long as ANY
## source still wants it.
var _pause_sources: Dictionary = {}


## source defaults to "manual" so existing callers don't need to change -
## only a caller sharing the tree with another pause source (see
## _pause_sources above) needs to pass its own distinct one.
func toggle_pause(turn_on: bool, source: String = "manual") -> void:
	if turn_on:
		_pause_sources[source] = true
	else:
		_pause_sources.erase(source)
	get_tree().paused = not _pause_sources.is_empty()

