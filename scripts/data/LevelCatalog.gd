extends RefCounted
class_name LevelCatalog

const LevelTypeScript := preload("res://scripts/data/LevelType.gd")

const DEFAULT_LEVELS := [
	{
		"id": "crypt_entry",
		"order": 1,
		"title": "Crypt Entry",
		"description": "Early pressure: even the first crypt demands clean chains and fast scaling.",
		"wave_count": 4,
		"turns_per_wave": 6,
		"max_shield": 4,
		"shop_charge_needed": 18,
		"enemy_spawn_start": 0.16,
		"enemy_spawn_step": 0.025,
		"enemy_spawn_max": 0.32,
		"boss_start_wave": 2,
		"boss_base_chance": 0.30,
		"boss_chance_step": 0.07,
		"boss_chance_max": 0.65,
		"boss_id": "bone_lord",
		"boss_turns": 5,
		"monster_weights": {
			"skeleton": 60,
			"bandana_skeleton": 28,
			"vampire": 0,
		},
		"monster_profile": {
			"hp_scale": 1.0,
			"damage_scale": 1.0,
			"timer_delta": 0,
			"xp_scale": 1.35,
			"gold_scale": 1.10,
		},
		"wave_power_step": {
			"hp_scale_step": 0.18,
			"damage_scale_step": 0.08,
		},
		"starting_modifiers": {},
	},
	{
		"id": "rogue_catacombs",
		"order": 2,
		"title": "Rogue Catacombs",
		"description": "Aggressive rogues crowd the board and punish weak openings.",
		"wave_count": 4,
		"turns_per_wave": 6,
		"max_shield": 4,
		"shop_charge_needed": 20,
		"enemy_spawn_start": 0.18,
		"enemy_spawn_step": 0.03,
		"enemy_spawn_max": 0.36,
		"boss_start_wave": 2,
		"boss_base_chance": 0.38,
		"boss_chance_step": 0.08,
		"boss_chance_max": 0.75,
		"boss_id": "bone_lord",
		"boss_turns": 5,
		"monster_weights": {
			"skeleton": 35,
			"bandana_skeleton": 45,
			"vampire": 0,
		},
		"monster_profile": {
			"hp_scale": 1.15,
			"damage_scale": 1.05,
			"timer_delta": -1,
			"xp_scale": 1.35,
			"gold_scale": 1.15,
		},
		"wave_power_step": {
			"hp_scale_step": 0.18,
			"damage_scale_step": 0.10,
		},
		"starting_modifiers": {},
	},
	{
		"id": "blood_vault",
		"order": 3,
		"title": "Blood Vault",
		"description": "The vault snowballs fast; only a strong build keeps pace with the vampires.",
		"wave_count": 5,
		"turns_per_wave": 5,
		"max_shield": 5,
		"shop_charge_needed": 22,
		"enemy_spawn_start": 0.22,
		"enemy_spawn_step": 0.03,
		"enemy_spawn_max": 0.40,
		"boss_start_wave": 2,
		"boss_base_chance": 0.45,
		"boss_chance_step": 0.10,
		"boss_chance_max": 0.85,
		"boss_id": "bone_lord",
		"boss_turns": 6,
		"monster_weights": {
			"skeleton": 18,
			"bandana_skeleton": 30,
			"vampire": 34,
		},
		"monster_profile": {
			"hp_scale": 1.25,
			"damage_scale": 1.15,
			"timer_delta": 0,
			"xp_scale": 1.45,
			"gold_scale": 1.20,
		},
		"wave_power_step": {
			"hp_scale_step": 0.20,
			"damage_scale_step": 0.12,
		},
		"starting_modifiers": {},
	},
]

static func ensure_initialized() -> void:
	if GameState.level_definitions.is_empty():
		GameState.level_definitions = get_default_levels()
	else:
		GameState.level_definitions = _normalize_levels(GameState.level_definitions)
	if GameState.level_definitions.is_empty():
		GameState.level_definitions = get_default_levels()
	var levels := GameState.level_definitions
	if GameState.unlocked_level_ids.is_empty():
		GameState.unlocked_level_ids = [levels[0]["id"]]
	if GameState.selected_level_id == "":
		GameState.selected_level_id = str(levels[0]["id"])

static func get_default_levels() -> Array:
	var levels := []
	for data in DEFAULT_LEVELS:
		levels.append(LevelTypeScript.new(data).to_dictionary())
	return levels

static func get_levels() -> Array:
	ensure_initialized()
	return _normalize_levels(GameState.level_definitions)

static func get_level(level_id: String) -> Dictionary:
	for level in get_levels():
		if str(level.get("id", "")) == level_id:
			return level.duplicate(true)
	var levels := get_levels()
	if levels.is_empty():
		return {}
	return levels[0].duplicate(true)

static func get_level_by_order(order: int) -> Dictionary:
	for level in get_levels():
		if int(level.get("order", 0)) == order:
			return level.duplicate(true)
	return {}

static func get_first_level() -> Dictionary:
	var levels := get_levels()
	if levels.is_empty():
		return {}
	return levels[0].duplicate(true)

static func get_next_level_id(level_id: String) -> String:
	var levels := get_levels()
	for i in range(levels.size()):
		if str(levels[i].get("id", "")) == level_id:
			if i + 1 < levels.size():
				return str(levels[i + 1].get("id", ""))
			return ""
	return ""

static func get_continue_level_id() -> String:
	ensure_initialized()
	for level in get_levels():
		var level_id := str(level.get("id", ""))
		if GameState.unlocked_level_ids.has(level_id) and not GameState.completed_level_ids.has(level_id):
			return level_id
	if GameState.last_played_level_id != "":
		return GameState.last_played_level_id
	return str(get_first_level().get("id", ""))

static func reset_campaign_progress() -> void:
	var first_level := get_first_level()
	GameState.completed_level_ids.clear()
	GameState.unlocked_level_ids = []
	if not first_level.is_empty():
		var first_id := str(first_level.get("id", ""))
		GameState.unlocked_level_ids.append(first_id)
		GameState.selected_level_id = first_id
		GameState.last_played_level_id = first_id

static func mark_level_completed(level_id: String) -> void:
	ensure_initialized()
	if not GameState.completed_level_ids.has(level_id):
		GameState.completed_level_ids.append(level_id)
	var next_level_id := get_next_level_id(level_id)
	if next_level_id != "" and not GameState.unlocked_level_ids.has(next_level_id):
		GameState.unlocked_level_ids.append(next_level_id)
	GameState.last_played_level_id = next_level_id if next_level_id != "" else level_id

static func upsert_level(raw_data: Dictionary) -> Dictionary:
	ensure_initialized()
	var level := LevelTypeScript.new(raw_data).to_dictionary()
	var levels := get_levels()
	var replaced := false
	for i in range(levels.size()):
		if str(levels[i].get("id", "")) == str(level.get("id", "")):
			levels[i] = level
			replaced = true
			break
	if not replaced:
		levels.append(level)
	GameState.level_definitions = levels
	if not GameState.unlocked_level_ids.has(str(level.get("id", ""))):
		GameState.unlocked_level_ids.append(str(level.get("id", "")))
	return level.duplicate(true)

static func _normalize_levels(raw_levels: Array) -> Array:
	var levels := []
	for raw_level in raw_levels:
		if raw_level is Dictionary:
			levels.append(LevelTypeScript.new(raw_level).to_dictionary())
	levels.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.get("order", 0)) < int(b.get("order", 0)))
	return levels
