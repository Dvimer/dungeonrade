extends RefCounted
class_name EquipmentCatalog

const RARITY_ORDER := {
	"common": 0,
	"uncommon": 1,
	"rare": 2,
	"epic": 3,
	"legendary": 4,
	"mythic": 5,
}

const RARITY_COLORS := {
	"common": Color(0.74, 0.76, 0.82, 1.0),
	"uncommon": Color(0.42, 0.84, 0.48, 1.0),
	"rare": Color(0.36, 0.66, 1.0, 1.0),
	"epic": Color(0.74, 0.42, 1.0, 1.0),
	"legendary": Color(1.0, 0.66, 0.24, 1.0),
	"mythic": Color(1.0, 0.30, 0.48, 1.0),
}

const SLOT_ORDER := {
	"weapon": 0,
	"shield": 1,
	"armor": 2,
	"helmet": 3,
	"gloves": 4,
	"boots": 5,
	"belt": 6,
	"ring": 7,
	"amulet": 8,
	"trinket": 9,
}

const TYPE_ORDER := {
	"offense": 0,
	"precision": 1,
	"defense": 2,
	"sustain": 3,
	"utility": 4,
	"hybrid": 5,
}

const SLOT_ICON_PATHS := {
	"weapon": "res://assets/icons/items/weapon.svg",
	"shield": "res://assets/icons/items/shield.svg",
	"armor": "res://assets/icons/items/armor.svg",
	"helmet": "res://assets/icons/items/helmet.svg",
	"gloves": "res://assets/icons/items/gloves.svg",
	"boots": "res://assets/icons/items/boots.svg",
	"belt": "res://assets/icons/items/belt.svg",
	"ring": "res://assets/icons/items/ring.svg",
	"amulet": "res://assets/icons/items/amulet.svg",
	"trinket": "res://assets/icons/items/trinket.svg",
}

const RARITY_TRACK := [
	"common",
	"common",
	"uncommon",
	"uncommon",
	"rare",
	"rare",
	"epic",
	"epic",
	"legendary",
	"mythic",
]

static var _definitions_cache: Dictionary = {}

static func get_item(item_id: String) -> Dictionary:
	var defs := _definitions()
	var raw: Dictionary = defs.get(item_id, defs.get("iron_sword", {}))
	return localize_item(raw.duplicate(true))

static func get_all_items(sort_key: String = "rarity") -> Array:
	var result := []
	for raw_id in _definitions().keys():
		result.append(get_item(str(raw_id)))
	return sort_items(result, sort_key)

static func get_shop_items() -> Array:
	var result := []
	for item in get_all_items("rarity"):
		if bool(item.get("shop_enabled", false)):
			result.append(item)
	return result

static func get_available_items() -> Array:
	var result := []
	for item in get_all_items("rarity"):
		var item_id := str(item.get("id", ""))
		if bool(item.get("shop_enabled", false)) or GameState.unlocked_item_ids.has(item_id):
			result.append(item)
	return result

static func skull_cost_for_rarity(rarity: String) -> int:
	match rarity:
		"common":    return 15
		"uncommon":  return 30
		"rare":      return 60
		"epic":      return 120
		"legendary": return 250
		"mythic":    return 500
	return 30

static func sort_items(items: Array, sort_key: String = "rarity") -> Array:
	var result := items.duplicate(true)
	match sort_key:
		"name":
			result.sort_custom(func(a: Dictionary, b: Dictionary): return _cmp_name(a, b))
		"slot":
			result.sort_custom(func(a: Dictionary, b: Dictionary): return _cmp_slot(a, b))
		"type":
			result.sort_custom(func(a: Dictionary, b: Dictionary): return _cmp_type(a, b))
		_:
			result.sort_custom(func(a: Dictionary, b: Dictionary): return _cmp_rarity(a, b))
	return result

static func bonus_dict(item: Dictionary) -> Dictionary:
	var bonuses = item.get("bonuses", {})
	if bonuses is Dictionary:
		return bonuses.duplicate(true)
	return {}

static func rarity_rank(rarity: String) -> int:
	return int(RARITY_ORDER.get(rarity, 0))

static func rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, RARITY_COLORS["common"])

