extends Node
## AudioManager — soft Christian-elevator ambient bed that builds toward miracles.
## Original audio only (no copyrighted hymns). Prefer OGG under assets/audio/;
## falls back to .ogg.b64 companions, then procedural AudioStreamGenerator pad.

const BED_OGG := "res://assets/audio/ambient_bed.ogg"
const SWELL_OGG := "res://assets/audio/ambient_swell.ogg"
const BED_B64 := "res://assets/audio/ambient_bed.ogg.b64"
const SWELL_B64 := "res://assets/audio/ambient_swell.ogg.b64"

const NEAR_START := 42.0
const NEAR_PEAK := 8.0
const BED_BASE_DB := -18.0
const BED_NEAR_DB := -10.0
const SWELL_BASE_DB := -80.0
const SWELL_NEAR_DB := -14.0
const SWELL_PEAK_DB := -8.0
const DUCK_DB := -28.0
const DUCK_SECONDS := 12.0

var _bed: AudioStreamPlayer
var _swell: AudioStreamPlayer
var _player: Node3D = null
var _intensity: float = 0.0
var _target_intensity: float = 0.0
var _duck_left: float = 0.0
var _scripture_peak: bool = false
var _using_procedural: bool = false
var _proc_bed: AudioStreamGeneratorPlayback = null
var _proc_swell: AudioStreamGeneratorPlayback = null
var _proc_phase: float = 0.0

func _ready() -> void:
	_bed = AudioStreamPlayer.new()
	_bed.name = "AmbientBed"
	_bed.bus = "Master"
	_bed.volume_db = BED_BASE_DB
	add_child(_bed)
	_swell = AudioStreamPlayer.new()
	_swell.name = "AmbientSwell"
	_swell.bus = "Master"
	_swell.volume_db = SWELL_BASE_DB
	add_child(_swell)
	_load_streams()
	if GameState.has_signal("scripture_presented"):
		GameState.scripture_presented.connect(_on_scripture)
	if GameState.has_signal("encounter_state_changed"):
		GameState.encounter_state_changed.connect(_on_encounter_state)
	if GameState.has_signal("miracle_phase_started"):
		GameState.miracle_phase_started.connect(_on_miracle_phase)
	_bed.play()
	_swell.play()

func _load_streams() -> void:
	var bed_stream := _try_load_ogg(BED_OGG, BED_B64)
	var swell_stream := _try_load_ogg(SWELL_OGG, SWELL_B64)
	if bed_stream and swell_stream:
		_bed.stream = bed_stream
		_swell.stream = swell_stream
		_using_procedural = false
		return
	_using_procedural = true
	_bed.stream = _make_generator()
	_swell.stream = _make_generator()

func _try_load_ogg(ogg_path: String, b64_path: String) -> AudioStream:
	if ResourceLoader.exists(ogg_path):
		var res = load(ogg_path)
		if res is AudioStream:
			return res
	if FileAccess.file_exists(b64_path):
		var f := FileAccess.open(b64_path, FileAccess.READ)
		if f:
			var b64 := f.get_as_text().strip_edges()
			var bytes := Marshalls.base64_to_raw(b64)
			if bytes.size() > 64 and AudioStreamOggVorbis.has_method("load_from_buffer"):
				var stream = AudioStreamOggVorbis.load_from_buffer(bytes)
				if stream:
					stream.loop = true
					return stream
	return null

func _make_generator() -> AudioStreamGenerator:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.5
	return gen

func _process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node3D
	_update_intensity_target()
	_intensity = lerpf(_intensity, _target_intensity, 1.0 - exp(-delta * 1.6))
	if _duck_left > 0.0:
		_duck_left = maxf(0.0, _duck_left - delta)
	var duck := 1.0
	if _duck_left > 0.0:
		duck = 0.35
	var bed_db := lerpf(BED_BASE_DB, BED_NEAR_DB, _intensity)
	var swell_db := lerpf(SWELL_BASE_DB, SWELL_NEAR_DB, clampf(_intensity * 1.15, 0.0, 1.0))
	if _scripture_peak or _intensity > 0.92:
		swell_db = lerpf(swell_db, SWELL_PEAK_DB, clampf((_intensity - 0.85) / 0.15, 0.0, 1.0))
	_bed.pitch_scale = lerpf(1.0, 1.04, _intensity)
	_swell.pitch_scale = lerpf(1.0, 1.06, _intensity)
	_bed.volume_db = bed_db + (DUCK_DB - bed_db) * (1.0 - duck) * 0.55
	_swell.volume_db = swell_db + (DUCK_DB - swell_db) * (1.0 - duck) * 0.7
	if not _bed.playing:
		_bed.play()
	if not _swell.playing:
		_swell.play()
	if _using_procedural:
		_fill_procedural()

