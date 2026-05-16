extends RefCounted
class_name ClassCatalog

const DEFINITIONS := {
	"warrior": {
		"id": "warrior",
		"title": "Warrior",
		"description": "Balanced fighter. Starts with bonus max HP and sword power.",
		"icon_text": "WAR",
		"token_cost": 0,
		"starting_modifiers": {"sword_damage_bonus": 1},
		"class_passive": "",
		"max_hp_bonus": 2,
	},
	"rogue": {
		"id": "rogue",
		"title": "Rogue",
		"description": "Coin chains deal 1 damage per coin to enemies. Gold income +30%.",
		"icon_text": "ROG",
		"token_cost": 1,
		"starting_modifiers": {"gold_bonus_pct": 0.30},
		"class_passive": "rogue_coin_attack",
		"max_hp_bonus": 0,
	},
	"vampire": {
		"id": "vampire",
		"title": "Vampire",
		"description": "Starts with 10% vampirism. Heart chains also grant +1 shield per heart.",
		"icon_text": "VAM",
		"token_cost": 2,
		"starting_modifiers": {"vampirism": 0.10},
		"class_passive": "vampire_heart_shield",
		"max_hp_bonus": 0,
	},
	"alchemist": {
		"id": "alchemist",
		"title": "Alchemist",
		"description": "On enemy kill: 40% chance to deal 1 poison damage to a random adjacent enemy.",
		"icon_text": "ALC",
		"token_cost": 3,
		"starting_modifiers": {},
		"class_passive": "alchemist_poison",
		"max_hp_bonus": 0,
	},
}

static func get_class(class_id: String) -> Dictionary:
	return DEFINITIONS.get(class_id, DEFINITIONS["warrior"]).duplicate(true)

static func get_all_classes() -> Array:
	var result := []
	for raw_id in ["warrior", "rogue", "vampire", "alchemist"]:
		result.append(get_class(str(raw_id)))
	return result

static func is_unlocked(class_id: String) -> bool:
	if class_id == "warrior":
		return true
	return GameState.unlocked_classes.has(class_id)

static func unlock_cost_skulls(_class_id: String) -> int:
	return 0  # classes cost boss_tokens, not skulls

static func rarity_color_for(class_id: String) -> Color:
	match class_id:
		"warrior":   return Color(0.74, 0.76, 0.82, 1.0)
		"rogue":     return Color(0.42, 0.84, 0.48, 1.0)
		"vampire":   return Color(0.72, 0.16, 0.22, 1.0)
		"alchemist": return Color(0.34, 1.0, 0.32, 1.0)
	return Color(0.74, 0.76, 0.82, 1.0)
