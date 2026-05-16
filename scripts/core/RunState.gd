extends Node

# Состояние текущего забега. Сбрасывается при старте нового.
# Держит HP игрока, щит, золото, активные апгрейды и эффекты.

const MAX_HP_DEFAULT := 30
const ROUNDS_DEFAULT := 80
const DEFAULT_MAX_SHIELD := 5
const DEFAULT_SHOP_CHARGE_NEEDED := 20

const SkillCatalogScript := preload("res://scripts/data/SkillCatalog.gd")
const EquipmentCatalogScript := preload("res://scripts/data/EquipmentCatalog.gd")

var hp: int = MAX_HP_DEFAULT
var max_hp: int = MAX_HP_DEFAULT
var shield: int = 0
var max_shield: int = DEFAULT_MAX_SHIELD
var base_max_shield: int = DEFAULT_MAX_SHIELD
var gold: int = 0
var shop_charge: int = 0
var shop_charge_needed: int = DEFAULT_SHOP_CHARGE_NEEDED
var wave: int = 0
var total_waves: int = 0
var score: int = 0
var level: int = 1
var xp: int = 0
var total_turns_taken: int = 0
var rounds_left: int = ROUNDS_DEFAULT
var current_wave: Dictionary = {}
var current_level: Dictionary = {}
var level_id: String = ""
var level_title: String = ""
var level_description: String = ""
var boss_active: bool = false
var skill_pool_ids: Array = []
var active_skills: Array = []
var active_equipment: Array = []
var pending_skill_upgrades: int = 0
var awaiting_upgrade_choice: bool = false
var offered_upgrades: Array = []
var pending_shop_count: int = 0
var awaiting_shop_choice: bool = false
var offered_shop_items: Array = []

# Активные модификаторы боя — их читает ChainResolver.
# Например: {"sword_damage_bonus": 2, "crit_chance": 0.15, "vampirism": 0.1}
var modifiers: Dictionary = {}
var base_modifiers: Dictionary = {}
var active_class: String = "warrior"
var class_passive: String = ""

func _ready() -> void:
	EventBus.upgrade_picked.connect(_on_upgrade_picked)
	EventBus.shop_picked.connect(_on_shop_picked)

func reset() -> void:
	hp = MAX_HP_DEFAULT
	max_hp = MAX_HP_DEFAULT
	shield = 0
	max_shield = DEFAULT_MAX_SHIELD
	base_max_shield = DEFAULT_MAX_SHIELD
	gold = 0
	shop_charge = 0
	shop_charge_needed = DEFAULT_SHOP_CHARGE_NEEDED
	wave = 0
	total_waves = 0
	score = 0
	level = 1
	xp = 0
	total_turns_taken = 0
	rounds_left = 0
	current_wave = {}
	current_level = {}
	level_id = ""
	level_title = ""
	level_description = ""
	boss_active = false
	skill_pool_ids = []
	active_skills = []
	active_equipment = []
	pending_skill_upgrades = 0
	awaiting_upgrade_choice = false
	offered_upgrades = []
	pending_shop_count = 0
	awaiting_shop_choice = false
	offered_shop_items = []
	modifiers = {}
	base_modifiers = {}
	active_class = GameState.selected_class
	class_passive = ""
	EventBus.emit_signal("rounds_changed", rounds_left)

