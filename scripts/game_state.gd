extends Node
## Autoload GameState — Infidel Crusader Level 1.
## Miracle states: locked → clues → puzzle → miracle → done

signal cash_changed(amount: int)
signal status_changed(new_status: String)
signal level_changed(level: int)
signal miracles_changed(completed: int, total: int)
signal mission_updated(text: String)
signal mission_completed(title: String, reward: int)
signal level_up(new_level: int, title: String)
signal scripture_presented(reference: String, quote: String)
signal major_beat_presented(beat_id: String, beat_name: String)
signal clue_revealed(miracle_id: String, clue_index: int, clue_text: String)
signal puzzle_opened(miracle_id: String, puzzle: Dictionary)
signal miracle_phase_started(miracle_id: String)
signal encounter_state_changed(miracle_id: String, new_state: String)
signal journal_changed()

var cash: int = 0
var player_level: int = 0
var player_status: String = "Fishmonger"
var miracles_completed: int = 0
var mission_active: bool = true
var mission_complete: bool = false

const FOLLOW_REWARD: int = 50
const MIRACLE_REWARD: int = 75
const MAJOR_BEAT_REWARD: int = 100

var map_locations: Dictionary = {
	"galilee_shore": {"name": "Sea of Galilee (shore)", "pos": Vector3(-6, 0, -8), "detail": "v0"},
	"capernaum": {"name": "Capernaum", "pos": Vector3(8, 0, 4), "detail": "v0"},
	"bethsaida": {"name": "Bethsaida", "pos": Vector3(18, 0, -4), "detail": "v0"},
	"cana": {"name": "Cana", "pos": Vector3(-18, 0, 10), "detail": "v0"},
	"nazareth": {"name": "Nazareth area", "pos": Vector3(-24, 0, 16), "detail": "v0"},
	"tabor": {"name": "Mount of Transfiguration", "pos": Vector3(-12, 2.5, 18), "detail": "v0"},
	"samaria_road": {"name": "Road through Samaria", "pos": Vector3(-2, 0, 24), "detail": "v0"},
	"bethany": {"name": "Bethany", "pos": Vector3(8, 0, 30), "detail": "v0"},
	"jerusalem": {"name": "Jerusalem", "pos": Vector3(4, 0, 36), "detail": "v0"},
	"olives_gethsemane": {"name": "Mount of Olives / Gethsemane", "pos": Vector3(12, 0, 34), "detail": "v0"},
	"golgotha": {"name": "Golgotha", "pos": Vector3(0, 0, 42), "detail": "v0"},
}

var miracles: Array[Dictionary] = []

func _ready() -> void:
	_init_miracles()
	_emit_progress()
	mission_updated.emit(_current_clue())
	journal_changed.emit()

