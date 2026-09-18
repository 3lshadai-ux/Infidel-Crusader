extends Node3D
## Reusable MiracleEncounter - clue -> puzzle -> miracle -> done (post follow_me).

const INTERACT_RADIUS: float = 5.5
const CLUE_NEAR_RADIUS: float = 14.0
const FILL_JAR_COUNT: int = 6

@onready var beacon: MeshInstance3D = $Beacon
@onready var label_3d: Label3D = $Label3D

var _player: Node3D = null
var _player_in_range: bool = false
var _active_id: String = ""
var _clue_timer: float = 0.0
var _watch_elapsed: float = 0.0
var _watch_required: float = 12.0
var _jars_filled: int = 0
var _jar_nodes: Array[Node3D] = []
var _fx_node: Node3D = null
var _prompt_shown: bool = false

signal request_puzzle_ui(miracle_id: String, puzzle: Dictionary)
signal request_clue_ui(miracle_id: String, clues: PackedStringArray)
signal request_interact_hint(text: String)
signal clear_interact_hint()
signal fill_jars_progress(filled: int, total: int)
signal watch_progress(elapsed: float, required: float)

func _ready() -> void:
	add_to_group("miracle_encounter")
	beacon.visible = false
	label_3d.visible = false
	GameState.encounter_state_changed.connect(_on_state_changed)
	GameState.mission_completed.connect(_on_mission_completed)
	GameState.puzzle_opened.connect(_on_puzzle_opened)
	GameState.miracle_phase_started.connect(_on_miracle_phase)
	_refresh_from_state()

func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node3D
		return
	var active := GameState.get_active_miracle()
	if active.is_empty():
		_hide_beacon()
		return
	var mid: String = str(active.get("id", ""))
	if mid == "follow_me":
		_hide_beacon()
		return
	if mid != _active_id:
		_setup_for_miracle(active)
	var state: String = str(active.get("state", "locked"))
	var dist := global_position.distance_to(_player.global_position)
	_player_in_range = dist <= INTERACT_RADIUS
	match state:
		"clues":
			_process_clues(delta, dist, mid)
		"puzzle":
			_process_puzzle(delta, dist, active)
		"miracle":
			_process_miracle(delta, dist, mid)
	_bob_beacon(delta)

func _setup_for_miracle(m: Dictionary) -> void:
	_active_id = str(m.get("id", ""))
	_clue_timer = 0.0
	_watch_elapsed = 0.0
	_jars_filled = 0
	_prompt_shown = false
	_clear_jars()
	_clear_fx()
	var loc: Dictionary = GameState.get_location(str(m.get("location_id", "")))
	var pos: Vector3 = loc.get("pos", Vector3.ZERO)
	global_position = pos + Vector3(0, 0, 2.5)
	beacon.visible = true
	label_3d.visible = true
	label_3d.text = str(m.get("name", "Miracle"))
	_tint_beacon(str(m.get("state", "clues")), bool(m.get("is_major_beat", false)))
	if _active_id == "water_to_wine":
		_spawn_waterpots()

func _process_clues(delta: float, dist: float, mid: String) -> void:
	if dist > CLUE_NEAR_RADIUS:
		clear_interact_hint.emit()
		_prompt_shown = false
		return
	_clue_timer += delta
	if not _prompt_shown:
		_prompt_shown = true
		GameState.reveal_next_clue(mid)
		request_clue_ui.emit(mid, GameState.get_revealed_clues(mid))
		request_interact_hint.emit("Press E / Interact - next clue (or wait)")
	elif _player_in_range and (Input.is_action_just_pressed("interact") or _clue_timer > 8.0):
		_clue_timer = 0.0
		var before_state := str(GameState.get_miracle(mid).get("state", ""))
		GameState.reveal_next_clue(mid)
		request_clue_ui.emit(mid, GameState.get_revealed_clues(mid))
		if str(GameState.get_miracle(mid).get("state", "")) != before_state:
			_prompt_shown = false
			clear_interact_hint.emit()