func _update_intensity_target() -> void:
	_target_intensity = 0.0
	_scripture_peak = false
	var active := GameState.get_active_miracle()
	if active.is_empty():
		return
	var mid: String = str(active.get("id", ""))
	if mid == "follow_me":
		var jesus := get_tree().get_first_node_in_group("jesus") as Node3D
		if jesus and _player:
			var d := _player.global_position.distance_to(jesus.global_position)
			_target_intensity = _dist_to_intensity(d) * 0.45
		return
	var loc: Dictionary = GameState.get_location(str(active.get("location_id", "")))
	var pos: Vector3 = loc.get("pos", Vector3.ZERO)
	if _player == null:
		return
	var dist := _player.global_position.distance_to(pos)
	var state: String = str(active.get("state", "locked"))
	var base := _dist_to_intensity(dist)
	match state:
		"clues":
			_target_intensity = base * 0.55
		"puzzle":
			_target_intensity = base * 0.75
		"miracle":
			_target_intensity = maxf(base, 0.85)
			_scripture_peak = base > 0.5
		_:
			_target_intensity = base * 0.3

func _dist_to_intensity(dist: float) -> float:
	if dist >= NEAR_START:
		return 0.0
	if dist <= NEAR_PEAK:
		return 1.0
	return 1.0 - (dist - NEAR_PEAK) / (NEAR_START - NEAR_PEAK)

func _on_scripture(_ref: String, _quote: String) -> void:
	_duck_left = DUCK_SECONDS
	_scripture_peak = true
	_target_intensity = 1.0
	_intensity = maxf(_intensity, 0.95)

func _on_encounter_state(_miracle_id: String, new_state: String) -> void:
	if new_state == "miracle":
		_target_intensity = maxf(_target_intensity, 0.9)
	elif new_state == "done":
		_target_intensity = 0.2
		_scripture_peak = false

func _on_miracle_phase(_miracle_id: String) -> void:
	_target_intensity = 1.0

func _fill_procedural() -> void:
	if _proc_bed == null and _bed.get_stream_playback():
		_proc_bed = _bed.get_stream_playback() as AudioStreamGeneratorPlayback
	if _proc_swell == null and _swell.get_stream_playback():
		_proc_swell = _swell.get_stream_playback() as AudioStreamGeneratorPlayback
	var frames := 0
	if _proc_bed:
		frames = maxi(frames, _proc_bed.get_frames_available())
	if _proc_swell:
		frames = maxi(frames, _proc_swell.get_frames_available())
	if frames <= 0:
		return
	var chords := [
		[130.81, 164.81, 196.00, 261.63],
		[174.61, 220.00, 261.63, 349.23],
		[196.00, 246.94, 293.66, 392.00],
		[130.81, 164.81, 196.00, 261.63],
	]
	var beat := 60.0 / 42.0
	var rate := 22050.0
	var bed_frames := _proc_bed.get_frames_available() if _proc_bed else 0
	var swell_frames := _proc_swell.get_frames_available() if _proc_swell else 0
	var n := maxi(bed_frames, swell_frames)
	for i in range(n):
		var t := _proc_phase / rate
		var ci := int(floor(t / (beat * 4.0))) % 4
		var freqs: Array = chords[ci]
		var sample := 0.0
		for f in freqs:
			var ff: float = float(f)
			sample += sin(TAU * ff * t) * 0.07
			sample += sin(TAU * ff * 1.5 * t) * 0.025
		var bed_s := tanh(sample * (0.55 + 0.15 * _intensity))
		var swell_s := bed_s
		swell_s += sin(TAU * 523.25 * t) * 0.03 * (0.4 + 0.6 * _intensity)
		swell_s += sin(TAU * 659.25 * t) * 0.02 * _intensity
		swell_s = tanh(swell_s)
		if _proc_bed and i < bed_frames:
			_proc_bed.push_frame(Vector2(bed_s, bed_s))
		if _proc_swell and i < swell_frames:
			_proc_swell.push_frame(Vector2(swell_s, swell_s))
		_proc_phase += 1.0
