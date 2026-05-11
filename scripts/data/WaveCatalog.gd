extends RefCounted
class_name WaveCatalog

# Генератор правил волн. Позже сюда можно вынести готовые главы, биомы,
# элитные волны и таблицы боссов.

const DEFAULT_TURNS := 7
const DEFAULT_BOSS_ID := "bone_lord"
const WaveTypeScript := preload("res://scripts/data/WaveType.gd")

static func get_wave(index: int):
	var safe_index: int = maxi(1, index)
	var spawn_chance: float = clampf(0.11 + float(safe_index - 1) * 0.015, 0.11, 0.28)
	var boss_chance: float = 0.0
	if safe_index >= 2:
		boss_chance = clampf(0.24 + float(safe_index - 2) * 0.04, 0.24, 0.55)

	return WaveTypeScript.new({
		"index": safe_index,
		"turns": DEFAULT_TURNS,
		"enemy_spawn_chance": spawn_chance,
		"monster_weights": _monster_weights_for_wave(safe_index),
		"boss_chance": boss_chance,
		"boss_id": DEFAULT_BOSS_ID,
		"boss_turns": 5,
	})

static func _monster_weights_for_wave(index: int) -> Dictionary:
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
