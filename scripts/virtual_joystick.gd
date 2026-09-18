extends Control
## Left-side virtual stick for mobile; mouse-drag works on desktop too.

signal direction_changed(dir: Vector2)

@export var deadzone: float = 0.15
@export var max_radius: float = 80.0

@onready var base: Panel = $Base
@onready var knob: Panel = $Base/Knob

var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _active: bool = false

func _ready() -> void:
	_center = base.size * 0.5
	knob.position = _center - knob.size * 0.5
	visible = true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag and _active:
		_update_knob(event.position)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _active and _touch_index == -2:
		_update_knob(event.position)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed and _touch_index < 0:
		if _point_in_base(event.position):
			_touch_index = event.index
			_active = true
			_update_knob(event.position)
	elif not event.pressed and event.index == _touch_index:
		_reset()

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed and _touch_index < 0 and _point_in_base(event.position):
		_touch_index = -2
		_active = true
		_update_knob(event.position)
	elif not event.pressed and _touch_index == -2:
		_reset()

func _point_in_base(local_pos: Vector2) -> bool:
	return Rect2(Vector2.ZERO, base.size).has_point(local_pos)

func _update_knob(local_pos: Vector2) -> void:
	var offset := local_pos - _center
	if offset.length() > max_radius:
		offset = offset.normalized() * max_radius
	knob.position = _center + offset - knob.size * 0.5
	var dir := offset / max_radius
	if dir.length() < deadzone:
		dir = Vector2.ZERO
	direction_changed.emit(Vector2(dir.x, -dir.y))

func _reset() -> void:
	_touch_index = -1
	_active = false
	knob.position = _center - knob.size * 0.5
	direction_changed.emit(Vector2.ZERO)
