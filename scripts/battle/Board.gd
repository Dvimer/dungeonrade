extends Node2D
class_name Board

# Визуальное поле: спавнит тайлы, синхронизирует их с BoardLogic.
# Логику не дублирует — только рендер.

@export var board_width: int = 6
@export var board_height: int = 6
@export var tile_size: float = 96.0
@export var tile_spacing: float = 4.0

var logic: BoardLogic
var tiles: Array = []     # tiles[y][x] = Tile
var _last_path: Array = []
var _hover_pos: Vector2 = Vector2(-1, -1)
var _hover_info_panel: PanelContainer
var _hover_info_label: Label
var is_animating: bool = false
const RESOLVE_SPEED_SCALE := 1.2

const HOVER_RULES := {
	TileType.Kind.SWORD: {
		"hoverable": true,
		"keep_kinds": [TileType.Kind.SWORD, TileType.Kind.ENEMY],
		"show_sword_power": true,
	},
	TileType.Kind.SHIELD: {
		"hoverable": true,
		"keep_kinds": [TileType.Kind.SHIELD],
	},
	TileType.Kind.COIN: {
		"hoverable": true,
		"keep_kinds": [TileType.Kind.COIN],
	},
	TileType.Kind.HEART: {
		"hoverable": true,
		"keep_kinds": [TileType.Kind.HEART],
	},
	TileType.Kind.ENEMY: {
		"hoverable": false,
	},
}

const TileScene := preload("res://scenes/battle/Tile.tscn")

# Цвета линии цепи в зависимости от типа первого тайла.
const CHAIN_COLORS := {
	TileType.Kind.SWORD:  Color(1.0, 0.55, 0.45, 0.95),
	TileType.Kind.SHIELD: Color(0.55, 0.75, 1.0, 0.95),
	TileType.Kind.COIN:   Color(1.0, 0.9, 0.45, 0.95),
	TileType.Kind.HEART:  Color(0.55, 1.0, 0.7, 0.95),
	TileType.Kind.ENEMY:  Color(1.0, 0.55, 0.45, 0.95),
}

@onready var _chain_line: Line2D = $ChainLine
@onready var _chain_glow: Line2D = $ChainGlow

func _ready() -> void:
	logic = BoardLogic.new(board_width, board_height)
	logic.fill_random(0.18)
	_spawn_tiles()
	_setup_hover_info()

func _spawn_tiles() -> void:
	for y in range(board_height):
		var row := []
		for x in range(board_width):
			var t := TileScene.instantiate() as Tile
			t.tile_size = tile_size
			t.position = _grid_to_local(Vector2(x, y))
			t.setup(Vector2(x, y), logic.get_tile(Vector2(x, y)))
			add_child(t)
			row.append(t)
		tiles.append(row)

# Локальные координаты тайла (центрированная раскладка).
func _grid_to_local(p: Vector2) -> Vector2:
	var step := tile_size + tile_spacing
	var origin_x := -((board_width - 1) * step) / 2.0
	var origin_y := -((board_height - 1) * step) / 2.0
	return Vector2(origin_x + p.x * step, origin_y + p.y * step)

func get_tile_at_world(world_point: Vector2) -> Tile:
	# Простая и явная логика хит-теста:
	# у каждой ячейки есть свой прямоугольник tile_size x tile_size в тех же
	# координатах, где она отрисована. Если точка мыши попала в прямоугольник,
	# значит ячейка активна, её можно подсветить и кликнуть.
	var local: Vector2 = to_local(world_point)
	for y in range(board_height):
		for x in range(board_width):
			var rect := _cell_rect_local(Vector2(x, y))
			if rect.has_point(local):
				return get_tile_node(Vector2(x, y))
	return null

func _cell_rect_local(p: Vector2) -> Rect2:
	var center: Vector2 = _grid_to_local(p)
	var half: Vector2 = Vector2.ONE * (tile_size / 2.0)
	return Rect2(center - half, Vector2.ONE * tile_size)

func get_tile_node(p: Vector2) -> Tile:
	if p.y < 0 or p.y >= tiles.size():
		return null
	var row = tiles[int(p.y)]
	if p.x < 0 or p.x >= row.size():
		return null
	return row[int(p.x)]

