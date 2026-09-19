extends Node3D
class_name MiracleEncounterCore
## Reusable MiracleEncounter — clue -> puzzle -> miracle -> done with cinematic set-pieces.

const INTERACT_RADIUS: float = 5.5
const CLUE_NEAR_RADIUS: float = 14.0
const FILL_JAR_COUNT: int = 6
const WATCH_LEAVE_MULT: float = 1.8

@onready var beacon: MeshInstance3D = $Beacon
@onready var label_3d: Label3D = $Label3D

var _player: Node3D = null
var _player_in_range: bool = false
var _active_id: String = ""
var _clue_timer: float = 0.0
var _watch_elapsed: float = 0.0
var _watch_required: float = 12.0
var _jars_filled: int = 0
var _jar_nodes: Array = []
var _fx_node: Node3D = null
var _stage_node: Node3D = null
var _prompt_shown: bool = false
var _world_env: WorldEnvironment = null
var _sun: DirectionalLight3D = null
var _saved_bg: Color = Color(0.55, 0.7, 0.85, 1)
var _saved_ambient: Color = Color(0.9, 0.85, 0.7, 1)
var _saved_sun_energy: float = 1.15
var _lighting_mode: String = "day"
var _storm_active: bool = false
var _transfig_hold: float = 0.0
var _nets_participated: bool = false
var _level1_banner_shown: bool = false

signal request_puzzle_ui(miracle_id: String, puzzle: Dictionary)
signal request_clue_ui(miracle_id: String, clues: PackedStringArray)
signal request_interact_hint(text: String)
signal clear_interact_hint()
signal fill_jars_progress(filled: int, total: int)
signal watch_progress(elapsed: float, required: float)
signal sleep_warning(text: String)
signal clear_sleep_warning()
signal level1_complete()

func _ready() -> void:
	add_to_group("miracle_encounter")
	beacon.visible = false
	label_3d.visible = false
	GameState.encounter_state_changed.connect(_on_state_changed)
	GameState.mission_completed.connect(_on_mission_completed)
	GameState.puzzle_opened.connect(_on_puzzle_opened)
	GameState.miracle_phase_started.connect(_on_miracle_phase)
	call_deferred("_cache_world")
	_refresh_from_state()

func _cache_world() -> void:
	_world_env = get_tree().current_scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
	_sun = get_tree().current_scene.get_node_or_null("Sun") as DirectionalLight3D
	if _world_env and _world_env.environment:
		_saved_bg = _world_env.environment.background_color
		_saved_ambient = _world_env.environment.ambient_light_color
	if _sun:
		_saved_sun_energy = _sun.light_energy

func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node3D
		return
	var active := GameState.get_active_miracle()
	if active.is_empty():
		_hide_beacon()
		_restore_day_if_needed()
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
	_update_setpiece_ambience(delta, mid, state, dist)

func _setup_for_miracle(m: Dictionary) -> void:
	_active_id = str(m.get("id", ""))
	_clue_timer = 0.0
	_watch_elapsed = 0.0
	_jars_filled = 0
	_prompt_shown = false
	_nets_participated = false
	_transfig_hold = 0.0
	_clear_jars()
	_clear_fx()
	_clear_stage()
	_restore_day_if_needed()
	var loc: Dictionary = GameState.get_location(str(m.get("location_id", "")))
	var pos: Vector3 = loc.get("pos", Vector3.ZERO)
	global_position = pos + Vector3(0, 0, 2.5)
	beacon.visible = true
	label_3d.visible = true
	label_3d.text = str(m.get("name", "Miracle"))
	_tint_beacon(str(m.get("state", "clues")), bool(m.get("is_major_beat", false)))
	_build_stage(_active_id)

func _build_stage(mid: String) -> void:
	_stage_node = Node3D.new()
	_stage_node.name = "SetPieceStage"
	add_child(_stage_node)
	match mid:
		"water_to_wine":
			MiracleSetpieces.stage_cana_wedding(_stage_node)
			_jar_nodes = MiracleSetpieces.spawn_waterpots(self, FILL_JAR_COUNT)
		"nets_overflow":
			MiracleSetpieces.stage_boat_dock(_stage_node)
		"calm_the_storm":
			MiracleSetpieces.stage_boat_simple(_stage_node)
		"loaves_and_fish":
			MiracleSetpieces.stage_crowd(_stage_node)
		"transfiguration":
			MiracleSetpieces.stage_tabor_cloud(_stage_node)
		"gethsemane":
			MiracleSetpieces.stage_garden_night(_stage_node)
			_set_lighting("night")
		"crucifixion":
			MiracleSetpieces.stage_golgotha_path(_stage_node)
			_set_lighting("solemn")

func _set_lighting(mode: String) -> void:
	_lighting_mode = mode
	if _world_env == null or _world_env.environment == null:
		_cache_world()
	if _world_env == null or _world_env.environment == null:
		return
	var env := _world_env.environment
	match mode:
		"night":
			env.background_color = Color(0.08, 0.1, 0.18)
			env.ambient_light_color = Color(0.25, 0.3, 0.4)
			env.ambient_light_energy = 0.35
			if _sun:
				_sun.light_energy = 0.25
				_sun.light_color = Color(0.55, 0.6, 0.8)
		"storm":
			env.background_color = Color(0.2, 0.22, 0.28)
			env.ambient_light_color = Color(0.4, 0.42, 0.5)
			env.ambient_light_energy = 0.4
			if _sun:
				_sun.light_energy = 0.35
				_sun.light_color = Color(0.7, 0.75, 0.85)
		"solemn":
			env.background_color = Color(0.35, 0.32, 0.38)
			env.ambient_light_color = Color(0.55, 0.5, 0.48)
			env.ambient_light_energy = 0.45
			if _sun:
				_sun.light_energy = 0.55
				_sun.light_color = Color(0.9, 0.75, 0.65)
		"glory":
			env.background_color = Color(0.75, 0.8, 0.95)
			env.ambient_light_color = Color(1.0, 0.95, 0.8)
			env.ambient_light_energy = 0.9
			if _sun:
				_sun.light_energy = 1.6
				_sun.light_color = Color(1.0, 0.95, 0.8)
		_:
			_restore_day()

func _restore_day() -> void:
	_lighting_mode = "day"
	_storm_active = false
	if _world_env and _world_env.environment:
		_world_env.environment.background_color = _saved_bg
		_world_env.environment.ambient_light_color = _saved_ambient
		_world_env.environment.ambient_light_energy = 0.55
	if _sun:
		_sun.light_energy = _saved_sun_energy
		_sun.light_color = Color(1, 0.95, 0.85)

func _restore_day_if_needed() -> void:
	if _lighting_mode != "day":
		_restore_day()

func _update_setpiece_ambience(delta: float, mid: String, state: String, dist: float) -> void:
	if mid == "calm_the_storm" and state in ["clues", "puzzle", "miracle"]:
		if dist < 28.0 and not _storm_active:
			_storm_active = true
			_set_lighting("storm")
			_ensure_fx()
			MiracleSetpieces.spawn_wind(_fx_node)
	if mid == "transfiguration" and state == "miracle":
		_transfig_hold += delta
		_set_lighting("glory")
	if mid == "gethsemane" and state in ["puzzle", "miracle"]:
		if _lighting_mode != "night":
			_set_lighting("night")

func _ensure_fx() -> void:
	if _fx_node == null or not is_instance_valid(_fx_node):
		_fx_node = Node3D.new()
		_fx_node.name = "MiracleFX"
		add_child(_fx_node)