func start_level_run(level_config: Dictionary) -> void:
	reset()
	current_level = level_config.duplicate(true)
	level_id = str(current_level.get("id", ""))
	level_title = Localization.level_title(level_id, str(current_level.get("title", "")))
	level_description = Localization.level_description(level_id, str(current_level.get("description", "")))
	total_waves = maxi(1, int(current_level.get("wave_count", 1)))
	base_max_shield = maxi(1, int(current_level.get("max_shield", DEFAULT_MAX_SHIELD)))
	max_shield = base_max_shield
	shop_charge_needed = maxi(1, int(current_level.get("shop_charge_needed", DEFAULT_SHOP_CHARGE_NEEDED)))
	var starting_modifiers_data = current_level.get("starting_modifiers", {})
	if starting_modifiers_data is Dictionary:
		base_modifiers = starting_modifiers_data.duplicate(true)
	else:
		base_modifiers = {}
	modifiers = base_modifiers.duplicate(true)
	var class_def := _class_definition(active_class)
	var class_mods: Dictionary = class_def.get("starting_modifiers", {})
	for key in class_mods.keys():
		add_mod(str(key), class_mods[key])
	var hp_bonus := int(class_def.get("max_hp_bonus", 0))
	if hp_bonus > 0:
		max_hp += hp_bonus
		hp = max_hp
	class_passive = str(class_def.get("class_passive", ""))
	if GameState.skill_pool_ids.is_empty():
		GameState.skill_pool_ids = SkillCatalogScript.get_default_pool_ids()
	skill_pool_ids = GameState.skill_pool_ids.duplicate()
	_rebuild_active_skills()
	_recompute_skill_bonuses()
	EventBus.emit_signal("gold_changed", gold)
	EventBus.emit_signal("shop_charge_changed", shop_charge, shop_charge_needed)
	EventBus.emit_signal("shield_changed", shield)
	EventBus.emit_signal("xp_changed", xp, xp_needed_for_next_level())
	EventBus.emit_signal("skills_changed")
	EventBus.emit_signal("equipment_changed")

func start_wave(wave_config: Dictionary) -> void:
	current_wave = wave_config.duplicate(true)
	wave = int(current_wave.get("index", wave + 1))
	rounds_left = int(current_wave.get("turns", ROUNDS_DEFAULT))
	boss_active = false
	EventBus.emit_signal("rounds_changed", rounds_left)
	EventBus.emit_signal("wave_started", wave)

func start_boss_phase(turns: int) -> void:
	rounds_left = maxi(1, turns)
	boss_active = true
	EventBus.emit_signal("rounds_changed", rounds_left)

func clear_wave() -> void:
	boss_active = false
	EventBus.emit_signal("wave_cleared", wave)

func xp_needed_for_next_level() -> int:
	# Первый пик силы должен приходить рано, дальше цена растёт мягче,
	# чтобы билд ощущался сильнее уже в середине забега.
	return 70 + maxi(0, level - 1) * 30

func add_xp(amount: int) -> void:
	xp += amount
	var leveled := false
	while xp >= xp_needed_for_next_level():
		xp -= xp_needed_for_next_level()
		level += 1
		leveled = true
		pending_skill_upgrades += 1
	EventBus.emit_signal("xp_changed", xp, xp_needed_for_next_level())
	if leveled:
		EventBus.emit_signal("level_up", level)
		_offer_next_upgrade_if_needed()

func mod(key: String, default_value = 0):
	return modifiers.get(key, default_value)

func add_mod(key: String, value) -> void:
	if modifiers.has(key) and typeof(modifiers[key]) == typeof(value) and (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT):
		modifiers[key] += value
	else:
		modifiers[key] = value

# --- HP / Shield ---
func take_damage(dmg: int) -> int:
	var blocked: int = mini(shield, dmg)
	shield -= blocked
	var actual: int = dmg - blocked
	hp -= actual
	EventBus.emit_signal("shield_changed", shield)
	if actual > 0:
		EventBus.emit_signal("player_damaged", actual)
	if hp <= 0:
		hp = 0
		EventBus.emit_signal("player_died")
	return actual

func heal(amount: int) -> void:
	var before: int = hp
	hp = mini(max_hp, hp + amount)
	if hp > before:
		EventBus.emit_signal("player_healed", hp - before)

func add_shield(amount: int) -> void:
	shield = mini(max_shield, shield + amount)
	EventBus.emit_signal("shield_changed", shield)

func add_gold(amount: int) -> void:
	var gold_pct := float(mod("gold_bonus_pct", 0.0))
	if gold_pct > 0.0:
		amount = int(ceil(float(amount) * (1.0 + gold_pct)))
	gold += amount
	var bonus_charge := int(mod("shop_charge_bonus", 0))
	shop_charge = mini(shop_charge_needed, shop_charge + amount + bonus_charge)
	EventBus.emit_signal("gold_changed", gold)
	EventBus.emit_signal("shop_charge_changed", shop_charge, shop_charge_needed)
	if shop_charge >= shop_charge_needed:
		pending_shop_count += 1
		EventBus.emit_signal("shop_ready")
		_try_offer_shop()

