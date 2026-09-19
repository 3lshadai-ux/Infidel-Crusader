extends CharacterBody3D
## Third-person mobile-friendly character controller.
## Keyboard (WASD) on desktop; virtual joystick on touch.

@export var move_speed: float = 7.5
@export var acceleration: float = 16.0
@export var rotation_speed: float = 12.0
@export var gravity: float = 20.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

## Set by VirtualJoystick UI (Vector2 in -1..1). Zero when not touching.
var joystick_input: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("player")
	spring_arm.spring_length = 7.0
	spring_arm.rotation_degrees.x = -28.0
	floor_snap_length = 0.4

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
