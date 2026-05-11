extends RefCounted
class_name ChainResolver

# Преобразует валидную цепочку позиций в ChainResult.
# Учитывает:
#   - длину цепи (множитель и комбо-лейбл),
#   - тип тайлов (мечи -> урон, щиты -> щит, монеты -> золото, хил -> HP),
#   - врагов в цепи (получают урон от мечей в этой же цепи),
#   - модификаторы из RunState (бонусы класса/апгрейдов).

const COMBO_THRESHOLDS := [
	{"len": 8, "label": "GODLIKE", "mult": 2.0},
	{"len": 6, "label": "INSANE",  "mult": 1.5},
	{"len": 4, "label": "GREAT",   "mult": 1.2},
]

static func resolve(board: BoardLogic, path: Array, run: Node) -> ChainResult:
	var result := ChainResult.new()
	result.chain_length = path.size()
	result.consumed_positions = path.duplicate()

	var swords := 0
	var shields := 0
	var coins := 0
	var hearts := 0

	for p in path:
		var t = board.get_tile(p)
		match t.kind:
			TileType.Kind.SWORD:
				swords += 1
			TileType.Kind.SHIELD:
				shields += 1
			TileType.Kind.COIN:
				coins += 1
			TileType.Kind.HEART:
				hearts += 1
			TileType.Kind.ENEMY:
				result.enemies_in_chain.append(p)

	# --- Множители комбо ---
	var mult: float = 1.0
	for tier in COMBO_THRESHOLDS:
		if path.size() >= tier.len:
			mult = tier.mult
			result.label = tier.label
			break
	result.combo_multiplier = mult

	# --- Крит ---
	var crit_chance: float = float(run.mod("crit_chance", 0.0))
	# Синергия меч+монета: монеты в одной цепи с мечами повышают шанс крита.
	if swords > 0 and coins > 0:
		crit_chance += 0.05 * coins
	if randf() < crit_chance:
		result.crit = true

	# --- Урон ---
	if swords > 0:
		var sword_power := 1 + int(run.mod("sword_damage_bonus", 0))
		var base_dmg := swords * sword_power
		var dmg := int(round(base_dmg * mult))
		if result.crit:
			dmg = int(round(dmg * 2.0))
		result.damage_to_enemies = dmg

	# --- Щит ---
	if shields > 0:
		var base_shield := shields
		result.shield_gained = int(round(base_shield * mult))

	# --- Хил ---
	if hearts > 0:
		var base_heal := hearts
		result.heal_amount = int(round(base_heal * mult))

	# --- Золото ---
	if coins > 0:
		var base_gold := coins
		result.gold_gained = int(round(base_gold * mult))

	return result

# Применяет результат: тратит HP врагов, восстанавливает HP игрока,
# даёт золото/щит. Возвращает массив позиций, которые надо очистить
# (включая всех убитых врагов).
static func apply(board: BoardLogic, result: ChainResult, run: Node) -> Array:
	# Распределяем урон по врагам в цепи поровну (округляя в большую сторону).
	var kill_gold_bonus := 0
	if result.damage_to_enemies > 0 and result.enemies_in_chain.size() > 0:
		var per := int(ceil(float(result.damage_to_enemies) / float(result.enemies_in_chain.size())))
		for ep in result.enemies_in_chain:
			var t = board.get_tile(ep)
			if t.kind == TileType.Kind.ENEMY:
				t.hp -= per
				EventBus.emit_signal("enemy_damaged", ep, per)
				if t.hp <= 0:
					result.killed_enemies.append(t.duplicate(true))
					kill_gold_bonus += int(t.get("gold_bonus", 0))
					EventBus.emit_signal("enemy_killed", ep)
				elif bool(t.get("reset_timer_on_hit", false)):
					_reset_timer_after_hit(t)

	if result.shield_gained > 0:
		run.add_shield(result.shield_gained)
	if result.heal_amount > 0:
		run.heal(result.heal_amount)
	if result.gold_gained > 0:
		run.add_gold(result.gold_gained)
	if kill_gold_bonus > 0:
		result.gold_gained += kill_gold_bonus
		run.add_gold(kill_gold_bonus)

	# Готовим список позиций к очистке: всё из цепи, плюс убитые враги (на случай,
	# если они не вошли в путь, но получили урон через AoE-эффекты — задел на будущее).
	var killed_positions := {}
	for ep in result.enemies_in_chain:
		var t = board.get_tile(ep)
		if t.kind == TileType.Kind.ENEMY and t.hp <= 0:
			killed_positions["%d,%d" % [int(ep.x), int(ep.y)]] = true

	var to_clear := []
	for p in result.consumed_positions:
		var tile = board.get_tile(p)
		if tile.kind != TileType.Kind.ENEMY or killed_positions.has("%d,%d" % [int(p.x), int(p.y)]):
			to_clear.append(p)
	return to_clear

static func _reset_timer_after_hit(enemy_tile: Dictionary) -> void:
	if bool(enemy_tile.get("reset_timer_on_hit", false)):
		enemy_tile.timer = int(enemy_tile.get("hit_timer_reset", enemy_tile.get("timer", 3)))