static func localize_item(item: Dictionary) -> Dictionary:
	var localized := item.duplicate(true)
	var item_id := str(localized.get("id", ""))
	if item_id == "":
		return localized
	localized["title"] = Localization.item_name(item_id, str(localized.get("title", item_id)))
	localized["description"] = Localization.item_description(item_id, str(localized.get("description", "")))
	localized["icon_text"] = Localization.item_icon_text(item_id, str(localized.get("icon_text", "*")))
	localized["slot"] = str(localized.get("slot", ""))
	localized["item_type"] = str(localized.get("item_type", "hybrid"))
	localized["rarity"] = str(localized.get("rarity", "common"))
	if str(localized.get("icon_path", "")) == "":
		localized["icon_path"] = str(SLOT_ICON_PATHS.get(localized["slot"], ""))
	return localized

static func _definitions() -> Dictionary:
	if _definitions_cache.is_empty():
		_definitions_cache = _build_definitions()
	return _definitions_cache

static func _build_definitions() -> Dictionary:
	var defs := {}

	_build_group(defs, {
		"slot": "weapon",
		"icon_text": "BLADE",
		"default_type": "offense",
		"entries": [
			{"id": "iron_sword", "title": "Iron Sword", "rarity": "common", "item_type": "offense", "bonuses": {"sword_damage_bonus": 3}, "shop_enabled": true, "description": "A heavier blade for larger chains."},
			{"id": "grave_shiv", "title": "Grave Shiv", "item_type": "precision"},
			{"id": "hunter_blade", "title": "Hunter Blade", "rarity": "uncommon", "item_type": "precision", "bonuses": {"sword_damage_bonus": 2, "crit_chance": 0.08}, "shop_enabled": true, "description": "A quick edge with better critical finishers."},
			{"id": "embershard_axe", "title": "Embershard Axe"},
			{"id": "duelist_saber", "title": "Duelist Saber", "item_type": "precision"},
			{"id": "cryptsplitter", "title": "Cryptsplitter", "item_type": "hybrid"},
			{"id": "moonfang_rapier", "title": "Moonfang Rapier", "item_type": "precision"},
			{"id": "stormtide_glaive", "title": "Stormtide Glaive", "item_type": "hybrid"},
			{"id": "kingbreaker", "title": "Kingbreaker", "item_type": "offense"},
			{"id": "sun_eater", "title": "Sun Eater", "item_type": "hybrid"},
		],
		"bonus_track": [
			{"sword_damage_bonus": 2},
			{"sword_damage_bonus": 2, "crit_chance": 0.02},
			{"sword_damage_bonus": 3},
			{"sword_damage_bonus": 3, "crit_chance": 0.03},
			{"sword_damage_bonus": 4},
			{"sword_damage_bonus": 4, "crit_chance": 0.05},
			{"sword_damage_bonus": 5, "crit_chance": 0.06},
			{"sword_damage_bonus": 5, "vampirism": 0.04},
			{"sword_damage_bonus": 6, "crit_chance": 0.08},
			{"sword_damage_bonus": 7, "crit_chance": 0.10, "vampirism": 0.06},
		],
	})

	_build_group(defs, {
		"slot": "shield",
		"icon_text": "GUARD",
		"default_type": "defense",
		"entries": [
			{"id": "oak_buckler", "title": "Oak Buckler"},
			{"id": "grave_guard", "title": "Grave Guard"},
			{"id": "crypt_wall", "title": "Crypt Wall"},
			{"id": "mirror_kite", "title": "Mirror Kite", "item_type": "hybrid"},
			{"id": "warden_bastion", "title": "Warden Bastion"},
			{"id": "moonward_bulwark", "title": "Moonward Bulwark", "item_type": "hybrid"},
			{"id": "saint_aegis", "title": "Saint Aegis"},
			{"id": "stormguard", "title": "Stormguard", "item_type": "utility"},
			{"id": "citadel_veil", "title": "Citadel Veil"},
			{"id": "last_parapet", "title": "Last Parapet", "item_type": "hybrid"},
		],
		"bonus_track": [
			{"max_shield_bonus": 1},
			{"max_shield_bonus": 1, "enemy_power_delta": -0.05},
			{"max_shield_bonus": 2},
			{"max_shield_bonus": 2, "enemy_power_delta": -0.08},
			{"max_shield_bonus": 3},
			{"max_shield_bonus": 3, "enemy_power_delta": -0.10},
			{"max_shield_bonus": 4},
			{"max_shield_bonus": 4, "enemy_power_delta": -0.12},
			{"max_shield_bonus": 5, "enemy_power_delta": -0.15},
			{"max_shield_bonus": 6, "enemy_power_delta": -0.20},
		],
	})

	_build_group(defs, {
		"slot": "armor",
		"icon_text": "MAIL",
		"default_type": "defense",
		"entries": [
			{"id": "threadbare_vest", "title": "Threadbare Vest"},
			{"id": "tower_shield", "title": "Tower Shield", "item_type": "defense", "rarity": "common", "bonuses": {"max_shield_bonus": 4}, "shop_enabled": true, "description": "Raises the shield cap for longer fights.", "icon_text": "SHIELD"},
			{"id": "cryptscale_mail", "title": "Cryptscale Mail"},
			{"id": "ashen_cuirass", "title": "Ashen Cuirass"},
			{"id": "guardian_harness", "title": "Guardian Harness"},
			{"id": "funeral_plate", "title": "Funeral Plate", "item_type": "hybrid"},
			{"id": "moonlit_brigandine", "title": "Moonlit Brigandine"},
			{"id": "void_tabard", "title": "Void Tabard", "item_type": "utility"},
			{"id": "throne_carapace", "title": "Throne Carapace"},
			{"id": "eternal_bastion", "title": "Eternal Bastion", "item_type": "hybrid"},
		],
		"bonus_track": [
			{"max_shield_bonus": 1},
			{"max_shield_bonus": 2},
			{"max_shield_bonus": 2, "vampirism": 0.03},
			{"max_shield_bonus": 3, "enemy_power_delta": -0.05},
			{"max_shield_bonus": 3, "vampirism": 0.04},
			{"max_shield_bonus": 4, "enemy_power_delta": -0.08},
			{"max_shield_bonus": 4, "vampirism": 0.05},
			{"max_shield_bonus": 5, "enemy_power_delta": -0.10},
			{"max_shield_bonus": 6, "vampirism": 0.06},
			{"max_shield_bonus": 7, "enemy_power_delta": -0.12, "vampirism": 0.08},
		],
	})

	_build_group(defs, {
		"slot": "gloves",
		"icon_text": "GRIP",
		"default_type": "utility",
		"entries": [
			{"id": "merchant_gloves", "title": "Merchant Gloves", "rarity": "common", "item_type": "utility", "bonuses": {"shop_charge_bonus": 3}, "shop_enabled": true, "description": "Gold chains fill the shop faster.", "icon_text": "GOLD"},
			{"id": "pickpocket_wraps", "title": "Pickpocket Wraps"},
			{"id": "gravehand_grips", "title": "Gravehand Grips"},
			{"id": "duelist_gloves", "title": "Duelist Gloves", "item_type": "precision"},
			{"id": "lockjaw_mitts", "title": "Lockjaw Mitts", "item_type": "offense"},
			{"id": "sunwoven_gauntlets", "title": "Sunwoven Gauntlets"},
			{"id": "harrier_fingers", "title": "Harrier Fingers", "item_type": "precision"},
			{"id": "boneweave_claws", "title": "Boneweave Claws", "item_type": "hybrid"},
			{"id": "royal_vice", "title": "Royal Vice", "item_type": "offense"},
			{"id": "starforged_hands", "title": "Starforged Hands", "item_type": "hybrid"},
		],
		"bonus_track": [
			{"shop_charge_bonus": 1},
			{"shop_charge_bonus": 1, "crit_chance": 0.02},
			{"shop_charge_bonus": 2},
			{"shop_charge_bonus": 2, "crit_chance": 0.03},
			{"shop_charge_bonus": 2, "sword_damage_bonus": 1},
			{"shop_charge_bonus": 3, "crit_chance": 0.04},
			{"shop_charge_bonus": 3, "sword_damage_bonus": 1},
			{"shop_charge_bonus": 4, "crit_chance": 0.05},
			{"shop_charge_bonus": 4, "sword_damage_bonus": 2},
			{"shop_charge_bonus": 5, "crit_chance": 0.06, "sword_damage_bonus": 2},
		],
	})

	_build_group(defs, {
		"slot": "ring",
		"icon_text": "RING",
		"default_type": "precision",
		"entries": [
			{"id": "copper_band", "title": "Copper Band"},
			{"id": "smoke_seal", "title": "Smoke Seal"},
			{"id": "grave_ring", "title": "Grave Ring", "item_type": "sustain"},
			{"id": "hunters_signet", "title": "Hunter's Signet"},
			{"id": "moonloop", "title": "Moonloop", "item_type": "hybrid"},
			{"id": "fang_circle", "title": "Fang Circle", "item_type": "sustain"},
			{"id": "storm_signet", "title": "Storm Signet"},
			{"id": "royal_band", "title": "Royal Band", "item_type": "hybrid"},
			{"id": "eclipse_ring", "title": "Eclipse Ring"},
			{"id": "crownspark_loop", "title": "Crownspark Loop", "item_type": "hybrid"},
		],
		"bonus_track": [
			{"crit_chance": 0.02},
			{"crit_chance": 0.03},
			{"crit_chance": 0.03, "vampirism": 0.03},
			{"crit_chance": 0.04},
			{"crit_chance": 0.05, "vampirism": 0.04},
			{"crit_chance": 0.06, "vampirism": 0.05},
			{"crit_chance": 0.08},
			{"crit_chance": 0.09, "vampirism": 0.06},
			{"crit_chance": 0.11},
			{"crit_chance": 0.14, "vampirism": 0.08},
		],
	})

	_build_group(defs, {
		"slot": "amulet",
		"icon_text": "CHARM",
		"default_type": "sustain",
		"entries": [
			{"id": "blood_charm", "title": "Blood Charm", "rarity": "common", "item_type": "sustain", "bonuses": {"vampirism": 0.12}, "shop_enabled": true, "description": "Turns each good chain into better sustain."},
			{"id": "gravebone_amulet", "title": "Gravebone Amulet"},
			{"id": "pilgrim_token", "title": "Pilgrim Token", "item_type": "utility"},
			{"id": "moonprayer_charm", "title": "Moonprayer Charm"},
			{"id": "furnace_talisman", "title": "Furnace Talisman", "item_type": "utility"},
			{"id": "redwell_relic", "title": "Redwell Relic"},
			{"id": "harvest_medallion", "title": "Harvest Medallion", "item_type": "hybrid"},
			{"id": "saint_bloodlocket", "title": "Saint Bloodlocket"},
			{"id": "sunheart_amulet", "title": "Sunheart Amulet", "item_type": "hybrid"},
			{"id": "eternal_feast", "title": "Eternal Feast"},
		],
		"bonus_track": [
			{"vampirism": 0.03},
			{"vampirism": 0.04},
			{"vampirism": 0.04, "shop_charge_bonus": 1},
			{"vampirism": 0.05},
			{"vampirism": 0.05, "shop_charge_bonus": 2},
			{"vampirism": 0.06},
			{"vampirism": 0.07, "shop_charge_bonus": 2},
			{"vampirism": 0.08},
			{"vampirism": 0.09, "shop_charge_bonus": 3},
			{"vampirism": 0.12, "shop_charge_bonus": 3},
		],
	})

	_build_group(defs, {
		"slot": "helmet",
		"icon_text": "HELM",
		"default_type": "defense",
		"entries": [
			{"id": "gravecap", "title": "Gravecap"},
			{"id": "watchers_hood", "title": "Watcher's Hood", "item_type": "utility"},
			{"id": "crypt_helm", "title": "Crypt Helm"},
			{"id": "ivory_mask", "title": "Ivory Mask", "item_type": "precision"},
			{"id": "wardens_visor", "title": "Warden's Visor"},
			{"id": "mooncrest_crown", "title": "Mooncrest Crown", "item_type": "hybrid"},
			{"id": "storm_helm", "title": "Storm Helm"},
			{"id": "voidmask", "title": "Voidmask", "item_type": "utility"},
			{"id": "throne_visor", "title": "Throne Visor"},
			{"id": "halo_of_ashes", "title": "Halo of Ashes", "item_type": "hybrid"},
		],
		"bonus_track": [
			{"max_shield_bonus": 1},
			{"max_shield_bonus": 1, "enemy_power_delta": -0.03},
			{"max_shield_bonus": 2},
			{"max_shield_bonus": 2, "crit_chance": 0.02},
			{"max_shield_bonus": 3},
			{"max_shield_bonus": 3, "enemy_power_delta": -0.06},
			{"max_shield_bonus": 4},
			{"max_shield_bonus": 4, "crit_chance": 0.04},
			{"max_shield_bonus": 5, "enemy_power_delta": -0.08},
			{"max_shield_bonus": 6, "enemy_power_delta": -0.10, "crit_chance": 0.05},
		],
	})

	_build_group(defs, {
		"slot": "boots",
		"icon_text": "BOOT",
		"default_type": "utility",
		"entries": [
			{"id": "roadworn_boots", "title": "Roadworn Boots"},
			{"id": "grave_treads", "title": "Grave Treads"},
			{"id": "duelist_step", "title": "Duelist Step", "item_type": "precision"},
			{"id": "frostbound_greaves", "title": "Frostbound Greaves"},
			{"id": "sunstride_boots", "title": "Sunstride Boots", "item_type": "hybrid"},
			{"id": "stormchaser_treads", "title": "Stormchaser Treads"},
			{"id": "ashen_greaves", "title": "Ashen Greaves", "item_type": "defense"},
			{"id": "phantom_steps", "title": "Phantom Steps", "item_type": "precision"},
			{"id": "royal_march", "title": "Royal March", "item_type": "hybrid"},
			{"id": "startrail_boots", "title": "Startrail Boots", "item_type": "utility"},
		],
		"bonus_track": [
			{"shop_charge_bonus": 1},
			{"shop_charge_bonus": 1, "crit_chance": 0.02},
			{"shop_charge_bonus": 1, "enemy_power_delta": -0.04},
			{"shop_charge_bonus": 2, "crit_chance": 0.03},
			{"shop_charge_bonus": 2, "enemy_power_delta": -0.06},
			{"shop_charge_bonus": 3, "crit_chance": 0.04},
			{"shop_charge_bonus": 3, "enemy_power_delta": -0.08},
			{"shop_charge_bonus": 3, "crit_chance": 0.05},
			{"shop_charge_bonus": 4, "enemy_power_delta": -0.10},
			{"shop_charge_bonus": 4, "crit_chance": 0.06, "enemy_power_delta": -0.12},
		],
	})

	_build_group(defs, {
		"slot": "belt",
		"icon_text": "BELT",
		"default_type": "hybrid",
		"entries": [
			{"id": "rope_belt", "title": "Rope Belt"},
			{"id": "grave_sash", "title": "Grave Sash"},
			{"id": "coinbinder", "title": "Coinbinder", "item_type": "utility"},
			{"id": "wardstrap", "title": "Wardstrap", "item_type": "defense"},
			{"id": "pilgrims_girdle", "title": "Pilgrim's Girdle"},
			{"id": "ashen_bind", "title": "Ashen Bind", "item_type": "utility"},
			{"id": "moonforged_belt", "title": "Moonforged Belt"},
			{"id": "storm_sash", "title": "Storm Sash", "item_type": "utility"},
			{"id": "royal_girdle", "title": "Royal Girdle"},
			{"id": "worldknot", "title": "Worldknot", "item_type": "hybrid"},
		],
		"bonus_track": [
			{"max_shield_bonus": 1},
			{"max_shield_bonus": 1, "shop_charge_bonus": 1},
			{"max_shield_bonus": 2},
			{"max_shield_bonus": 2, "shop_charge_bonus": 1},
			{"max_shield_bonus": 2, "shop_charge_bonus": 2},
			{"max_shield_bonus": 3},
			{"max_shield_bonus": 3, "shop_charge_bonus": 2},
			{"max_shield_bonus": 4},
			{"max_shield_bonus": 4, "shop_charge_bonus": 3},
			{"max_shield_bonus": 5, "shop_charge_bonus": 4},
		],
	})

	_build_group(defs, {
		"slot": "trinket",
		"icon_text": "LENS",
		"default_type": "precision",
		"entries": [
			{"id": "bone_lens", "title": "Bone Lens", "rarity": "common", "item_type": "precision", "bonuses": {"crit_chance": 0.14}, "shop_enabled": true, "description": "Helps land precise critical hits."},
			{"id": "grave_idol", "title": "Grave Idol", "item_type": "sustain"},
			{"id": "ember_orb", "title": "Ember Orb", "item_type": "offense"},
			{"id": "storm_dial", "title": "Storm Dial", "item_type": "utility"},
			{"id": "moon_lens", "title": "Moon Lens"},
			{"id": "blood_idol", "title": "Blood Idol", "item_type": "sustain"},
			{"id": "royal_prism", "title": "Royal Prism", "item_type": "hybrid"},
			{"id": "ashen_astrolabe", "title": "Ashen Astrolabe", "item_type": "utility"},
			{"id": "eclipse_orb", "title": "Eclipse Orb", "item_type": "offense"},
			{"id": "starwake_eye", "title": "Starwake Eye", "item_type": "hybrid"},
		],
		"bonus_track": [
			{"crit_chance": 0.03},
			{"vampirism": 0.03},
			{"crit_chance": 0.04, "sword_damage_bonus": 1},
			{"shop_charge_bonus": 1, "crit_chance": 0.04},
			{"crit_chance": 0.05, "sword_damage_bonus": 1},
			{"vampirism": 0.05, "crit_chance": 0.05},
			{"crit_chance": 0.07, "sword_damage_bonus": 2},
			{"shop_charge_bonus": 2, "crit_chance": 0.07},
			{"crit_chance": 0.10, "sword_damage_bonus": 2},
			{"crit_chance": 0.12, "vampirism": 0.06, "sword_damage_bonus": 2},
		],
	})

	_build_group(defs, {
		"slot": "amulet",
		"icon_text": "SIGIL",
		"default_type": "utility",
		"entries": [
			{"id": "coinseal", "title": "Coinseal", "item_type": "utility"},
			{"id": "grave_writ", "title": "Grave Writ", "item_type": "hybrid"},
			{"id": "sunscript", "title": "Sunscript", "item_type": "utility"},
			{"id": "stormglyph", "title": "Stormglyph", "item_type": "utility"},
			{"id": "warden_script", "title": "Warden Script", "item_type": "defense"},
			{"id": "lunarseal", "title": "Lunarseal", "item_type": "precision"},
			{"id": "void_contract", "title": "Void Contract", "item_type": "hybrid"},
			{"id": "royal_edict", "title": "Royal Edict", "item_type": "utility"},
			{"id": "sunlit_ledger", "title": "Sunlit Ledger", "item_type": "hybrid"},
			{"id": "fate_warrant", "title": "Fate Warrant", "item_type": "hybrid", "rarity": "mythic"},
		],
		"bonus_track": [
			{"shop_charge_bonus": 1},
			{"shop_charge_bonus": 1, "vampirism": 0.02},
			{"shop_charge_bonus": 2},
			{"shop_charge_bonus": 2, "crit_chance": 0.02},
			{"shop_charge_bonus": 2, "enemy_power_delta": -0.04},
			{"shop_charge_bonus": 3, "crit_chance": 0.03},
			{"shop_charge_bonus": 3, "vampirism": 0.04},
			{"shop_charge_bonus": 4, "crit_chance": 0.04},
			{"shop_charge_bonus": 4, "enemy_power_delta": -0.06},
			{"shop_charge_bonus": 5, "crit_chance": 0.05, "vampirism": 0.05},
		],
	})

	_build_group(defs, {
		"slot": "helmet",
		"icon_text": "CROWN",
		"default_type": "hybrid",
		"entries": [
			{"id": "thorn_circlet", "title": "Thorn Circlet", "item_type": "precision"},
			{"id": "gravelet", "title": "Gravelet", "item_type": "sustain"},
			{"id": "ash_crown", "title": "Ash Crown"},
			{"id": "moon_diadem", "title": "Moon Diadem", "item_type": "precision"},
			{"id": "suncrest", "title": "Suncrest", "item_type": "hybrid"},
			{"id": "warden_crown", "title": "Warden Crown"},
			{"id": "storm_diadem", "title": "Storm Diadem", "item_type": "utility"},
			{"id": "void_halo", "title": "Void Halo", "item_type": "hybrid"},
			{"id": "royal_thorns", "title": "Royal Thorns"},
			{"id": "myth_crown", "title": "Myth Crown", "item_type": "hybrid"},
		],
		"bonus_track": [
			{"crit_chance": 0.02},
			{"vampirism": 0.02},
			{"crit_chance": 0.03, "max_shield_bonus": 1},
			{"crit_chance": 0.04},
			{"crit_chance": 0.04, "vampirism": 0.03},
			{"crit_chance": 0.05, "max_shield_bonus": 2},
			{"crit_chance": 0.06, "enemy_power_delta": -0.04},
			{"crit_chance": 0.07, "vampirism": 0.04},
			{"crit_chance": 0.08, "max_shield_bonus": 2},
			{"crit_chance": 0.10, "vampirism": 0.05, "enemy_power_delta": -0.06},
		],
	})

	return defs

