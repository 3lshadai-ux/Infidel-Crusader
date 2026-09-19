extends Control
## Mobile virtual stick — uses global touch coords so Android touches register reliably.

signal direction_changed(dir: Vector2)

@export var deadzone: float = 0.12
@export var max_radius: float = 90.0

@onready var base: Panel = $Base
@onready var knob: Panel = $Base/Knob

var _touch_index: int = -1
var _center_global: Vector2 = Vector2.ZERO
var _active: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if base:
		base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if knob:
		knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	call_deferred("_refresh_center")
	visibility_changed.connect(_refresh_center)
	resized.connect(_refresh_center)

func _refresh_center() -> void:
	if base == null:
		return
	_center_global = base.get_global_rect().get_center()
	_reset_knob_visual()

func _input(event: InputEvent) -> void:
	# Prefer raw screen touch on device; also accept mouse (emulated touch / desktop).
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed and _touch_index < 0:
			if _in_stick_zone(st.position):
				_touch_index = st.index
				_active = true
				_update_from_global(st.position)
				get_viewport().set_input_as_handled()
		elif (not st.pressed) and st.index == _touch_index:
			_reset()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and _active and event.index == _touch_index:
		_update_from_global(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _touch_index < 0 and _in_stick_zone(event.position):
			_touch_index = -2
			_active = true
			_update_from_global(event.position)
			get_viewport().set_input_as_handled()
		elif (not event.pressed) and _touch_index == -2:
			_reset()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _active and _touch_index == -2:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_update_from_global(event.position)
			get_viewport().set_input_as_handled()

func _in_stick_zone(global_pos: Vector2) -> bool:
	# Generous hit area: whole joystick control rect (not just the base panel).
	return get_global_rect().grow(24.0).has_point(global_pos)

func _update_from_global(global_pos: Vector2) -> void:
	if _center_global == Vector2.ZERO:
		_refresh_center()
	var offset := global_pos - _center_global
	if offset.length() > max_radius:
		offset = offset.normalized() * max_radius
	if knob and base:
		var local_center := base.size * 0.5
		knob.position = local_center + offset - knob.size * 0.5
	var dir := offset / max_radius
	if dir.length() < deadzone:
		dir = Vector2.ZERO
	# UI Y down → game forward is -Y in stick space
	direction_changed.emit(Vector2(dir.x, -dir.y))

func _reset_knob_visual() -> void:
	if knob == null or base == null:
		return
	var local_center := base.size * 0.5
	knob.position = local_center - knob.size * 0.5

func _reset() -> void:
	_touch_index = -1
	_active = false
	_reset_knob_visual()
	direction_changed.emit(Vector2.ZERO)
