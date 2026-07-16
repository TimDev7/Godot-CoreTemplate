@tool
extends MarginContainer
class_name JuicyCheckboxPanel

## DO NOT INTERACT WITH CHILDREN.
## USE PROPERTIES TO ACCESS WITH THEM FROM THIS CLASS INSTEAD

@onready var label: Label = %Label
@onready var juicy_check_box: JuicyCheckbox = %JuicyCheckBox
@onready var button: CheckBox = juicy_check_box.button


@export var text:String:
	set(value):
		text = value
		call_deferred("_update_ui")

@export var font_size:int:
	set(value):
		font_size = value
		call_deferred("_update_ui")


@export var button_min_size:Vector2 = Vector2(32,32):
	set(value):
		button_min_size = value
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
	if not juicy_check_box:
		juicy_check_box = %JuicyCheckBox
	if not button:
		button = juicy_check_box.button
	label.text = text
	label.add_theme_font_size_override("font_size",font_size)
	button.disabled = disabled
	juicy_check_box.custom_minimum_size = button_min_size


func _on_button_toggled(toggled_on: bool) -> void:
	if button_pressed == toggled_on:
		return
	button_pressed = toggled_on
