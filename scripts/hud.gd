extends CanvasLayer
## HUD: cash, status, level, miracles X/N, mission, scripture, major-beat banner.

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

func _ready() -> void:
	complete_panel.visible = false
	levelup_panel.visible = false
	scripture_panel.visible = false
	major_panel.visible = false
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
	if joystick.has_signal("direction_changed"):
		joystick.direction_changed.connect(_on_joystick)

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

func _on_level_up(new_level: int, title: String) -> void:
	levelup_panel.visible = true
	levelup_label.text = "LEVEL UP — %d\n%s" % [new_level, title]
	get_tree().create_timer(3.0).timeout.connect(func(): levelup_panel.visible = false)

func _on_scripture(reference: String, quote: String) -> void:
	scripture_panel.visible = true
	scripture_ref.text = reference
	scripture_quote.text = "\"%s\"" % quote
	get_tree().create_timer(8.0).timeout.connect(func(): scripture_panel.visible = false)

func _on_major_beat(_beat_id: String, beat_name: String) -> void:
	major_panel.visible = true
	major_label.text = "★ MAJOR STORY BEAT ★\n%s" % beat_name
	get_tree().create_timer(5.0).timeout.connect(func(): major_panel.visible = false)

func _on_joystick(dir: Vector2) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_joystick"):
		player.set_joystick(dir)