func spend_round(amount: int = 1) -> void:
	total_turns_taken += maxi(0, amount)
	if boss_active:
		EventBus.emit_signal("rounds_changed", rounds_left)
		return
	rounds_left = maxi(0, rounds_left - amount)
	EventBus.emit_signal("rounds_changed", rounds_left)

func is_wave_timer_done() -> bool:
	return rounds_left <= 0

func sword_power() -> int:
	return 1 + int(mod("sword_damage_bonus", 0))

func enemy_power() -> int:
	var damage_scale := 1.0
	var profile = current_wave.get("monster_profile", null)
	if profile is Dictionary:
		damage_scale = float(profile.get("damage_scale", 1.0))
	damage_scale += float(mod("enemy_power_delta", 0.0))
	return maxi(1, int(round(damage_scale + float(maxi(0, wave - 1)) * 0.35)))

func current_stats() -> Dictionary:
	return {
		"crit_chance": int(round(float(mod("crit_chance", 0.0)) * 100.0)),
		"vampirism": int(round(float(mod("vampirism", 0.0)) * 100.0)),
		"hp": hp,
		"max_hp": max_hp,
		"shield": shield,
		"max_shield": max_shield,
		"sword_power": sword_power(),
		"enemy_power": enemy_power(),
		"shop_charge": shop_charge,
		"shop_charge_needed": shop_charge_needed,
		"pending_skill_upgrades": pending_skill_upgrades,
		"equipment_names": equipped_item_titles(),
	}

func _rebuild_active_skills() -> void:
	active_skills.clear()

func _offer_next_upgrade_if_needed() -> void:
	if pending_skill_upgrades <= 0 or awaiting_upgrade_choice:
		return
	if awaiting_shop_choice:
		return
	offered_upgrades = _roll_upgrade_choices()
	if offered_upgrades.is_empty():
		return
	awaiting_upgrade_choice = true
	EventBus.emit_signal("upgrade_offered", offered_upgrades)

func _roll_upgrade_choices() -> Array:
	var candidate_ids := []
	if active_skills.size() < 4:
		for skill_id in skill_pool_ids:
			if not _has_active_skill(str(skill_id)):
				candidate_ids.append(str(skill_id))
		if candidate_ids.is_empty():
			for skill in active_skills:
				candidate_ids.append(str(skill.get("id", "")))
	else:
		for skill in active_skills:
			candidate_ids.append(str(skill.get("id", "")))

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	candidate_ids.shuffle()
	var choices := []
	var max_choices := mini(3, candidate_ids.size())
	for i in range(max_choices):
		var skill := SkillCatalogScript.get_skill(candidate_ids[i])
		var current_level := _skill_level(candidate_ids[i])
		skill["level"] = current_level + 1 if current_level > 0 else 1
		skill["current_level"] = current_level
		choices.append(skill)
	return choices

func _on_upgrade_picked(upgrade) -> void:
	if not awaiting_upgrade_choice:
		return
	if upgrade == null or not (upgrade is Dictionary):
		return
	var skill_id := str(upgrade.get("id", ""))
	if skill_id == "":
		return
	awaiting_upgrade_choice = false
	pending_skill_upgrades = maxi(0, pending_skill_upgrades - 1)
	_apply_skill_pick(skill_id)
	EventBus.emit_signal("skills_changed")
	_offer_next_upgrade_if_needed()
	_try_offer_shop()

func _apply_skill_pick(skill_id: String) -> void:
	for i in range(active_skills.size()):
		if str(active_skills[i].get("id", "")) == skill_id:
			var current_level := int(active_skills[i].get("level", 1))
			var max_level := int(active_skills[i].get("max_level", 5))
			active_skills[i]["level"] = mini(max_level, current_level + 1)
			_recompute_skill_bonuses()
			return
	if active_skills.size() < 4:
		var skill := SkillCatalogScript.get_skill(skill_id)
		skill["level"] = 1
		active_skills.append(skill)
	_recompute_skill_bonuses()

