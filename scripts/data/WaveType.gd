extends RefCounted
class_name WaveType

# Описание одной волны. Это не состояние боя, а набор правил спавна и финала.

var index: int = 1
var turns: int = 7
var enemy_spawn_chance: float = 0.14
var base_enemy_spawn_chance: float = 0.14
var monster_weights: Dictionary = {}
var monster_profile: Dictionary = {}
var base_monster_profile: Dictionary = {}
var boss_chance: float = 0.0
var boss_id: String = ""
var boss_turns: int = 5

func _init(data: Dictionary = {}) -> void:
	index = int(data.get("index", index))
	turns = int(data.get("turns", turns))
	enemy_spawn_chance = float(data.get("enemy_spawn_chance", enemy_spawn_chance))
	base_enemy_spawn_chance = float(data.get("base_enemy_spawn_chance", enemy_spawn_chance))
	monster_weights = data.get("monster_weights", monster_weights).duplicate(true)
	monster_profile = data.get("monster_profile", monster_profile).duplicate(true)
	base_monster_profile = data.get("base_monster_profile", monster_profile).duplicate(true)
	boss_chance = float(data.get("boss_chance", boss_chance))
	boss_id = str(data.get("boss_id", boss_id))
	boss_turns = int(data.get("boss_turns", boss_turns))

func to_dictionary() -> Dictionary:
	return {
		"index": index,
		"turns": turns,
		"enemy_spawn_chance": enemy_spawn_chance,
		"base_enemy_spawn_chance": base_enemy_spawn_chance,
		"monster_weights": monster_weights.duplicate(true),
		"monster_profile": monster_profile.duplicate(true),
		"base_monster_profile": base_monster_profile.duplicate(true),
		"boss_chance": boss_chance,
		"boss_id": boss_id,
		"boss_turns": boss_turns,
	}
