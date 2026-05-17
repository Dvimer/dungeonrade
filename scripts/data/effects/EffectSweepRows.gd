extends SkillEffect

# Собирает всё содержимое двух нижних рядов доски.
func apply(run: Node, board_logic: BoardLogic, skill: Dictionary) -> Dictionary:
	var positions: Array = []
	var gold := 0
	var healed := 0
	var shield_gained := 0
	var bottom: int = board_logic.height - 1
	for row in [bottom, bottom - 1]:
		if row < 0:
			continue
		for x in range(board_logic.width):
			var p := Vector2(x, row)
			var t: Dictionary = board_logic.get_tile(p)
			match t.kind:
				TileType.Kind.COIN:
					gold += 1
					positions.append(p)
				TileType.Kind.HEART:
					healed += 1
					positions.append(p)
				TileType.Kind.SHIELD:
					shield_gained += 1
					positions.append(p)
				TileType.Kind.SWORD:
					positions.append(p)
				TileType.Kind.ENEMY:
					var dmg: int = run.sword_power()
					t.hp -= dmg
					EventBus.emit_signal("enemy_damaged", p, dmg)
					if t.hp <= 0:
						EventBus.emit_signal("enemy_killed", p)
						positions.append(p)
	if gold > 0:
		run.add_gold(gold)
	if shield_gained > 0:
		run.add_shield(shield_gained)
	if healed > 0:
		run.heal(healed)
	return {"tiles_cleared": positions}
