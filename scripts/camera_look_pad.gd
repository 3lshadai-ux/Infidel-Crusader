extends Control
## Transparent right-side pad: drag to pivot the third-person camera.
## Anchored to the right half of the HUD; BottomBar sits above it in the tree
## so Interact / Journal keep priority. Joystick is on the left half.

var _touch_index: int = -1
var _active: bool = false
var _hud: Node = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(true)

func bind_hud(hud: Node) -> void:
	_hud = hud

func _input(event: InputEvent) -> void:
	if _modals_block():
		if _active:
			_reset()
		return

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed and _touch_index < 0:
			if _in_pad(st.position) and not _hits_ui_button(st.position):
				_touch_index = st.index
				_active = true
				get_viewport().set_input_as_handled()
		elif (not st.pressed) and st.index == _touch_index:
			_reset()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and _active and event.index == _touch_index:
		_apply_drag(event.relative)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _touch_index < 0 and _in_pad(event.position) and not _hits_ui_button(event.position):
			_touch_index = -2
			_active = true
			get_viewport().set_input_as_handled()
		elif (not event.pressed) and _touch_index == -2:
			_reset()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _active and _touch_index == -2:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_apply_drag(event.relative)
			get_viewport().set_input_as_handled()

func _in_pad(global_pos: Vector2) -> bool:
	return get_global_rect().has_point(global_pos)

func _hits_ui_button(global_pos: Vector2) -> bool:
	if _hud == null:
		return false
	for key in ["interact_btn", "journal_btn"]:
		var btn = _hud.get(key)
		if btn and btn.visible and btn.get_global_rect().grow(8.0).has_point(global_pos):
			return true
	var joy = _hud.get("joystick")
	if joy and joy.visible and joy.get_global_rect().grow(24.0).has_point(global_pos):
		return true
	return false

func _apply_drag(relative: Vector2) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_look"):
		player.add_look(relative.x, relative.y)

func _modals_block() -> bool:
	if _hud == null:
		return false
	for key in ["puzzle_panel", "journal_panel", "scripture_panel", "complete_panel", "levelup_panel", "major_panel"]:
		var node = _hud.get(key)
		if node and node.visible:
			return true
	return false

func _reset() -> void:
	_touch_index = -1
	_active = false
