extends RefCounted
class_name WaveCatalog

# Генератор правил волн. Позже сюда можно вынести готовые главы, биомы,
# элитные волны и таблицы боссов.

const DEFAULT_TURNS := 7
const DEFAULT_BOSS_ID := "bone_lord"
const WaveTypeScript := preload("res://scripts/data/WaveType.gd")

static func get_wave(index: int):
	return get_wave_for_level({}, index)

static func get_wave_for_level(level_config: Dictionary, index: int):
	var safe_index: int = maxi(1, index)
	var turns := int(level_config.get("turns_per_wave", DEFAULT_TURNS))
	var spawn_chance: float = clampf(
		float(level_config.get("enemy_spawn_start", 0.11)) + float(safe_index - 1) * float(level_config.get("enemy_spawn_step", 0.015)),
		0.0,
		float(level_config.get("enemy_spawn_max", 0.28))
	)
	var boss_chance: float = 0.0
	var boss_start_wave := int(level_config.get("boss_start_wave", 2))
	if safe_index >= boss_start_wave:
		boss_chance = clampf(
			float(level_config.get("boss_base_chance", 0.24)) + float(safe_index - boss_start_wave) * float(level_config.get("boss_chance_step", 0.04)),
			0.0,
			float(level_config.get("boss_chance_max", 0.55))
		)

	return WaveTypeScript.new({
		"index": safe_index,
		"turns": turns,
		"enemy_spawn_chance": spawn_chance,
		"base_enemy_spawn_chance": spawn_chance,
		"monster_weights": _monster_weights_for_wave(level_config, safe_index),
		"boss_chance": boss_chance,
		"boss_id": str(level_config.get("boss_id", DEFAULT_BOSS_ID)),
		"boss_turns": int(level_config.get("boss_turns", 5)),
		"monster_profile": _monster_profile_for_wave(level_config, safe_index),
		"base_monster_profile": _monster_profile_for_wave(level_config, safe_index),
	})

static func _monster_weights_for_wave(level_config: Dictionary, index: int) -> Dictionary:
	var configured = level_config.get("monster_weights", {})
	if configured is Dictionary and not configured.is_empty():
		return configured.duplicate(true)
	var weights := {
		"skeleton": 55,
		"bandana_skeleton": 14,
		"vampire": 0,
	}
	if index >= 2:
		weights["bandana_skeleton"] = 20
	if index >= 3:
		weights["vampire"] = 10
		weights["skeleton"] = 45
	if index >= 5:
		weights["vampire"] = 16
		weights["bandana_skeleton"] = 24
		weights["skeleton"] = 38
	return weights

static func _monster_profile_for_wave(level_config: Dictionary, index: int) -> Dictionary:
	var base: Dictionary = {}
	var raw_profile = level_config.get("monster_profile", null)
	if raw_profile is Dictionary:
		base = raw_profile.duplicate(true)
	var step_data: Dictionary = {}
	var raw_step_data = level_config.get("wave_power_step", null)
	if raw_step_data is Dictionary:
		step_data = raw_step_data.duplicate(true)
	var wave_offset := maxi(0, index - 1)
	base["hp_scale"] = float(base.get("hp_scale", 1.0)) + float(step_data.get("hp_scale_step", 0.0)) * wave_offset
	base["damage_scale"] = float(base.get("damage_scale", 1.0)) + float(step_data.get("damage_scale_step", 0.0)) * wave_offset
	base["xp_scale"] = float(base.get("xp_scale", 1.0)) + float(step_data.get("xp_scale_step", 0.0)) * wave_offset
	base["gold_scale"] = float(base.get("gold_scale", 1.0)) + float(step_data.get("gold_scale_step", 0.0)) * wave_offset
	base["timer_delta"] = int(base.get("timer_delta", 0)) + int(step_data.get("timer_delta_step", 0)) * wave_offset
	return base
