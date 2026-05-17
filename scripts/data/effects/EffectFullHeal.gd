extends SkillEffect

func apply(run: Node, board_logic: BoardLogic, skill: Dictionary) -> Dictionary:
	var amount: int = run.max_hp - run.hp
	if amount > 0:
		run.heal(amount)
	return {}
