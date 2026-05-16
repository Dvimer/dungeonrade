extends RefCounted
class_name SkillEffect

# Базовый класс для активных эффектов навыков.
# Подклассы переопределяют apply() и применяют эффект напрямую через run/board_logic.
# Возвращаемый словарь — только данные для Board/Battle:
#   "tiles_cleared": Array[Vector2]  — позиции для consume_and_refill
#   "next_crit_set": bool            — флаг форсированного крита установлен
#   "damage_dealt": int              — суммарный урон (для float-лейблов)
func apply(run: Node, board_logic: BoardLogic) -> Dictionary:
	return {}
