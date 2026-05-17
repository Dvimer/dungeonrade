extends RefCounted
class_name SkillEffect

# Базовый класс для активных эффектов навыков.
# apply() возвращает словарь для Battle/RunState:
#   "tiles_cleared": Array[Vector2]  — позиции для consume_and_refill
#   "next_crit_set": bool            — флаг форсированного крита установлен
#   "damage_dealt": int              — суммарный урон
func apply(run: Node, board_logic: BoardLogic, skill: Dictionary) -> Dictionary:
	return {}
