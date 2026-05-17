extends SkillEffect

func apply(run: Node, board_logic: BoardLogic, skill: Dictionary) -> Dictionary:
	var dmg: int = run.sword_power()
	var total := 0
	var to_clear: Array = []
	for y in range(board_logic.height):
		for x in range(board_logic.width):
			var p := Vector2(x, y)
			var t: Dictionary = board_logic.get_tile(p)
			if t.kind == TileType.Kind.ENEMY:
				t.hp -= dmg
				total += dmg
				EventBus.emit_signal("enemy_damaged", p, dmg)
				if t.hp <= 0:
					EventBus.emit_signal("enemy_killed", p)
					to_clear.append(p)
	return {"tiles_cleared": to_clear, "damage_dealt": total}
