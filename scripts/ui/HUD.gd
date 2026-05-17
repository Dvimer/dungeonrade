extends CanvasLayer
class_name HUD

const SKILL_XP_COLOR := Color(0.62, 0.42, 1.0, 1.0)
const SHOP_COLOR := Color(0.36, 1.0, 0.48, 1.0)
const SkillCatalogScript := preload("res://scripts/data/SkillCatalog.gd")
const EquipmentCatalogScript := preload("res://scripts/data/EquipmentCatalog.gd")

@onready var _skill_slots: HBoxContainer = $Root/TopDock/SkillSlots
@onready var _menu_button: Button = $Root/TopDock/RightButtons/MenuButton
@onready var _stats_button: Button = $Root/TopDock/RightButtons/StatsButton
@onready var _wave_label: Label = $Root/TopDock/RightButtons/WaveLabel
@onready var _gold_label: Label = $Root/BottomDock/GoldPanel/Value
@onready var _enemy_value: Label = $Root/BottomDock/StatsRow/EnemyStat/Value
@onready var _shield_value: Label = $Root/BottomDock/StatsRow/ShieldStat/Value
@onready var _sword_value: Label = $Root/BottomDock/StatsRow/SwordStat/Value
@onready var _hp_value: Label = $Root/BottomDock/StatsRow/HpStat/Value
@onready var _skill_xp_bar: ProgressBar = $Root/BottomDock/Bars/SkillXPBar
@onready var _skill_xp_label: Label = $Root/BottomDock/Bars/SkillXPLabel
@onready var _shop_bar: ProgressBar = $Root/BottomDock/Bars/ShopBar
@onready var _shop_label: Label = $Root/BottomDock/Bars/ShopLabel
@onready var _stats_popup: PanelContainer = $Root/StatsPopup
@onready var _stats_popup_label: RichTextLabel = $Root/StatsPopup/Margin/VBox/Body
@onready var _upgrade_overlay: ColorRect = $Root/UpgradeOverlay
@onready var _upgrade_title: Label = $Root/UpgradeOverlay/UpgradeCard/Margin/VBox/Title
@onready var _upgrade_subtitle: Label = $Root/UpgradeOverlay/UpgradeCard/Margin/VBox/SubTitle
@onready var _upgrade_choices: HBoxContainer = $Root/UpgradeOverlay/UpgradeCard/Margin/VBox/Choices
@onready var _shop_overlay: ColorRect = $Root/ShopOverlay
@onready var _shop_title: Label = $Root/ShopOverlay/ShopCard/Margin/VBox/Title
@onready var _shop_subtitle: Label = $Root/ShopOverlay/ShopCard/Margin/VBox/SubTitle
@onready var _shop_choices: HBoxContainer = $Root/ShopOverlay/ShopCard/Margin/VBox/Choices

var _xp_shimmer: ColorRect
var _shop_shimmer: ColorRect
var _last_xp: int = -1
var _last_level: int = -1
var _last_shop_charge: int = -1
var _ui_texture_cache: Dictionary = {}
var _tooltip_panel: PanelContainer = null
var _tooltip_label: RichTextLabel = null
var _tooltip_visible: bool = false
var _tooltip_tween: Tween = null

func _ready() -> void:
	_menu_button.pressed.connect(func(): EventBus.main_menu_requested.emit())
	_stats_button.pressed.connect(_toggle_stats_popup)
	EventBus.xp_changed.connect(_on_xp_changed)
	EventBus.level_up.connect(_on_level_up)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.shop_charge_changed.connect(_on_shop_charge_changed)
	EventBus.shield_changed.connect(_on_shield_changed)
	EventBus.rounds_changed.connect(_on_rounds_changed)
	EventBus.skills_changed.connect(_refresh_skill_slots)
	EventBus.equipment_changed.connect(_refresh_all)
	EventBus.upgrade_offered.connect(_show_upgrade_choices)
	EventBus.shop_offered.connect(_show_shop_choices)
	EventBus.player_damaged.connect(func(_x): _refresh_all())
	EventBus.player_healed.connect(func(_x): _refresh_all())
	Localization.language_changed.connect(func(_language): _refresh_all())
	_style_bars()
	_setup_shimmer()
	_refresh_skill_slots()
	_refresh_all()
	_setup_tooltip()
	EventBus.tile_hovered.connect(_on_tile_hovered)
	EventBus.tile_unhovered.connect(_on_tile_unhovered)

