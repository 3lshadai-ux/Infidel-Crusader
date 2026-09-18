extends CharacterBody3D
## Jesus NPC — walks a fixed path; player must stay nearby to complete the calling.

enum Phase { WAITING, WALKING, ARRIVED }

@export var walk_speed: float = 3.2
@export var follow_radius: float = 8.0
@export var lose_radius: float = 14.0

@onready var path_points: Node3D = $PathPoints
@onready var marker_mesh: MeshInstance3D = $MarkerBeacon
@onready var label_3d: Label3D = $Label3D

var phase: Phase = Phase.WAITING
var _waypoints: Array[Vector3] = []
var _wp_index: int = 0
var _player: Node3D = null
var _follow_started: bool = false
var _warned_distance: bool = false

func _ready() -> void:
	add_to_group("jesus")
	for child in path_points.get_children():
		if child is Node3D:
			_waypoints.append(child.global_position)
	label_3d.text = "Jesus"
	GameState.update_mission_text("Approach Jesus at the Capernaum shore (yellow beacon).")

func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node3D
		return

	var dist := global_position.distance_to(_player.global_position)

	match phase:
		Phase.WAITING:
			_bob_marker(delta)
			if dist <= follow_radius * 0.75:
				_start_follow()
		Phase.WALKING:
			_bob_marker(delta)
			_walk_path(delta)
			_check_follow_distance(dist)
		Phase.ARRIVED:
			pass

func _start_follow() -> void:
	if _follow_started:
		return
	_follow_started = true
	phase = Phase.WALKING
	_wp_index = 0
	GameState.update_mission_text("Follow Jesus — stay close along the shore path.")

func _walk_path(_delta: float) -> void:
	if _wp_index >= _waypoints.size():
		_finish()
		return
	var target: Vector3 = _waypoints[_wp_index]
	var to_target := target - global_position
	to_target.y = 0.0
	if to_target.length() < 0.6:
		_wp_index += 1
		return
	var dir := to_target.normalized()
	velocity = dir * walk_speed
	velocity.y = 0.0
	look_at(global_position + dir, Vector3.UP)
	move_and_slide()

func _check_follow_distance(dist: float) -> void:
	if dist > lose_radius:
		if not _warned_distance:
			_warned_distance = true
			GameState.update_mission_text("You're falling behind — catch up to Jesus!")
	elif dist <= follow_radius:
		_warned_distance = false
		if phase == Phase.WALKING:
			GameState.update_mission_text("Following Jesus… stay near Him.")

func _finish() -> void:
	phase = Phase.ARRIVED
	velocity = Vector3.ZERO
	marker_mesh.visible = false
	if _player and global_position.distance_to(_player.global_position) <= lose_radius:
		GameState.complete_follow_mission()
	else:
		GameState.update_mission_text("You lost Him on the path. Approach the beacon to try again.")
		_reset_path()

func _reset_path() -> void:
	phase = Phase.WAITING
	_follow_started = false
	_warned_distance = false
	_wp_index = 0
	if _waypoints.size() > 0:
		global_position = _waypoints[0] + Vector3(0, 0, 2)
	marker_mesh.visible = true

func _bob_marker(delta: float) -> void:
	if marker_mesh:
		marker_mesh.rotation.y += delta * 1.5
		marker_mesh.position.y = 2.4 + sin(Time.get_ticks_msec() * 0.004) * 0.15
