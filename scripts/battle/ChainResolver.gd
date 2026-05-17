extends RefCounted
class_name ChainResolver

# Преобразует валидную цепочку позиций в ChainResult.
# Учитывает:
#   - длину цепи (множитель и комбо-лейбл),
#   - тип тайлов (мечи -> урон, щиты -> щит, монеты -> золото, хил -> HP),
#   - врагов в цепи (получают урон от мечей в этой же цепи),
#   - модификаторы из RunState (бонусы класса/апгрейдов).

const COMBO_THRESHOLDS := [
	{"len": 8, "label": "godlike", "mult": 2.0},
	{"len": 6, "label": "insane",  "mult": 1.5},
	{"len": 4, "label": "great",   "mult": 1.2},
]

# --- ЧЕКЛИСТ при добавлении нового TileType.Kind ---
# 1. TileType.gd    : добавить в Kind, SPAWN_WEIGHTS, name_of(); can_link() если линкуется с другим типом
# 2. Здесь resolve(): добавить счётчик var, кейс в match, включить в resource_count
# 3. ChainResult.gd : добавить поле для нового ресурса (например: var mana_gained: int = 0)
# 4. Здесь apply()  : добавить run.add_xxx(result.xxx_gained)
# 5. Board.gd       : добавить визуал тайла (текстура, цвет)
static func resolve(board: BoardLogic, path: Array, run: Node) -> ChainResult:
	var result := ChainResult.new()
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
	var resource_count := swords + shields + coins + hearts
	result.chain_length = resource_count

	# --- Множители комбо ---
	var mult: float = 1.0
	for tier in COMBO_THRESHOLDS:
		if resource_count >= tier.len:
			mult = tier.mult
			result.label = Localization.combo_label(str(tier.label), str(tier.label).to_upper())
			break
	result.combo_multiplier = mult

	# --- Крит ---
	var crit_chance: float = float(run.mod("crit_chance", 0.0))
	# Синергия меч+монета: монеты в одной цепи с мечами повышают шанс крита.
	if swords > 0 and coins > 0:
		crit_chance += 0.05 * coins
	if randf() < crit_chance:
		result.crit = true
	# Форсированный крит от активного навыка
	var _forced_crit := false
	if not result.crit and "next_crit_forced" in run and bool(run.next_crit_forced):
		result.crit = true
		_forced_crit = true
		run.next_crit_forced = false

	# --- Урон ---
	if result.enemies_in_chain.size() > 0:
		var base_dmg := _attack_base_damage(run, swords)
		var dmg := int(round(base_dmg * mult))
		if result.crit:
			var crit_mult := 2.0
			if _forced_crit and "next_crit_forced_mult" in run:
				crit_mult = float(run.next_crit_forced_mult)
				run.next_crit_forced_mult = 2.0
			dmg = int(round(dmg * crit_mult))
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

	# --- Class passives (resolve phase) ---
	var class_passive: String = str(run.class_passive) if "class_passive" in run else ""
	if class_passive == "rogue_coin_attack" and coins > 0 and result.enemies_in_chain.size() > 0:
		result.damage_to_enemies += coins
	if class_passive == "vampire_heart_shield" and hearts > 0:
		result.shield_gained += hearts

	return result

# Применяет результат: тратит HP врагов, восстанавливает HP игрока,
# даёт золото/щит. Возвращает массив позиций, которые надо очистить
# (включая всех убитых врагов).
static func apply(board: BoardLogic, result: ChainResult, run: Node) -> Array:
	# Распределяем урон по врагам в цепи поровну (округляя в большую сторону).
	var kill_gold_bonus := 0
	if result.damage_to_enemies > 0 and result.enemies_in_chain.size() > 0:
		var per := result.damage_to_enemies
		for ep in result.enemies_in_chain:
			var t = board.get_tile(ep)
			if t.kind == TileType.Kind.ENEMY:
				var reduced := maxi(1, per - int(t.get("defense", 0)))
				t.hp -= reduced
				EventBus.emit_signal("enemy_damaged", ep, reduced)
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
		result.gold_gained = run.add_gold(result.gold_gained)
	if kill_gold_bonus > 0:
		var kill_gold_actual: int = run.add_gold(kill_gold_bonus)
		result.gold_gained += kill_gold_actual

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

	# --- Alchemist poison spread ---
	if "class_passive" in run and str(run.class_passive) == "alchemist_poison":
		var poison_additions: Array = []
		for ep in result.enemies_in_chain:
			var t = board.get_tile(ep)
			if t.kind == TileType.Kind.ENEMY and int(t.get("hp", 1)) <= 0:
				var poisoned_pos := _find_poison_target(board, ep)
				if poisoned_pos.x >= 0:
					var pt = board.get_tile(poisoned_pos)
					pt.hp = maxi(0, int(pt.hp) - 1)
					EventBus.emit_signal("enemy_damaged", poisoned_pos, 1)
					if int(pt.hp) <= 0:
						result.killed_enemies.append(pt.duplicate(true))
						EventBus.emit_signal("enemy_killed", poisoned_pos)
						poison_additions.append(poisoned_pos)
		to_clear.append_array(poison_additions)

	return to_clear

static func _reset_timer_after_hit(enemy_tile: Dictionary) -> void:
	if bool(enemy_tile.get("reset_timer_on_hit", false)):
		enemy_tile.timer = int(enemy_tile.get("hit_timer_reset", enemy_tile.get("timer", 3)))

static func _attack_base_damage(run: Node, swords: int) -> int:
	var sword_power := 1 + int(run.mod("sword_damage_bonus", 0))
	var attack_instances := maxi(1, swords)
	return attack_instances * sword_power

static func _find_poison_target(board: BoardLogic, origin: Vector2) -> Vector2:
	if randf() >= 0.40:
		return Vector2(-1, -1)
	var candidates := []
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var np := Vector2(int(origin.x) + dx, int(origin.y) + dy)
			if not board.in_bounds(np):
				continue
			var nt = board.get_tile(np)
			if nt.kind == TileType.Kind.ENEMY and int(nt.get("hp", 0)) > 0:
				candidates.append(np)
	if candidates.is_empty():
		return Vector2(-1, -1)
	return candidates[randi() % candidates.size()]