# --- Подсветка цепи ---
# Дифф-обновление: дёргаем set_highlighted ТОЛЬКО на изменившихся тайлах,
# чтобы пульс-анимация в Tile.gd не запускалась каждый кадр.
func highlight_path(path: Array) -> void:
	var new_keys := {}
	for p in path:
		new_keys[_key(p)] = p
	var old_keys := {}
	for p in _last_path:
		old_keys[_key(p)] = p

	# Снимаем подсветку с тайлов, которые ушли из пути.
	for k in old_keys.keys():
		if not new_keys.has(k):
			var n := get_tile_node(old_keys[k])
			if n:
				n.set_highlighted(false)

	# Подсвечиваем новые тайлы (которых не было в прошлом пути).
	for k in new_keys.keys():
		if not old_keys.has(k):
			var n := get_tile_node(new_keys[k])
			if n:
				n.set_highlighted(true)

	_last_path = path.duplicate()
	_update_chain_line(path)

func clear_highlights() -> void:
	for p in _last_path:
		var n := get_tile_node(p)
		if n:
			n.set_highlighted(false)
	_last_path.clear()
	_update_chain_line([])

# Гасит все тайлы, не совместимые с типом start_kind.
# Используется при старте свайпа: например, кликнули на меч →
# щиты/монеты/хилы тускнеют, а мечи и враги остаются яркими.
func focus_kind(start_kind: int) -> void:
	for y in range(board_height):
		for x in range(board_width):
			var node := get_tile_node(Vector2(x, y))
			if not node:
				continue
			var k: int = logic.get_tile(Vector2(x, y)).kind
			var compatible: bool = TileType.can_link(start_kind, k)
			node.set_dim(not compatible)

func unfocus_all() -> void:
	for y in range(board_height):
		for x in range(board_width):
			var node := get_tile_node(Vector2(x, y))
			if node:
				node.set_dim(false)

# --- Hover ---
# Подсвечивает рамкой тайл под курсором мыши. На сенсоре не используется.
func set_hover_at_world(world_point: Vector2) -> void:
	var t: Tile = get_tile_at_world(world_point)
	if t != null and not _is_hoverable_kind(t.data.kind):
		t = null
	var new_pos: Vector2 = t.board_pos if t != null else Vector2(-1, -1)
	if new_pos == _hover_pos:
		_update_hover_info_position(world_point)
		return
	if t != null:
		print("[HOVER] cursor over cell=", t.board_pos, " world=", world_point, " kind=", t.data.kind)
	else:
		print("[HOVER] cursor left board world=", world_point)
	# снимаем hover с предыдущего
	if _hover_pos.x >= 0:
		var old := get_tile_node(_hover_pos)
		if old:
			old.set_hovered(false)
	_hover_pos = new_pos
	if t != null and not t.dimmed:
		t.set_hovered(true)
	_apply_hover_rule(t, world_point)

func clear_hover() -> void:
	if _hover_pos.x >= 0:
		var n := get_tile_node(_hover_pos)
		if n:
			n.set_hovered(false)
	_hover_pos = Vector2(-1, -1)
	_clear_hover_rule()

func _update_chain_line(path: Array) -> void:
	var pts := PackedVector2Array()
	for p in path:
		pts.append(_grid_to_local(p))
	if _chain_line:
		_chain_line.points = pts
	if _chain_glow:
		_chain_glow.points = pts

	if path.size() > 0:
		var k: int = logic.get_tile(path[0]).kind
		var col: Color = CHAIN_COLORS.get(k, Color(1, 1, 1, 0.9))
		if _chain_line:
			_chain_line.default_color = col
		if _chain_glow:
			var glow := col
			glow.a = 0.25
			_chain_glow.default_color = glow

func _key(p: Vector2) -> String:
	return "%d,%d" % [int(p.x), int(p.y)]

# Перерисовать визуал по логике (например, после изменения hp врага).
func sync_view() -> void:
	for y in range(board_height):
		for x in range(board_width):
			var node := get_tile_node(Vector2(x, y))
			if node:
				node.update_view(logic.get_tile(Vector2(x, y)))

