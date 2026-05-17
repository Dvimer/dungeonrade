extends SkillEffect

func apply(run: Node, board_logic: BoardLogic, skill: Dictionary) -> Dictionary:
	var positions: Array = []
	var gold := 0
	for y in range(board_logic.height):
		for x in range(board_logic.width):
			var p := Vector2(x, y)
			var t: Dictionary = board_logic.get_tile(p)
			if t.kind == TileType.Kind.COIN:
				gold += 1
				positions.append(p)
	if gold > 0:
		run.add_gold(gold)
	return {"tiles_cleared": positions}