func _init_miracles() -> void:
	miracles = [
		_m("follow_me", "Follow Me", "galilee_shore", PackedStringArray(["Find Jesus at the Capernaum fish market / Galilee shore.", "Stay close as He walks the shore path."]), {}, "Disciple", "Matthew 4:19 (KJV)", "And he saith unto them, Follow me, and I will make you fishers of men.", false, true, "clues"),
		_m("water_to_wine", "Water to Wine", "cana", PackedStringArray(["Servants whisper of empty jars at a wedding feast in Cana.", "Six stone waterpots stand by the door — the Teacher will speak of filling them.", "When He commands, draw out and bear unto the governor of the feast."]), {"type": "riddle", "prompt": "According to the Gospel of John, how many stone waterpots stood there for the purifying of the Jews? (Enter a number.)", "solution": "6", "hint": "John 2:6 — there were set there six waterpots of stone."}, "Witness", "John 2:7–9 (KJV)", "Jesus saith unto them, Fill the waterpots with water. And they filled them up to the brim. And he saith unto them, Draw out now, and bear unto the governor of the feast. And they bare it. When the ruler of the feast had tasted the water that was made wine, and knew not whence it was: (but the servants which drew the water knew;)", false, false, "locked"),
		_m("nets_overflow", "Nets Overflow", "bethsaida", PackedStringArray(["Return toward Bethsaida / the docks — the Teacher spoke of a catch.", "At His word, let down the net even after a fruitless night."]), {"type": "riddle", "prompt": "Simon answered: Master, we have toiled all the night, and have taken ______: nevertheless at thy word I will let down the net. (one word)", "solution": "nothing", "hint": "Luke 5:5 — taken nothing."}, "Disciple", "Luke 5:5–6 (KJV)", "And Simon answering said unto him, Master, we have toiled all the night, and have taken nothing: nevertheless at thy word I will let down the net. And when they had this done, they inclosed a great multitude of fishes: and their net brake.", false, false, "locked"),
		_m("calm_the_storm", "Calm the Storm", "galilee_shore", PackedStringArray(["Return to the Galilee shore when the sky grows restless.", "Stay near the boat — He will arise and rebuke the wind."]), {"type": "riddle", "prompt": "What two words did Jesus say unto the sea? (Mark 4:39)", "solution": "peace be still", "hint": "Peace, be still."}, "Witness", "Mark 4:39 (KJV)", "And he arose, and rebuked the wind, and said unto the sea, Peace, be still. And the wind ceased, and there was a great calm.", false, false, "locked"),
		_m("loaves_and_fish", "Loaves and Fish", "bethsaida", PackedStringArray(["Near Bethsaida a hillside crowd grows hungry.", "Bring what little you have — five loaves and two fishes."]), {"type": "riddle", "prompt": "How many loaves and how many fishes were blessed? Answer like: 5 and 2", "solution": "5 and 2", "hint": "Matthew 14:19 — five loaves, and the two fishes."}, "Apostle", "Matthew 14:19–20 (KJV)", "And he commanded the multitude to sit down on the grass, and took the five loaves, and the two fishes, and looking up to heaven, he blessed, and brake, and gave the loaves to his disciples, and the disciples to the multitude. And they did all eat, and were filled: and they took up of the fragments that remained twelve baskets full.", false, false, "locked"),
		_m("transfiguration", "The Transfiguration", "tabor", PackedStringArray(["MAJOR: Climb the Mount of Transfiguration.", "Witness the bright cloud and hear the voice from heaven."]), {"type": "arrive", "prompt": "Climb to the summit marker.", "solution": "arrive", "hint": "Stand on the mountaintop pad."}, "Apostle", "Matthew 17:5 (KJV)", "While he yet spake, behold, a bright cloud overshadowed them: and behold a voice out of the cloud, which said, This is my beloved Son, in whom I am well pleased; hear ye him.", true, false, "locked"),
		_m("gethsemane", "Garden of Gethsemane", "olives_gethsemane", PackedStringArray(["MAJOR: Journey to Gethsemane on the Mount of Olives.", "Keep watch — do not fall asleep while He prays."]), {"type": "keep_watch", "prompt": "Stay near and keep watch.", "solution": "watch", "duration": 12.0, "hint": "Remain within the garden circle."}, "Apostle", "Matthew 26:39 (KJV)", "And he went a little further, and fell on his face, and prayed, saying, O my Father, if it be possible, let this cup pass from me: nevertheless not as I will, but as thou wilt.", true, false, "locked"),
		_m("crucifixion", "The Crucifixion", "golgotha", PackedStringArray(["MAJOR — Level 1 climax: Take the road past Jerusalem toward Golgotha.", "Stand near the place called The Skull and bear witness."]), {"type": "arrive", "prompt": "Approach Golgotha.", "solution": "arrive", "hint": "Stand at the Golgotha marker."}, "Witness of the Cross", "Luke 23:46 (KJV)", "And when Jesus had cried with a loud voice, he said, Father, into thy hands I commend my spirit: and having said thus, he gave up the ghost.", true, false, "locked"),
	]

func _m(id: String, name: String, loc: String, clues: PackedStringArray, puzzle: Dictionary, status_at: String, reference: String, scripture: String, is_major: bool, unlocked: bool, state: String) -> Dictionary:
	return {"id": id, "name": name, "location_id": loc, "clue": clues[0] if clues.size() > 0 else "", "clues": clues, "puzzle": puzzle, "state": state, "status_at": status_at, "reference": reference, "scripture": scripture, "is_major_beat": is_major, "unlocked": unlocked, "done": false, "clue_index": 0}

func total_miracles() -> int:
	return miracles.size()

func get_location(location_id: String) -> Dictionary:
	return map_locations.get(location_id, {})

