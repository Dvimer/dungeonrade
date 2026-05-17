extends Node

const BattleScene := preload("res://scenes/battle/Battle.tscn")
const LevelCatalogScript := preload("res://scripts/data/LevelCatalog.gd")
const LevelTypeScript := preload("res://scripts/data/LevelType.gd")
const SkillCatalogScript := preload("res://scripts/data/SkillCatalog.gd")
const EquipmentCatalogScript := preload("res://scripts/data/EquipmentCatalog.gd")
const ClassCatalogScript := preload("res://scripts/data/ClassCatalog.gd")

const DEV_LEVELS_OPEN := true

@onready var _battle_root: Node = $BattleRoot
@onready var _menu_root: Control = $MenuLayer/Root
@onready var _title_label: Label = $MenuLayer/Root/MenuCard/Margin/VBox/TitleLabel
@onready var _subtitle_label: Label = $MenuLayer/Root/MenuCard/Margin/VBox/SubtitleLabel
@onready var _summary_label: Label = $MenuLayer/Root/MenuCard/Margin/VBox/SummaryLabel
@onready var _continue_button: Button = $MenuLayer/Root/MenuCard/Margin/VBox/ContinueButton
@onready var _skills_button: Button = $MenuLayer/Root/MenuCard/Margin/VBox/SkillsButton
@onready var _choose_level_button: Button = $MenuLayer/Root/MenuCard/Margin/VBox/ChooseLevelButton
@onready var _create_level_button: Button = $MenuLayer/Root/MenuCard/Margin/VBox/CreateLevelButton
@onready var _edit_level_button: Button = $MenuLayer/Root/MenuCard/Margin/VBox/EditLevelButton
@onready var _lang_title: Label = $MenuLayer/Root/MenuCard/Margin/VBox/LangRow/Label
@onready var _lang_ru_button: Button = $MenuLayer/Root/MenuCard/Margin/VBox/LangRow/RuButton
@onready var _lang_en_button: Button = $MenuLayer/Root/MenuCard/Margin/VBox/LangRow/EnButton
@onready var _level_list_panel: PanelContainer = $MenuLayer/Root/LevelListPanel
@onready var _level_list_title: Label = $MenuLayer/Root/LevelListPanel/Margin/VBox/Title
@onready var _level_list_box: VBoxContainer = $MenuLayer/Root/LevelListPanel/Margin/VBox/Scroll/LevelList
@onready var _skills_panel: PanelContainer = $MenuLayer/Root/SkillsPanel
@onready var _skills_summary: Label = $MenuLayer/Root/SkillsPanel/Margin/VBox/SummaryLabel
@onready var _skills_selected_grid: GridContainer = $MenuLayer/Root/SkillsPanel/Margin/VBox/SelectedGrid
@onready var _skills_hover_title: Label = $MenuLayer/Root/SkillsPanel/Margin/VBox/HoverCard/Margin/VBox/SkillTitle
@onready var _skills_hover_description: Label = $MenuLayer/Root/SkillsPanel/Margin/VBox/HoverCard/Margin/VBox/SkillDescription
@onready var _skills_available_grid: GridContainer = $MenuLayer/Root/SkillsPanel/Margin/VBox/Scroll/AvailableGrid
@onready var _skills_error: Label = $MenuLayer/Root/SkillsPanel/Margin/VBox/ErrorLabel
@onready var _editor_panel: PanelContainer = $MenuLayer/Root/EditorPanel
@onready var _editor_title: Label = $MenuLayer/Root/EditorPanel/Margin/VBox/Title
@onready var _editor_help: Label = $MenuLayer/Root/EditorPanel/Margin/VBox/HelpLabel
@onready var _editor_text: TextEdit = $MenuLayer/Root/EditorPanel/Margin/VBox/EditorText
@onready var _editor_error: Label = $MenuLayer/Root/EditorPanel/Margin/VBox/ErrorLabel

var _active_battle: Node = null
var _editor_mode: String = ""
var _editing_level_id: String = ""
var _selected_skill_ids: Array = []
var _pending_replacement_skill_id: String = ""
var _items_button: Button = null
var _crypt_button: Button = null
var _skills_backdrop: ColorRect = null
var _items_backdrop: ColorRect = null
var _items_panel: PanelContainer = null
var _items_title: Label = null
var _items_summary: Label = null
var _items_hover_title: Label = null
var _items_hover_meta: Label = null
var _items_hover_description: Label = null
var _items_grid: GridContainer = null
var _items_close_button: Button = null
var _items_sort_buttons: Dictionary = {}
var _item_sort_key: String = "rarity"
var _summary_panel: PanelContainer = null
var _summary_title_label: Label = null
var _summary_stats_label: Label = null
var _summary_earned_label: Label = null
var _summary_continue_button: Button = null
var _last_run_result: Dictionary = {}
var _crypt_backdrop: ColorRect = null
var _crypt_panel: PanelContainer = null
var _crypt_skulls_label: Label = null
var _crypt_tokens_label: Label = null
var _crypt_tab_buttons: Dictionary = {}
var _crypt_content_box: VBoxContainer = null
var _crypt_scroll: ScrollContainer = null
var _crypt_play_button: Button = null
var _crypt_active_tab: String = "equipment"
var _class_select_panel: PanelContainer = null
var _pending_level_id: String = ""
var _class_select_grid: GridContainer = null
var _ui_texture_cache: Dictionary = {}

func _ready() -> void:
	EventBus.run_finished.connect(_on_run_finished)
	EventBus.main_menu_requested.connect(_on_main_menu_requested)
	Localization.language_changed.connect(func(_language): _refresh_menu_state())
	_ensure_items_codex_ui()
	_menu_root.resized.connect(_layout_items_panel)
	_menu_root.resized.connect(_layout_crypt_panel)
	_wire_buttons()
	await get_tree().process_frame
	LevelCatalogScript.ensure_initialized()
	_ensure_skill_pool_initialized()
	_refresh_menu_state()
	_show_menu()

func _wire_buttons() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)
	$MenuLayer/Root/MenuCard/Margin/VBox/NewGameButton.pressed.connect(_on_new_game_pressed)
	_skills_button.pressed.connect(_open_skills_panel)
	if _items_button != null:
		_items_button.pressed.connect(_open_items_panel)
	if _crypt_button != null:
		_crypt_button.pressed.connect(_open_crypt_panel)
	_choose_level_button.pressed.connect(func(): _open_level_picker("play"))
	_create_level_button.pressed.connect(_on_create_level_pressed)
	_edit_level_button.pressed.connect(func(): _open_level_picker("edit"))
	_lang_ru_button.pressed.connect(func(): Localization.set_language("ru"))
	_lang_en_button.pressed.connect(func(): Localization.set_language("en"))
	$MenuLayer/Root/LevelListPanel/Margin/VBox/CloseButton.pressed.connect(func(): _level_list_panel.visible = false)
	$MenuLayer/Root/SkillsPanel/Margin/VBox/ButtonRow/CancelButton.pressed.connect(_close_skills_panel)
	$MenuLayer/Root/SkillsPanel/Margin/VBox/ButtonRow/SaveButton.pressed.connect(_save_skill_pool)
	$MenuLayer/Root/EditorPanel/Margin/VBox/ButtonRow/CancelButton.pressed.connect(func(): _editor_panel.visible = false)
	$MenuLayer/Root/EditorPanel/Margin/VBox/ButtonRow/SaveButton.pressed.connect(_save_level_from_editor)