func _refresh_all() -> void:
	_apply_localized_texts()
	_refresh_skill_slots()
	_on_xp_changed(RunState.xp, RunState.xp_needed_for_next_level())
	_on_level_up(RunState.level)
	_on_gold_changed(RunState.gold)
	_on_shop_charge_changed(RunState.shop_charge, RunState.shop_charge_needed)
	_on_shield_changed(RunState.shield)
	_on_rounds_changed(RunState.rounds_left)
	_refresh_stat_values()
	_refresh_stats_popup()
	if _upgrade_overlay and not RunState.awaiting_upgrade_choice:
		_upgrade_overlay.visible = false
	if _shop_overlay and not RunState.awaiting_shop_choice:
		_shop_overlay.visible = false
	_on_tile_unhovered()

func _refresh_skill_slots() -> void:
	if _skill_slots == null:
		return
	for child in _skill_slots.get_children():
		child.queue_free()
	var filled := 0
	for skill in RunState.active_skills:
		_skill_slots.add_child(_make_skill_card(skill))
		filled += 1
	while filled < 4:
		_skill_slots.add_child(_make_empty_skill_card())
		filled += 1

func _make_skill_card(skill: Dictionary) -> Control:
	var skill_id := str(skill.get("id", ""))
	var is_active := str(skill.get("skill_kind", "passive")) == "active"
	var cooldown: int = RunState.get_skill_cooldown(skill_id)
	var is_ready := cooldown <= 0

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(112, 88)
	var style := StyleBoxFlat.new()
	var border_col: Color = skill.get("color", Color(0.55, 0.40, 0.95, 1.0))
	if is_active and not is_ready:
		style.bg_color = Color(0.08, 0.08, 0.14, 0.94)
		border_col = border_col.darkened(0.55)
	else:
		style.bg_color = Color(0.10, 0.10, 0.18, 0.94)
	style.border_color = border_col
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.offset_left = 8
	box.offset_top = 6
	box.offset_right = 104
	box.offset_bottom = 82
	panel.add_child(box)

	var icon := Label.new()
	icon.text = Localization.skill_icon_text(skill_id, str(skill.get("icon_text", "SKILL")))
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 16)
	icon.add_theme_color_override("font_color", border_col)
	box.add_child(icon)

	var title := Label.new()
	title.text = Localization.skill_short_name(skill_id, str(skill.get("short_title", skill.get("title", "Skill"))))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.94, 1.0))
	box.add_child(title)

	var bottom_label := Label.new()
	if is_active:
		if is_ready:
			bottom_label.text = Localization.t("hud.skill.ready")
			bottom_label.add_theme_color_override("font_color", Color(0.52, 1.0, 0.62))
		else:
			bottom_label.text = str(cooldown)
			bottom_label.add_theme_color_override("font_color", Color(0.70, 0.68, 0.82))
	else:
		bottom_label.text = Localization.t("hud.level", [int(skill.get("level", 1))])
		bottom_label.add_theme_color_override("font_color", Color(0.88, 0.82, 1.0))
	bottom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bottom_label.add_theme_font_size_override("font_size", 18)
	box.add_spacer(false)
	box.add_child(bottom_label)

	if is_active and is_ready:
		var btn := Button.new()
		btn.flat = true
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.pressed.connect(func():
			EventBus.emit_signal("skill_tapped", skill_id)
		)
		panel.add_child(btn)

	return panel

func _make_empty_skill_card() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(112, 88)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.85)
	style.border_color = Color(0.34, 0.30, 0.42, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)

	var title := Label.new()
	title.text = Localization.t("hud.empty")
	title.anchor_right = 1.0
	title.anchor_bottom = 1.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.60, 0.60, 0.68))
	panel.add_child(title)
	return panel

func _refresh_stat_values() -> void:
	if _enemy_value:
		_enemy_value.text = "+%d" % RunState.enemy_power()
	if _shield_value:
		_shield_value.text = "%d/%d" % [RunState.shield, RunState.max_shield]
	if _sword_value:
		_sword_value.text = "+%d" % RunState.sword_power()
	if _hp_value:
		_hp_value.text = "%d/%d" % [RunState.hp, RunState.max_hp]

func _on_xp_changed(current: int, needed: int) -> void:
	if _skill_xp_bar:
		_skill_xp_bar.max_value = needed
		_skill_xp_bar.value = current
		if _last_xp >= 0 and (current > _last_xp or RunState.level > _last_level):
			_flash_bar(_skill_xp_bar, _xp_shimmer)
	if _skill_xp_label:
		_skill_xp_label.text = Localization.t("hud.skill_xp", [current, needed, RunState.level])
	_last_xp = current
	_last_level = RunState.level
	_refresh_stats_popup()

