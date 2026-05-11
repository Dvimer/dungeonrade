extends Node

# Состояние текущего забега. Сбрасывается при старте нового.
# Держит HP игрока, щит, золото, активные апгрейды и эффекты.

const MAX_HP_DEFAULT := 30
const ROUNDS_DEFAULT := 80

var hp: int = MAX_HP_DEFAULT
var max_hp: int = MAX_HP_DEFAULT
var shield: int = 0
var gold: int = 0
var wave: int = 0
var score: int = 0
var level: int = 1
var xp: int = 0
var rounds_left: int = ROUNDS_DEFAULT

# Активные модификаторы боя — их читает ChainResolver.
# Например: {"sword_damage_bonus": 2, "crit_chance": 0.15, "vampirism": 0.1}
var modifiers: Dictionary = {}
var active_class: String = "warrior"

func reset() -> void:
	hp = MAX_HP_DEFAULT
	max_hp = MAX_HP_DEFAULT
	shield = 0
	gold = 0
	wave = 0
	score = 0
	level = 1
	xp = 0
	rounds_left = ROUNDS_DEFAULT
	modifiers = {}
	active_class = GameState.selected_class
	EventBus.emit_signal("rounds_changed", rounds_left)

func xp_needed_for_next_level() -> int:
	# Простая формула: 100 * level. Можно крутить.
	return 100 * level

func add_xp(amount: int) -> void:
	xp += amount
	var leveled := false
	while xp >= xp_needed_for_next_level():
		xp -= xp_needed_for_next_level()
		level += 1
		leveled = true
	EventBus.emit_signal("xp_changed", xp, xp_needed_for_next_level())
	if leveled:
		EventBus.emit_signal("level_up", level)

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
	shield += amount
	EventBus.emit_signal("shield_changed", shield)

func add_gold(amount: int) -> void:
	gold += amount
	EventBus.emit_signal("gold_changed", gold)

func spend_round(amount: int = 1) -> void:
	rounds_left = maxi(0, rounds_left - amount)
	EventBus.emit_signal("rounds_changed", rounds_left)