# Применить расход тайлов и пополнение, обновить визуал.
# (Анимации опускания пока без интерполяции — для прототипа достаточно.)
func consume_and_refill(consumed: Array) -> void:
	if is_animating:
		return
	is_animating = true

	var consumed_keys := {}
	for p in consumed:
		consumed_keys[_key(p)] = true

	var old_tiles: Array = tiles
	var removed_nodes: Array = []
	var new_tiles: Array = []
	for y in range(board_height):
		var row := []
		for x in range(board_width):
			row.append(null)
		new_tiles.append(row)

	var result: Dictionary = logic.apply_consumed_and_refill(consumed)
	var tween := create_tween().set_parallel(true)

	for y in range(board_height):
		for x in range(board_width):
			var p := Vector2(x, y)
			if consumed_keys.has(_key(p)):
				var node: Tile = old_tiles[y][x]
				if node:
					removed_nodes.append(node)
					node.z_index = 120
					node.rotation = 0.0
					tween.tween_property(node, "scale", Vector2(1.16, 1.16), 0.07 * RESOLVE_SPEED_SCALE) \
						.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					tween.tween_property(node, "scale", Vector2(0.18, 0.18), 0.12 * RESOLVE_SPEED_SCALE) \
						.set_delay(0.07 * RESOLVE_SPEED_SCALE) \
						.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
					tween.tween_property(node, "modulate:a", 0.0, 0.14 * RESOLVE_SPEED_SCALE) \
						.set_delay(0.04 * RESOLVE_SPEED_SCALE) \
						.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
					tween.tween_property(node, "rotation", deg_to_rad(10.0), 0.08 * RESOLVE_SPEED_SCALE) \
						.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
					tween.tween_property(node, "rotation", deg_to_rad(-14.0), 0.11 * RESOLVE_SPEED_SCALE) \
						.set_delay(0.08 * RESOLVE_SPEED_SCALE) \
						.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	for x in range(board_width):
		var survivors: Array = []
		for y in range(board_height - 1, -1, -1):
			var p := Vector2(x, y)
			if not consumed_keys.has(_key(p)):
				var survivor: Tile = old_tiles[y][x]
				if survivor:
					survivors.append(survivor)

		var write_y: int = board_height - 1
		for node in survivors:
			var target := Vector2(x, write_y)
			new_tiles[write_y][x] = node
			node.board_pos = target
			node.update_view(logic.get_tile(target))
			var fall_distance: float = abs(node.position.y - _grid_to_local(target).y)
			var fall_time: float = clamp(0.12 + fall_distance / 520.0, 0.14, 0.28) * RESOLVE_SPEED_SCALE
			tween.tween_property(node, "position", _grid_to_local(target), fall_time) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween.tween_property(node, "scale", Vector2(1.04, 0.96), fall_time * 0.55) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tween.tween_property(node, "scale", Vector2.ONE, 0.10 * RESOLVE_SPEED_SCALE) \
				.set_delay(fall_time) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			write_y -= 1

		var spawn_offset: int = 0
		for y in range(write_y, -1, -1):
			var spawn_pos := Vector2(x, y)
			var node := TileScene.instantiate() as Tile
			node.tile_size = tile_size
			node.setup(spawn_pos, logic.get_tile(spawn_pos))
			node.position = _grid_to_local(Vector2(x, -1 - spawn_offset))
			node.modulate.a = 0.0
			node.scale = Vector2(0.88, 1.12)
			add_child(node)
			new_tiles[y][x] = node
			var spawn_fall_time: float = clamp(0.16 + spawn_offset * 0.03 + y * 0.01, 0.18, 0.34) * RESOLVE_SPEED_SCALE
			tween.tween_property(node, "position", _grid_to_local(spawn_pos), spawn_fall_time) \
				.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tween.tween_property(node, "modulate:a", 1.0, 0.14 * RESOLVE_SPEED_SCALE) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(node, "scale", Vector2(1.06, 0.94), spawn_fall_time) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(node, "scale", Vector2.ONE, 0.10 * RESOLVE_SPEED_SCALE) \
				.set_delay(spawn_fall_time) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			spawn_offset += 1

	await tween.finished

	for node in removed_nodes:
		if is_instance_valid(node):
			node.queue_free()

	tiles = new_tiles
	for y in range(board_height):
		for x in range(board_width):
			var node: Tile = tiles[y][x]
			if node:
				node.board_pos = Vector2(x, y)
				node.position = _grid_to_local(Vector2(x, y))
				node.scale = Vector2.ONE
				node.modulate.a = 1.0
				node.rotation = 0.0
				node.z_index = 0
				node.update_view(logic.get_tile(Vector2(x, y)))

	is_animating = false

