extends RefCounted
class_name EnemyScalingCatalog

const TURN_THRESHOLDS := [
	{"turn": 10, "attack_min": 1, "attack_max": 1, "defense_min": 0, "defense_max": 0, "hp_min": 4, "hp_max": 4},
	{"turn": 20, "attack_min": 1, "attack_max": 1, "defense_min": 0, "defense_max": 0, "hp_min": 4, "hp_max": 4},
	{"turn": 30, "attack_min": 1, "attack_max": 1, "defense_min": 0, "defense_max": 0, "hp_min": 4, "hp_max": 4},
	{"turn": 40, "attack_min": 1, "attack_max": 1, "defense_min": 1, "defense_max": 1, "hp_min": 4, "hp_max": 4},
	{"turn": 50, "attack_min": 1, "attack_max": 1, "defense_min": 1, "defense_max": 1, "hp_min": 4, "hp_max": 4},
	{"turn": 60, "attack_min": 1, "attack_max": 1, "defense_min": 1, "defense_max": 2, "hp_min": 4, "hp_max": 6},
	{"turn": 70, "attack_min": 2, "attack_max": 2, "defense_min": 2, "defense_max": 2, "hp_min": 4, "hp_max": 6},
	{"turn": 80, "attack_min": 2, "attack_max": 2, "defense_min": 2, "defense_max": 2, "hp_min": 4, "hp_max": 8},
	{"turn": 90, "attack_min": 2, "attack_max": 2, "defense_min": 2, "defense_max": 2, "hp_min": 6, "hp_max": 8},
	{"turn": 100, "attack_min": 2, "attack_max": 2, "defense_min": 2, "defense_max": 3, "hp_min": 7, "hp_max": 9},
	{"turn": 110, "attack_min": 2, "attack_max": 3, "defense_min": 3, "defense_max": 3, "hp_min": 7, "hp_max": 11},
	{"turn": 120, "attack_min": 3, "attack_max": 3, "defense_min": 3, "defense_max": 4, "hp_min": 8, "hp_max": 12},
	{"turn": 130, "attack_min": 3, "attack_max": 3, "defense_min": 3, "defense_max": 4, "hp_min": 8, "hp_max": 13},
	{"turn": 140, "attack_min": 3, "attack_max": 4, "defense_min": 3, "defense_max": 4, "hp_min": 9, "hp_max": 14},
	{"turn": 150, "attack_min": 3, "attack_max": 4, "defense_min": 4, "defense_max": 4, "hp_min": 11, "hp_max": 15},
	{"turn": 160, "attack_min": 4, "attack_max": 4, "defense_min": 4, "defense_max": 4, "hp_min": 11, "hp_max": 15},
	{"turn": 170, "attack_min": 4, "attack_max": 4, "defense_min": 4, "defense_max": 5, "hp_min": 12, "hp_max": 15},
	{"turn": 180, "attack_min": 4, "attack_max": 4, "defense_min": 5, "defense_max": 5, "hp_min": 12, "hp_max": 15},
	{"turn": 190, "attack_min": 4, "attack_max": 5, "defense_min": 5, "defense_max": 5, "hp_min": 12, "hp_max": 19},
	{"turn": 200, "attack_min": 5, "attack_max": 5, "defense_min": 5, "defense_max": 6, "hp_min": 13, "hp_max": 20},
	{"turn": 210, "attack_min": 5, "attack_max": 5, "defense_min": 5, "defense_max": 6, "hp_min": 14, "hp_max": 20},
	{"turn": 220, "attack_min": 5, "attack_max": 6, "defense_min": 6, "defense_max": 7, "hp_min": 16, "hp_max": 20},
	{"turn": 230, "attack_min": 5, "attack_max": 6, "defense_min": 7, "defense_max": 7, "hp_min": 16, "hp_max": 21},
	{"turn": 240, "attack_min": 5, "attack_max": 6, "defense_min": 7, "defense_max": 7, "hp_min": 16, "hp_max": 21},
	{"turn": 250, "attack_min": 6, "attack_max": 6, "defense_min": 7, "defense_max": 8, "hp_min": 16, "hp_max": 21},
	{"turn": 260, "attack_min": 6, "attack_max": 7, "defense_min": 7, "defense_max": 8, "hp_min": 17, "hp_max": 21},
	{"turn": 270, "attack_min": 6, "attack_max": 7, "defense_min": 7, "defense_max": 9, "hp_min": 17, "hp_max": 26},
	{"turn": 280, "attack_min": 7, "attack_max": 8, "defense_min": 7, "defense_max": 9, "hp_min": 21, "hp_max": 28},
	{"turn": 290, "attack_min": 7, "attack_max": 9, "defense_min": 8, "defense_max": 9, "hp_min": 21, "hp_max": 28},
	{"turn": 300, "attack_min": 7, "attack_max": 9, "defense_min": 8, "defense_max": 9, "hp_min": 22, "hp_max": 30},
	{"turn": 310, "attack_min": 7, "attack_max": 9, "defense_min": 9, "defense_max": 10, "hp_min": 22, "hp_max": 31},
	{"turn": 320, "attack_min": 8, "attack_max": 9, "defense_min": 9, "defense_max": 10, "hp_min": 23, "hp_max": 31},
	{"turn": 330, "attack_min": 8, "attack_max": 9, "defense_min": 9, "defense_max": 11, "hp_min": 24, "hp_max": 32},
	{"turn": 340, "attack_min": 8, "attack_max": 9, "defense_min": 9, "defense_max": 11, "hp_min": 24, "hp_max": 34},
]

static func get_threshold(total_turns: int) -> Dictionary:
	var threshold: Dictionary = TURN_THRESHOLDS[0]
	for entry in TURN_THRESHOLDS:
		if total_turns >= int(entry.get("turn", 0)):
			threshold = entry
		else:
			break
	return threshold.duplicate(true)

static func get_tier_index(total_turns: int) -> int:
	var tier_index := 0
	for i in range(TURN_THRESHOLDS.size()):
		if total_turns >= int(TURN_THRESHOLDS[i].get("turn", 0)):
			tier_index = i
		else:
			break
	return tier_index

static func build_runtime_wave(base_wave: Dictionary, total_turns: int) -> Dictionary:
	var runtime_wave := base_wave.duplicate(true)
	var threshold := get_threshold(total_turns)
	var tier_index := get_tier_index(total_turns)
	var base_profile: Dictionary = runtime_wave.get("base_monster_profile", runtime_wave.get("monster_profile", {})).duplicate(true)
	var base_spawn_chance := float(runtime_wave.get("base_enemy_spawn_chance", runtime_wave.get("enemy_spawn_chance", 0.0)))

	base_profile["progression_turn"] = int(threshold.get("turn", 10))
	base_profile["progression_attack_min"] = int(threshold.get("attack_min", 1))
	base_profile["progression_attack_max"] = int(threshold.get("attack_max", 1))
	base_profile["progression_defense_min"] = int(threshold.get("defense_min", 0))
	base_profile["progression_defense_max"] = int(threshold.get("defense_max", 0))
	base_profile["progression_hp_min"] = int(threshold.get("hp_min", 1))
	base_profile["progression_hp_max"] = int(threshold.get("hp_max", 1))
	base_profile["progression_tier_index"] = tier_index

	runtime_wave["monster_profile"] = base_profile
	runtime_wave["enemy_spawn_chance"] = clampf(base_spawn_chance * (1.0 + float(tier_index) * 0.05), 0.0, 0.92)
	return runtime_wave
