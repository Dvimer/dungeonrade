extends SkillEffect

# Сбрасывает таймеры всех врагов до максимума (attack_cooldown).
func apply(run: Node, board_logic: BoardLogic) -> Dictionary:
	for y in range(board_logic.height):
		for x in range(board_logic.width):
			var t: Dictionary = board_logic.get_tile(Vector2(x, y))
			if t.kind == TileType.Kind.ENEMY:
				t["timer"] = int(t.get("attack_cooldown", 3))
	return {}
