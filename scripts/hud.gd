extends CanvasLayer
## HUD: cash, status, level, miracles, mission, clues, puzzle, journal, scripture.

@onready var cash_label: Label = $Root/TopBar/CashLabel
@onready var status_label: Label = $Root/TopBar/StatusLabel
@onready var level_label: Label = $Root/TopBar/LevelLabel
@onready var miracles_label: Label = $Root/TopBar/MiraclesLabel
@onready var mission_label: Label = $Root/MissionPanel/MissionLabel
@onready var complete_panel: PanelContainer = $Root/CompletePanel
@onready var complete_title: Label = $Root/CompletePanel/VBox/TitleLabel
@onready var complete_body: Label = $Root/CompletePanel/VBox/BodyLabel
@onready var levelup_panel: PanelContainer = $Root/LevelUpPanel
@onready var levelup_label: Label = $Root/LevelUpPanel/LevelUpLabel
@onready var scripture_panel: PanelContainer = $Root/ScripturePanel
@onready var scripture_ref: Label = $Root/ScripturePanel/VBox/ReferenceLabel
@onready var scripture_quote: Label = $Root/ScripturePanel/VBox/QuoteLabel
@onready var major_panel: PanelContainer = $Root/MajorBeatPanel
@onready var major_label: Label = $Root/MajorBeatPanel/MajorLabel
@onready var joystick: Control = $Root/VirtualJoystick
@onready var clue_panel: PanelContainer = $Root/CluePanel
@onready var clue_label: RichTextLabel = $Root/CluePanel/Margin/ClueLabel
@onready var puzzle_panel: PanelContainer = $Root/PuzzlePanel
@onready var puzzle_prompt: Label = $Root/PuzzlePanel/VBox/PromptLabel
@onready var puzzle_input: LineEdit = $Root/PuzzlePanel/VBox/AnswerInput
@onready var puzzle_hint: Label = $Root/PuzzlePanel/VBox/HintLabel
@onready var puzzle_feedback: Label = $Root/PuzzlePanel/VBox/FeedbackLabel
@onready var puzzle_submit: Button = $Root/PuzzlePanel/VBox/ButtonRow/SubmitButton
@onready var puzzle_close: Button = $Root/PuzzlePanel/VBox/ButtonRow/CloseButton
@onready var journal_panel: PanelContainer = $Root/JournalPanel
@onready var journal_text: RichTextLabel = $Root/JournalPanel/Margin/VBox/JournalText
@onready var journal_btn: Button = $Root/BottomBar/JournalButton
@onready var interact_btn: Button = $Root/BottomBar/InteractButton
@onready var hint_label: Label = $Root/HintLabel

var _puzzle_miracle_id: String = ""
var _scripture_timer: SceneTreeTimer = null

func _ready() -> void:
	complete_panel.visible = false
	levelup_panel.visible = false
	scripture_panel.visible = false
	major_panel.visible = false
	clue_panel.visible = false
	puzzle_panel.visible = false
	journal_panel.visible = false
	hint_label.visible = false
	_refresh_cash(GameState.cash)
	_refresh_status(GameState.player_status)
	_refresh_level(GameState.player_level)
	_refresh_miracles(GameState.miracles_completed, GameState.total_miracles())
	mission_label.text = "Find Jesus at the Capernaum shore market, then follow Him."
	GameState.cash_changed.connect(_refresh_cash)
	GameState.status_changed.connect(_refresh_status)
	GameState.level_changed.connect(_refresh_level)
	GameState.miracles_changed.connect(_refresh_miracles)
	GameState.mission_updated.connect(_on_mission_updated)
	GameState.mission_completed.connect(_on_mission_completed)
	GameState.level_up.connect(_on_level_up)
	GameState.scripture_presented.connect(_on_scripture)
	GameState.major_beat_presented.connect(_on_major_beat)
	GameState.clue_revealed.connect(_on_clue_revealed)
	GameState.journal_changed.connect(_refresh_journal)
	GameState.puzzle_opened.connect(_on_puzzle_opened_signal)
	if joystick.has_signal("direction_changed"):
		joystick.direction_changed.connect(_on_joystick)
	journal_btn.pressed.connect(_toggle_journal)
	interact_btn.pressed.connect(_on_interact_pressed)
	puzzle_submit.pressed.connect(_on_puzzle_submit)
	puzzle_close.pressed.connect(func(): puzzle_panel.visible = false)
	puzzle_input.text_submitted.connect(func(_t): _on_puzzle_submit())
	var close_j: Button = $Root/JournalPanel/Margin/VBox/CloseJournal
	close_j.pressed.connect(func(): journal_panel.visible = false)
	_connect_encounter()
	_refresh_journal()

func _connect_encounter() -> void:
	await get_tree().process_frame
	var enc := get_tree().get_first_node_in_group("miracle_encounter")
	if enc == null:
		return
	if enc.has_signal("request_puzzle_ui"):
		enc.request_puzzle_ui.connect(_open_puzzle)
	if enc.has_signal("request_clue_ui"):
		enc.request_clue_ui.connect(_show_clues)
	if enc.has_signal("request_interact_hint"):
		enc.request_interact_hint.connect(_show_hint)
	if enc.has_signal("clear_interact_hint"):
		enc.clear_interact_hint.connect(_hide_hint)
	if enc.has_signal("fill_jars_progress"):
		enc.fill_jars_progress.connect(_on_jars_progress)
	if enc.has_signal("watch_progress"):
		enc.watch_progress.connect(_on_watch_progress)
	if enc.has_signal("sleep_warning"):
		enc.sleep_warning.connect(_on_sleep_warning)
	if enc.has_signal("clear_sleep_warning"):
		enc.clear_sleep_warning.connect(_on_clear_sleep_warning)
	if enc.has_signal("level1_complete"):
		enc.level1_complete.connect(_on_level1_complete)

