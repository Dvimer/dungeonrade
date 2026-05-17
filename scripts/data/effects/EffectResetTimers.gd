extends SkillEffect

# Сбрасывает таймеры всех врагов. freeze_turns > 0 устанавливает фиксированное
# значение вместо attack_cooldown (блокирует атаки на несколько ходов).
func apply(run: Node, board_logic: BoardLogic, skill: Dictionary) -> Dictionary:
	var freeze_turns: int = int(skill.get("freeze_turns", 0))
	for y in range(board_logic.height):
		for x in range(board_logic.width):
			var t: Dictionary = board_logic.get_tile(Vector2(x, y))
			if t.kind == TileType.Kind.ENEMY:
				if freeze_turns > 0:
					t["timer"] = freeze_turns
				else:
					t["timer"] = int(t.get("attack_cooldown", 3))
	return {}