func _refresh_menu_state() -> void:
	LevelCatalogScript.ensure_initialized()
	var levels := LevelCatalogScript.get_levels()
	var completed := GameState.completed_level_ids.size()
	var total := levels.size()
	var continue_level_id := LevelCatalogScript.get_continue_level_id()
	var continue_level := LevelCatalogScript.get_level(continue_level_id)
	_title_label.text = Localization.t("menu.title")
	_subtitle_label.text = Localization.t("menu.subtitle")
	_lang_title.text = Localization.t("menu.language")
	_lang_ru_button.text = Localization.language_label("ru")
	_lang_en_button.text = Localization.language_label("en")
	_summary_label.text = Localization.t("menu.summary", [
		completed,
		total,
		Localization.level_title(continue_level_id, str(continue_level.get("title", "First level"))),
	])
	if _skills_button:
		_skills_button.text = Localization.t("menu.skills", [_selected_skill_ids.size()])
	if _items_button:
		_items_button.text = Localization.t("menu.items")
	if _crypt_button:
		_crypt_button.text = Localization.t("menu.crypt", [GameState.skulls, GameState.boss_tokens])
	_continue_button.text = Localization.t("menu.continue")
	$MenuLayer/Root/MenuCard/Margin/VBox/NewGameButton.text = Localization.t("menu.new_game")
	_choose_level_button.text = Localization.t("menu.pick_level")
	_create_level_button.text = Localization.t("menu.create_level")
	_edit_level_button.text = Localization.t("menu.edit_level")
	$MenuLayer/Root/LevelListPanel/Margin/VBox/CloseButton.text = Localization.t("menu.close")
	$MenuLayer/Root/SkillsPanel/Margin/VBox/ButtonRow/CancelButton.text = Localization.t("menu.cancel")
	$MenuLayer/Root/SkillsPanel/Margin/VBox/ButtonRow/SaveButton.text = Localization.t("menu.save")
	$MenuLayer/Root/EditorPanel/Margin/VBox/ButtonRow/CancelButton.text = Localization.t("menu.cancel")
	$MenuLayer/Root/EditorPanel/Margin/VBox/ButtonRow/SaveButton.text = Localization.t("menu.save")
	$MenuLayer/Root/SkillsPanel/Margin/VBox/Title.text = Localization.t("menu.skills.title")
	$MenuLayer/Root/SkillsPanel/Margin/VBox/AvailableTitle.text = Localization.t("menu.skills.other")
	_refresh_items_panel_text()
	_continue_button.disabled = continue_level_id == ""
	_choose_level_button.visible = DEV_LEVELS_OPEN
	_create_level_button.visible = DEV_LEVELS_OPEN
	_edit_level_button.visible = DEV_LEVELS_OPEN

func _show_menu() -> void:
	_menu_root.visible = true
	_level_list_panel.visible = false
	if _skills_backdrop != null: _skills_backdrop.visible = false
	_skills_panel.visible = false
	_editor_panel.visible = false
	if _items_backdrop != null: _items_backdrop.visible = false
	if _items_panel != null: _items_panel.visible = false
	if _crypt_backdrop != null: _crypt_backdrop.visible = false
	if _crypt_panel != null: _crypt_panel.visible = false
	_refresh_menu_state()

func _hide_menu() -> void:
	_menu_root.visible = false
	_level_list_panel.visible = false
	if _skills_backdrop != null: _skills_backdrop.visible = false
	_skills_panel.visible = false
	_editor_panel.visible = false
	if _items_backdrop != null: _items_backdrop.visible = false
	if _items_panel != null: _items_panel.visible = false
	if _crypt_backdrop != null: _crypt_backdrop.visible = false
	if _crypt_panel != null: _crypt_panel.visible = false

func _on_continue_pressed() -> void:
	var level_id := LevelCatalogScript.get_continue_level_id()
	if level_id == "":
		return
	_start_level(level_id)

func _on_new_game_pressed() -> void:
	LevelCatalogScript.reset_campaign_progress()
	GameState.selected_class = "warrior"
	SaveSystem.save()
	var first_level := LevelCatalogScript.get_first_level()
	if first_level.is_empty():
		return
	_start_level_direct(str(first_level.get("id", "")))

func _start_level(level_id: String) -> void:
	if level_id == "":
		return
	var unlocked := ClassCatalogScript.get_all_classes().filter(func(c): return ClassCatalogScript.is_unlocked(str(c.get("id", ""))))
	if unlocked.size() > 1:
		_pending_level_id = level_id
		_refresh_class_select_grid()
		_class_select_panel.visible = true
		_level_list_panel.visible = false
		_skills_panel.visible = false
		_editor_panel.visible = false
		if _items_panel != null: _items_panel.visible = false
		if _crypt_panel != null: _crypt_panel.visible = false
		return
	_start_level_direct(level_id)

func _start_level_direct(level_id: String) -> void:
	GameState.selected_level_id = level_id
	GameState.last_played_level_id = level_id
	SaveSystem.save()
	if _active_battle != null and is_instance_valid(_active_battle):
		_active_battle.queue_free()
	_active_battle = BattleScene.instantiate()
	_battle_root.add_child(_active_battle)
	_hide_menu()

func _on_run_finished(result: Dictionary) -> void:
	if _active_battle != null and is_instance_valid(_active_battle):
		_active_battle.queue_free()
		_active_battle = null
	_last_run_result = result

	var won := bool(result.get("won", false))
	var level_id := str(result.get("level_id", ""))
	var waves := int(result.get("wave", 0))
	var bosses := int(result.get("bosses_killed", 0))

	GameState.total_runs += 1
	if won and level_id != "":
		LevelCatalogScript.mark_level_completed(level_id)

	# Award skulls and boss tokens
	var skulls_earned := waves * 10 + bosses * 25 + (15 if won else 0)
	var tokens_earned := bosses
	GameState.skulls += skulls_earned
	GameState.boss_tokens += tokens_earned

	SaveSystem.save()
	_show_run_summary(result, skulls_earned, tokens_earned)

func _show_run_summary(result: Dictionary, skulls_earned: int, tokens_earned: int) -> void:
	if _summary_panel == null:
		_show_menu()
		return
	var won := bool(result.get("won", false))
	var waves := int(result.get("wave", 0))
	var total_waves := int(result.get("total_waves", 0))
	var bosses := int(result.get("bosses_killed", 0))
	var gold := int(result.get("gold", 0))

	_summary_title_label.text = "Victory!" if won else "Defeated"
	_summary_title_label.add_theme_color_override("font_color",
		Color(0.952941, 0.823529, 0.478431, 1.0) if won else Color(0.9, 0.3, 0.3, 1.0))

	_summary_stats_label.text = "Waves: %d / %d    Bosses: %d    Gold: %d" % [waves, total_waves, bosses, gold]

	var earned_lines := []
	if skulls_earned > 0:
		earned_lines.append("+ %d Skulls" % skulls_earned)
	if tokens_earned > 0:
		earned_lines.append("+ %d Boss Token%s" % [tokens_earned, "s" if tokens_earned > 1 else ""])
	if earned_lines.is_empty():
		earned_lines.append("No rewards earned")
	_summary_earned_label.text = "\n".join(PackedStringArray(earned_lines))

	_summary_continue_button.text = "Open Crypt  (%d skulls  %d tokens)" % [GameState.skulls, GameState.boss_tokens]

	_menu_root.visible = true
	_summary_panel.visible = true

func _on_summary_continue_pressed() -> void:
	_summary_panel.visible = false
	_open_crypt_panel()

func _on_main_menu_requested() -> void:
	if _active_battle != null and is_instance_valid(_active_battle):
		_active_battle.queue_free()
		_active_battle = null
	SaveSystem.save()
	_show_menu()