static func _build_group(defs: Dictionary, config: Dictionary) -> void:
	var slot := str(config.get("slot", "trinket"))
	var entries: Array = config.get("entries", [])
	var default_icon := str(config.get("icon_text", "ITEM"))
	var default_icon_path := str(config.get("icon_path", str(SLOT_ICON_PATHS.get(slot, ""))))
	var default_type := str(config.get("default_type", "hybrid"))
	var bonus_track: Array = config.get("bonus_track", [])
	for i in range(entries.size()):
		var entry: Dictionary = entries[i]
		var rarity := str(entry.get("rarity", RARITY_TRACK[i]))
		var bonuses: Dictionary = entry.get("bonuses", bonus_track[i]).duplicate(true)
		var title := str(entry.get("title", "Item"))
		var item_type := str(entry.get("item_type", default_type))
		var item_id := str(entry.get("id", _slugify(title)))
		var icon_text := str(entry.get("icon_text", default_icon))
		var shop_enabled := bool(entry.get("shop_enabled", false))
		defs[item_id] = {
			"id": item_id,
			"title": title,
			"slot": str(entry.get("slot", slot)),
			"item_type": item_type,
			"rarity": rarity,
			"description": str(entry.get("description", _description_for(item_type, rarity))),
			"icon_text": icon_text,
			"icon_path": str(entry.get("icon_path", default_icon_path)),
			"color": entry.get("color", rarity_color(rarity)),
			"bonuses": bonuses,
			"shop_enabled": shop_enabled,
		}