func get_miracle_index(miracle_id: String) -> int:
	for i in range(miracles.size()):
		if miracles[i].get("id", "") == miracle_id:
			return i
	return -1

func get_miracle(miracle_id: String) -> Dictionary:
	var idx := get_miracle_index(miracle_id)
	return {} if idx < 0 else miracles[idx]

func get_active_miracle() -> Dictionary:
	for m in miracles:
		if m.get("unlocked", false) and not m.get("done", false):
			return m
	return {}

func get_revealed_clues(miracle_id: String) -> PackedStringArray:
	var m := get_miracle(miracle_id)
	if m.is_empty():
		return PackedStringArray()
	var all_clues: PackedStringArray = m.get("clues", PackedStringArray())
	var idx: int = int(m.get("clue_index", 0))
	var out := PackedStringArray()
	var state: String = str(m.get("state", "locked"))
	if state == "locked":
		return out
	var show_count := clampi(idx, 0, maxi(all_clues.size() - 1, 0)) + 1
	if state in ["puzzle", "miracle", "done"]:
		show_count = all_clues.size()
	for i in range(mini(show_count, all_clues.size())):
		out.append(all_clues[i])
	return out

func _current_clue() -> String:
	var m := get_active_miracle()
	if m.is_empty():
		return "Level 1 complete — free roam. (Resurrection / Level 2 TBD)"
	var state: String = str(m.get("state", "clues"))
	var name_str: String = str(m.get("name", ""))
	match state:
		"clues":
			var clues: PackedStringArray = m.get("clues", PackedStringArray())
			var ci: int = clampi(int(m.get("clue_index", 0)), 0, maxi(clues.size() - 1, 0))
			return "[%s] %s" % [name_str, clues[ci]] if clues.size() > 0 else str(m.get("clue", ""))
		"puzzle":
			return "[%s] Puzzle: %s" % [name_str, str(m.get("puzzle", {}).get("prompt", "Solve the puzzle."))]
		"miracle":
			return "[%s] The moment is at hand — participate / observe at the marker." % name_str
		_:
			return str(m.get("clue", ""))

func add_cash(amount: int) -> void:
	cash += amount
	cash_changed.emit(cash)

func set_status(status: String) -> void:
	player_status = status
	status_changed.emit(player_status)

func update_mission_text(text: String) -> void:
	mission_updated.emit(text)

func _emit_progress() -> void:
	level_changed.emit(player_level)
	miracles_changed.emit(miracles_completed, total_miracles())

func present_scripture(reference: String, quote: String) -> void:
	scripture_presented.emit(reference, quote)
	if DisplayServer.has_method("tts_speak"):
		if DisplayServer.has_method("tts_stop"):
			DisplayServer.tts_stop()
		DisplayServer.tts_speak(quote, "", 50, 1.0, 1.0)

func set_miracle_state(miracle_id: String, new_state: String) -> void:
	var idx := get_miracle_index(miracle_id)
	if idx < 0:
		return
	miracles[idx]["state"] = new_state
	if new_state != "locked":
		miracles[idx]["unlocked"] = true
	if new_state == "done":
		miracles[idx]["done"] = true
	encounter_state_changed.emit(miracle_id, new_state)
	mission_updated.emit(_current_clue())
	journal_changed.emit()

func reveal_next_clue(miracle_id: String = "") -> bool:
	if miracle_id.is_empty():
		var active := get_active_miracle()
		if active.is_empty():
			return false
		miracle_id = str(active.get("id", ""))
	var idx := get_miracle_index(miracle_id)
	if idx < 0:
		return false
	var m: Dictionary = miracles[idx]
	if not m.get("unlocked", false) or m.get("done", false):
		return false
	if str(m.get("state", "locked")) != "clues":
		return false
	var clues: PackedStringArray = m.get("clues", PackedStringArray())
	var ci: int = int(m.get("clue_index", 0))
	if clues.is_empty():
		_advance_after_clues(idx)
		return false
	clue_revealed.emit(miracle_id, ci, clues[ci])
	if ci >= clues.size() - 1:
		miracles[idx]["clue_index"] = clues.size() - 1
		_advance_after_clues(idx)
	else:
		miracles[idx]["clue_index"] = ci + 1
		mission_updated.emit(_current_clue())
	journal_changed.emit()
	return true