func _apply_hover_rule(tile: Tile, world_point: Vector2) -> void:
	_clear_hover_dim()
	_hide_hover_info()
	if tile == null:
		return
	var rule: Dictionary = HOVER_RULES.get(tile.data.kind, {})
	var keep_kinds: Array = rule.get("keep_kinds", [])
	if keep_kinds.size() > 0:
		_apply_hover_focus(keep_kinds)
	if bool(rule.get("show_sword_power", false)):
		_show_sword_power(world_point)

func _clear_hover_rule() -> void:
	_clear_hover_dim()
	_hide_hover_info()

func _apply_hover_focus(keep_kinds: Array) -> void:
	var keep := {}
	for kind in keep_kinds:
		keep[kind] = true
	for y in range(board_height):
		for x in range(board_width):
			var node := get_tile_node(Vector2(x, y))
			if not node:
				continue
			var kind: int = logic.get_tile(Vector2(x, y)).kind
			node.set_hover_dim(not keep.has(kind))

func _clear_hover_dim() -> void:
	for y in range(board_height):
		for x in range(board_width):
			var node := get_tile_node(Vector2(x, y))
			if node:
				node.set_hover_dim(false)

func _is_hoverable_kind(kind: int) -> bool:
	var rule: Dictionary = HOVER_RULES.get(kind, {})
	return bool(rule.get("hoverable", true))

func _setup_hover_info() -> void:
	_hover_info_panel = PanelContainer.new()
	_hover_info_panel.visible = false
	_hover_info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_info_panel.z_index = 300
	_hover_info_panel.top_level = true
	add_child(_hover_info_panel)

	_hover_info_label = Label.new()
	_hover_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hover_info_label.add_theme_font_size_override("font_size", 20)
	_hover_info_label.text = ""
	_hover_info_panel.add_child(_hover_info_label)

func _show_sword_power(world_point: Vector2) -> void:
	if _hover_info_label == null or _hover_info_panel == null:
		return
	var sword_count: int = _count_tiles_of_kind(TileType.Kind.SWORD)
	var sword_power: int = 1 + int(RunState.mod("sword_damage_bonus", 0))
	var total_power: int = sword_power * sword_count
	_hover_info_label.text = "Might %d x %d = %d" % [sword_power, sword_count, total_power]
	_hover_info_panel.visible = true
	_update_hover_info_position(world_point)

func _update_hover_info_position(world_point: Vector2) -> void:
	if _hover_info_panel == null or not _hover_info_panel.visible:
		return
	_hover_info_panel.position = world_point + Vector2(18, -42)

func _hide_hover_info() -> void:
	if _hover_info_panel:
		_hover_info_panel.visible = false

func _count_tiles_of_kind(kind: int) -> int:
	var count: int = 0
	for y in range(board_height):
		for x in range(board_width):
			if logic.get_tile(Vector2(x, y)).kind == kind:
				count += 1
	return count

func show_chain_preview(path: Array, world_point: Vector2) -> void:
	if _hover_info_label == null or _hover_info_panel == null:
		return
	if path.is_empty():
		_hover_info_panel.visible = false
		return
	var start_tile := logic.get_tile(path[0])
	var kind: int = int(start_tile.kind)
	var amount: int = path.size()
	var text := ""
	match kind:
		TileType.Kind.SWORD:
			var sword_power: int = 1 + int(RunState.mod("sword_damage_bonus", 0))
			text = "ATK +%d" % [sword_power * amount]
		TileType.Kind.HEART:
			text = "HP +%d" % [amount]
		TileType.Kind.SHIELD:
			text = "Shield +%d" % [amount]
		TileType.Kind.COIN:
			text = "Gold +%d" % [amount]
		_:
			text = "+%d" % [amount]
	_hover_info_label.text = text
	_hover_info_panel.visible = true
	_update_hover_info_position(world_point)

func clear_chain_preview() -> void:
	_hide_hover_info()