func _on_level_up(_new_level: int) -> void:
	_refresh_stat_values()
	_refresh_stats_popup()

func _on_gold_changed(value: int) -> void:
	if _gold_label:
		_gold_label.text = str(value)

func _on_shop_charge_changed(current: int, needed: int) -> void:
	if _shop_bar:
		_shop_bar.max_value = needed
		_shop_bar.value = current
		if _last_shop_charge >= 0 and current > _last_shop_charge:
			_flash_bar(_shop_bar, _shop_shimmer)
	if _shop_label:
		var suffix := Localization.t("hud.shop_ready") if current >= needed else ""
		_shop_label.text = Localization.t("hud.shop_charge", [current, needed, suffix])
	_last_shop_charge = current
	_refresh_stats_popup()

func _on_shield_changed(_value: int) -> void:
	_refresh_stat_values()
	_refresh_stats_popup()

func _on_rounds_changed(value: int) -> void:
	if _wave_label:
		if RunState.boss_active:
			_wave_label.text = Localization.t("hud.wave_boss", [RunState.wave])
		else:
			_wave_label.text = Localization.t("hud.wave_turns", [RunState.wave, value])

func _toggle_stats_popup() -> void:
	_stats_popup.visible = not _stats_popup.visible
	if _stats_popup.visible:
		_refresh_stats_popup()

func _refresh_stats_popup() -> void:
	if _stats_popup_label == null:
		return
	var stats := RunState.current_stats()
	_stats_popup_label.text = "[b]%s[/b]\n" % Localization.t("hud.stats_title")
	_stats_popup_label.text += Localization.t("hud.stats.crit", [int(stats.get("crit_chance", 0))]) + "\n"
	_stats_popup_label.text += Localization.t("hud.stats.vamp", [int(stats.get("vampirism", 0))]) + "\n"
	_stats_popup_label.text += Localization.t("hud.stats.hp", [int(stats.get("hp", 0)), int(stats.get("max_hp", 0))]) + "\n"
	_stats_popup_label.text += Localization.t("hud.stats.shield", [int(stats.get("shield", 0)), int(stats.get("max_shield", 0))]) + "\n"
	_stats_popup_label.text += Localization.t("hud.stats.sword", [int(stats.get("sword_power", 0))]) + "\n"
	_stats_popup_label.text += Localization.t("hud.stats.enemy", [int(stats.get("enemy_power", 0))]) + "\n"
	_stats_popup_label.text += Localization.t("hud.stats.shop", [int(stats.get("shop_charge", 0)), int(stats.get("shop_charge_needed", 0))]) + "\n"
	var equipment_names: Array = stats.get("equipment_names", [])
	if equipment_names.is_empty():
		_stats_popup_label.text += Localization.t("hud.stats.equipment.none")
	else:
		_stats_popup_label.text += Localization.t("hud.stats.equipment", [", ".join(equipment_names)])

func _show_upgrade_choices(choices: Array) -> void:
	if _upgrade_overlay == null:
		return
	_upgrade_overlay.visible = true
	for child in _upgrade_choices.get_children():
		child.queue_free()
	_upgrade_title.text = Localization.t("hud.upgrade.title")
	_upgrade_subtitle.text = Localization.t("hud.upgrade.subtitle")
	for choice in choices:
		_upgrade_choices.add_child(_make_upgrade_choice_button(choice))