static func _description_for(item_type: String, rarity: String) -> String:
	return "%s %s item tuned for dungeon builds." % [rarity.capitalize(), item_type]

static func _cmp_name(a: Dictionary, b: Dictionary) -> bool:
	var an := str(a.get("title", "")).to_lower()
	var bn := str(b.get("title", "")).to_lower()
	if an == bn:
		return _cmp_rarity_then_slot(a, b)
	return an < bn

static func _cmp_rarity(a: Dictionary, b: Dictionary) -> bool:
	var ar := rarity_rank(str(a.get("rarity", "common")))
	var br := rarity_rank(str(b.get("rarity", "common")))
	if ar == br:
		return _cmp_name_then_slot(a, b)
	return ar > br

static func _cmp_slot(a: Dictionary, b: Dictionary) -> bool:
	var aslot := int(SLOT_ORDER.get(str(a.get("slot", "")), 999))
	var bslot := int(SLOT_ORDER.get(str(b.get("slot", "")), 999))
	if aslot == bslot:
		return _cmp_rarity_then_name(a, b)
	return aslot < bslot

static func _cmp_type(a: Dictionary, b: Dictionary) -> bool:
	var atype := int(TYPE_ORDER.get(str(a.get("item_type", "")), 999))
	var btype := int(TYPE_ORDER.get(str(b.get("item_type", "")), 999))
	if atype == btype:
		return _cmp_rarity_then_name(a, b)
	return atype < btype

