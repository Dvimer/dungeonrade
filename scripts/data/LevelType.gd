extends RefCounted
class_name LevelType

var id: String = "level_1"
var order: int = 1
var title: String = "Level 1"
var description: String = ""
var wave_count: int = 3
var turns_per_wave: int = 7
var max_shield: int = 5
var shop_charge_needed: int = 45
var enemy_spawn_start: float = 0.11
var enemy_spawn_step: float = 0.015
var enemy_spawn_max: float = 0.28
var boss_start_wave: int = 2
var boss_base_chance: float = 0.24
var boss_chance_step: float = 0.04
var boss_chance_max: float = 0.55
var boss_id: String = "bone_lord"
var boss_turns: int = 5
var monster_weights: Dictionary = {}
var monster_profile: Dictionary = {}
var wave_power_step: Dictionary = {}
var starting_modifiers: Dictionary = {}

func _init(data: Dictionary = {}) -> void:
	id = str(data.get("id", id)).strip_edges()
	if id == "":
		id = "level_1"
	order = int(data.get("order", order))
	title = str(data.get("title", title))
	description = str(data.get("description", description))
	wave_count = maxi(1, int(data.get("wave_count", wave_count)))
	turns_per_wave = maxi(1, int(data.get("turns_per_wave", turns_per_wave)))
	max_shield = maxi(1, int(data.get("max_shield", max_shield)))
	shop_charge_needed = maxi(1, int(data.get("shop_charge_needed", shop_charge_needed)))
	enemy_spawn_start = clampf(float(data.get("enemy_spawn_start", enemy_spawn_start)), 0.0, 1.0)
	enemy_spawn_step = float(data.get("enemy_spawn_step", enemy_spawn_step))
	enemy_spawn_max = clampf(float(data.get("enemy_spawn_max", enemy_spawn_max)), 0.0, 1.0)
	boss_start_wave = maxi(1, int(data.get("boss_start_wave", boss_start_wave)))
	boss_base_chance = clampf(float(data.get("boss_base_chance", boss_base_chance)), 0.0, 1.0)
	boss_chance_step = float(data.get("boss_chance_step", boss_chance_step))
	boss_chance_max = clampf(float(data.get("boss_chance_max", boss_chance_max)), 0.0, 1.0)
	boss_id = str(data.get("boss_id", boss_id))
	boss_turns = maxi(1, int(data.get("boss_turns", boss_turns)))
	monster_weights = _dup_dict(data.get("monster_weights", monster_weights))
	monster_profile = _dup_dict(data.get("monster_profile", monster_profile))
	wave_power_step = _dup_dict(data.get("wave_power_step", wave_power_step))
	starting_modifiers = _dup_dict(data.get("starting_modifiers", starting_modifiers))

func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"order": order,
		"title": title,
		"description": description,
		"wave_count": wave_count,
		"turns_per_wave": turns_per_wave,
		"max_shield": max_shield,
		"shop_charge_needed": shop_charge_needed,
		"enemy_spawn_start": enemy_spawn_start,
		"enemy_spawn_step": enemy_spawn_step,
		"enemy_spawn_max": enemy_spawn_max,
		"boss_start_wave": boss_start_wave,
		"boss_base_chance": boss_base_chance,
		"boss_chance_step": boss_chance_step,
		"boss_chance_max": boss_chance_max,
		"boss_id": boss_id,
		"boss_turns": boss_turns,
		"monster_weights": monster_weights.duplicate(true),
		"monster_profile": monster_profile.duplicate(true),
		"wave_power_step": wave_power_step.duplicate(true),
		"starting_modifiers": starting_modifiers.duplicate(true),
	}

func _dup_dict(value) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}