func _open_level_picker(mode: String) -> void:
	_editor_mode = mode
	_level_list_panel.visible = true
	_level_list_title.text = Localization.t("menu.level_picker.play") if mode == "play" else Localization.t("menu.level_picker.edit")
	for child in _level_list_box.get_children():
		child.queue_free()
	for level in LevelCatalogScript.get_levels():
		var button := Button.new()
		var level_id := str(level.get("id", ""))
		var unlocked := GameState.unlocked_level_ids.has(level_id)
		var completed := GameState.completed_level_ids.has(level_id)
		var marker := ""
		if completed:
			marker = Localization.t("menu.level.done")
		elif unlocked:
			marker = Localization.t("menu.level.open")
		button.text = "%d. %s%s" % [int(level.get("order", 0)), Localization.level_title(level_id, str(level.get("title", level_id))), marker]
		button.custom_minimum_size.y = 52.0
		if mode == "play":
			button.pressed.connect(_on_level_picked.bind(level_id))
		else:
			button.pressed.connect(_open_editor_for_level.bind(level_id))
		_level_list_box.add_child(button)

func _on_level_picked(level_id: String) -> void:
	_level_list_panel.visible = false
	_start_level(level_id)

func _on_create_level_pressed() -> void:
	var next_order := LevelCatalogScript.get_levels().size() + 1
	var template := LevelTypeScript.new({
		"id": "custom_level_%d" % next_order,
		"order": next_order,
		"title": Localization.t("menu.editor.custom_level_title", [next_order]),
		"description": Localization.t("menu.editor.custom_level_desc"),
		"wave_count": 4,
		"turns_per_wave": 6,
		"max_shield": 4,
		"shop_charge_needed": 34,
		"enemy_spawn_start": 0.18,
		"enemy_spawn_step": 0.03,
		"enemy_spawn_max": 0.36,
		"boss_start_wave": 2,
		"boss_base_chance": 0.32,
		"boss_chance_step": 0.06,
		"boss_chance_max": 0.60,
		"boss_id": "bone_lord",
		"boss_turns": 5,
		"monster_weights": {
			"skeleton": 45,
			"bandana_skeleton": 25,
			"vampire": 10,
		},
		"monster_profile": {
			"hp_scale": 1.0,
			"damage_scale": 1.0,
			"timer_delta": 0,
			"xp_scale": 1.30,
			"gold_scale": 1.10,
		},
		"wave_power_step": {
			"hp_scale_step": 0.16,
			"damage_scale_step": 0.08,
		},
		"starting_modifiers": {},
	}).to_dictionary()
	_open_editor_with_data("create", "", template)

func _open_editor_for_level(level_id: String) -> void:
	_level_list_panel.visible = false
	var level := LevelCatalogScript.get_level(level_id)
	_open_editor_with_data("edit", level_id, level)

func _open_editor_with_data(mode: String, level_id: String, data: Dictionary) -> void:
	_editor_mode = mode
	_editing_level_id = level_id
	_editor_title.text = Localization.t("menu.editor.title.create") if mode == "create" else Localization.t("menu.editor.title.edit")
	_editor_help.text = Localization.t("menu.editor.help")
	_editor_text.text = JSON.stringify(data, "\t")
	_editor_error.text = ""
	_editor_panel.visible = true

func _save_level_from_editor() -> void:
	var parsed = JSON.parse_string(_editor_text.text)
	if parsed == null or not (parsed is Dictionary):
		_editor_error.text = Localization.t("menu.editor.invalid_json")
		return
	var normalized := LevelTypeScript.new(parsed).to_dictionary()
	var saved := LevelCatalogScript.upsert_level(normalized)
	if _editor_mode == "create" and GameState.selected_level_id == "":
		GameState.selected_level_id = str(saved.get("id", ""))
	SaveSystem.save()
	_editor_error.text = Localization.t("menu.editor.saved")
	_refresh_menu_state()

func _ensure_skill_pool_initialized() -> void:
	if GameState.skill_pool_ids.is_empty():
		GameState.skill_pool_ids = SkillCatalogScript.get_default_pool_ids()
	_selected_skill_ids = GameState.skill_pool_ids.duplicate()

func _open_skills_panel() -> void:
	_ensure_skill_pool_initialized()
	if _skills_backdrop != null:
		_skills_backdrop.visible = true
	_skills_panel.visible = true
	_level_list_panel.visible = false
	_editor_panel.visible = false
	if _items_panel != null:
		_items_panel.visible = false
	_pending_replacement_skill_id = ""
	_skills_error.text = ""
	_refresh_skills_panel()
	_refresh_skills_summary()

func _close_skills_panel() -> void:
	if _skills_backdrop != null:
		_skills_backdrop.visible = false
	_skills_panel.visible = false

func _refresh_skills_summary() -> void:
	if _skills_summary == null:
		return
	if _pending_replacement_skill_id != "":
		var skill := SkillCatalogScript.get_skill(_pending_replacement_skill_id)
		_skills_summary.text = Localization.t("menu.skills.summary.replace", [Localization.skill_name(_pending_replacement_skill_id, str(skill.get("title", _pending_replacement_skill_id)))])
	else:
		_skills_summary.text = Localization.t("menu.skills.summary")

func _refresh_skills_panel() -> void:
	_clear_container(_skills_selected_grid)
	_clear_container(_skills_available_grid)

	for skill_id in _selected_skill_ids:
		var skill := SkillCatalogScript.get_skill(str(skill_id))
		_skills_selected_grid.add_child(_make_skill_pick_button(skill, true))

	for skill in SkillCatalogScript.get_all_skills():
		var skill_id := str(skill.get("id", ""))
		if _selected_skill_ids.has(skill_id):
			continue
		_skills_available_grid.add_child(_make_skill_pick_button(skill, false))

	if _skills_hover_title:
		_skills_hover_title.text = Localization.t("menu.skills.hover_title")
	if _skills_hover_description:
		_skills_hover_description.text = Localization.t("menu.skills.hover_text")

func _make_skill_pick_button(skill: Dictionary, selected: bool) -> Button:
	var skill_id := str(skill.get("id", ""))
	var color: Color = skill.get("color", Color(0.7, 0.7, 0.7, 1.0))
	var meta_level := int(GameState.skill_levels.get(skill_id, 1))
	var meta_suffix := (" ★%d" % meta_level) if meta_level > 1 else ""

	var button := Button.new()
	button.custom_minimum_size = Vector2(140, 92)
	button.clip_text = true
	button.text = "%s%s\n%s" % [
		Localization.skill_icon_text(skill_id, str(skill.get("icon_text", "*"))),
		meta_suffix,
		Localization.skill_short_name(skill_id, str(skill.get("short_title", skill.get("title", "Skill")))),
	]
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", color)
	button.mouse_entered.connect(_show_skill_hover.bind(skill))
	if selected:
		button.pressed.connect(_on_selected_skill_pressed.bind(skill_id))
	else:
		button.modulate = Color(0.7, 0.7, 0.7, 0.85)
		button.pressed.connect(_on_available_skill_pressed.bind(skill_id))
	return button

func _show_skill_hover(skill: Dictionary) -> void:
	if _skills_hover_title:
		_skills_hover_title.text = Localization.skill_name(str(skill.get("id", "")), str(skill.get("title", Localization.t("menu.skills.hover_title"))))
	if _skills_hover_description:
		_skills_hover_description.text = Localization.skill_description(str(skill.get("id", "")), str(skill.get("description", "")))

func _on_available_skill_pressed(skill_id: String) -> void:
	_pending_replacement_skill_id = skill_id
	var skill := SkillCatalogScript.get_skill(skill_id)
	_show_skill_hover(skill)
	_refresh_skills_summary()
	_skills_error.text = Localization.t("menu.skills.error.replace")

