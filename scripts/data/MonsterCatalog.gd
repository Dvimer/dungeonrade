extends RefCounted
class_name MonsterCatalog

const DEFAULT_MONSTER_ID := "skeleton"

const DEFINITIONS := {
	"skeleton": {
		"id": "skeleton",
		"display_name": "Skeleton",
		"icon_path": "res://assets/icons/monsters/skeleton.svg",
		"hp": 2,
		"dmg": 1,
		"timer": 3,
		"attack_cooldown": 3,
		"remove_on_attack": false,
		"spawn_weight": 50,
		"xp_bonus": 1,
		"gold_bonus": 1,
		"tile_color": Color(0.18, 0.09, 0.20),
		"rim_color": Color(0.58, 0.37, 0.48),
	},
	"bandana_skeleton": {
		"id": "bandana_skeleton",
		"display_name": "Bone Rogue",
		"icon_path": "res://assets/icons/monsters/bandana_skeleton.svg",
		"hp": 3,
		"dmg": 1,
		"timer": 2,
		"attack_cooldown": 3,
		"reset_timer_on_hit": true,
		"hit_timer_reset": 3,
		"remove_on_attack": false,
		"spawn_weight": 18,
		"xp_bonus": 4,
		"gold_bonus": 2,
		"tile_color": Color(0.20, 0.08, 0.11),
		"rim_color": Color(0.78, 0.36, 0.26),
	},
	"vampire": {
		"id": "vampire",
		"display_name": "Vampire",
		"icon_path": "res://assets/icons/monsters/vampire.svg",
		"hp": 5,
		"dmg": 2,
		"timer": 3,
		"attack_cooldown": 3,
		"remove_on_attack": false,
		"heal_on_attack": true,
		"heal_on_attack_ratio": 1.0,
		"spawn_weight": 12,
		"xp_bonus": 9,
		"gold_bonus": 3,
		"tile_color": Color(0.16, 0.02, 0.07),
		"rim_color": Color(0.72, 0.16, 0.22),
	},
	"bone_lord": {
		"id": "bone_lord",
		"display_name": "Bone Lord",
		"icon_path": "res://assets/icons/monsters/bone_lord.svg",
		"hp": 16,
		"dmg": 3,
		"timer": 2,
		"attack_cooldown": 3,
		"remove_on_attack": false,
		"is_boss": true,
		"spawn_weight": 0,
		"xp_bonus": 24,
		"gold_bonus": 10,
		"tile_color": Color(0.24, 0.06, 0.08),
		"rim_color": Color(0.95, 0.62, 0.25),
	},
	"bomb": {
		"id": "bomb",
		"display_name": "Bomb",
		"icon_path": "res://assets/icons/skull.svg",
		"hp": 2,
		"dmg": 1,
		"timer": 2,
		"attack_cooldown": 4,
		"remove_on_attack": true,
		"explode_on_attack": true,
		"explosion_radius": 1,
		"explosion_player_damage": 2,
		"spawn_weight": 0,
		"xp_bonus": 3,
		"gold_bonus": 1,
		"tile_color": Color(0.30, 0.16, 0.05),
		"rim_color": Color(0.96, 0.56, 0.18),
	},
}

static func get_monster(id: String) -> MonsterType:
	var data: Dictionary = DEFINITIONS.get(id, DEFINITIONS[DEFAULT_MONSTER_ID]).duplicate(true)
	var monster_id := str(data.get("id", DEFAULT_MONSTER_ID))
	data["display_name"] = Localization.monster_name(monster_id, str(data.get("display_name", monster_id)))
	return MonsterType.new(data)

static func roll_monster(rng: RandomNumberGenerator, weights: Dictionary = {}) -> MonsterType:
	var total := 0
	var ids := _roll_ids(weights)
	for raw_id in ids:
		var id := str(raw_id)
		total += _weight_for(id, weights)
	if total <= 0:
		return get_monster(DEFAULT_MONSTER_ID)
	var roll := rng.randi_range(1, max(1, total))
	var acc := 0
	for raw_id in ids:
		var id := str(raw_id)
		acc += _weight_for(id, weights)
		if roll <= acc:
			return get_monster(id)
	return get_monster(DEFAULT_MONSTER_ID)

static func make_enemy_tile(rng: RandomNumberGenerator, monster_id: String = "", weights: Dictionary = {}, profile: Dictionary = {}) -> Dictionary:
	var monster := get_monster(monster_id) if monster_id != "" else roll_monster(rng, weights)
	return _apply_profile(monster.to_enemy_tile(), profile, rng)

