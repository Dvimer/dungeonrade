extends CanvasLayer
class_name HUD

# HUD: HP-колба слева, XP-шкала и уровень в центре, "сила меча" справа.
# Подписан на сигналы EventBus и тянет данные из RunState.

@onready var _xp_bar: ProgressBar = $Root/Bottom/Center/XPBar
@onready var _xp_label: Label = $Root/Bottom/Center/XPLabel
@onready var _level_label: Label = $Root/Bottom/Center/LevelLabel
@onready var _gold_label: Label = $Root/Top/GoldGroup/GoldLabel
@onready var _sword_value: Label = $Root/Bottom/Right/SwordValue
@onready var _shield_value: Label = $Root/Top/ShieldGroup/ShieldLabel
@onready var _rounds_label: Label = $Root/Top/RoundsLabel

func _ready() -> void:
	EventBus.xp_changed.connect(_on_xp_changed)
	EventBus.level_up.connect(_on_level_up)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.shield_changed.connect(_on_shield_changed)
	EventBus.rounds_changed.connect(_on_rounds_changed)
	EventBus.player_damaged.connect(func(_x): _refresh_all())
	EventBus.player_healed.connect(func(_x): _refresh_all())
	_refresh_all()

func _refresh_all() -> void:
	_on_xp_changed(RunState.xp, RunState.xp_needed_for_next_level())
	_on_level_up(RunState.level)
	_on_gold_changed(RunState.gold)
	_on_shield_changed(RunState.shield)
	_on_rounds_changed(RunState.rounds_left)
	_refresh_sword()

func _on_xp_changed(current: int, needed: int) -> void:
	if _xp_bar:
		_xp_bar.max_value = needed
		_xp_bar.value = current
	if _xp_label:
		_xp_label.text = "%d / %d" % [current, needed]

func _on_level_up(new_level: int) -> void:
	if _level_label:
		_level_label.text = "Lv. %d" % new_level

func _on_gold_changed(value: int) -> void:
	if _gold_label:
		_gold_label.text = str(value)

func _on_shield_changed(value: int) -> void:
	if _shield_value:
		_shield_value.text = str(value)
	# показываем/скрываем всю группу щита
	var shield_group: Node = get_node_or_null("Root/Top/ShieldGroup")
	if shield_group:
		shield_group.visible = value > 0

func _on_rounds_changed(value: int) -> void:
	if _rounds_label:
		_rounds_label.text = "Round %d" % value

func _refresh_sword() -> void:
	if _sword_value:
		var bonus: int = int(RunState.mod("sword_damage_bonus", 0))
		_sword_value.text = "+%d" % bonus