func _on_selected_skill_pressed(skill_id: String) -> void:
	if _pending_replacement_skill_id == "":
		var skill := SkillCatalogScript.get_skill(skill_id)
		_show_skill_hover(skill)
		_skills_error.text = Localization.t("menu.skills.error.already")
		return
	if skill_id == _pending_replacement_skill_id:
		_pending_replacement_skill_id = ""
		_refresh_skills_summary()
		_skills_error.text = ""
		return
	var replace_index := _selected_skill_ids.find(skill_id)
	if replace_index < 0:
		return
	_selected_skill_ids[replace_index] = _pending_replacement_skill_id
	var new_skill := SkillCatalogScript.get_skill(_pending_replacement_skill_id)
	_pending_replacement_skill_id = ""
	_refresh_skills_panel()
	_refresh_skills_summary()
	_show_skill_hover(new_skill)
	_skills_error.text = Localization.t("menu.skills.error.replaced")

func _clear_container(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()

func _save_skill_pool() -> void:
	if _selected_skill_ids.size() < 4:
		_skills_error.text = Localization.t("menu.skills.error.min")
		return
	if _selected_skill_ids.size() > 8:
		_skills_error.text = Localization.t("menu.skills.error.max")
		return
	GameState.skill_pool_ids = _selected_skill_ids.duplicate()
	SaveSystem.save()
	_close_skills_panel()
	_refresh_menu_state()

func _ensure_items_codex_ui() -> void:
	var menu_box: VBoxContainer = $MenuLayer/Root/MenuCard/Margin/VBox
	_items_button = Button.new()
	_items_button.custom_minimum_size = Vector2(0, 56)
	menu_box.add_child(_items_button)
	menu_box.move_child(_items_button, _skills_button.get_index() + 1)

	_crypt_button = Button.new()
	_crypt_button.custom_minimum_size = Vector2(0, 56)
	menu_box.add_child(_crypt_button)
	menu_box.move_child(_crypt_button, _items_button.get_index() + 1)

	_skills_backdrop = ColorRect.new()
	_skills_backdrop.visible = false
	_skills_backdrop.color = Color(0.03, 0.04, 0.06, 0.88)
	_skills_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_skills_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_root.add_child(_skills_backdrop)
	_menu_root.move_child(_skills_backdrop, _skills_panel.get_index())

	_items_backdrop = ColorRect.new()
	_items_backdrop.visible = false
	_items_backdrop.color = Color(0.03, 0.04, 0.06, 0.86)
	_items_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_items_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_root.add_child(_items_backdrop)

	_items_panel = PanelContainer.new()
	_items_panel.visible = false
	_items_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_items_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_root.add_child(_items_panel)
	var items_panel_style := StyleBoxFlat.new()
	items_panel_style.bg_color = Color(0.10, 0.10, 0.12, 0.985)
	items_panel_style.border_color = Color(0.24, 0.25, 0.30, 1.0)
	items_panel_style.border_width_left = 2
	items_panel_style.border_width_top = 2
	items_panel_style.border_width_right = 2
	items_panel_style.border_width_bottom = 2
	items_panel_style.corner_radius_top_left = 18
	items_panel_style.corner_radius_top_right = 18
	items_panel_style.corner_radius_bottom_left = 18
	items_panel_style.corner_radius_bottom_right = 18
	_items_panel.add_theme_stylebox_override("panel", items_panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_items_panel.add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_theme_constant_override("separation", 12)
	margin.add_child(root_box)

	_items_title = Label.new()
	_items_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_items_title.add_theme_font_size_override("font_size", 26)
	_items_title.add_theme_color_override("font_color", Color(0.952941, 0.823529, 0.478431, 1.0))
	root_box.add_child(_items_title)

	_items_summary = Label.new()
	_items_summary.custom_minimum_size = Vector2(0, 30)
	_items_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_items_summary.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88, 1.0))
	root_box.add_child(_items_summary)

	var sort_row := HBoxContainer.new()
	sort_row.alignment = BoxContainer.ALIGNMENT_CENTER
	sort_row.add_theme_constant_override("separation", 10)
	root_box.add_child(sort_row)

	for sort_key in ["rarity", "name", "slot", "type"]:
		var sort_button := Button.new()
		sort_button.custom_minimum_size = Vector2(132, 40)
		sort_button.toggle_mode = true
		sort_button.pressed.connect(_set_item_sort.bind(sort_key))
		sort_row.add_child(sort_button)
		_items_sort_buttons[sort_key] = sort_button

	var hover_card := PanelContainer.new()
	hover_card.custom_minimum_size = Vector2(0, 100)
	root_box.add_child(hover_card)

	var hover_margin := MarginContainer.new()
	hover_margin.add_theme_constant_override("margin_left", 14)
	hover_margin.add_theme_constant_override("margin_top", 12)
	hover_margin.add_theme_constant_override("margin_right", 14)
	hover_margin.add_theme_constant_override("margin_bottom", 12)
	hover_card.add_child(hover_margin)

	var hover_box := VBoxContainer.new()
	hover_box.add_theme_constant_override("separation", 6)
	hover_margin.add_child(hover_box)

	_items_hover_title = Label.new()
	_items_hover_title.add_theme_font_size_override("font_size", 22)
	_items_hover_title.add_theme_color_override("font_color", Color(0.952941, 0.823529, 0.478431, 1.0))
	hover_box.add_child(_items_hover_title)

	_items_hover_meta = Label.new()
	_items_hover_meta.add_theme_color_override("font_color", Color(0.76, 0.80, 0.92, 1.0))
	hover_box.add_child(_items_hover_meta)

	_items_hover_description = Label.new()
	_items_hover_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_items_hover_description.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88, 1.0))
	hover_box.add_child(_items_hover_description)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 380)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(scroll)

	_items_grid = GridContainer.new()
	_items_grid.columns = 5
	_items_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_grid.add_theme_constant_override("h_separation", 10)
	_items_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_items_grid)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.custom_minimum_size = Vector2(0, 56)
	root_box.add_child(button_row)

	_items_close_button = Button.new()
	_items_close_button.custom_minimum_size = Vector2(180, 52)
	_items_close_button.text = Localization.t("menu.close")
	_items_close_button.pressed.connect(_close_items_panel)
	button_row.add_child(_items_close_button)

	_layout_items_panel()
	_refresh_items_panel_text()
	_build_summary_panel()

func _build_summary_panel() -> void:
	_summary_panel = PanelContainer.new()
	_summary_panel.visible = false
	_summary_panel.custom_minimum_size = Vector2(560, 0)
	_summary_panel.set_anchors_preset(Control.PRESET_CENTER)
	_summary_panel.anchor_left = 0.5
	_summary_panel.anchor_top = 0.5
	_summary_panel.anchor_right = 0.5
	_summary_panel.anchor_bottom = 0.5
	_summary_panel.offset_left = -280.0
	_summary_panel.offset_top = -280.0
	_summary_panel.offset_right = 280.0
	_summary_panel.offset_bottom = 280.0
	_menu_root.add_child(_summary_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	_summary_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	_summary_title_label = Label.new()
	_summary_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_title_label.add_theme_font_size_override("font_size", 32)
	_summary_title_label.add_theme_color_override("font_color", Color(0.952941, 0.823529, 0.478431, 1.0))
	vbox.add_child(_summary_title_label)

	_summary_stats_label = Label.new()
	_summary_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_stats_label.add_theme_font_size_override("font_size", 22)
	_summary_stats_label.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88, 1.0))
	_summary_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_summary_stats_label)

	_summary_earned_label = Label.new()
	_summary_earned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_earned_label.add_theme_font_size_override("font_size", 26)
	_summary_earned_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.34, 1.0))
	_summary_earned_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_summary_earned_label)

	_summary_continue_button = Button.new()
	_summary_continue_button.custom_minimum_size = Vector2(0, 60)
	_summary_continue_button.add_theme_font_size_override("font_size", 22)
	_summary_continue_button.text = "Continue"
	_summary_continue_button.pressed.connect(_on_summary_continue_pressed)
	vbox.add_child(_summary_continue_button)
	_build_crypt_panel()

