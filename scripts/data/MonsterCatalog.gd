extends RefCounted
class_name MonsterCatalog

const DEFAULT_MONSTER_ID := "skeleton"

const DEFINITIONS := {
	"skeleton": {
		"id": "skeleton",
		"display_name": "Skeleton",
		"icon_path": "res://assets/icons/monsters/skeleton.svg",
		"hp": 1,
		"dmg": 1,
		"timer": 3,
		"attack_cooldown": 3,
		"spawn_weight": 50,
		"xp_bonus": 0,
		"gold_bonus": 0,
		"tile_color": Color(0.18, 0.09, 0.20),
		"rim_color": Color(0.58, 0.37, 0.48),
	},
	"bandana_skeleton": {
		"id": "bandana_skeleton",
		"display_name": "Bone Rogue",
		"icon_path": "res://assets/icons/monsters/bandana_skeleton.svg",
		"hp": 1,
		"dmg": 1,
		"timer": 1,
		"attack_cooldown": 3,
		"reset_timer_on_hit": true,
		"hit_timer_reset": 3,
		"remove_on_attack": false,
		"spawn_weight": 18,
		"xp_bonus": 4,
		"gold_bonus": 1,
		"tile_color": Color(0.20, 0.08, 0.11),
		"rim_color": Color(0.78, 0.36, 0.26),
	},
	"vampire": {
		"id": "vampire",
		"display_name": "Vampire",
		"icon_path": "res://assets/icons/monsters/vampire.svg",
		"hp": 3,
		"dmg": 2,
		"timer": 3,
		"attack_cooldown": 3,
		"remove_on_attack": false,
		"heal_on_attack": true,
		"heal_on_attack_ratio": 1.0,
		"spawn_weight": 12,
		"xp_bonus": 7,
		"gold_bonus": 2,
		"tile_color": Color(0.16, 0.02, 0.07),
		"rim_color": Color(0.72, 0.16, 0.22),
	},
	"bone_lord": {
		"id": "bone_lord",
		"display_name": "Bone Lord",
		"icon_path": "res://assets/icons/monsters/bandana_skeleton.svg",
		"hp": 9,
		"dmg": 3,
		"timer": 2,
		"attack_cooldown": 3,
		"remove_on_attack": false,
		"is_boss": true,
		"spawn_weight": 0,
		"xp_bonus": 20,
		"gold_bonus": 8,
		"tile_color": Color(0.24, 0.06, 0.08),
		"rim_color": Color(0.95, 0.62, 0.25),
	},
}

static func get_monster(id: String) -> MonsterType:
	var data: Dictionary = DEFINITIONS.get(id, DEFINITIONS[DEFAULT_MONSTER_ID])
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

static func make_enemy_tile(rng: RandomNumberGenerator, monster_id: String = "", weights: Dictionary = {}) -> Dictionary:
	var monster := get_monster(monster_id) if monster_id != "" else roll_monster(rng, weights)
	return monster.to_enemy_tile()

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
