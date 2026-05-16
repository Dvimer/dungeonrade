extends RefCounted
class_name SkillCatalog

const SkillTypeScript := preload("res://scripts/data/SkillType.gd")

const DEFINITIONS := {
	"bone_crown": {
		"id": "bone_crown",
		"title": "Bone Crown",
		"short_title": "Crown",
		"description": "More damage against bosses and elites.",
		"icon_text": "BONE",
		"color": Color(0.76, 0.30, 0.30, 1.0),
		"bonuses": {"sword_damage_bonus": 2},
	},
	"arc_star": {
		"id": "arc_star",
		"title": "Arc Star",
		"short_title": "Star",
		"description": "Chain length adds bonus critical chance.",
		"icon_text": "STAR",
		"color": Color(0.62, 0.42, 1.0, 1.0),
		"bonuses": {"crit_chance": 0.07},
	},
	"violet_blade": {
		"id": "violet_blade",
		"title": "Violet Blade",
		"short_title": "Blade",
		"description": "Each sword tile hits harder.",
		"icon_text": "EDGE",
		"color": Color(0.72, 0.24, 0.95, 1.0),
		"bonuses": {"sword_damage_bonus": 2},
	},
	"frost_sigils": {
		"id": "frost_sigils",
		"title": "Frost Sigils",
		"short_title": "Frost",
		"description": "Enemies lose speed on long chains.",
		"icon_text": "FROST",
		"color": Color(0.28, 0.86, 1.0, 1.0),
		"bonuses": {"enemy_power_delta": -0.25},
	},
	"coin_furnace": {
		"id": "coin_furnace",
		"title": "Coin Furnace",
		"short_title": "Coins",
		"description": "Shop charge fills faster from gold.",
		"icon_text": "GOLD",
		"color": Color(0.95, 0.78, 0.20, 1.0),
		"bonuses": {"shop_charge_bonus": 2},
	},
	"thorn_mail": {
		"id": "thorn_mail",
		"title": "Thorn Mail",
		"short_title": "Armor",
		"description": "Blocked hits return damage.",
		"icon_text": "MAIL",
		"color": Color(0.48, 0.68, 1.0, 1.0),
		"bonuses": {"max_shield_bonus": 2},
	},
	"blood_well": {
		"id": "blood_well",
		"title": "Blood Well",
		"short_title": "Blood",
		"description": "Healing chains recover extra health.",
		"icon_text": "BLOOD",
		"color": Color(0.92, 0.24, 0.36, 1.0),
		"bonuses": {"vampirism": 0.08},
	},
	"grave_tempo": {
		"id": "grave_tempo",
		"title": "Grave Tempo",
		"short_title": "Tempo",
		"description": "More actions before enemies scale up.",
		"icon_text": "TEMPO",
		"color": Color(0.40, 0.96, 0.56, 1.0),
		"bonuses": {"crit_chance": 0.04, "shop_charge_bonus": 1},
	},
	"moon_ward": {
		"id": "moon_ward",
		"title": "Moon Ward",
		"short_title": "Ward",
		"description": "Raise shield capacity and resist damage.",
		"icon_text": "WARD",
		"color": Color(0.78, 0.82, 1.0, 1.0),
		"bonuses": {"max_shield_bonus": 3},
	},
	"venom_burst": {
		"id": "venom_burst",
		"title": "Venom Burst",
		"short_title": "Venom",
		"description": "Enemy kills splash poison damage.",
		"icon_text": "VENOM",
		"color": Color(0.34, 1.0, 0.32, 1.0),
		"bonuses": {"sword_damage_bonus": 1, "crit_chance": 0.05},
	},
}

static func get_skill(skill_id: String) -> Dictionary:
	var raw: Dictionary = DEFINITIONS.get(skill_id, DEFINITIONS["bone_crown"])
	return localize_skill(SkillTypeScript.new(raw).to_dictionary())

static func get_all_skills() -> Array:
	var result := []
	var ids := DEFINITIONS.keys()
	ids.sort()
	for raw_id in ids:
		result.append(get_skill(str(raw_id)))
	return result

static func get_default_pool_ids() -> Array:
	var ids := []
	for skill in get_all_skills():
		ids.append(str(skill.get("id", "")))
		if ids.size() >= 8:
			break
	return ids

static func localize_skill(skill: Dictionary) -> Dictionary:
	var localized := skill.duplicate(true)
	var skill_id := str(localized.get("id", ""))
	if skill_id == "":
		return localized
	localized["title"] = Localization.skill_name(skill_id, str(localized.get("title", skill_id)))
	localized["short_title"] = Localization.skill_short_name(skill_id, str(localized.get("short_title", localized.get("title", skill_id))))
	localized["description"] = Localization.skill_description(skill_id, str(localized.get("description", "")))
	localized["icon_text"] = Localization.skill_icon_text(skill_id, str(localized.get("icon_text", "*")))
	return localized

static func level_bonus(skill: Dictionary) -> Dictionary:
	var bonuses = skill.get("bonuses", {})
	if bonuses is Dictionary:
		return bonuses.duplicate(true)
	return {}

static func describe_bonus_block(data: Dictionary) -> Array:
	var lines := []
	for raw_key in data.keys():
		var key := str(raw_key)
		var value = data[raw_key]
		match key:
			"sword_damage_bonus":
				lines.append(Localization.t("bonus.sword_damage_bonus", [int(value)]))
			"crit_chance":
				lines.append(Localization.t("bonus.crit_chance", [int(round(float(value) * 100.0))]))
			"vampirism":
				lines.append(Localization.t("bonus.vampirism", [int(round(float(value) * 100.0))]))
			"shop_charge_bonus":
				lines.append(Localization.t("bonus.shop_charge_bonus", [int(value)]))
			"max_shield_bonus":
				lines.append(Localization.t("bonus.max_shield_bonus", [int(value)]))
			"enemy_power_delta":
				lines.append(Localization.t("bonus.enemy_power_delta", [float(value)]))
	return lines