func _build_crypt_panel() -> void:
	_crypt_backdrop = ColorRect.new()
	_crypt_backdrop.visible = false
	_crypt_backdrop.color = Color(0.03, 0.04, 0.06, 0.86)
	_crypt_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_crypt_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_root.add_child(_crypt_backdrop)

	_crypt_panel = PanelContainer.new()
	_crypt_panel.visible = false
	_crypt_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_crypt_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_root.add_child(_crypt_panel)
	var crypt_style := StyleBoxFlat.new()
	crypt_style.bg_color = Color(0.10, 0.10, 0.12, 0.985)
	crypt_style.border_color = Color(0.24, 0.25, 0.30, 1.0)
	crypt_style.border_width_left = 2
	crypt_style.border_width_top = 2
	crypt_style.border_width_right = 2
	crypt_style.border_width_bottom = 2
	crypt_style.corner_radius_top_left = 18
	crypt_style.corner_radius_top_right = 18
	crypt_style.corner_radius_bottom_left = 18
	crypt_style.corner_radius_bottom_right = 18
	_crypt_panel.add_theme_stylebox_override("panel", crypt_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_crypt_panel.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", 14)
	margin.add_child(root_vbox)

	# Header
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 26)
	root_vbox.add_child(header)

	var crypt_title := Label.new()
	crypt_title.text = "The Crypt"
	crypt_title.add_theme_font_size_override("font_size", 27)
	crypt_title.add_theme_color_override("font_color", Color(0.952941, 0.823529, 0.478431, 1.0))
	header.add_child(crypt_title)

	_crypt_skulls_label = Label.new()
	_crypt_skulls_label.add_theme_font_size_override("font_size", 18)
	_crypt_skulls_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.34, 1.0))
	header.add_child(_crypt_skulls_label)

	_crypt_tokens_label = Label.new()
	_crypt_tokens_label.add_theme_font_size_override("font_size", 18)
	_crypt_tokens_label.add_theme_color_override("font_color", Color(0.95, 0.62, 0.25, 1.0))
	header.add_child(_crypt_tokens_label)

	# Tabs
	var tab_row := HBoxContainer.new()
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_row.add_theme_constant_override("separation", 12)
	root_vbox.add_child(tab_row)

	for tab_id in ["equipment", "classes", "skills"]:
		var tab_btn := Button.new()
		tab_btn.custom_minimum_size = Vector2(180, 44)
		tab_btn.toggle_mode = true
		tab_btn.add_theme_font_size_override("font_size", 17)
		match tab_id:
			"equipment": tab_btn.text = "Equipment"
			"classes":   tab_btn.text = "Classes"
			"skills":    tab_btn.text = "Skills"
		tab_btn.pressed.connect(_crypt_switch_tab.bind(tab_id))
		tab_row.add_child(tab_btn)
		_crypt_tab_buttons[tab_id] = tab_btn

	# Content area (rebuilt each tab switch)
	var scroll := ScrollContainer.new()
	_crypt_scroll = scroll
	scroll.custom_minimum_size = Vector2(0, 420)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)

	_crypt_content_box = VBoxContainer.new()
	_crypt_content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_crypt_content_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_crypt_content_box)

	# Play button
	_crypt_play_button = Button.new()
	_crypt_play_button.custom_minimum_size = Vector2(0, 60)
	_crypt_play_button.add_theme_font_size_override("font_size", 22)
	_crypt_play_button.text = "Play"
	var play_style := StyleBoxFlat.new()
	play_style.bg_color = Color(0.16, 0.12, 0.08, 1.0)
	play_style.border_color = Color(0.73, 0.55, 0.30, 1.0)
	play_style.border_width_left = 2
	play_style.border_width_top = 2
	play_style.border_width_right = 2
	play_style.border_width_bottom = 2
	play_style.corner_radius_top_left = 12
	play_style.corner_radius_top_right = 12
	play_style.corner_radius_bottom_left = 12
	play_style.corner_radius_bottom_right = 12
	_crypt_play_button.add_theme_stylebox_override("normal", play_style)
	_crypt_play_button.add_theme_stylebox_override("hover", play_style)
	_crypt_play_button.add_theme_stylebox_override("pressed", play_style)
	_crypt_play_button.add_theme_color_override("font_color", Color(0.98, 0.90, 0.76, 1.0))
	_crypt_play_button.pressed.connect(_on_crypt_play_pressed)
	root_vbox.add_child(_crypt_play_button)
	_layout_crypt_panel()
	_build_class_select_panel()

