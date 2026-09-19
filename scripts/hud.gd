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
@onready var look_pad: Control = $Root/CameraLookPad
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
	if look_pad and look_pad.has_method("bind_hud"):
		look_pad.bind_hud(self)
	journal_btn.pressed.connect(_toggle_journal)
	interact_btn.pressed.connect(_on_interact_pressed)
	puzzle_submit.pressed.connect(_on_puzzle_submit)
	puzzle_close.pressed.connect(func(): puzzle_panel.visible = false)
	puzzle_input.text_submitted.connect(func(_t): _on_puzzle_submit())
	var close_j: Button = $Root/JournalPanel/Margin/VBox/CloseJournal
	close_j.pressed.connect(func(): journal_panel.visible = false)
	_connect_encounter()
	_refresh_journal()