func _refresh_cash(amount: int) -> void:
	cash_label.text = "Cash: $%d" % amount

func _refresh_status(status: String) -> void:
	status_label.text = "Status: %s" % status

func _refresh_level(level: int) -> void:
	level_label.text = "Level: %d" % level

func _refresh_miracles(completed: int, total: int) -> void:
	miracles_label.text = "Miracles: %d/%d" % [completed, total]

func _on_mission_updated(text: String) -> void:
	mission_label.text = text

func _on_mission_completed(title: String, reward: int) -> void:
	complete_panel.visible = true
	complete_title.text = title
	complete_body.text = "Witnessed.\n(+ $%d)" % reward
	get_tree().create_timer(3.5).timeout.connect(func(): complete_panel.visible = false)
	puzzle_panel.visible = false
	_refresh_journal()

func _on_level_up(new_level: int, title: String) -> void:
	levelup_panel.visible = true
	levelup_label.text = "* LEVEL UP - %d *\nNew title: %s\nNext clue unlocked" % [new_level, title]
	get_tree().create_timer(4.0).timeout.connect(func(): levelup_panel.visible = false)

func _on_scripture(reference: String, quote: String) -> void:
	scripture_panel.visible = true
	scripture_ref.text = reference
	scripture_quote.text = "\"%s\"" % quote
	get_tree().create_timer(10.0).timeout.connect(func(): scripture_panel.visible = false)

func _on_major_beat(_beat_id: String, beat_name: String) -> void:
	major_panel.visible = true
	major_label.text = "* MAJOR STORY BEAT *\n%s" % beat_name
	get_tree().create_timer(5.0).timeout.connect(func(): major_panel.visible = false)

func _on_clue_revealed(_miracle_id: String, clue_index: int, clue_text: String) -> void:
	clue_panel.visible = true
	clue_label.text = "[b]Clue %d[/b]\n%s" % [clue_index + 1, clue_text]
	get_tree().create_timer(5.0).timeout.connect(func(): clue_panel.visible = false)
	_refresh_journal()

func _show_clues(miracle_id: String, clues: PackedStringArray) -> void:
	clue_panel.visible = true
	var lines := "[b]Journal clues - %s[/b]\n" % miracle_id
	for i in range(clues.size()):
		lines += "* %s\n" % clues[i]
	clue_label.text = lines
	get_tree().create_timer(6.0).timeout.connect(func(): clue_panel.visible = false)

func _on_puzzle_opened_signal(miracle_id: String, puzzle: Dictionary) -> void:
	_open_puzzle(miracle_id, puzzle)

func _open_puzzle(miracle_id: String, puzzle: Dictionary) -> void:
	var ptype: String = str(puzzle.get("type", "riddle"))
	if ptype in ["arrive", "keep_watch"]:
		return
	_puzzle_miracle_id = miracle_id
	puzzle_panel.visible = true
	puzzle_prompt.text = str(puzzle.get("prompt", "Solve the puzzle."))
	puzzle_hint.text = "Hint: %s" % str(puzzle.get("hint", ""))
	puzzle_feedback.text = ""
	puzzle_input.text = ""
	puzzle_input.grab_focus()

func _on_puzzle_submit() -> void:
	if _puzzle_miracle_id.is_empty():
		return
	var answer := puzzle_input.text
	var enc := get_tree().get_first_node_in_group("miracle_encounter")
	var ok := false
	if enc and enc.has_method("submit_answer"):
		ok = enc.submit_answer(_puzzle_miracle_id, answer)
	else:
		ok = GameState.submit_puzzle_answer(_puzzle_miracle_id, answer)
	if ok:
		puzzle_feedback.text = "Correct - the way is open."
		puzzle_feedback.add_theme_color_override("font_color", Color(0.25, 1.0, 0.4))
		get_tree().create_timer(1.2).timeout.connect(func(): puzzle_panel.visible = false)
	else:
		puzzle_feedback.text = "Not yet - search the scriptures and try again."
		puzzle_feedback.add_theme_color_override("font_color", Color(1.0, 0.35, 0.28))

func _toggle_journal() -> void:
	journal_panel.visible = not journal_panel.visible
	if journal_panel.visible:
		_refresh_journal()

func _refresh_journal() -> void:
	if journal_text:
		journal_text.text = MiracleJournal.journal_text(GameState.get_journal_entries())

func _on_interact_pressed() -> void:
	var enc := get_tree().get_first_node_in_group("miracle_encounter")
	if enc and enc.has_method("try_interact"):
		enc.try_interact()

func _show_hint(text: String) -> void:
	hint_label.visible = true
	hint_label.text = text

func _hide_hint() -> void:
	hint_label.visible = false

func _on_jars_progress(filled: int, total: int) -> void:
	_show_hint("Waterpots filled: %d / %d" % [filled, total])

func _on_watch_progress(elapsed: float, required: float) -> void:
	_show_hint("Keep watch... %.0f / %.0f s" % [elapsed, required])

func _on_sleep_warning(text: String) -> void:
	_show_hint(text)
	hint_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.45))

func _on_clear_sleep_warning() -> void:
	hint_label.remove_theme_color_override("font_color")

func _on_level1_complete() -> void:
	major_panel.visible = true
	major_label.text = "* LEVEL 1 COMPLETE *\nThe Crucifixion witnessed.\nFree roam unlocked — Resurrection / Level 2 TBD"
	get_tree().create_timer(8.0).timeout.connect(func(): major_panel.visible = false)

func _on_joystick(dir: Vector2) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_joystick"):
		player.set_joystick(dir)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal"):
		_toggle_journal()
