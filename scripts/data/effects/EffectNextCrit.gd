extends SkillEffect

func apply(run: Node, board_logic: BoardLogic) -> Dictionary:
	run.next_crit_forced = true
	return {"next_crit_set": true}
