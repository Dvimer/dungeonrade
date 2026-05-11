extends RefCounted
class_name BoardLogic

# Чистая логика поля. Никаких нод — только данные.
# grid[y][x] — словарь {kind: int, hp: int, dmg: int, timer: int}.
# Для не-врагов dmg/timer/hp игнорируются.

var width: int
var height: int
var grid: Array = []     # Array[Array[Dictionary]]
var rng := RandomNumberGenerator.new()
var enemy_spawn_chance: float = 0.0

func _init(w: int = 6, h: int = 6, rng_seed: int = 0) -> void:
	width = w
	height = h
	if rng_seed != 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	_build_empty()

func _build_empty() -> void:
	grid.clear()
	for y in range(height):
		var row := []
		for x in range(width):
			row.append(_make_empty())
		grid.append(row)

# --- Базовые операции ---
func in_bounds(p: Vector2) -> bool:
	return p.x >= 0 and p.x < width and p.y >= 0 and p.y < height

func get_tile(p: Vector2) -> Dictionary:
	return grid[int(p.y)][int(p.x)]

func set_tile(p: Vector2, tile: Dictionary) -> void:
	grid[int(p.y)][int(p.x)] = tile

func clear_tile(p: Vector2) -> void:
	set_tile(p, _make_empty())

func _make_empty() -> Dictionary:
	return {"kind": TileType.Kind.EMPTY}

# --- Соседство (8 направлений) ---
static func are_neighbors(a: Vector2, b: Vector2) -> bool:
	if a == b:
		return false
	var dx: int = int(abs(a.x - b.x))
	var dy: int = int(abs(a.y - b.y))
	return dx <= 1 and dy <= 1

# --- Проверка цепочки ---
# Возвращает true, если последовательность позиций — валидная цепь:
#   - все в границах,
#   - нет повторов,
#   - соседние позиции — реально соседи,
#   - все типы можно связать (TileType.can_link).
func is_valid_chain(path: Array) -> bool:
	if path.size() < 2:
		return false
	var seen := {}
	for i in range(path.size()):
		var p: Vector2 = path[i]
		if not in_bounds(p):
			return false
		var key := "%d,%d" % [int(p.x), int(p.y)]
		if seen.has(key):
			return false
		seen[key] = true
		if i > 0 and not BoardLogic.are_neighbors(path[i - 1], p):
			return false
	# Проверяем линкуемость по всем парам подряд.
	var prev_kind: int = get_tile(path[0]).kind
	for i in range(1, path.size()):
		var cur_kind: int = get_tile(path[i]).kind
		if not TileType.can_link(prev_kind, cur_kind):
			return false
		prev_kind = cur_kind
	return true

# --- Генерация ---
func fill_random(enemy_chance: float = 0.0) -> void:
	enemy_spawn_chance = enemy_chance
	for y in range(height):
		for x in range(width):
			var p := Vector2(x, y)
			if rng.randf() < enemy_spawn_chance:
				set_tile(p, _make_enemy(1, 1, 3))
			else:
				set_tile(p, _make_random_basic())

func _make_random_basic() -> Dictionary:
	var total := 0
	for w in TileType.SPAWN_WEIGHTS.values():
		total += w
	var r := rng.randi_range(1, total)
	var acc := 0
	for kind in TileType.SPAWN_WEIGHTS.keys():
		acc += TileType.SPAWN_WEIGHTS[kind]
		if r <= acc:
			return {"kind": kind}
	return {"kind": TileType.Kind.SWORD}

func _make_enemy(hp: int, dmg: int, timer: int) -> Dictionary:
	return {
		"kind": TileType.Kind.ENEMY,
		"hp": hp,
		"max_hp": hp,
		"dmg": dmg,
		"timer": timer,
	}

# --- Гравитация и пополнение поля после хода ---
# Очищает позиции, опускает оставшиеся вниз, спавнит новые сверху.
# Возвращает массив "движений" для анимации:
#   [{from: Vector2, to: Vector2}, ...] и {spawned: [{pos, tile}, ...]}.
func apply_consumed_and_refill(consumed: Array) -> Dictionary:
	for p in consumed:
		clear_tile(p)
	var movements := []
	for x in range(width):
		# Собираем не-пустые тайлы снизу вверх.
		var stack := []
		for y in range(height - 1, -1, -1):
			var tile = grid[y][x]
			if tile.kind != TileType.Kind.EMPTY:
				stack.append({"tile": tile, "from_y": y})
		# Раскладываем снизу.
		var write_y := height - 1
		for entry in stack:
			if entry.from_y != write_y:
				movements.append({
					"from": Vector2(x, entry.from_y),
					"to": Vector2(x, write_y),
				})
			grid[write_y][x] = entry.tile
			write_y -= 1
		# Заполняем верх.
		var spawned := []
		for y in range(write_y, -1, -1):
			var t := _make_enemy(1, 1, 3) if rng.randf() < enemy_spawn_chance else _make_random_basic()
			grid[y][x] = t
			spawned.append({"pos": Vector2(x, y), "tile": t})
		if spawned.size() > 0:
			movements.append({"spawned_column": x, "spawned": spawned})
	return {"movements": movements}

# --- Тики врагов ---
# Уменьшает таймер у всех врагов на 1, возвращает позиции тех, кто атакует.
func tick_enemies() -> Array:
	var attackers := []
	for y in range(height):
		for x in range(width):
			var t = grid[y][x]
			if t.kind == TileType.Kind.ENEMY:
				t.timer -= 1
				if t.timer <= 0:
					attackers.append(Vector2(x, y))
					t.timer = 3   # перезарядка после атаки
	return attackers