func _advance_after_clues(idx: int) -> void:
	var m: Dictionary = miracles[idx]
	var puzzle: Dictionary = m.get("puzzle", {})
	var mid: String = str(m.get("id", ""))
	if puzzle.is_empty() or str(puzzle.get("type", "")) == "":
		set_miracle_state(mid, "miracle")
		miracle_phase_started.emit(mid)
	else:
		set_miracle_state(mid, "puzzle")
		puzzle_opened.emit(mid, puzzle)

func submit_puzzle_answer(miracle_id: String, answer: String) -> bool:
	var idx := get_miracle_index(miracle_id)
	if idx < 0:
		return false
	if str(miracles[idx].get("state", "")) != "puzzle":
		return false
	var puzzle: Dictionary = miracles[idx].get("puzzle", {})
	var ptype: String = str(puzzle.get("type", "riddle"))
	if ptype in ["arrive", "keep_watch", "fill_jars", "interact"]:
		return false
	var expected := _normalize_answer(str(puzzle.get("solution", "")))
	var given := _normalize_answer(answer)
	if expected.is_empty() or given != expected:
		return false
	_pass_puzzle(idx)
	return true

func complete_puzzle(miracle_id: String) -> void:
	var idx := get_miracle_index(miracle_id)
	if idx < 0 or str(miracles[idx].get("state", "")) != "puzzle":
		return
	_pass_puzzle(idx)

func _pass_puzzle(idx: int) -> void:
	var mid: String = str(miracles[idx].get("id", ""))
	set_miracle_state(mid, "miracle")
	miracle_phase_started.emit(mid)
	update_mission_text("[%s] Puzzle solved — witness the miracle at the marker." % str(miracles[idx].get("name", "")))

func _normalize_answer(s: String) -> String:
	var t := s.strip_edges().to_lower()
	t = t.replace(",", " ").replace(".", " ").replace(";", " ").replace(":", " ")
	while t.find("  ") >= 0:
		t = t.replace("  ", " ")
	return t.strip_edges()

func participate_miracle(miracle_id: String) -> void:
	var idx := get_miracle_index(miracle_id)
	if idx < 0 or str(miracles[idx].get("state", "")) != "miracle":
		return
	complete_miracle(miracle_id)

func complete_miracle(miracle_id: String, reward: int = -1) -> void:
	var idx := get_miracle_index(miracle_id)
	if idx < 0:
		push_warning("Unknown miracle/beat: %s" % miracle_id)
		return
	if miracles[idx].get("done", false):
		return
	var is_major: bool = bool(miracles[idx].get("is_major_beat", false))
	if reward < 0:
		reward = MAJOR_BEAT_REWARD if is_major else MIRACLE_REWARD
		if miracle_id == "follow_me":
			reward = FOLLOW_REWARD
	miracles[idx]["done"] = true
	miracles[idx]["state"] = "done"
	miracles[idx]["unlocked"] = true
	miracles_completed += 1
	player_level = miracles_completed
	var new_title: String = str(miracles[idx].get("status_at", player_status))
	set_status(new_title)
	add_cash(reward)
	if idx + 1 < miracles.size():
		miracles[idx + 1]["unlocked"] = true
		miracles[idx + 1]["state"] = "clues"
		miracles[idx + 1]["clue_index"] = 0
	_emit_progress()
	level_up.emit(player_level, new_title)
	if is_major:
		major_beat_presented.emit(miracle_id, str(miracles[idx].get("name", "")))
	present_scripture(str(miracles[idx].get("reference", "")), str(miracles[idx].get("scripture", "")))
	var title: String = str(miracles[idx].get("name", "Miracle"))
	if is_major:
		title = "★ " + title
	mission_completed.emit(title, reward)
	mission_updated.emit(_current_clue())
	encounter_state_changed.emit(miracle_id, "done")
	journal_changed.emit()
	if miracle_id == "follow_me":
		mission_complete = true
		mission_active = false

func complete_follow_mission() -> void:
	complete_miracle("follow_me", FOLLOW_REWARD)

func get_journal_entries() -> Array[Dictionary]:
	return miracles.duplicate(true)