func _process_puzzle(delta: float, dist: float, m: Dictionary) -> void:
	var mid: String = str(m.get("id", ""))
	var puzzle: Dictionary = m.get("puzzle", {})
	var ptype: String = str(puzzle.get("type", "riddle"))
	if not _player_in_range:
		if _prompt_shown and ptype != "keep_watch":
			clear_interact_hint.emit()
			_prompt_shown = false
		if ptype == "keep_watch" and _watch_elapsed > 0.0 and dist > INTERACT_RADIUS * 1.8:
			_watch_elapsed = 0.0
			request_interact_hint.emit("You drifted away - return and keep watch.")
		return
	match ptype:
		"riddle":
			if mid == "water_to_wine" and _jar_nodes.size() > 0:
				if not _prompt_shown:
					_prompt_shown = true
					request_puzzle_ui.emit(mid, puzzle)
				request_interact_hint.emit("Answer the riddle (UI) OR fill jars with E (%d/%d)" % [_jars_filled, FILL_JAR_COUNT])
				if Input.is_action_just_pressed("interact"):
					_try_fill_nearest_jar(mid)
			else:
				if not _prompt_shown:
					_prompt_shown = true
					request_puzzle_ui.emit(mid, puzzle)
					request_interact_hint.emit("Solve the puzzle (UI) - or press E to reopen")
				elif Input.is_action_just_pressed("interact"):
					request_puzzle_ui.emit(mid, puzzle)
		"arrive":
			request_interact_hint.emit("You have arrived - press E to proceed")
			_prompt_shown = true
			if Input.is_action_just_pressed("interact"):
				GameState.complete_puzzle(mid)
				clear_interact_hint.emit()
		"keep_watch":
			_watch_required = float(puzzle.get("duration", 12.0))
			_watch_elapsed += delta
			watch_progress.emit(_watch_elapsed, _watch_required)
			request_interact_hint.emit("Keep watch... %.0f / %.0f s" % [_watch_elapsed, _watch_required])
			_prompt_shown = true
			if _watch_elapsed >= _watch_required:
				GameState.complete_puzzle(mid)
				clear_interact_hint.emit()
				_watch_elapsed = 0.0
		"fill_jars":
			_process_fill_jars()
		_:
			if Input.is_action_just_pressed("interact"):
				request_puzzle_ui.emit(mid, puzzle)

func _try_fill_nearest_jar(mid: String) -> void:
	var best: Node3D = null
	var best_d := 3.0
	for j in _jar_nodes:
		if j.has_meta("filled") and j.get_meta("filled"):
			continue
		var d: float = j.global_position.distance_to(_player.global_position)
		if d < best_d:
			best_d = d
			best = j
	if best:
		best.set_meta("filled", true)
		_jars_filled += 1
		_paint_jar_filled(best)
		fill_jars_progress.emit(_jars_filled, FILL_JAR_COUNT)
		if _jars_filled >= FILL_JAR_COUNT:
			GameState.complete_puzzle(mid)
			clear_interact_hint.emit()
	else:
		request_puzzle_ui.emit(mid, GameState.get_miracle(mid).get("puzzle", {}))

func _process_fill_jars() -> void:
	request_interact_hint.emit("Fill the waterpots - walk to each jar and press E (%d/%d)" % [_jars_filled, FILL_JAR_COUNT])
	_prompt_shown = true
	if Input.is_action_just_pressed("interact"):
		_try_fill_nearest_jar(_active_id)

func _process_miracle(_delta: float, dist: float, mid: String) -> void:
	if dist > INTERACT_RADIUS:
		clear_interact_hint.emit()
		_prompt_shown = false
		return
	if not _prompt_shown:
		_prompt_shown = true
		_play_miracle_fx(mid)
	request_interact_hint.emit("Press E / Interact - witness the miracle")
	if Input.is_action_just_pressed("interact"):
		clear_interact_hint.emit()
		GameState.participate_miracle(mid)

func submit_answer(miracle_id: String, answer: String) -> bool:
	var ok := GameState.submit_puzzle_answer(miracle_id, answer)
	if ok:
		clear_interact_hint.emit()
		_prompt_shown = false
	return ok

func _on_state_changed(miracle_id: String, new_state: String) -> void:
	if miracle_id == _active_id or _active_id.is_empty():
		_tint_beacon(new_state, false)
		_prompt_shown = false
		if new_state == "miracle":
			_play_miracle_fx(miracle_id)

func _on_puzzle_opened(miracle_id: String, puzzle: Dictionary) -> void:
	if miracle_id == _active_id:
		request_puzzle_ui.emit(miracle_id, puzzle)

func _on_miracle_phase(miracle_id: String) -> void:
	if miracle_id == _active_id:
		_play_miracle_fx(miracle_id)

func _on_mission_completed(_title: String, _reward: int) -> void:
	_clear_fx()
	_refresh_from_state()

func _refresh_from_state() -> void:
	var active := GameState.get_active_miracle()
	if active.is_empty() or str(active.get("id", "")) == "follow_me":
		_hide_beacon()
		_active_id = ""
		return
	_setup_for_miracle(active)

func _hide_beacon() -> void:
	beacon.visible = false
	label_3d.visible = false
	clear_interact_hint.emit()

func _tint_beacon(state: String, is_major: bool) -> void:
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	match state:
		"clues":
			mat.albedo_color = Color(0.4, 0.7, 1.0)
			mat.emission = Color(0.3, 0.6, 1.0)
		"puzzle":
			mat.albedo_color = Color(1.0, 0.7, 0.2)
			mat.emission = Color(1.0, 0.65, 0.15)
		"miracle":
			mat.albedo_color = Color(0.95, 0.9, 0.4)
			mat.emission = Color(1.0, 0.9, 0.3)
		_:
			mat.albedo_color = Color(0.6, 0.6, 0.6)
			mat.emission = Color(0.4, 0.4, 0.4)
	mat.emission_energy_multiplier = 2.2 if is_major else 1.6
	beacon.material_override = mat