static func rescale_enemy_tile(enemy_tile: Dictionary, profile: Dictionary, rng: RandomNumberGenerator) -> void:
	if enemy_tile.is_empty():
		return
	if int(enemy_tile.get("kind", TileType.Kind.EMPTY)) != TileType.Kind.ENEMY:
		return
	var old_max_hp := maxi(1, int(enemy_tile.get("max_hp", enemy_tile.get("hp", 1))))
	var old_hp := maxi(0, int(enemy_tile.get("hp", old_max_hp)))
	var hp_ratio := float(old_hp) / float(old_max_hp)
	var scaled := _apply_profile(enemy_tile.duplicate(true), profile, rng)
	enemy_tile["max_hp"] = int(scaled.get("max_hp", old_max_hp))
	enemy_tile["hp"] = maxi(1, int(round(float(int(enemy_tile["max_hp"])) * hp_ratio)))
	enemy_tile["dmg"] = int(scaled.get("dmg", enemy_tile.get("dmg", 1)))
	enemy_tile["defense"] = int(scaled.get("defense", enemy_tile.get("defense", 0)))
	enemy_tile["progression_turn"] = int(scaled.get("progression_turn", enemy_tile.get("progression_turn", 0)))
	enemy_tile["progression_attack_roll"] = int(scaled.get("progression_attack_roll", enemy_tile.get("progression_attack_roll", 1)))
	enemy_tile["progression_defense_roll"] = int(scaled.get("progression_defense_roll", enemy_tile.get("progression_defense_roll", 0)))
	enemy_tile["progression_hp_roll"] = int(scaled.get("progression_hp_roll", enemy_tile.get("progression_hp_roll", 1)))

static func _roll_ids(weights: Dictionary) -> Array:
	if weights.is_empty():
		var ids := []
		for raw_id in DEFINITIONS.keys():
			var id := str(raw_id)
			if int(DEFINITIONS[id].get("spawn_weight", 0)) > 0:
				ids.append(id)
		ids.sort()
		return ids
	var weighted_ids := []
	for raw_id in weights.keys():
		var id := str(raw_id)
		if DEFINITIONS.has(id) and int(weights[id]) > 0:
			weighted_ids.append(id)
	weighted_ids.sort()
	return weighted_ids

static func _weight_for(id: String, weights: Dictionary) -> int:
	if weights.is_empty():
		return int(DEFINITIONS[id].get("spawn_weight", 0))
	return int(weights.get(id, 0))

static func _apply_profile(tile: Dictionary, profile: Dictionary, rng: RandomNumberGenerator = null) -> Dictionary:
	if profile.is_empty():
		return tile
	var result := tile.duplicate(true)
	var hp_scale := float(profile.get("hp_scale", 1.0))
	var damage_scale := float(profile.get("damage_scale", 1.0))
	var xp_scale := float(profile.get("xp_scale", 1.0))
	var gold_scale := float(profile.get("gold_scale", 1.0))
	var timer_delta := int(profile.get("timer_delta", 0))
	var local_rng := rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		local_rng.randomize()

	var progression_turn := int(profile.get("progression_turn", 0))
	if progression_turn > 0 and int(result.get("progression_turn", -1)) != progression_turn:
		result["progression_turn"] = progression_turn
		result["progression_attack_roll"] = local_rng.randi_range(
			int(profile.get("progression_attack_min", 1)),
			int(profile.get("progression_attack_max", profile.get("progression_attack_min", 1)))
		)
		result["progression_defense_roll"] = local_rng.randi_range(
			int(profile.get("progression_defense_min", 0)),
			int(profile.get("progression_defense_max", profile.get("progression_defense_min", 0)))
		)
		result["progression_hp_roll"] = local_rng.randi_range(
			int(profile.get("progression_hp_min", 1)),
			int(profile.get("progression_hp_max", profile.get("progression_hp_min", 1)))
		)

	var base_hp := maxi(1, int(result.get("base_hp", result.get("hp", 1))))
	var base_dmg := maxi(1, int(result.get("base_dmg", result.get("dmg", 1))))
	var base_defense := maxi(0, int(result.get("base_defense", result.get("defense", 0))))
	var progression_hp_roll := maxi(1, int(result.get("progression_hp_roll", 1)))
	var progression_attack_roll := maxi(1, int(result.get("progression_attack_roll", 1)))
	var progression_defense_roll := maxi(0, int(result.get("progression_defense_roll", 0)))

	result["hp"] = maxi(1, int(round(float(base_hp) * hp_scale * float(progression_hp_roll))))
	result["max_hp"] = result["hp"]
	result["dmg"] = maxi(1, int(round(float(base_dmg) * damage_scale * float(progression_attack_roll))))
	result["defense"] = maxi(0, base_defense + progression_defense_roll)
	result["xp_bonus"] = maxi(0, int(round(float(int(result.get("xp_bonus", 0))) * xp_scale)))
	result["gold_bonus"] = maxi(0, int(round(float(int(result.get("gold_bonus", 0))) * gold_scale)))
	result["timer"] = maxi(1, int(result.get("timer", 1)) + timer_delta)
	result["attack_cooldown"] = maxi(1, int(result.get("attack_cooldown", 1)) + timer_delta)
	if bool(result.get("reset_timer_on_hit", false)):
		result["hit_timer_reset"] = maxi(1, int(result.get("hit_timer_reset", result["attack_cooldown"])) + timer_delta)
	return result
