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

var _xp_shimmer: ColorRect
var _last_xp: int = -1
var _last_level: int = -1

func _ready() -> void:
	EventBus.xp_changed.connect(_on_xp_changed)
	EventBus.level_up.connect(_on_level_up)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.shield_changed.connect(_on_shield_changed)
	EventBus.rounds_changed.connect(_on_rounds_changed)
	EventBus.player_damaged.connect(func(_x): _refresh_all())
	EventBus.player_healed.connect(func(_x): _refresh_all())
	_setup_xp_shimmer()
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
		if _last_xp >= 0 and (current > _last_xp or RunState.level > _last_level):
			_flash_xp_bar()
	if _xp_label:
		_xp_label.text = "%d / %d XP" % [current, needed]
	_last_xp = current
	_last_level = RunState.level

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
		if RunState.boss_active:
			_rounds_label.text = "BOSS W%d" % [RunState.wave]
		else:
			_rounds_label.text = "WAVE %d  %d" % [RunState.wave, value]

func _refresh_sword() -> void:
	if _sword_value:
		var bonus: int = int(RunState.mod("sword_damage_bonus", 0))
		_sword_value.text = "+%d" % bonus

func _setup_xp_shimmer() -> void:
	if _xp_bar == null:
		return
	_xp_shimmer = ColorRect.new()
	_xp_shimmer.color = Color(1.0, 0.88, 0.42, 0.46)
	_xp_shimmer.modulate.a = 0.0
	_xp_shimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_shimmer.size = Vector2(48, max(8.0, _xp_bar.size.y))
	_xp_shimmer.position = Vector2(-60, 0)
	_xp_shimmer.z_index = 4
	_xp_shimmer.visible = false
	_xp_bar.add_child(_xp_shimmer)

func _flash_xp_bar() -> void:
	if _xp_bar == null:
		return
	var bar_tw := create_tween()
	_xp_bar.modulate = Color(1.28, 1.16, 0.68, 1.0)
	bar_tw.tween_property(_xp_bar, "modulate", Color.WHITE, 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if _xp_shimmer == null:
		return
	_xp_shimmer.visible = true
	_xp_shimmer.position = Vector2(-_xp_shimmer.size.x, 0)
	_xp_shimmer.size.y = max(8.0, _xp_bar.size.y)
	_xp_shimmer.modulate.a = 0.0
	var shimmer_tw := create_tween().set_parallel(true)
	shimmer_tw.tween_property(_xp_shimmer, "position:x", _xp_bar.size.x + 8.0, 0.55) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	shimmer_tw.tween_property(_xp_shimmer, "modulate:a", 1.0, 0.14)
	shimmer_tw.tween_property(_xp_shimmer, "modulate:a", 0.0, 0.24).set_delay(0.22)
	shimmer_tw.chain().tween_callback(func(): _xp_shimmer.visible = false)
