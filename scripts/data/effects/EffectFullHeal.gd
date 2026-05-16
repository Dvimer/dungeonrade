extends SkillEffect

func apply(run: Node, board_logic: BoardLogic) -> Dictionary:
	var amount: int = run.max_hp - run.hp
	if amount > 0:
		run.heal(amount)
	return {}