func _build_class_select_panel() -> void:
	_class_select_panel = PanelContainer.new()
	_class_select_panel.visible = false
	_class_select_panel.custom_minimum_size = Vector2(680, 0)
	_class_select_panel.set_anchors_preset(Control.PRESET_CENTER)
	_class_select_panel.anchor_left = 0.5
	_class_select_panel.anchor_top = 0.5
	_class_select_panel.anchor_right = 0.5
	_class_select_panel.anchor_bottom = 0.5
	_class_select_panel.offset_left = -340.0
	_class_select_panel.offset_top = -300.0
	_class_select_panel.offset_right = 340.0
	_class_select_panel.offset_bottom = 300.0
	_menu_root.add_child(_class_select_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	_class_select_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Choose Class"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.952941, 0.823529, 0.478431, 1.0))
	vbox.add_child(title)

	var grid := GridContainer.new()
	_class_select_grid = grid
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	vbox.add_child(grid)

	for class_def in ClassCatalogScript.get_all_classes():
		var class_id := str(class_def.get("id", "warrior"))
		if not ClassCatalogScript.is_unlocked(class_id):
			continue
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(290, 90)
		btn.add_theme_font_size_override("font_size", 17)
		var icon := str(class_def.get("icon_text", "?"))
		var name_text := str(class_def.get("title", class_id))
		var desc := str(class_def.get("description", ""))
		btn.text = "%s  %s\n%s" % [icon, name_text, desc]
		btn.clip_text = false
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.modulate = ClassCatalogScript.rarity_color_for(class_id)
		btn.pressed.connect(_on_class_selected.bind(class_id))
		grid.add_child(btn)

	var back_btn := Button.new()
	back_btn.custom_minimum_size = Vector2(0, 50)
	back_btn.text = "Back"
	back_btn.pressed.connect(func():
		_class_select_panel.visible = false
		_pending_level_id = ""
	)
	vbox.add_child(back_btn)

func _refresh_class_select_grid() -> void:
	if _class_select_grid == null:
		return
	_clear_container(_class_select_grid)
	for class_def in ClassCatalogScript.get_all_classes():
		var class_id := str(class_def.get("id", "warrior"))
		if not ClassCatalogScript.is_unlocked(class_id):
			continue
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(290, 90)
		btn.add_theme_font_size_override("font_size", 17)
		var icon := str(class_def.get("icon_text", "?"))
		var name_text := str(class_def.get("title", class_id))
		var desc := str(class_def.get("description", ""))
		btn.text = "%s  %s\n%s" % [icon, name_text, desc]
		btn.clip_text = false
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.modulate = ClassCatalogScript.rarity_color_for(class_id)
		btn.pressed.connect(_on_class_selected.bind(class_id))
		_class_select_grid.add_child(btn)

func _on_class_selected(class_id: String) -> void:
	GameState.selected_class = class_id
	_class_select_panel.visible = false
	if _pending_level_id != "":
		_start_level_direct(_pending_level_id)
		_pending_level_id = ""

func _open_crypt_panel() -> void:
	if _crypt_panel == null:
		_show_menu()
		return
	_crypt_active_tab = "equipment"
	_layout_crypt_panel()
	if _crypt_backdrop != null:
		_crypt_backdrop.visible = true
	_crypt_panel.visible = true
	_menu_root.visible = true
	_crypt_skulls_label.text = "Skulls: %d" % GameState.skulls
	_crypt_tokens_label.text = "Tokens: %d" % GameState.boss_tokens
	_crypt_switch_tab("equipment")

func _crypt_switch_tab(tab_id: String) -> void:
	_crypt_active_tab = tab_id
	for raw_id in _crypt_tab_buttons.keys():
		var btn: Button = _crypt_tab_buttons[str(raw_id)]
		btn.button_pressed = str(raw_id) == tab_id
	_clear_container(_crypt_content_box)
	match tab_id:
		"equipment": _build_crypt_equipment_tab()
		"classes":   _build_crypt_classes_tab()
		"skills":    _build_crypt_skills_tab()

func _on_crypt_play_pressed() -> void:
	if _crypt_backdrop != null:
		_crypt_backdrop.visible = false
	_crypt_panel.visible = false
	_show_menu()

func _build_crypt_equipment_tab() -> void:
	var skull_header := Label.new()
	skull_header.text = "Unlock items to add them to the in-run shop. Base items are always available."
	skull_header.add_theme_color_override("font_color", Color(0.70, 0.70, 0.70, 1.0))
	skull_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skull_header.add_theme_font_size_override("font_size", 13)
	_crypt_content_box.add_child(skull_header)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_crypt_content_box.add_child(grid)

	# Sort: available/unlocked first, then ascending rarity (common → mythic)
	var all_items := EquipmentCatalogScript.get_all_items("rarity")
	all_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_av := bool(a.get("shop_enabled", false)) or GameState.unlocked_item_ids.has(str(a.get("id", "")))
		var b_av := bool(b.get("shop_enabled", false)) or GameState.unlocked_item_ids.has(str(b.get("id", "")))
		if a_av != b_av:
			return a_av
		return EquipmentCatalogScript.rarity_rank(str(a.get("rarity", "common"))) < EquipmentCatalogScript.rarity_rank(str(b.get("rarity", "common")))
	)
	for item in all_items:
		grid.add_child(_make_crypt_item_card(item))

func _make_crypt_item_card(item: Dictionary) -> PanelContainer:
	var item_id := str(item.get("id", ""))
	var rarity := str(item.get("rarity", "common"))
	var is_available := bool(item.get("shop_enabled", false)) or GameState.unlocked_item_ids.has(item_id)
	var cost := EquipmentCatalogScript.skull_cost_for_rarity(rarity)
	var title := Localization.item_name(item_id, str(item.get("title", "Item")))
	var rarity_color := EquipmentCatalogScript.rarity_color(rarity)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.07, 0.10, 0.97) if not is_available else Color(0.07, 0.11, 0.09, 0.97)
	style.border_color = rarity_color if is_available else rarity_color * Color(0.55, 0.55, 0.55, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)

	# Icon column
	var icon_path := str(item.get("icon_path", ""))
	var icon_tex := _load_ui_texture(icon_path)
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(36, 36)
		icon.texture = icon_tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = rarity_color if is_available else Color(0.55, 0.55, 0.55, 1.0)
		hbox.add_child(icon)

	# Text column
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(vbox)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color",
		Color(0.96, 0.93, 0.98, 1.0) if is_available else Color(0.65, 0.63, 0.68, 1.0))
	vbox.add_child(title_label)

	var rarity_label := Label.new()
	rarity_label.text = rarity.capitalize()
	rarity_label.add_theme_font_size_override("font_size", 12)
	rarity_label.add_theme_color_override("font_color",
		rarity_color if is_available else rarity_color * Color(0.6, 0.6, 0.6, 1.0))
	vbox.add_child(rarity_label)

	if is_available:
		var status := Label.new()
		status.text = "In shop"
		status.add_theme_font_size_override("font_size", 12)
		status.add_theme_color_override("font_color", Color(0.48, 0.88, 0.58, 1.0))
		vbox.add_child(status)
	else:
		var action_btn := Button.new()
		action_btn.custom_minimum_size = Vector2(0, 28)
		action_btn.add_theme_font_size_override("font_size", 12)
		if GameState.skulls >= cost:
			action_btn.text = "Unlock  %d 💀" % cost
			action_btn.pressed.connect(_unlock_item.bind(item_id, cost))
		else:
			action_btn.disabled = true
			action_btn.text = "%d 💀 needed" % cost
			action_btn.modulate = Color(0.6, 0.6, 0.6, 1.0)
		vbox.add_child(action_btn)
	return panel

func _unlock_item(item_id: String, cost: int) -> void:
	if GameState.skulls < cost:
		return
	if GameState.unlocked_item_ids.has(item_id):
		return
	GameState.skulls -= cost
	GameState.unlocked_item_ids.append(item_id)
	SaveSystem.save()
	_crypt_skulls_label.text = "Skulls: %d" % GameState.skulls
	_crypt_switch_tab("equipment")

func _layout_crypt_panel() -> void:
	if _crypt_panel == null or _menu_root == null:
		return
	var viewport_size := _menu_root.size
	var horizontal_margin := 18.0
	var vertical_margin := 18.0
	if viewport_size.x >= 1100.0:
		horizontal_margin = 44.0
	elif viewport_size.x >= 860.0:
		horizontal_margin = 28.0
	if viewport_size.y >= 980.0:
		vertical_margin = 26.0
	elif viewport_size.y <= 760.0:
		vertical_margin = 12.0
	_crypt_panel.offset_left = horizontal_margin
	_crypt_panel.offset_top = vertical_margin
	_crypt_panel.offset_right = -horizontal_margin
	_crypt_panel.offset_bottom = -vertical_margin
	if _crypt_scroll != null:
		if viewport_size.y >= 980.0:
			_crypt_scroll.custom_minimum_size = Vector2(0, 460)
		elif viewport_size.y >= 820.0:
			_crypt_scroll.custom_minimum_size = Vector2(0, 380)
		else:
			_crypt_scroll.custom_minimum_size = Vector2(0, 320)

func _build_crypt_classes_tab() -> void:
	var header := Label.new()
	header.text = "Earn Boss Tokens by killing bosses. Use tokens to unlock new classes."
	header.add_theme_color_override("font_color", Color(0.70, 0.70, 0.70, 1.0))
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_theme_font_size_override("font_size", 13)
	_crypt_content_box.add_child(header)

	var vlist := VBoxContainer.new()
	vlist.add_theme_constant_override("separation", 10)
	_crypt_content_box.add_child(vlist)

	for class_def in ClassCatalogScript.get_all_classes():
		vlist.add_child(_make_crypt_class_card(class_def))

