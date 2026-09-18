extends Node
## Autoload GameState — Infidel Crusader Level 1.
## player_level = miracles/beats completed (starts at 0).
## Map: stylized ancient Israel; each campaign entry has location_id.

signal cash_changed(amount: int)
signal status_changed(new_status: String)
signal level_changed(level: int)
signal miracles_changed(completed: int, total: int)
signal mission_updated(text: String)
signal mission_completed(title: String, reward: int)
signal level_up(new_level: int, title: String)
signal scripture_presented(reference: String, quote: String)
signal major_beat_presented(beat_id: String, beat_name: String)

var cash: int = 0
var player_level: int = 0
var player_status: String = "Fishmonger"
var miracles_completed: int = 0
var mission_active: bool = true
var mission_complete: bool = false

const FOLLOW_REWARD: int = 50
const MIRACLE_REWARD: int = 75
const MAJOR_BEAT_REWARD: int = 100

## Stylized ancient-Israel places. detail "v0" = labeled blockout; "later" = stub.
var map_locations: Dictionary = {
	"galilee_shore": {"name": "Sea of Galilee (shore)", "pos": Vector3(-6, 0, -8), "detail": "v0"},
	"capernaum": {"name": "Capernaum", "pos": Vector3(8, 0, 4), "detail": "v0"},
	"bethsaida": {"name": "Bethsaida", "pos": Vector3(18, 0, -4), "detail": "v0"},
	"cana": {"name": "Cana", "pos": Vector3(-18, 0, 10), "detail": "v0"},
	"nazareth": {"name": "Nazareth area", "pos": Vector3(-24, 0, 16), "detail": "v0"},
	"tabor": {"name": "Mount of Transfiguration", "pos": Vector3(-12, 0, 18), "detail": "v0"},
	"samaria_road": {"name": "Road through Samaria", "pos": Vector3(-2, 0, 24), "detail": "later"},
	"bethany": {"name": "Bethany", "pos": Vector3(8, 0, 30), "detail": "later"},
	"jerusalem": {"name": "Jerusalem", "pos": Vector3(4, 0, 36), "detail": "later"},
	"olives_gethsemane": {"name": "Mount of Olives / Gethsemane", "pos": Vector3(12, 0, 34), "detail": "later"},
	"golgotha": {"name": "Golgotha", "pos": Vector3(0, 0, 42), "detail": "later"},
}

