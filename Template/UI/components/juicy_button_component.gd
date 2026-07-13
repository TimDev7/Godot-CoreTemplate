extends Node
class_name JuicyButtonComponent

@export var button_down_scale:Vector2 = Vector2(0.8,0.8)
@export var button_up_scale:Vector2 = Vector2(1.1,1.1)
@export var anim_time:float = 0.1

var tween:Tween
var _button:BaseButton

func _ready() -> void:
	var parent = get_parent()
	if parent is BaseButton:
		_button = parent
	_button.pivot_offset_ratio = Vector2(0.5,0.5)
	_button.button_down.connect(_on_button_down)
	_button.button_up.connect(_on_button_up)


func _on_button_down() -> void:
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(_button, "scale", button_down_scale, anim_time).set_ease(Tween.EASE_IN)


func _on_button_up() -> void:
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(_button, "scale", button_up_scale, anim_time).set_ease(Tween.EASE_OUT)
	tween.tween_property(_button, "scale", Vector2.ONE, anim_time).set_ease(Tween.EASE_OUT)