func _make_crypt_class_card(class_def: Dictionary) -> PanelContainer:
	var class_id := str(class_def.get("id", "warrior"))
	var cost := int(class_def.get("token_cost", 0))
	var is_unlocked := ClassCatalogScript.is_unlocked(class_id)
	var is_selected := GameState.selected_class == class_id
	var class_color := ClassCatalogScript.rarity_color_for(class_id)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.08, 0.14, 0.97) if is_unlocked else Color(0.08, 0.07, 0.10, 0.97)
	style.border_color = class_color if is_unlocked else class_color * Color(0.45, 0.45, 0.45, 1.0)
	style.border_width_left = 3 if is_selected else 2
	style.border_width_top = 3 if is_selected else 2
	style.border_width_right = 3 if is_selected else 2
	style.border_width_bottom = 3 if is_selected else 2
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(m)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	m.add_child(hbox)

	# Left: icon
	var icon_label := Label.new()
	icon_label.text = str(class_def.get("icon_text", "?"))
	icon_label.custom_minimum_size = Vector2(48, 0)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.add_theme_color_override("font_color", class_color if is_unlocked else class_color * Color(0.5, 0.5, 0.5, 1.0))
	hbox.add_child(icon_label)

	# Middle: name + description
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	vbox.add_child(name_row)

	var name_label := Label.new()
	name_label.text = str(class_def.get("title", class_id))
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color",
		Color(0.952941, 0.823529, 0.478431, 1.0) if is_unlocked else Color(0.55, 0.52, 0.50, 1.0))
	name_row.add_child(name_label)

	if is_selected:
		var selected_badge := Label.new()
		selected_badge.text = "▶ Active"
		selected_badge.add_theme_font_size_override("font_size", 13)
		selected_badge.add_theme_color_override("font_color", Color(0.48, 0.88, 0.58, 1.0))
		name_row.add_child(selected_badge)

	var desc_label := Label.new()
	desc_label.text = str(class_def.get("description", ""))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color",
		Color(0.82, 0.82, 0.82, 1.0) if is_unlocked else Color(0.50, 0.50, 0.50, 1.0))
	vbox.add_child(desc_label)

	# Right: action button
	var action_btn := Button.new()
	action_btn.custom_minimum_size = Vector2(110, 40)
	action_btn.add_theme_font_size_override("font_size", 15)

	if is_unlocked and is_selected:
		action_btn.text = "Active"
		action_btn.disabled = true
	elif is_unlocked:
		action_btn.text = "Select"
		action_btn.pressed.connect(_select_class.bind(class_id, panel))
	elif GameState.boss_tokens >= cost:
		action_btn.text = "Unlock\n%d token%s" % [cost, "s" if cost > 1 else ""]
		action_btn.pressed.connect(_unlock_class.bind(class_id, cost, action_btn, panel))
	else:
		action_btn.text = "🔒 %d token%s" % [cost, "s" if cost > 1 else ""]
		action_btn.disabled = true
		action_btn.modulate = Color(0.55, 0.55, 0.55, 1.0)

	hbox.add_child(action_btn)
	return panel

func _unlock_class(class_id: String, cost: int, btn: Button, panel: Node) -> void:
	if GameState.boss_tokens < cost:
		return
	GameState.boss_tokens -= cost
	GameState.unlocked_classes.append(class_id)
	SaveSystem.save()
	_crypt_tokens_label.text = "Tokens: %d" % GameState.boss_tokens
	btn.text = "Select"
	btn.set_pressed_no_signal(false)
	btn.pressed.disconnect(_unlock_class.bind(class_id, cost, btn, panel))
	btn.pressed.connect(_select_class.bind(class_id, panel))

func _select_class(class_id: String, _panel: Node) -> void:
	GameState.selected_class = class_id
	SaveSystem.save()
	_crypt_switch_tab("classes")

func _build_crypt_skills_tab() -> void:
	var header := Label.new()
	header.text = Localization.t("crypt.skills.header")
	header.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78, 1.0))
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_crypt_content_box.add_child(header)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	_crypt_content_box.add_child(grid)

	for skill in SkillCatalogScript.get_all_skills():
		grid.add_child(_make_crypt_skill_card(skill))

func _make_crypt_skill_card(skill: Dictionary) -> Control:
	var skill_id := str(skill.get("id", ""))
	const SKILL_COST := 20
	var in_pool := GameState.skill_pool_ids.has(skill_id)
	var title := Localization.skill_name(skill_id, str(skill.get("title", skill_id)))
	var icon := Localization.skill_icon_text(skill_id, str(skill.get("icon_text", "*")))
	var desc := Localization.skill_description(skill_id, str(skill.get("description", "")))
	var color: Color = skill.get("color", Color(0.7, 0.7, 0.7, 1.0))

	# Card container with border
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.10, 0.10, 0.15, 0.95)
	card_style.border_color = color.darkened(0.3) if in_pool else Color(0.25, 0.25, 0.30, 1.0)
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card_style.content_margin_left = 8
	card_style.content_margin_top = 8
	card_style.content_margin_right = 8
	card_style.content_margin_bottom = 8
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", card_style)

	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 6)
	card.add_child(panel)

	# Top row: icon + name + level badge
	var top_row := HBoxContainer.new()
	panel.add_child(top_row)

	var icon_lbl := Label.new()
	icon_lbl.text = icon
	icon_lbl.add_theme_font_size_override("font_size", 18)
	icon_lbl.add_theme_color_override("font_color", color)
	top_row.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = "  " + title
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.94, 1.0))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(name_lbl)

	if in_pool:
		var meta_level := int(GameState.skill_levels.get(skill_id, 1))
		var max_level := int(skill.get("max_level", 5))
		var badge := Label.new()
		badge.text = "Lv %d/%d" % [meta_level, max_level]
		badge.add_theme_font_size_override("font_size", 11)
		badge.add_theme_color_override("font_color",
			Color(1.0, 0.85, 0.3) if meta_level >= max_level else Color(0.52, 1.0, 0.62))
		top_row.add_child(badge)

	# Description
	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.75))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(desc_lbl)

	# Action button
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 32)
	btn.add_theme_font_size_override("font_size", 12)
	if in_pool:
		var cur_ml := int(GameState.skill_levels.get(skill_id, 1))
		var max_ml := int(skill.get("max_level", 5))
		btn.text = Localization.t("crypt.skills.max_level") if cur_ml >= max_ml else Localization.t("crypt.skills.in_pool")
		btn.disabled = true
		btn.modulate = Color(0.6, 0.9, 0.6, 1.0)
	elif GameState.skulls >= SKILL_COST:
		btn.text = Localization.t("crypt.skills.unlock", [SKILL_COST])
		btn.add_theme_color_override("font_color", Color(0.95, 0.94, 1.0))
		btn.tooltip_text = desc
		btn.pressed.connect(_unlock_skill.bind(skill_id, SKILL_COST, btn))
	else:
		btn.text = Localization.t("crypt.skills.unlock_need", [SKILL_COST])
		btn.disabled = true
		btn.modulate = Color(0.45, 0.45, 0.45, 1.0)
	panel.add_child(btn)

	# Upgrade button (only for skills in pool that aren't max level)
	if in_pool:
		var meta_level := int(GameState.skill_levels.get(skill_id, 1))
		var max_level := int(skill.get("max_level", 5))
		var upgrades: Array = SkillCatalogScript.DEFINITIONS.get(skill_id, {}).get("upgrades", [])
		if meta_level < max_level and upgrades.size() >= meta_level:
			var next_upgrade: Dictionary = upgrades[meta_level - 1]
			var next_desc := Localization.t(str(next_upgrade.get("desc_key", "")), [])
			var cost := SkillCatalogScript.upgrade_cost(SkillCatalogScript.DEFINITIONS.get(skill_id, {}), meta_level + 1)
			var upgrade_btn := Button.new()
			upgrade_btn.custom_minimum_size = Vector2(0, 32)
			upgrade_btn.add_theme_font_size_override("font_size", 12)
			if GameState.skulls >= cost:
				upgrade_btn.text = "▲ %s  (%d 💀)" % [next_desc, cost]
				upgrade_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
				upgrade_btn.pressed.connect(_upgrade_skill.bind(skill_id, cost))
			else:
				upgrade_btn.text = "▲ %s  (%d 💀 нужно)" % [next_desc, cost]
				upgrade_btn.disabled = true
				upgrade_btn.modulate = Color(0.50, 0.50, 0.50, 1.0)
			panel.add_child(upgrade_btn)

	return card

