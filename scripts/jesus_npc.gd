extends CharacterBody3D
## Jesus NPC — shore Follow Me path (ground-only collision + unstick), then guides to active miracle.

enum Phase { WAITING, WALKING, ARRIVED, GUIDING }

@export var walk_speed: float = 3.4
@export var follow_radius: float = 10.0
@export var lose_radius: float = 18.0
@export var guide_speed: float = 3.8

@onready var path_points: Node3D = $PathPoints
@onready var marker_mesh: MeshInstance3D = $MarkerBeacon
@onready var label_3d: Label3D = $Label3D

var phase: Phase = Phase.WAITING
var _waypoints: Array[Vector3] = []
var _wp_index: int = 0
var _player: Node3D = null
var _follow_started: bool = false
var _warned_distance: bool = false
var _stuck_timer: float = 0.0
var _last_pos: Vector3 = Vector3.ZERO
var _guide_target: Vector3 = Vector3.ZERO
var _guide_label_timer: float = 0.0

func _ready() -> void:
	add_to_group("jesus")
	# Layer 4 self; mask only ground (layer 1). Props stay on layer 2 so Jesus never snags.
	collision_layer = 4
	collision_mask = 1
	safe_margin = 0.12
	floor_snap_length = 0.5
	for child in path_points.get_children():
		if child is Node3D:
			var p: Vector3 = child.global_position
			p.y = 0.15
			_waypoints.append(p)
	_apply_look()
	label_3d.text = "Jesus"
	_last_pos = global_position
	GameState.miracle_phase_started.connect(_on_miracle_phase)
	GameState.encounter_state_changed.connect(_on_encounter_state)
	GameState.update_mission_text("Approach Jesus at the Capernaum shore (yellow beacon).")

func _apply_look() -> void:
	var body := get_node_or_null("Body") as MeshInstance3D
	var head := get_node_or_null("Head") as MeshInstance3D
	var robe := get_node_or_null("Robe") as MeshInstance3D
	if body:
		body.material_override = WorldTextures.mat("robe_cream", Color(0.95, 0.92, 0.82), 0.85)
	if head:
		head.material_override = WorldTextures.mat("skin", Color(0.92, 0.78, 0.62), 0.7)
	if robe:
		robe.material_override = WorldTextures.mat("robe_cream", Color(1.0, 0.97, 0.88), 0.9)
	if marker_mesh:
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color(1.0, 0.85, 0.15)
		bm.emission_enabled = true
		bm.emission = Color(1.0, 0.85, 0.2)
		bm.emission_energy_multiplier = 3.5
		marker_mesh.material_override = bm
		marker_mesh.scale = Vector3(1.4, 1.4, 1.4)

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
		if _player == null:
			return
	var dist := global_position.distance_to(_player.global_position)
	match phase:
		Phase.WAITING:
			_bob_marker(delta)
			velocity = Vector3.ZERO
			_snap_to_floor()
			if dist <= follow_radius:
				_start_follow()
		Phase.WALKING:
			_bob_marker(delta)
			_walk_path(delta)
			_check_follow_distance(dist)
		Phase.ARRIVED:
			velocity = Vector3.ZERO
			_maybe_start_guiding()
		Phase.GUIDING:
			_bob_marker(delta)
			_guide_to_miracle(delta, dist)

func _start_follow() -> void:
	if _follow_started:
		return
	_follow_started = true
	phase = Phase.WALKING
	_wp_index = 0
	_stuck_timer = 0.0
	GameState.update_mission_text("Follow Jesus — stay close along the shore path.")

func _walk_path(delta: float) -> void:
	if _wp_index >= _waypoints.size():
		_finish()
		return
	var target: Vector3 = _waypoints[_wp_index]
	var to_target := target - global_position
	to_target.y = 0.0
	var horiz := to_target.length()
	if horiz < 0.75:
		_wp_index += 1
		_stuck_timer = 0.0
		return
	var moved := global_position.distance_to(_last_pos)
	_last_pos = global_position
	if moved < 0.025:
		_stuck_timer += delta
	else:
		_stuck_timer = 0.0
	if _stuck_timer > 0.85:
		_stuck_timer = 0.0
		if horiz < 4.5:
			global_position = Vector3(target.x, maxf(global_position.y, 0.15), target.z)
			_wp_index += 1
		else:
			var slide := to_target.normalized() * 1.8
			global_position += Vector3(slide.x, 0.0, slide.z)
		_snap_to_floor()
		return
	var dir := to_target.normalized()
	velocity = dir * walk_speed
	velocity.y = 0.0
	if dir.length_squared() > 0.001:
		look_at(global_position + dir, Vector3.UP)
	move_and_slide()
	_snap_to_floor()

