extends SkillEffect

func apply(run: Node, board_logic: BoardLogic, skill: Dictionary) -> Dictionary:
	run.next_crit_forced = true
	run.next_crit_forced_mult = float(skill.get("crit_damage_mult", 2.0))
	return {"next_crit_set": true}
