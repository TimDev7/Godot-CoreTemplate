@tool
extends TextureProgressBar
class_name JuicyProgressBar

## USE 'new_value' INSTEAD FOR SMOOTH EFFECT

signal max_value_achived
signal animation_finished

@export var new_value:float:
	set(value):
		new_value = clampf(value,min_value,max_value)
		await _change_value_smooth(new_value)
		if is_equal_approx(new_value, max_value):
			max_value_achived.emit()

@export var icon_tex:Texture2D:
	set(value):
		icon_tex = value
		call_deferred("_update_ui")

@export var anim_time:float = 0.2:
	set(value):
		anim_time = clampf(value,0.05,10)

@export_category("Margins")
@export var container_margin_left:int = 4:
	set(value):
		container_margin_left = value
		call_deferred("_update_ui")
@export var container_margin_top:int = 4:
	set(value):
		container_margin_top = value
		call_deferred("_update_ui")
@export var container_margin_right:int = 4:
	set(value):
		container_margin_right = value
		call_deferred("_update_ui")
@export var container_margin_bottom:int = 4:
	set(value):
		container_margin_bottom = value
		call_deferred("_update_ui")

@onready var margin_container: MarginContainer = %MarginContainer
@onready var value_label: Label = %ValueLabel
@onready var icon: TextureRect = %Icon

var _tween:Tween


func _update_ui() -> void:
	if not is_inside_tree(): return
	if not margin_container:
		margin_container = %MarginContainer
	if not value_label:
		value_label = %ValueLabel
	if not icon:
		icon = %Icon
	
	margin_container.add_theme_constant_override("margin_bottom",container_margin_bottom)
	margin_container.add_theme_constant_override("margin_left", container_margin_left)
	margin_container.add_theme_constant_override("margin_right", container_margin_right)
	margin_container.add_theme_constant_override("margin_top", container_margin_top)
	#value_label.text = str(value / max_value * 100) + "%"
	icon.texture = icon_tex
	

func _change_value_smooth(_new_value: float) -> void:
	if _tween: _tween.kill()
	_tween = create_tween().set_parallel(true)
	
	_tween.tween_property(self, "value", _new_value, anim_time).set_trans(Tween.TRANS_BACK)
	_tween.tween_method(
		func(val:float):
			value_label.text = str(snapped(val / max_value * 100.0, 0.1)) + "%"
			print(0),
		value,
		_new_value,
		anim_time
	)
	await _tween.finished
	animation_finished.emit()