func _make_upgrade_choice_button(skill: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(180, 220)
	button.text = "%s\n%s\n%s" % [
		Localization.skill_icon_text(str(skill.get("id", "")), str(skill.get("icon_text", "*"))),
		Localization.skill_name(str(skill.get("id", "")), str(skill.get("title", "Skill"))),
		_upgrade_choice_hint(skill) + "\n" + "\n".join(SkillCatalogScript.describe_bonus_block(SkillCatalogScript.level_bonus(skill))),
	]
	button.clip_text = true
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(func():
		_upgrade_overlay.visible = false
		EventBus.emit_signal("upgrade_picked", skill)
	)
	return button

func _upgrade_choice_hint(skill: Dictionary) -> String:
	var current_level := int(skill.get("current_level", 0))
	if current_level <= 0:
		return Localization.t("hud.upgrade.new")
	return Localization.t("hud.upgrade.next", [int(skill.get("level", current_level + 1))])

func _show_shop_choices(choices: Array) -> void:
	if _shop_overlay == null:
		return
	_shop_overlay.visible = true
	for child in _shop_choices.get_children():
		child.queue_free()
	_shop_title.text = Localization.t("hud.shop.title")
	_shop_subtitle.text = Localization.t("hud.shop.subtitle")
	for choice in choices:
		_shop_choices.add_child(_make_shop_choice_button(choice))

func _make_shop_choice_button(item: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(180, 220)
	button.text = ""
	button.clip_contents = true
	var icon_path := str(item.get("icon_path", ""))
	var icon_tex := _load_ui_texture(icon_path)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	button.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	if icon_tex != null:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(52, 52)
		icon.texture = icon_tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(icon)

	var title := Label.new()
	title.text = Localization.item_name(str(item.get("id", "")), str(item.get("title", "Item")))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 18)
	box.add_child(title)

	var slot := Label.new()
	slot.text = Localization.item_slot(str(item.get("slot", "")), str(item.get("slot", "slot")).capitalize())
	slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot.add_theme_font_size_override("font_size", 16)
	slot.add_theme_color_override("font_color", Color(0.80, 0.82, 0.94, 1.0))
	box.add_child(slot)

	var bonus := Label.new()
	bonus.text = "\n".join(SkillCatalogScript.describe_bonus_block(EquipmentCatalogScript.bonus_dict(item)))
	bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bonus.add_theme_font_size_override("font_size", 15)
	box.add_child(bonus)
	button.pressed.connect(func():
		_shop_overlay.visible = false
		EventBus.emit_signal("shop_picked", item)
	)
	return button

func _load_ui_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if not _ui_texture_cache.has(path):
		_ui_texture_cache[path] = load(path)
	var tex = _ui_texture_cache[path]
	return tex if tex is Texture2D else null

func _apply_localized_texts() -> void:
	_menu_button.text = Localization.t("hud.menu")
	_stats_button.text = Localization.t("hud.stats")
	var gold_title: Label = $Root/BottomDock/GoldPanel/Title
	var enemy_title: Label = $Root/BottomDock/StatsRow/EnemyStat/Title
	var shield_title: Label = $Root/BottomDock/StatsRow/ShieldStat/Title
	var sword_title: Label = $Root/BottomDock/StatsRow/SwordStat/Title
	var hp_title: Label = $Root/BottomDock/StatsRow/HpStat/Title
	var stats_title: Label = $Root/StatsPopup/Margin/VBox/Title
	gold_title.text = Localization.t("hud.gold")
	enemy_title.text = Localization.t("hud.enemy")
	shield_title.text = Localization.t("hud.shield")
	sword_title.text = Localization.t("hud.sword")
	hp_title.text = Localization.t("hud.hp")
	stats_title.text = Localization.t("hud.stats")

func _style_bars() -> void:
	_apply_bar_style(_skill_xp_bar, SKILL_XP_COLOR)
	_apply_bar_style(_shop_bar, SHOP_COLOR)

func _apply_bar_style(bar: ProgressBar, fill_color: Color) -> void:
	if bar == null:
		return
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.10, 0.10, 0.16, 0.98)
	bg.corner_radius_top_left = 8
	bg.corner_radius_top_right = 8
	bg.corner_radius_bottom_left = 8
	bg.corner_radius_bottom_right = 8
	bg.border_width_left = 2
	bg.border_width_top = 2
	bg.border_width_right = 2
	bg.border_width_bottom = 2
	bg.border_color = Color(0.34, 0.28, 0.50, 0.95)
	bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = 8
	fill.corner_radius_top_right = 8
	fill.corner_radius_bottom_left = 8
	fill.corner_radius_bottom_right = 8
	bar.add_theme_stylebox_override("fill", fill)

func _setup_shimmer() -> void:
	_xp_shimmer = _attach_shimmer(_skill_xp_bar, SKILL_XP_COLOR)
	_shop_shimmer = _attach_shimmer(_shop_bar, SHOP_COLOR)

