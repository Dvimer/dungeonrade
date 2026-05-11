extends RefCounted
class_name ChainResult

# Результат разрешения цепочки тайлов.
# Чистая структура данных — без зависимостей от сцен.

var damage_to_enemies: int = 0       # суммарный урон, распределяемый по врагам в цепи
var enemies_in_chain: Array = []     # позиции [Vector2(x,y)] врагов, которые в цепи
var shield_gained: int = 0
var heal_amount: int = 0
var gold_gained: int = 0
var combo_multiplier: float = 1.0
var crit: bool = false
var chain_length: int = 0
var consumed_positions: Array = []   # все позиции, которые надо очистить
var label: String = ""               # GREAT / INSANE / GODLIKE для UI

func to_dict() -> Dictionary:
	return {
		"damage_to_enemies": damage_to_enemies,
		"enemies_in_chain": enemies_in_chain,
		"shield_gained": shield_gained,
		"heal_amount": heal_amount,
		"gold_gained": gold_gained,
		"combo_multiplier": combo_multiplier,
		"crit": crit,
		"chain_length": chain_length,
		"consumed_positions": consumed_positions,
		"label": label,
	}
