extends RefCounted
class_name MiracleJournal
## Helper for journal UI — major beats get distinct treatment.

static func format_entry(entry: Dictionary) -> String:
	var star := "★ " if entry.get("is_major_beat", false) else ""
	var state := "done" if entry.get("done", false) else ("unlocked" if entry.get("unlocked", false) else "locked")
	return "%s%s [%s] — %s" % [star, entry.get("name", "?"), state, entry.get("reference", "")]

static func major_beats(entries: Array) -> Array:
	var out: Array = []
	for e in entries:
		if e.get("is_major_beat", false):
			out.append(e)
	return out