func _setup_tooltip() -> void:
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.custom_minimum_size = Vector2(220, 0)
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.visible = false
	_tooltip_panel.modulate.a = 0.0
	_tooltip_panel.z_index = 200

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.06, 0.14, 0.96)
	style.border_color = Color(0.58, 0.37, 0.48, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	_tooltip_panel.add_theme_stylebox_override("panel", style)

	_tooltip_label = RichTextLabel.new()
	_tooltip_label.bbcode_enabled = true
	_tooltip_label.fit_content = true
	_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_label.custom_minimum_size = Vector2(196, 0)
	_tooltip_label.add_theme_font_size_override("normal_font_size", 16)
	_tooltip_label.add_theme_font_size_override("bold_font_size", 17)
	_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.add_child(_tooltip_label)

	$Root.add_child(_tooltip_panel)

func _attach_shimmer(bar: ProgressBar, color: Color) -> ColorRect:
	if bar == null:
		return null
	var rect := ColorRect.new()
	rect.color = color
	rect.modulate.a = 0.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.size = Vector2(56, max(10.0, bar.size.y))
	rect.position = Vector2(-64, 0)
	rect.visible = false
	bar.add_child(rect)
	return rect

func _on_tile_hovered(tile_data: Dictionary) -> void:
	_tooltip_label.text = _build_monster_tooltip(tile_data)
	_tooltip_panel.visible = true
	_tooltip_visible = true
	_reposition_tooltip()
	if _tooltip_tween and _tooltip_tween.is_valid():
		_tooltip_tween.kill()
	_tooltip_tween = create_tween()
	_tooltip_tween.tween_property(_tooltip_panel, "modulate:a", 1.0, 0.12)

func _on_tile_unhovered() -> void:
	_tooltip_visible = false
	if _tooltip_panel == null:
		return
	if _tooltip_tween and _tooltip_tween.is_valid():
		_tooltip_tween.kill()
	_tooltip_tween = create_tween()
	_tooltip_tween.tween_property(_tooltip_panel, "modulate:a", 0.0, 0.10)
	_tooltip_tween.tween_callback(func(): _tooltip_panel.visible = false)

func _build_monster_tooltip(data: Dictionary) -> String:
	var monster_id := str(data.get("monster_id", ""))
	var name := Localization.monster_name(monster_id, str(data.get("monster_name", "?")))
	var hp := int(data.get("hp", 0))
	var dmg := int(data.get("dmg", 0))
	var defense := int(data.get("defense", 0))
	var timer := int(data.get("timer", 0))

	var text := ""

	if bool(data.get("is_boss", false)):
		text += "[color=#ff6666]" + Localization.t("tooltip.enemy.boss") + "[/color]\n"

	text += "[b]" + name + "[/b]\n"

	var info := Localization.t("monster.info", [name, hp, dmg, defense, timer])
	var parts := info.split("\n")
	if parts.size() > 1:
		text += parts[1] + "\n"

	if bool(data.get("heal_on_attack", false)):
		var ratio := float(data.get("heal_on_attack_ratio", 1.0))
		text += Localization.t("tooltip.enemy.heal_on_attack", [ratio]) + "\n"
	if bool(data.get("explode_on_attack", false)):
		var radius := int(data.get("explosion_radius", 1))
		var pdmg := int(data.get("explosion_player_damage", 0))
		text += Localization.t("tooltip.enemy.explode", [radius, pdmg]) + "\n"
	if bool(data.get("reset_timer_on_hit", false)):
		text += Localization.t("tooltip.enemy.reset_timer") + "\n"
	if bool(data.get("remove_on_attack", false)):
		text += Localization.t("tooltip.enemy.remove_on_attack") + "\n"

	return text.strip_edges()

func _reposition_tooltip() -> void:
	if _tooltip_panel == null:
		return
	var mp := get_viewport().get_mouse_position()
	var vp_size := get_viewport().get_visible_rect().size
	var panel_size := _tooltip_panel.get_minimum_size()
	if panel_size == Vector2.ZERO:
		panel_size = Vector2(220, 80)
	var pos := mp + Vector2(16.0, 16.0)
	pos.x = minf(pos.x, vp_size.x - panel_size.x - 8.0)
	pos.y = minf(pos.y, vp_size.y - panel_size.y - 8.0)
	_tooltip_panel.position = pos

func _process(_delta: float) -> void:
	if _tooltip_visible:
		_reposition_tooltip()

func _flash_bar(bar: ProgressBar, shimmer: ColorRect) -> void:
	if bar == null:
		return
	var base_color := bar.modulate
	bar.modulate = Color(1.16, 1.16, 1.16, 1.0)
	var tween := create_tween()
	tween.tween_property(bar, "modulate", base_color, 0.28)
	if shimmer == null:
		return
	shimmer.visible = true
	shimmer.position = Vector2(-shimmer.size.x, 0)
	shimmer.size.y = max(10.0, bar.size.y)
	shimmer.modulate.a = 0.0
	var shimmer_tw := create_tween().set_parallel(true)
	shimmer_tw.tween_property(shimmer, "position:x", bar.size.x + 10.0, 0.55)
	shimmer_tw.tween_property(shimmer, "modulate:a", 0.35, 0.14)
	shimmer_tw.tween_property(shimmer, "modulate:a", 0.0, 0.24).set_delay(0.22)
	shimmer_tw.chain().tween_callback(func(): shimmer.visible = false)
