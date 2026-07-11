@tool
extends MarginContainer
class_name JuicyCheckbox

## DO NOT INTERACT WITH CHILDREN.
## USE PROPERTIES TO ACCESS WITH THEM FROM THIS CLASS INSTEAD

@onready var label: Label = %Label
@onready var h_box_container: HBoxContainer = %HBoxContainer
@onready var button: TextureButton = %Button
@onready var debug_label: Label = %DebugLabel

@export var text:String:
	set(value):
		text = value
		call_deferred("_update_ui")

@export var font_size:int:
	set(value):
		font_size = value
		call_deferred("_update_ui")


@export var h_separation: int:
	set(value):
		h_separation = value
		call_deferred("_update_ui")


@export_category("Button")
@export var disabled:bool:
	set(value):
		disabled = value
		call_deferred("_update_ui")


@export var button_pressed:bool:
	set(value):
		button_pressed = value
		call_deferred("_update_ui")


func _update_ui() -> void:
	if not is_inside_tree(): return
	if not label:
		label = %Label
	if not h_box_container:
		h_box_container = %HBoxContainer
	if not button:
		button = %Button
	if not debug_label:
		debug_label = %DebugLabel
	label.text = text
	label.add_theme_font_size_override("font_size",font_size)
	h_box_container.add_theme_constant_override("separation",h_separation)
	button.disabled = disabled
	debug_label.text = str(button_pressed)


func _on_button_toggled(toggled_on: bool) -> void:
	if button_pressed == toggled_on:
		return
	button_pressed = toggled_on