static func _cmp_name_then_slot(a: Dictionary, b: Dictionary) -> bool:
	var an := str(a.get("title", "")).to_lower()
	var bn := str(b.get("title", "")).to_lower()
	if an != bn:
		return an < bn
	var aslot := int(SLOT_ORDER.get(str(a.get("slot", "")), 999))
	var bslot := int(SLOT_ORDER.get(str(b.get("slot", "")), 999))
	if aslot != bslot:
		return aslot < bslot
	return str(a.get("id", "")) < str(b.get("id", ""))

static func _cmp_rarity_then_name(a: Dictionary, b: Dictionary) -> bool:
	var ar := rarity_rank(str(a.get("rarity", "common")))
	var br := rarity_rank(str(b.get("rarity", "common")))
	if ar != br:
		return ar > br
	return _cmp_name_then_slot(a, b)

static func _cmp_rarity_then_slot(a: Dictionary, b: Dictionary) -> bool:
	var ar := rarity_rank(str(a.get("rarity", "common")))
	var br := rarity_rank(str(b.get("rarity", "common")))
	if ar != br:
		return ar > br
	var aslot := int(SLOT_ORDER.get(str(a.get("slot", "")), 999))
	var bslot := int(SLOT_ORDER.get(str(b.get("slot", "")), 999))
	if aslot != bslot:
		return aslot < bslot
	return str(a.get("id", "")) < str(b.get("id", ""))

static func _slugify(text: String) -> String:
	return text.to_lower().replace("'", "").replace(" ", "_")