## Ordered Level 1 arc. Scripture = public-domain KJV.
var miracles: Array[Dictionary] = [
	{
		"id": "follow_me",
		"name": "Follow Me",
		"location_id": "galilee_shore",
		"clue": "Find Jesus at the Capernaum fish market / Galilee shore, then follow Him.",
		"status_at": "Disciple",
		"reference": "Matthew 4:19 (KJV)",
		"scripture": "And he saith unto them, Follow me, and I will make you fishers of men.",
		"is_major_beat": false,
		"unlocked": true,
		"done": false,
	},
	{
		"id": "nets_overflow",
		"name": "Nets Overflow",
		"location_id": "bethsaida",
		"clue": "Return toward Bethsaida / the docks at dawn — the Teacher spoke of a catch.",
		"status_at": "Disciple",
		"reference": "Luke 5:5–6 (KJV)",
		"scripture": "And Simon answering said unto him, Master, we have toiled all the night, and have taken nothing: nevertheless at thy word I will let down the net. And when they had this done, they inclosed a great multitude of fishes: and their net brake.",
		"is_major_beat": false,
		"unlocked": false,
		"done": false,
	},
	{
		"id": "water_to_wine",
		"name": "Water to Wine",
		"location_id": "cana",
		"clue": "A wedding feast in Cana needs servants who listen.",
		"status_at": "Witness",
		"reference": "John 2:7–9 (KJV)",
		"scripture": "Jesus saith unto them, Fill the waterpots with water. And they filled them up to the brim. And he saith unto them, Draw out now, and bear unto the governor of the feast. And they bare it. When the ruler of the feast had tasted the water that was made wine, and knew not whence it was: (but the servants which drew the water knew;)",
		"is_major_beat": false,
		"unlocked": false,
		"done": false,
	},
	{
		"id": "calm_the_storm",
		"name": "Calm the Storm",
		"location_id": "galilee_shore",
		"clue": "Cross the Sea of Galilee when the sky turns dark — stay in the boat.",
		"status_at": "Witness",
		"reference": "Mark 4:39 (KJV)",
		"scripture": "And he arose, and rebuked the wind, and said unto the sea, Peace, be still. And the wind ceased, and there was a great calm.",
		"is_major_beat": false,
		"unlocked": false,
		"done": false,
	},
	{
		"id": "loaves_and_fish",
		"name": "Loaves and Fish",
		"location_id": "bethsaida",
		"clue": "Near Bethsaida a hillside crowd grows hungry; bring what little you have.",
		"status_at": "Apostle",
		"reference": "Matthew 14:19–20 (KJV)",
		"scripture": "And he commanded the multitude to sit down on the grass, and took the five loaves, and the two fishes, and looking up to heaven, he blessed, and brake, and gave the loaves to his disciples, and the disciples to the multitude. And they did all eat, and were filled: and they took up of the fragments that remained twelve baskets full.",
		"is_major_beat": false,
		"unlocked": false,
		"done": false,
	},
	{
		"id": "transfiguration",
		"name": "The Transfiguration",
		"location_id": "tabor",
		"clue": "MAJOR: Climb the Mount of Transfiguration when He calls three aside.",
		"status_at": "Apostle",
		"reference": "Matthew 17:5 (KJV)",
		"scripture": "While he yet spake, behold, a bright cloud overshadowed them: and behold a voice out of the cloud, which said, This is my beloved Son, in whom I am well pleased; hear ye him.",
		"is_major_beat": true,
		"unlocked": false,
		"done": false,
	},
	{
		"id": "gethsemane",
		"name": "Garden of Gethsemane",
		"location_id": "olives_gethsemane",
		"clue": "MAJOR: Keep watch with Him in Gethsemane on the Mount of Olives.",
		"status_at": "Apostle",
		"reference": "Matthew 26:39 (KJV)",
		"scripture": "And he went a little further, and fell on his face, and prayed, saying, O my Father, if it be possible, let this cup pass from me: nevertheless not as I will, but as thou wilt.",
		"is_major_beat": true,
		"unlocked": false,
		"done": false,
	},
	{
		"id": "crucifixion",
		"name": "The Crucifixion",
		"location_id": "golgotha",
		"clue": "MAJOR — Level 1 climax: Follow the road from Jerusalem to Golgotha.",
		"status_at": "Witness of the Cross",
		"reference": "Luke 23:46 (KJV)",
		"scripture": "And when Jesus had cried with a loud voice, he said, Father, into thy hands I commend my spirit: and having said thus, he gave up the ghost.",
		"is_major_beat": true,
		"unlocked": false,
		"done": false,
	},
]

func _ready() -> void:
	_emit_progress()
	mission_updated.emit(_current_clue())

func total_miracles() -> int:
	return miracles.size()

func get_location(location_id: String) -> Dictionary:
	return map_locations.get(location_id, {})

func _current_clue() -> String:
	for m in miracles:
		if m.get("unlocked", false) and not m.get("done", false):
			return str(m.get("clue", ""))
	return "Level 1 complete — free roam. (Resurrection / Level 2 TBD)"

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

func complete_miracle(miracle_id: String, reward: int = -1) -> void:
	var idx := -1
	for i in range(miracles.size()):
		if miracles[i].get("id", "") == miracle_id:
			idx = i
			break
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
	miracles_completed += 1
	player_level = miracles_completed

	var new_title: String = str(miracles[idx].get("status_at", player_status))
	set_status(new_title)
	add_cash(reward)

	if idx + 1 < miracles.size():
		miracles[idx + 1]["unlocked"] = true

	_emit_progress()
	level_up.emit(player_level, new_title)

	if is_major:
		major_beat_presented.emit(miracle_id, str(miracles[idx].get("name", "")))

	present_scripture(
		str(miracles[idx].get("reference", "")),
		str(miracles[idx].get("scripture", ""))
	)

	var title: String = str(miracles[idx].get("name", "Miracle"))
	if is_major:
		title = "★ " + title
	mission_completed.emit(title, reward)
	mission_updated.emit(_current_clue())

	if miracle_id == "follow_me":
		mission_complete = true
		mission_active = false

func complete_follow_mission() -> void:
	complete_miracle("follow_me", FOLLOW_REWARD)

func get_journal_entries() -> Array[Dictionary]:
	return miracles.duplicate(true)