func _bob_beacon(delta: float) -> void:
	if beacon and beacon.visible:
		beacon.rotation.y += delta * 1.2
		beacon.position.y = 2.6 + sin(Time.get_ticks_msec() * 0.004) * 0.18

func _spawn_waterpots() -> void:
	_clear_jars()
	for i in range(FILL_JAR_COUNT):
		var jar := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.35
		cyl.bottom_radius = 0.4
		cyl.height = 0.9
		jar.mesh = cyl
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.55, 0.5, 0.42)
		jar.material_override = mat
		var angle := TAU * float(i) / float(FILL_JAR_COUNT)
		jar.position = Vector3(cos(angle) * 3.2, 0.45, sin(angle) * 3.2)
		jar.set_meta("filled", false)
		add_child(jar)
		_jar_nodes.append(jar)
		var lbl := Label3D.new()
		lbl.text = "Jar %d" % (i + 1)
		lbl.font_size = 28
		lbl.position = Vector3(0, 0.7, 0)
		jar.add_child(lbl)

func _paint_jar_filled(jar: Node3D) -> void:
	if jar is MeshInstance3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.45, 0.25, 0.55)
		mat.emission_enabled = true
		mat.emission = Color(0.5, 0.2, 0.6)
		mat.emission_energy_multiplier = 0.8
		(jar as MeshInstance3D).material_override = mat

func _clear_jars() -> void:
	for j in _jar_nodes:
		if is_instance_valid(j):
			j.queue_free()
	_jar_nodes.clear()
	_jars_filled = 0

func _play_miracle_fx(mid: String) -> void:
	_clear_fx()
	_fx_node = Node3D.new()
	_fx_node.name = "MiracleFX"
	add_child(_fx_node)
	match mid:
		"water_to_wine":
			_fx_wine()
		"nets_overflow":
			_fx_simple(Color(0.3, 0.55, 0.9))
		"calm_the_storm":
			_fx_simple(Color(0.7, 0.85, 1.0))
		"loaves_and_fish":
			_fx_simple(Color(0.9, 0.75, 0.35))
		"transfiguration":
			_fx_transfiguration()
		"gethsemane":
			_fx_simple(Color(0.4, 0.55, 0.35))
		"crucifixion":
			_fx_crucifixion()
		_:
			_fx_simple(Color(1.0, 0.9, 0.5))

func _fx_wine() -> void:
	for jar in _jar_nodes:
		_paint_jar_filled(jar)
	_fx_simple(Color(0.55, 0.15, 0.45))

func _fx_transfiguration() -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.95, 0.7)
	light.light_energy = 8.0
	light.omni_range = 18.0
	light.position = Vector3(0, 4, 0)
	_fx_node.add_child(light)
	var sphere := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.2
	sm.height = 2.4
	sphere.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.95, 0.7, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.95, 0.6)
	mat.emission_energy_multiplier = 4.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere.material_override = mat
	sphere.position = Vector3(0, 3.5, 0)
	_fx_node.add_child(sphere)

func _fx_crucifixion() -> void:
	var beam := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.35, 6.0, 0.35)
	beam.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.25, 0.18)
	beam.material_override = mat
	beam.position = Vector3(0, 3.0, 0)
	_fx_node.add_child(beam)
	var cross := MeshInstance3D.new()
	var box2 := BoxMesh.new()
	box2.size = Vector3(2.4, 0.3, 0.3)
	cross.mesh = box2
	cross.material_override = mat
	cross.position = Vector3(0, 4.5, 0)
	_fx_node.add_child(cross)
	var light := OmniLight3D.new()
	light.light_color = Color(0.9, 0.7, 0.5)
	light.light_energy = 3.0
	light.omni_range = 14.0
	light.position = Vector3(0, 5, 0)
	_fx_node.add_child(light)

func _fx_simple(color: Color) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 5.0
	light.omni_range = 12.0
	light.position = Vector3(0, 3, 0)
	_fx_node.add_child(light)

func _clear_fx() -> void:
	if _fx_node and is_instance_valid(_fx_node):
		_fx_node.queue_free()
	_fx_node = null

func try_interact() -> void:
	if _player == null:
		return
	var active := GameState.get_active_miracle()
	if active.is_empty():
		return
	var mid: String = str(active.get("id", ""))
	if mid == "follow_me":
		return
	if global_position.distance_to(_player.global_position) > INTERACT_RADIUS * 1.2:
		return
	var state: String = str(active.get("state", ""))
	match state:
		"clues":
			GameState.reveal_next_clue(mid)
			request_clue_ui.emit(mid, GameState.get_revealed_clues(mid))
		"puzzle":
			var puzzle: Dictionary = active.get("puzzle", {})
			var ptype: String = str(puzzle.get("type", "riddle"))
			if ptype == "riddle":
				if mid == "water_to_wine":
					_try_fill_nearest_jar(mid)
				else:
					request_puzzle_ui.emit(mid, puzzle)
			elif ptype == "arrive":
				GameState.complete_puzzle(mid)
			elif ptype == "fill_jars":
				_process_fill_jars()
		"miracle":
			GameState.participate_miracle(mid)
