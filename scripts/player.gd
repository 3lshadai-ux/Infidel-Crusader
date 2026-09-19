extends CharacterBody3D
## Third-person mobile-friendly character controller.
## Keyboard (WASD) on desktop; virtual joystick on touch.
## Look: CameraLookPad (mobile) / right-mouse drag (desktop).

@export var move_speed: float = 7.5
@export var acceleration: float = 16.0
@export var rotation_speed: float = 12.0
@export var gravity: float = 20.0

@export var look_sensitivity: float = 0.12
@export var invert_y: bool = false
@export var pitch_min_deg: float = -50.0
@export var pitch_max_deg: float = -10.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

## Set by VirtualJoystick UI (Vector2 in -1..1). Zero when not touching.
var joystick_input: Vector2 = Vector2.ZERO

var _rmb_looking: bool = false

func _ready() -> void:
	add_to_group("player")
	spring_arm.spring_length = 7.0
	spring_arm.rotation_degrees.x = -28.0
	floor_snap_length = 0.4
	collision_layer = 1
	collision_mask = 3  # ground(1) + props(2)
	_apply_look()

func _apply_look() -> void:
	var body := get_node_or_null("MeshInstance3D") as MeshInstance3D
	var head := get_node_or_null("Head") as MeshInstance3D
	var tunic := get_node_or_null("Tunic") as MeshInstance3D
	if body:
		body.material_override = WorldTextures.mat("tunic", Color(0.45, 0.55, 0.75), 0.85)
	if head:
		head.material_override = WorldTextures.mat("skin", Color(0.9, 0.75, 0.6), 0.7)
	if tunic:
		tunic.material_override = WorldTextures.mat("tunic", Color(0.4, 0.5, 0.72), 0.88)

func add_look(delta_yaw: float, delta_pitch: float) -> void:
	## delta_yaw / delta_pitch are screen-pixel drag deltas.
	camera_pivot.rotate_y(-delta_yaw * look_sensitivity * 0.0174533)
	var pitch_sign := -1.0 if invert_y else 1.0
	var new_pitch := spring_arm.rotation_degrees.x + (delta_pitch * pitch_sign * look_sensitivity)
	spring_arm.rotation_degrees.x = clampf(new_pitch, pitch_min_deg, pitch_max_deg)

func _physics_process(delta: float) -> void:
	var input_dir := _get_move_input()
	var cam_basis := camera_pivot.global_transform.basis
	var forward := -cam_basis.z
	var right := cam_basis.x
	forward.y = 0.0
	right.y = 0.0
	if forward.length_squared() > 0.0001:
		forward = forward.normalized()
	if right.length_squared() > 0.0001:
		right = right.normalized()

	var direction := (right * input_dir.x + forward * input_dir.y)
	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	var target_vel := direction * move_speed
	velocity.x = lerpf(velocity.x, target_vel.x, clampf(acceleration * delta, 0.0, 1.0))
	velocity.z = lerpf(velocity.z, target_vel.z, clampf(acceleration * delta, 0.0, 1.0))

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0

	if direction.length_squared() > 0.01:
		var look_target := global_position + Vector3(direction.x, 0.0, direction.z)
		if look_target.distance_squared_to(global_position) > 0.001:
			var target_basis := Basis.looking_at(look_target - global_position, Vector3.UP)
			mesh.global_transform.basis = mesh.global_transform.basis.slerp(target_basis, clampf(rotation_speed * delta, 0.0, 1.0))

	move_and_slide()

func _get_move_input() -> Vector2:
	var kb := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if kb.length_squared() > 0.01:
		return kb
	return joystick_input

func set_joystick(dir: Vector2) -> void:
	joystick_input = dir.limit_length(1.0)

func _unhandled_input(event: InputEvent) -> void:
	# Desktop: right-mouse drag looks around (optional mouse-capture feel).
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_rmb_looking = event.pressed
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _rmb_looking:
		var mm := event as InputEventMouseMotion
		add_look(mm.relative.x, mm.relative.y)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rmb_looking = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