func _unlock_skill(skill_id: String, cost: int, btn: Button) -> void:
	if GameState.skulls < cost:
		return
	if GameState.skill_pool_ids.has(skill_id):
		return
	GameState.skulls -= cost
	GameState.skill_pool_ids.append(skill_id)
	GameState.unlocked_skill_ids.append(skill_id)
	SaveSystem.save()
	_crypt_skulls_label.text = "Skulls: %d" % GameState.skulls
	_crypt_switch_tab("skills")

func _upgrade_skill(skill_id: String, cost: int) -> void:
	if GameState.skulls < cost:
		return
	var base_def: Dictionary = SkillCatalogScript.DEFINITIONS.get(skill_id, {})
	var max_level := int(base_def.get("max_level", 5))
	var current_level := int(GameState.skill_levels.get(skill_id, 1))
	if current_level >= max_level:
		return
	GameState.skulls -= cost
	GameState.skill_levels[skill_id] = current_level + 1
	SaveSystem.save()
	_crypt_skulls_label.text = "Skulls: %d" % GameState.skulls
	_crypt_switch_tab("skills")

func _refresh_items_panel_text() -> void:
	if _items_panel == null:
		return
	if _items_title != null:
		_items_title.text = Localization.t("menu.items.title")
	if _items_close_button != null:
		_items_close_button.text = Localization.t("menu.close")
	if _items_sort_buttons.has("rarity"):
		_items_sort_buttons["rarity"].text = Localization.t("menu.items.sort.rarity")
	if _items_sort_buttons.has("name"):
		_items_sort_buttons["name"].text = Localization.t("menu.items.sort.name")
	if _items_sort_buttons.has("slot"):
		_items_sort_buttons["slot"].text = Localization.t("menu.items.sort.slot")
	if _items_sort_buttons.has("type"):
		_items_sort_buttons["type"].text = Localization.t("menu.items.sort.type")
	var sort_label := Localization.t("menu.items.sort.%s" % _item_sort_key)
	_items_summary.text = Localization.t("menu.items.summary", [EquipmentCatalogScript.get_all_items().size(), sort_label])
	if _items_hover_title != null and _items_hover_title.text == "":
		_items_hover_title.text = Localization.t("menu.items.hover_title")
	if _items_hover_meta != null and _items_hover_meta.text == "":
		_items_hover_meta.text = Localization.t("menu.items.hover_meta")
	if _items_hover_description != null and _items_hover_description.text == "":
		_items_hover_description.text = Localization.t("menu.items.hover_text")
	for raw_sort_key in _items_sort_buttons.keys():
		var sort_key := str(raw_sort_key)
		var button: Button = _items_sort_buttons[sort_key]
		button.button_pressed = sort_key == _item_sort_key
	if _items_panel.visible:
		_refresh_items_grid()

func _open_items_panel() -> void:
	if _items_panel == null:
		return
	_layout_items_panel()
	if _items_backdrop != null:
		_items_backdrop.visible = true
	_items_panel.visible = true
	_level_list_panel.visible = false
	_skills_panel.visible = false
	_editor_panel.visible = false
	_refresh_items_panel_text()
	_refresh_items_grid()

func _close_items_panel() -> void:
	if _items_backdrop != null:
		_items_backdrop.visible = false
	if _items_panel != null:
		_items_panel.visible = false

func _set_item_sort(sort_key: String) -> void:
	_item_sort_key = sort_key
	_refresh_items_panel_text()
	_refresh_items_grid()

func _refresh_items_grid() -> void:
	if _items_grid == null:
		return
	_layout_items_panel()
	_clear_container(_items_grid)
	var items := EquipmentCatalogScript.get_all_items(_item_sort_key)
	for item in items:
		_items_grid.add_child(_make_item_card(item))
	if not items.is_empty():
		_show_item_hover(items[0])

func _make_item_card(item: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(172, 118)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.07, 0.09, 0.96)
	style.border_color = EquipmentCatalogScript.rarity_color(str(item.get("rarity", "common")))
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	card.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var icon_path := str(item.get("icon_path", ""))
	var icon_tex := _load_ui_texture(icon_path)
	var title := Localization.item_name(str(item.get("id", "")), str(item.get("title", "Item")))
	var rarity := Localization.item_rarity(str(item.get("rarity", "common")), str(item.get("rarity", "common")).capitalize())
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(42, 42)
		icon.texture = icon_tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(icon)

	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.98, 1.0))
	box.add_child(title_label)

	var rarity_label := Label.new()
	rarity_label.text = rarity
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 14)
	rarity_label.add_theme_color_override("font_color", EquipmentCatalogScript.rarity_color(str(item.get("rarity", "common"))))
	box.add_child(rarity_label)

	card.mouse_entered.connect(_show_item_hover.bind(item))
	card.focus_entered.connect(_show_item_hover.bind(item))
	return card

func _show_item_hover(item: Dictionary) -> void:
	if _items_hover_title != null:
		_items_hover_title.text = Localization.item_name(str(item.get("id", "")), str(item.get("title", Localization.t("menu.items.hover_title"))))
	var rarity_text := Localization.item_rarity(str(item.get("rarity", "common")), str(item.get("rarity", "common")).capitalize())
	var slot_text := Localization.item_slot(str(item.get("slot", "")), str(item.get("slot", "")).capitalize())
	var type_text := Localization.item_type(str(item.get("item_type", "hybrid")), str(item.get("item_type", "hybrid")).capitalize())
	if _items_hover_meta != null:
		_items_hover_meta.text = "%s  •  %s  •  %s" % [rarity_text, slot_text, type_text]
	if _items_hover_description != null:
		var lines := [Localization.item_description(str(item.get("id", "")), str(item.get("description", "")))]
		var bonuses := SkillCatalogScript.describe_bonus_block(EquipmentCatalogScript.bonus_dict(item))
		if not bonuses.is_empty():
			lines.append(" | ".join(PackedStringArray(bonuses)))
		_items_hover_description.text = "\n".join(PackedStringArray(lines))

func _load_ui_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if not _ui_texture_cache.has(path):
		_ui_texture_cache[path] = load(path)
	var tex = _ui_texture_cache[path]
	return tex if tex is Texture2D else null

func _layout_items_panel() -> void:
	if _items_panel == null or _menu_root == null:
		return
	var viewport_size := _menu_root.size
	var horizontal_margin := 18.0
	var vertical_margin := 18.0
	if viewport_size.x >= 1100.0:
		horizontal_margin = 42.0
	elif viewport_size.x >= 860.0:
		horizontal_margin = 28.0
	if viewport_size.y >= 980.0:
		vertical_margin = 28.0
	elif viewport_size.y <= 760.0:
		vertical_margin = 12.0
	_items_panel.offset_left = horizontal_margin
	_items_panel.offset_top = vertical_margin
	_items_panel.offset_right = -horizontal_margin
	_items_panel.offset_bottom = -vertical_margin
	if _items_grid != null:
		if viewport_size.x >= 1180.0:
			_items_grid.columns = 5
		elif viewport_size.x >= 930.0:
			_items_grid.columns = 4
		elif viewport_size.x >= 720.0:
			_items_grid.columns = 3
		else:
			_items_grid.columns = 2