func _recompute_skill_bonuses() -> void:
	modifiers = base_modifiers.duplicate(true)
	max_shield = base_max_shield
	for skill in active_skills:
		var level_count := maxi(1, int(skill.get("level", 1)))
		var bonus := SkillCatalogScript.level_bonus(skill)
		for key in bonus.keys():
			var value = bonus[key]
			if key == "max_shield_bonus":
				max_shield += int(value) * level_count
				continue
			if typeof(value) == TYPE_FLOAT:
				add_mod(str(key), float(value) * level_count)
			elif typeof(value) == TYPE_INT:
				add_mod(str(key), int(value) * level_count)
	for item in active_equipment:
		var item_bonus := EquipmentCatalogScript.bonus_dict(item)
		for key in item_bonus.keys():
			var item_value = item_bonus[key]
			if key == "max_shield_bonus":
				max_shield += int(item_value)
				continue
			if typeof(item_value) == TYPE_FLOAT:
				add_mod(str(key), float(item_value))
			elif typeof(item_value) == TYPE_INT:
				add_mod(str(key), int(item_value))
	shield = mini(shield, max_shield)
	EventBus.emit_signal("shield_changed", shield)

func _has_active_skill(skill_id: String) -> bool:
	return _skill_level(skill_id) > 0

func _skill_level(skill_id: String) -> int:
	for skill in active_skills:
		if str(skill.get("id", "")) == skill_id:
			return int(skill.get("level", 1))
	return 0

func _try_offer_shop() -> void:
	if pending_shop_count <= 0 or awaiting_shop_choice:
		return
	if awaiting_upgrade_choice:
		return
	offered_shop_items = _roll_shop_choices()
	if offered_shop_items.is_empty():
		return
	awaiting_shop_choice = true
	EventBus.emit_signal("shop_offered", offered_shop_items)

func _roll_shop_choices() -> Array:
	var available := []
	for item in EquipmentCatalogScript.get_available_items():
		if not _has_equipment(str(item.get("id", ""))):
			available.append(item)
	if available.is_empty():
		for item in active_equipment:
			available.append(item.duplicate(true))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	available.shuffle()
	var result := []
	for i in range(mini(3, available.size())):
		result.append(available[i].duplicate(true))
	return result

func _has_equipment(item_id: String) -> bool:
	for item in active_equipment:
		if str(item.get("id", "")) == item_id:
			return true
	return false

func _on_shop_picked(item) -> void:
	if not awaiting_shop_choice:
		return
	if item == null or not (item is Dictionary):
		return
	awaiting_shop_choice = false
	pending_shop_count = maxi(0, pending_shop_count - 1)
	shop_charge = 0
	EventBus.emit_signal("shop_charge_changed", shop_charge, shop_charge_needed)
	_apply_shop_pick(item)
	EventBus.emit_signal("equipment_changed")
	_offer_next_upgrade_if_needed()
	_try_offer_shop()

func _apply_shop_pick(item: Dictionary) -> void:
	var item_id := str(item.get("id", ""))
	if item_id == "":
		return
	for i in range(active_equipment.size()):
		if str(active_equipment[i].get("slot", "")) == str(item.get("slot", "")):
			active_equipment[i] = item.duplicate(true)
			_recompute_skill_bonuses()
			return
	active_equipment.append(item.duplicate(true))
	_recompute_skill_bonuses()

func equipped_item_titles() -> Array:
	var result := []
	for item in active_equipment:
		result.append(Localization.item_name(str(item.get("id", "")), str(item.get("title", ""))))
	return result

func _class_definition(class_id: String) -> Dictionary:
	var class_catalog = load("res://scripts/data/ClassCatalog.gd")
	if class_catalog != null and class_catalog.has_method("get_class_data"):
		var data = class_catalog.call("get_class_data", class_id)
		if data is Dictionary:
			return data
	return {
		"id": "warrior",
		"starting_modifiers": {"sword_damage_bonus": 1},
		"class_passive": "",
		"max_hp_bonus": 2,
	}
