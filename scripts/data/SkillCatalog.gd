extends RefCounted
class_name SkillCatalog

const SkillTypeScript := preload("res://scripts/data/SkillType.gd")

const EFFECT_SCRIPTS := {
	"collect_gold": preload("res://scripts/data/effects/EffectCollectGold.gd"),
	"damage_all":   preload("res://scripts/data/effects/EffectDamageAll.gd"),
	"sweep_rows":   preload("res://scripts/data/effects/EffectSweepRows.gd"),
	"full_heal":    preload("res://scripts/data/effects/EffectFullHeal.gd"),
	"reset_timers": preload("res://scripts/data/effects/EffectResetTimers.gd"),
	"next_crit":    preload("res://scripts/data/effects/EffectNextCrit.gd"),
}

static func get_effect_script(effect_id: String):
	return EFFECT_SCRIPTS.get(effect_id, null)

const DEFINITIONS := {
	"bone_crown": {
		"id": "bone_crown",
		"title": "Bone Crown",
		"short_title": "Crown",
		"description": "More damage against bosses and elites.",
		"icon_text": "BONE",
		"color": Color(0.76, 0.30, 0.30, 1.0),
		"bonuses": {"sword_damage_bonus": 2},
		"upgrade_cost_base": 30,
		"upgrade_cost_step": 15,
		"upgrades": [
			{"desc_key": "upgrade.bone_crown.1", "bonus_delta": {"sword_damage_bonus": 1}},
			{"desc_key": "upgrade.bone_crown.2", "bonus_delta": {"sword_damage_bonus": 1}},
			{"desc_key": "upgrade.bone_crown.3", "bonus_delta": {"sword_damage_bonus": 1}},
			{"desc_key": "upgrade.bone_crown.4", "bonus_delta": {"crit_chance": 0.05}},
		],
	},
	"arc_star": {
		"id": "arc_star",
		"title": "Arc Star",
		"short_title": "Star",
		"description": "Chain length adds bonus critical chance.",
		"icon_text": "STAR",
		"color": Color(0.62, 0.42, 1.0, 1.0),
		"bonuses": {"crit_chance": 0.07},
		"upgrade_cost_base": 35,
		"upgrade_cost_step": 20,
		"upgrades": [
			{"desc_key": "upgrade.arc_star.1", "bonus_delta": {"crit_chance": 0.03}},
			{"desc_key": "upgrade.arc_star.2", "crit_damage_mult": 2.5},
			{"desc_key": "upgrade.arc_star.3", "bonus_delta": {"crit_chance": 0.04}},
			{"desc_key": "upgrade.arc_star.4", "crit_damage_mult": 3.0},
		],
	},
	"violet_blade": {
		"id": "violet_blade",
		"title": "Violet Blade",
		"short_title": "Blade",
		"description": "Each sword tile hits harder.",
		"icon_text": "EDGE",
		"color": Color(0.72, 0.24, 0.95, 1.0),
		"bonuses": {"sword_damage_bonus": 2},
		"upgrade_cost_base": 30,
		"upgrade_cost_step": 15,
		"upgrades": [
			{"desc_key": "upgrade.violet_blade.1", "bonus_delta": {"sword_damage_bonus": 1}},
			{"desc_key": "upgrade.violet_blade.2", "bonus_delta": {"sword_damage_bonus": 1}},
			{"desc_key": "upgrade.violet_blade.3", "bonus_delta": {"sword_damage_bonus": 1}},
			{"desc_key": "upgrade.violet_blade.4", "bonus_delta": {"crit_chance": 0.05}},
		],
	},
	"frost_sigils": {
		"id": "frost_sigils",
		"title": "Frost Sigils",
		"short_title": "Frost",
		"description": "Enemies lose speed on long chains.",
		"icon_text": "FROST",
		"color": Color(0.28, 0.86, 1.0, 1.0),
		"bonuses": {"enemy_power_delta": -0.25},
		"upgrade_cost_base": 35,
		"upgrade_cost_step": 20,
		"upgrades": [
			{"desc_key": "upgrade.frost_sigils.1", "bonus_delta": {"enemy_power_delta": -0.10}},
			{"desc_key": "upgrade.frost_sigils.2", "bonus_delta": {"crit_chance": 0.03}},
			{"desc_key": "upgrade.frost_sigils.3", "bonus_delta": {"enemy_power_delta": -0.10}},
			{"desc_key": "upgrade.frost_sigils.4", "bonus_delta": {"crit_chance": 0.05}},
		],
	},
	"coin_furnace": {
		"id": "coin_furnace",
		"title": "Coin Furnace",
		"short_title": "Coins",
		"description": "Shop charge fills faster from gold.",
		"icon_text": "GOLD",
		"color": Color(0.95, 0.78, 0.20, 1.0),
		"bonuses": {"shop_charge_bonus": 2},
		"upgrade_cost_base": 30,
		"upgrade_cost_step": 15,
		"upgrades": [
			{"desc_key": "upgrade.coin_furnace.1", "bonus_delta": {"shop_charge_bonus": 1}},
			{"desc_key": "upgrade.coin_furnace.2", "bonus_delta": {"crit_chance": 0.05}},
			{"desc_key": "upgrade.coin_furnace.3", "bonus_delta": {"shop_charge_bonus": 1}},
			{"desc_key": "upgrade.coin_furnace.4", "bonus_delta": {"shop_charge_bonus": 2}},
		],
	},
	"thorn_mail": {
		"id": "thorn_mail",
		"title": "Thorn Mail",
		"short_title": "Armor",
		"description": "Blocked hits return damage.",
		"icon_text": "MAIL",
		"color": Color(0.48, 0.68, 1.0, 1.0),
		"bonuses": {"max_shield_bonus": 2},
		"upgrade_cost_base": 30,
		"upgrade_cost_step": 15,
		"upgrades": [
			{"desc_key": "upgrade.thorn_mail.1", "bonus_delta": {"max_shield_bonus": 1}},
			{"desc_key": "upgrade.thorn_mail.2", "bonus_delta": {"crit_chance": 0.05}},
			{"desc_key": "upgrade.thorn_mail.3", "bonus_delta": {"max_shield_bonus": 1}},
			{"desc_key": "upgrade.thorn_mail.4", "bonus_delta": {"max_shield_bonus": 1}},
		],
	},
	"blood_well": {
		"id": "blood_well",
		"title": "Blood Well",
		"short_title": "Blood",
		"description": "Healing chains recover extra health.",
		"icon_text": "BLOOD",
		"color": Color(0.92, 0.24, 0.36, 1.0),
		"bonuses": {"vampirism": 0.08},
		"upgrade_cost_base": 35,
		"upgrade_cost_step": 20,
		"upgrades": [
			{"desc_key": "upgrade.blood_well.1", "bonus_delta": {"vampirism": 0.04}},
			{"desc_key": "upgrade.blood_well.2", "bonus_delta": {"crit_chance": 0.05}},
			{"desc_key": "upgrade.blood_well.3", "bonus_delta": {"vampirism": 0.04}},
			{"desc_key": "upgrade.blood_well.4", "bonus_delta": {"vampirism": 0.04}},
		],
	},
	"grave_tempo": {
		"id": "grave_tempo",
		"title": "Grave Tempo",
		"short_title": "Tempo",
		"description": "More actions before enemies scale up.",
		"icon_text": "TEMPO",
		"color": Color(0.40, 0.96, 0.56, 1.0),
		"bonuses": {"crit_chance": 0.04, "shop_charge_bonus": 1},
		"upgrade_cost_base": 30,
		"upgrade_cost_step": 15,
		"upgrades": [
			{"desc_key": "upgrade.grave_tempo.1", "bonus_delta": {"crit_chance": 0.03}},
			{"desc_key": "upgrade.grave_tempo.2", "bonus_delta": {"shop_charge_bonus": 1}},
			{"desc_key": "upgrade.grave_tempo.3", "bonus_delta": {"crit_chance": 0.03}},
			{"desc_key": "upgrade.grave_tempo.4", "bonus_delta": {"shop_charge_bonus": 1}},
		],
	},
	"moon_ward": {
		"id": "moon_ward",
		"title": "Moon Ward",
		"short_title": "Ward",
		"description": "Raise shield capacity and resist damage.",
		"icon_text": "WARD",
		"color": Color(0.78, 0.82, 1.0, 1.0),
		"bonuses": {"max_shield_bonus": 3},
		"upgrade_cost_base": 30,
		"upgrade_cost_step": 15,
		"upgrades": [
			{"desc_key": "upgrade.moon_ward.1", "bonus_delta": {"max_shield_bonus": 1}},
			{"desc_key": "upgrade.moon_ward.2", "bonus_delta": {"max_shield_bonus": 1}},
			{"desc_key": "upgrade.moon_ward.3", "bonus_delta": {"max_shield_bonus": 1}},
			{"desc_key": "upgrade.moon_ward.4", "bonus_delta": {"crit_chance": 0.05}},
		],
	},
	"venom_burst": {
		"id": "venom_burst",
		"title": "Venom Burst",
		"short_title": "Venom",
		"description": "Enemy kills splash poison damage.",
		"icon_text": "VENOM",
		"color": Color(0.34, 1.0, 0.32, 1.0),
		"bonuses": {"sword_damage_bonus": 1, "crit_chance": 0.05},
		"upgrade_cost_base": 35,
		"upgrade_cost_step": 20,
		"upgrades": [
			{"desc_key": "upgrade.venom_burst.1", "bonus_delta": {"sword_damage_bonus": 1}},
			{"desc_key": "upgrade.venom_burst.2", "bonus_delta": {"crit_chance": 0.03}},
			{"desc_key": "upgrade.venom_burst.3", "bonus_delta": {"sword_damage_bonus": 1}},
			{"desc_key": "upgrade.venom_burst.4", "bonus_delta": {"crit_chance": 0.05}},
		],
	},
	"gold_sweep": {
		"id": "gold_sweep",
		"title": "Gold Sweep",
		"short_title": "Sweep",
		"description": "Collect all gold from the board instantly.",
		"icon_text": "SWEEP",
		"color": Color(0.98, 0.80, 0.22, 1.0),
		"skill_kind": "active",
		"cooldown_base": 6,
		"cooldown_reduction_per_level": 1,
		"effect_id": "collect_gold",
		"max_level": 5,
		"upgrade_cost_base": 40,
		"upgrade_cost_step": 20,
		"upgrades": [
			{"desc_key": "upgrade.gold_sweep.1", "cooldown_delta": -1},
			{"desc_key": "upgrade.gold_sweep.2", "sweep_count": 2},
			{"desc_key": "upgrade.gold_sweep.3", "cooldown_delta": -1},
			{"desc_key": "upgrade.gold_sweep.4", "sweep_count": 3},
		],
	},
	"wrath": {
		"id": "wrath",
		"title": "Wrath",
		"short_title": "Wrath",
		"description": "Deal sword damage to every enemy on the board.",
		"icon_text": "WRATH",
		"color": Color(1.0, 0.32, 0.28, 1.0),
		"skill_kind": "active",
		"cooldown_base": 8,
		"cooldown_reduction_per_level": 1,
		"effect_id": "damage_all",
		"max_level": 5,
		"upgrade_cost_base": 45,
		"upgrade_cost_step": 25,
		"upgrades": [
			{"desc_key": "upgrade.wrath.1", "cooldown_delta": -1},
			{"desc_key": "upgrade.wrath.2", "bonus_delta": {"sword_damage_bonus": 1}},
			{"desc_key": "upgrade.wrath.3", "cooldown_delta": -1},
			{"desc_key": "upgrade.wrath.4", "bonus_delta": {"sword_damage_bonus": 1}},
		],
	},
	"row_sweep": {
		"id": "row_sweep",
		"title": "Row Sweep",
		"short_title": "Rows",
		"description": "Collect everything in the bottom two rows.",
		"icon_text": "ROWS",
		"color": Color(0.42, 0.72, 1.0, 1.0),
		"skill_kind": "active",
		"cooldown_base": 7,
		"cooldown_reduction_per_level": 1,
		"effect_id": "sweep_rows",
		"max_level": 5,
		"upgrade_cost_base": 40,
		"upgrade_cost_step": 20,
		"upgrades": [
			{"desc_key": "upgrade.row_sweep.1", "cooldown_delta": -1},
			{"desc_key": "upgrade.row_sweep.2", "sweep_count": 2},
			{"desc_key": "upgrade.row_sweep.3", "cooldown_delta": -1},
			{"desc_key": "upgrade.row_sweep.4", "sweep_count": 3},
		],
	},
	"full_heal": {
		"id": "full_heal",
		"title": "Full Heal",
		"short_title": "Heal",
		"description": "Restore HP to maximum.",
		"icon_text": "HEAL",
		"color": Color(0.40, 1.0, 0.58, 1.0),
		"skill_kind": "active",
		"cooldown_base": 12,
		"cooldown_reduction_per_level": 1,
		"effect_id": "full_heal",
		"max_level": 5,
		"upgrade_cost_base": 50,
		"upgrade_cost_step": 25,
		"upgrades": [
			{"desc_key": "upgrade.full_heal.1", "cooldown_delta": -2},
			{"desc_key": "upgrade.full_heal.2", "bonus_delta": {"vampirism": 0.05}},
			{"desc_key": "upgrade.full_heal.3", "cooldown_delta": -2},
			{"desc_key": "upgrade.full_heal.4", "bonus_delta": {"vampirism": 0.05}},
		],
	},
	"stasis": {
		"id": "stasis",
		"title": "Stasis",
		"short_title": "Stasis",
		"description": "Reset all enemy timers to their maximum.",
		"icon_text": "STOP",
		"color": Color(0.62, 0.88, 1.0, 1.0),
		"skill_kind": "active",
		"cooldown_base": 9,
		"cooldown_reduction_per_level": 1,
		"effect_id": "reset_timers",
		"max_level": 5,
		"upgrade_cost_base": 40,
		"upgrade_cost_step": 20,
		"upgrades": [
			{"desc_key": "upgrade.stasis.1", "cooldown_delta": -1},
			{"desc_key": "upgrade.stasis.2", "freeze_turns": 2},
			{"desc_key": "upgrade.stasis.3", "cooldown_delta": -1},
			{"desc_key": "upgrade.stasis.4", "freeze_turns": 3},
		],
	},
	"predator": {
		"id": "predator",
		"title": "Predator",
		"short_title": "Pred",
		"description": "Your next chain is a guaranteed critical hit.",
		"icon_text": "CRIT",
		"color": Color(1.0, 0.60, 0.18, 1.0),
		"skill_kind": "active",
		"cooldown_base": 7,
		"cooldown_reduction_per_level": 1,
		"effect_id": "next_crit",
		"max_level": 5,
		"upgrade_cost_base": 40,
		"upgrade_cost_step": 20,
		"upgrades": [
			{"desc_key": "upgrade.predator.1", "cooldown_delta": -1},
			{"desc_key": "upgrade.predator.2", "crit_damage_mult": 2.5},
			{"desc_key": "upgrade.predator.3", "cooldown_delta": -1},
			{"desc_key": "upgrade.predator.4", "crit_damage_mult": 3.0},
		],
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
	# Куратированный пул: 5 пассивных + 3 активных
	return [
		"arc_star", "blood_well", "coin_furnace", "frost_sigils", "thorn_mail",
		"gold_sweep", "predator", "stasis",
	]

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
	if str(skill.get("skill_kind", "passive")) == "active":
		return {}
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

# Returns a copy of base_def with all upgrade deltas for the given meta-level applied.
# level 1 = base (no changes). level 2 applies upgrades[0], level 3 applies [0,1], etc.
static func compute_at_level(base_def: Dictionary, level: int) -> Dictionary:
	var result := base_def.duplicate(true)
	var upgrades: Array = base_def.get("upgrades", [])
	var tiers := mini(level - 1, upgrades.size())
	for i in range(tiers):
		var u: Dictionary = upgrades[i]
		if u.has("cooldown_delta"):
			result["cooldown_base"] = maxi(1, int(result.get("cooldown_base", 0)) + int(u["cooldown_delta"]))
		if u.has("sweep_count"):
			result["sweep_count"] = int(u["sweep_count"])
		if u.has("crit_damage_mult"):
			result["crit_damage_mult"] = float(u["crit_damage_mult"])
		if u.has("freeze_turns"):
			result["freeze_turns"] = int(u["freeze_turns"])
		if u.has("bonus_delta") and u["bonus_delta"] is Dictionary:
			var bonuses: Dictionary = result.get("bonuses", {}).duplicate()
			for k in u["bonus_delta"].keys():
				bonuses[str(k)] = float(bonuses.get(str(k), 0.0)) + float(u["bonus_delta"][k])
			result["bonuses"] = bonuses
	result["meta_level"] = level
	return result

# Cost in skulls to upgrade a skill to target_level (target_level >= 2).
static func upgrade_cost(base_def: Dictionary, target_level: int) -> int:
	var base: int = int(base_def.get("upgrade_cost_base", 50))
	var step: int = int(base_def.get("upgrade_cost_step", 25))
	return base + (target_level - 2) * step
