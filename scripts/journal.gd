extends RefCounted
class_name MiracleJournal
## Helper for journal UI - major beats, states, and revealed clues.

static func format_entry(entry: Dictionary) -> String:
	var star := "* " if entry.get("is_major_beat", false) else ""
	var state := str(entry.get("state", ""))
	if state.is_empty():
		state = "done" if entry.get("done", false) else ("unlocked" if entry.get("unlocked", false) else "locked")
	var loc := str(entry.get("location_id", ""))
	return "%s%s [%s] @ %s - %s" % [star, entry.get("name", "?"), state, loc, entry.get("reference", "")]

static func format_entry_rich(entry: Dictionary) -> String:
	var star := "* " if entry.get("is_major_beat", false) else ""
	var state := str(entry.get("state", "locked"))
	var color := {
		"locked": "#888888",
		"clues": "#6ab0ff",
		"puzzle": "#ffb84d",
		"miracle": "#ffe066",
		"done": "#7dffa0",
	}.get(state, "#cccccc")
	var line := "[color=%s]%s%s[/color]  [%s]" % [color, star, entry.get("name", "?"), state]
	if entry.get("unlocked", false) and not entry.get("done", false):
		var clues: PackedStringArray = entry.get("clues", PackedStringArray())
		var ci: int = int(entry.get("clue_index", 0))
		if state in ["puzzle", "miracle"]:
			ci = maxi(clues.size() - 1, 0)
		if clues.size() > 0:
			var shown := mini(ci + 1, clues.size())
			line += "\n  Clues (%d/%d):" % [shown, clues.size()]
			for i in range(shown):
				line += "\n  * %s" % clues[i]
	elif entry.get("done", false):
		line += "\n  Completed - %s" % entry.get("reference", "")
	return line

static func major_beats(entries: Array) -> Array:
	var out: Array = []
	for e in entries:
		if e.get("is_major_beat", false):
			out.append(e)
	return out

static func journal_text(entries: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append("- Disciple Journal -")
	for e in entries:
		parts.append(format_entry_rich(e))
		parts.append("")
	return "\n".join(parts)