func _snap_to_floor() -> void:
	var from := global_position + Vector3(0, 2.5, 0)
	var to := global_position + Vector3(0, -8.0, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		global_position.y = float(hit.position.y)

func _check_follow_distance(dist: float) -> void:
	if dist > lose_radius:
		if not _warned_distance:
			_warned_distance = true
			GameState.update_mission_text("You're falling behind — catch up to Jesus!")
	elif dist <= follow_radius:
		_warned_distance = false

func _finish() -> void:
	phase = Phase.ARRIVED
	velocity = Vector3.ZERO
	if _player and global_position.distance_to(_player.global_position) <= lose_radius:
		GameState.complete_follow_mission()
		marker_mesh.visible = true
		_maybe_start_guiding()
	else:
		GameState.update_mission_text("You lost Him on the path. Approach the beacon to try again.")
		_reset_path()

func _reset_path() -> void:
	phase = Phase.WAITING
	_follow_started = false
	_warned_distance = false
	_wp_index = 0
	_stuck_timer = 0.0
	if _waypoints.size() > 0:
		global_position = _waypoints[0] + Vector3(0, 0, 2)
	marker_mesh.visible = true

func _maybe_start_guiding() -> void:
	var active := GameState.get_active_miracle()
	if active.is_empty() or str(active.get("id", "")) == "follow_me":
		return
	var loc := GameState.get_location(str(active.get("location_id", "")))
	if loc.is_empty():
		return
	var pos: Vector3 = loc.get("pos", Vector3.ZERO)
	_guide_target = Vector3(pos.x, 0.15, pos.z) + Vector3(0, 0, 1.5)
	phase = Phase.GUIDING
	marker_mesh.visible = true
	_update_guide_text(true)

func _guide_to_miracle(delta: float, player_dist: float) -> void:
	var to := _guide_target - global_position
	to.y = 0.0
	var d := to.length()
	_guide_label_timer += delta
	if _guide_label_timer > 2.5:
		_guide_label_timer = 0.0
		_update_guide_text(false)
	if d < 1.25:
		velocity = Vector3.ZERO
		_snap_to_floor()
		label_3d.text = "Jesus — miracle here"
		if _player:
			var face := _player.global_position - global_position
			face.y = 0.0
			if face.length_squared() > 0.01:
				look_at(global_position + face.normalized(), Vector3.UP)
		return
	var dir := to.normalized()
	velocity = dir * guide_speed
	velocity.y = 0.0
	look_at(global_position + dir, Vector3.UP)
	move_and_slide()
	_snap_to_floor()
	if global_position.distance_to(_last_pos) < 0.02:
		_stuck_timer += delta
		if _stuck_timer > 1.0:
			global_position = global_position.lerp(_guide_target, 0.2)
			global_position.y = 0.15
			_stuck_timer = 0.0
	else:
		_stuck_timer = 0.0
	_last_pos = global_position
	if player_dist > lose_radius * 1.2:
		GameState.update_mission_text("Jesus is ahead at the miracle — follow the inland road (yellow beacon).")

func _update_guide_text(_force: bool) -> void:
	var active := GameState.get_active_miracle()
	if active.is_empty():
		return
	var loc := GameState.get_location(str(active.get("location_id", "")))
	var place := str(loc.get("name", active.get("location_id", "")))
	var mname := str(active.get("name", "Miracle"))
	var dist_m := 0.0
	if _player:
		dist_m = _player.global_position.distance_to(_guide_target)
	var dir_hint := _cardinal_hint(_guide_target - (_player.global_position if _player else global_position))
	GameState.update_mission_text("[%s] Jesus awaits in %s — go %s (%.0fm). Big yellow/blue beacon marks the site." % [mname, place, dir_hint, dist_m])

func _cardinal_hint(v: Vector3) -> String:
	v.y = 0.0
	if v.length_squared() < 0.01:
		return "nearby"
	var deg := rad_to_deg(atan2(v.x, -v.z))
	if deg < 0.0:
		deg += 360.0
	if deg >= 315.0 or deg < 45.0:
		return "north / inland"
	if deg < 135.0:
		return "east"
	if deg < 225.0:
		return "south"
	return "west / inland"

func _on_miracle_phase(_mid: String) -> void:
	if phase == Phase.ARRIVED or phase == Phase.GUIDING:
		_maybe_start_guiding()

func _on_encounter_state(miracle_id: String, new_state: String) -> void:
	if new_state in ["clues", "puzzle", "miracle"] and miracle_id != "follow_me":
		if phase == Phase.ARRIVED or phase == Phase.GUIDING or (_follow_started and phase != Phase.WALKING):
			_maybe_start_guiding()

func _bob_marker(delta: float) -> void:
	if marker_mesh == null:
		return
	marker_mesh.rotation.y += delta * 1.6
	marker_mesh.position.y = 2.8 + sin(Time.get_ticks_msec() * 0.004) * 0.2
	var s := 1.6 if phase == Phase.GUIDING or phase == Phase.WAITING else 1.25
	marker_mesh.scale = Vector3.ONE * s
