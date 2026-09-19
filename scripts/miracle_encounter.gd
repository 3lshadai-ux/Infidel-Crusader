extends MiracleEncounterCore
## Puzzle / miracle interaction layer for MiracleEncounter.

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
		if ptype == "keep_watch" and _watch_elapsed > 0.0 and dist > INTERACT_RADIUS * WATCH_LEAVE_MULT:
			_watch_elapsed = 0.0
			sleep_warning.emit("You drifted away — the disciples sleep. Return and keep watch.")
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
			clear_sleep_warning.emit()
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
		MiracleSetpieces.paint_jar_water(best)
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

func _process_miracle(delta: float, dist: float, mid: String) -> void:
	if mid == "transfiguration":
		_transfig_hold += delta
	if dist > INTERACT_RADIUS:
		clear_interact_hint.emit()
		_prompt_shown = false
		return
	if not _prompt_shown:
		_prompt_shown = true
		_play_miracle_fx(mid)
	if mid == "nets_overflow" and not _nets_participated:
		request_interact_hint.emit("Press E — let down the net / haul the catch")
	elif mid == "transfiguration" and _transfig_hold < 2.5:
		request_interact_hint.emit("Behold the glory... (hold)")
	else:
		request_interact_hint.emit("Press E / Interact - witness the miracle")
	if Input.is_action_just_pressed("interact"):
		if mid == "nets_overflow" and not _nets_participated:
			_nets_participated = true
			_ensure_fx()
			MiracleSetpieces.fx_nets_catch(_fx_node)
			request_interact_hint.emit("Press E again - witness the miracle")
			return
		if mid == "calm_the_storm":
			_clear_fx()
			_ensure_fx()
			_restore_day()
			MiracleSetpieces.fx_storm_calm(_fx_node)
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
	if _active_id == "calm_the_storm":
		_restore_day()
	if _active_id == "crucifixion" and not _level1_banner_shown:
		_level1_banner_shown = true
		level1_complete.emit()
	_refresh_from_state()

func _refresh_from_state() -> void:
	var active := GameState.get_active_miracle()
	if active.is_empty() or str(active.get("id", "")) == "follow_me":
		_hide_beacon()
		_active_id = ""
		_clear_stage()
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
	if _fx_node:
		for c in _fx_node.get_children():
			if c.has_meta("wind"):
				c.position.x += float(c.get_meta("spd")) * delta
				if c.position.x > 8.0:
					c.position.x = -8.0

func _clear_jars() -> void:
	for j in _jar_nodes:
		if is_instance_valid(j):
			j.queue_free()
	_jar_nodes.clear()
	_jars_filled = 0

func _play_miracle_fx(mid: String) -> void:
	_clear_fx()
	_ensure_fx()
	match mid:
		"water_to_wine":
			MiracleSetpieces.fx_wine(_fx_node, _jar_nodes)
		"nets_overflow":
			MiracleSetpieces.fx_simple(_fx_node, Color(0.3, 0.55, 0.9))
		"calm_the_storm":
			_set_lighting("storm")
			MiracleSetpieces.spawn_wind(_fx_node)
		"loaves_and_fish":
			MiracleSetpieces.fx_loaves(_fx_node)
		"transfiguration":
			_set_lighting("glory")
			MiracleSetpieces.fx_transfiguration(_fx_node)
		"gethsemane":
			_set_lighting("night")
			MiracleSetpieces.fx_gethsemane(_fx_node)
		"crucifixion":
			_set_lighting("solemn")
			MiracleSetpieces.fx_crucifixion(_fx_node)
		_:
			MiracleSetpieces.fx_simple(_fx_node, Color(1.0, 0.9, 0.5))

func _clear_fx() -> void:
	if _fx_node and is_instance_valid(_fx_node):
		_fx_node.queue_free()
	_fx_node = null

func _clear_stage() -> void:
	if _stage_node and is_instance_valid(_stage_node):
		_stage_node.queue_free()
	_stage_node = null

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
			if mid == "nets_overflow" and not _nets_participated:
				_nets_participated = true
				_ensure_fx()
				MiracleSetpieces.fx_nets_catch(_fx_node)
				return
			if mid == "calm_the_storm":
				_clear_fx()
				_ensure_fx()
				_restore_day()
				MiracleSetpieces.fx_storm_calm(_fx_node)
			GameState.participate_miracle(mid)
