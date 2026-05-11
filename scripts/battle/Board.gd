extends Node2D
class_name Board

# Визуальное поле: спавнит тайлы, синхронизирует их с BoardLogic.
# Логику не дублирует — только рендер.

@export var board_width: int = 6
@export var board_height: int = 6
@export var tile_size: float = 96.0
@export var tile_spacing: float = 4.0
@export var debug_hover: bool = false

var logic: BoardLogic
var tiles: Array = []     # tiles[y][x] = Tile
var _last_path: Array = []
var _hover_pos: Vector2 = Vector2(-1, -1)
var _hover_info_panel: PanelContainer
var _hover_info_label: Label
var is_animating: bool = false
var _active_chain_path: Array = []
var _chain_glint_t: float = 0.0
var _chain_glint_line: Line2D
var _chain_glint_glow: Line2D
const RESOLVE_SPEED_SCALE := 1.2
const FRAME_PAD := 26.0
const COLOR_FRAME_DARK := Color(0.045, 0.043, 0.050, 0.96)
const COLOR_FRAME_INNER := Color(0.10, 0.105, 0.13, 0.92)
const COLOR_FOIL := Color(0.73, 0.55, 0.30, 0.82)
const COLOR_FOIL_HI := Color(0.95, 0.80, 0.45, 0.95)

const HOVER_RULES := {
	TileType.Kind.SWORD: {
		"hoverable": true,
		"keep_kinds": [TileType.Kind.SWORD, TileType.Kind.ENEMY],
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
	set_process(true)
	logic = BoardLogic.new(board_width, board_height)
	logic.fill_random(0.14)
	EventBus.enemy_damaged.connect(_on_enemy_damaged)
	_spawn_tiles()
	_setup_hover_info()
	_setup_chain_glint()
	queue_redraw()

func _process(delta: float) -> void:
	if _active_chain_path.size() < 2:
		_set_chain_glint_visible(false)
		return
	_chain_glint_t = fmod(_chain_glint_t + delta * 1.65, 1.0)
	_update_chain_glint()

func _draw() -> void:
	var board_px := Vector2(
		board_width * tile_size + (board_width - 1) * tile_spacing,
		board_height * tile_size + (board_height - 1) * tile_spacing
	)
	var board_rect := Rect2(-board_px / 2.0, board_px)
	var frame_rect := board_rect.grow(FRAME_PAD)
	var inner_rect := board_rect.grow(10.0)

	draw_rect(frame_rect.grow(8.0), Color(0, 0, 0, 0.62), true)
	draw_rect(frame_rect, COLOR_FRAME_DARK, true)
	draw_rect(frame_rect.grow(-4.0), COLOR_FRAME_INNER, false, 3.0)
	draw_rect(inner_rect, Color(0.025, 0.026, 0.032, 0.72), true)
	draw_rect(inner_rect, COLOR_FOIL.darkened(0.18), false, 2.0)
	draw_rect(board_rect.grow(3.0), Color(0, 0, 0, 0.45), false, 3.0)

	for y in range(board_height):
		for x in range(board_width):
			var center := _grid_to_local(Vector2(x, y))
			var cell := Rect2(center - Vector2.ONE * tile_size * 0.5, Vector2.ONE * tile_size)
			draw_rect(cell.grow(3.0), Color(0, 0, 0, 0.22), false, 1.0)

	var corner_len := 36.0
	var corners := [
		Vector2(frame_rect.position.x + 8.0, frame_rect.position.y + 8.0),
		Vector2(frame_rect.end.x - 8.0, frame_rect.position.y + 8.0),
		Vector2(frame_rect.position.x + 8.0, frame_rect.end.y - 8.0),
		Vector2(frame_rect.end.x - 8.0, frame_rect.end.y - 8.0),
	]
	for i in range(corners.size()):
		var p: Vector2 = corners[i]
		var sx := -1.0 if i % 2 == 1 else 1.0
		var sy := -1.0 if i >= 2 else 1.0
		draw_line(p, p + Vector2(sx * corner_len, 0), COLOR_FOIL_HI, 2.0)
		draw_line(p, p + Vector2(0, sy * corner_len), COLOR_FOIL_HI, 2.0)
		draw_circle(p + Vector2(sx * 7.0, sy * 7.0), 3.0, COLOR_FOIL)

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

func apply_wave_profile(wave_config: Dictionary, refill_board: bool = false) -> void:
	if logic == null:
		return
	logic.configure_spawn(
		float(wave_config.get("enemy_spawn_chance", logic.enemy_spawn_chance)),
		wave_config.get("monster_weights", {})
	)
	if refill_board:
		logic.fill_random(logic.enemy_spawn_chance)
		sync_view()

func spawn_monster(monster_id: String) -> Vector2:
	if logic == null:
		return Vector2(-1, -1)
	var pos := logic.spawn_enemy(monster_id)
	if pos.x >= 0:
		sync_view()
		var node := get_tile_node(pos)
		if node:
			node.z_index = 160
			node.scale = Vector2(0.7, 0.7)
			node.modulate = Color(1.35, 0.82, 0.38, 1.0)
			var tween := create_tween().set_parallel(true)
			tween.tween_property(node, "scale", Vector2(1.18, 1.18), 0.16) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(node, "scale", Vector2.ONE, 0.12).set_delay(0.16) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(node, "modulate", Color.WHITE, 0.22) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.chain().tween_callback(func():
				if is_instance_valid(node):
					node.z_index = 0
			)
	return pos

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
	if t != null and not _is_hoverable_tile(t):
		t = null
	var new_pos: Vector2 = t.board_pos if t != null else Vector2(-1, -1)
	if new_pos == _hover_pos:
		_update_hover_info_position(world_point)
		return
	if t != null and debug_hover:
		print("[HOVER] cursor over cell=", t.board_pos, " world=", world_point, " kind=", t.data.kind)
	elif debug_hover:
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
	_active_chain_path = path.duplicate()
	if _active_chain_path.size() < 2:
		_set_chain_glint_visible(false)
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

func play_enemy_attacks(attackers: Array) -> void:
	if attackers.is_empty():
		return
	for ep in attackers:
		var node := get_tile_node(ep)
		if node == null:
			continue
		_play_enemy_attack(node)
	await get_tree().create_timer(0.30).timeout
	for ep in attackers:
		var node := get_tile_node(ep)
		if node:
			node.position = _grid_to_local(ep)
			node.scale = Vector2.ONE
			node.rotation = 0.0
			node.modulate = Color.WHITE
			node.z_index = 0

# Применить расход тайлов и пополнение, обновить визуал.
# (Анимации опускания пока без интерполяции — для прототипа достаточно.)
func consume_and_refill(consumed: Array, mark_spawned_enemies_fresh: bool = false) -> void:
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

	var result: Dictionary = logic.apply_consumed_and_refill(consumed, mark_spawned_enemies_fresh)
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

func _play_enemy_attack(node: Tile) -> void:
	var original := node.position
	var lunge := Vector2(-18, -22)
	node.z_index = 180
	node.rotation = 0.0

	var motion := create_tween()
	motion.tween_property(node, "position", original + lunge, 0.08) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	motion.tween_property(node, "position", original + Vector2(10, 8), 0.07) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	motion.tween_property(node, "position", original, 0.12) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	var squash := create_tween()
	squash.tween_property(node, "scale", Vector2(1.20, 0.86), 0.08) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	squash.tween_property(node, "scale", Vector2(0.92, 1.16), 0.07) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	squash.tween_property(node, "scale", Vector2.ONE, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var flash := create_tween()
	flash.tween_property(node, "modulate", Color(1.35, 0.62, 0.42, 1.0), 0.06)
	flash.tween_property(node, "modulate", Color.WHITE, 0.16)

	var twist := create_tween()
	twist.tween_property(node, "rotation", deg_to_rad(-8.0), 0.07)
	twist.tween_property(node, "rotation", deg_to_rad(7.0), 0.07)
	twist.tween_property(node, "rotation", 0.0, 0.12)

func _apply_hover_rule(tile: Tile, world_point: Vector2) -> void:
	_clear_hover_dim()
	_hide_hover_info()
	if tile == null:
		return
	var rule: Dictionary = HOVER_RULES.get(tile.data.kind, {})
	if tile.data.kind == TileType.Kind.ENEMY and bool(tile.data.get("is_boss", false)):
		_show_monster_info(tile, world_point)
		return
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

func _is_hoverable_tile(tile: Tile) -> bool:
	if tile == null:
		return false
	if tile.data.kind == TileType.Kind.ENEMY:
		return bool(tile.data.get("is_boss", false))
	return _is_hoverable_kind(tile.data.kind)

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
	_hover_info_label.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62))
	_hover_info_label.text = ""
	_hover_info_panel.add_child(_hover_info_label)

func _show_sword_power(world_point: Vector2) -> void:
	if _hover_info_label == null or _hover_info_panel == null:
		return
	var sword_count: int = _count_tiles_of_kind(TileType.Kind.SWORD)
	var sword_power: int = 1 + int(RunState.mod("sword_damage_bonus", 0))
	var total_power: int = sword_power * sword_count
	_hover_info_label.text = Localization.t("preview.might", [sword_power, sword_count, total_power])
	_hover_info_panel.visible = true
	_update_hover_info_position(world_point)

func _show_monster_info(tile: Tile, world_point: Vector2) -> void:
	if _hover_info_label == null or _hover_info_panel == null:
		return
	var monster_id := str(tile.data.get("monster_id", ""))
	var fallback_name := str(tile.data.get("monster_name", "Boss"))
	var name := Localization.monster_name(monster_id, fallback_name).to_upper()
	_hover_info_label.text = Localization.t("monster.info", [
		name,
		int(tile.data.get("hp", 0)),
		int(tile.data.get("dmg", 0)),
		int(tile.data.get("timer", 0)),
	])
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
	var amount: int = _count_chain_kind(path, kind)
	var text := ""
	match kind:
		TileType.Kind.SWORD:
			var sword_power: int = 1 + int(RunState.mod("sword_damage_bonus", 0))
			text = Localization.t("preview.attack", [sword_power * amount])
		TileType.Kind.HEART:
			text = Localization.t("preview.heal", [amount])
		TileType.Kind.SHIELD:
			text = Localization.t("preview.shield", [amount])
		TileType.Kind.COIN:
			text = Localization.t("preview.gold", [amount])
		_:
			text = "+%d" % [amount]
	_hover_info_label.text = text
	_hover_info_panel.visible = true
	_update_hover_info_position(world_point)

func clear_chain_preview() -> void:
	_hide_hover_info()

func _on_enemy_damaged(pos: Vector2, _dmg: int) -> void:
	var node := get_tile_node(pos)
	if node == null:
		return
	var original := node.position
	var tween := create_tween()
	tween.tween_property(node, "modulate", Color(1.25, 0.38, 0.30, 1.0), 0.05)
	tween.tween_property(node, "position", original + Vector2(5, -2), 0.04)
	tween.tween_property(node, "position", original + Vector2(-4, 3), 0.04)
	tween.tween_property(node, "position", original, 0.04)
	tween.tween_property(node, "modulate", Color.WHITE, 0.12)
	show_float_at_grid(pos, "-%d" % [_dmg], Color(1.0, 0.34, 0.24), Vector2(0, -42))

func _count_chain_kind(path: Array, kind: int) -> int:
	var count := 0
	for p in path:
		if logic.get_tile(p).kind == kind:
			count += 1
	return count

func show_float_at_grid(pos: Vector2, text: String, color: Color, offset: Vector2 = Vector2.ZERO) -> void:
	var label := Label.new()
	label.text = text
	label.size = Vector2(150, 34)
	label.pivot_offset = label.size * 0.5
	label.position = _grid_to_local(pos) + offset - label.pivot_offset
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.z_index = 420
	label.scale = Vector2(0.72, 0.72)
	add_child(label)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 48.0, 0.72) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.08, 1.08), 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.28).set_delay(0.48)
	tween.chain().tween_callback(label.queue_free)

func _setup_chain_glint() -> void:
	_chain_glint_glow = Line2D.new()
	_chain_glint_glow.z_index = 13
	_chain_glint_glow.width = 18.0
	_chain_glint_glow.default_color = Color(1.0, 0.72, 0.24, 0.18)
	_chain_glint_glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_chain_glint_glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	_chain_glint_glow.antialiased = true
	_chain_glint_glow.visible = false
	add_child(_chain_glint_glow)

	_chain_glint_line = Line2D.new()
	_chain_glint_line.z_index = 14
	_chain_glint_line.width = 5.0
	_chain_glint_line.default_color = Color(1.0, 0.95, 0.72, 0.86)
	_chain_glint_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_chain_glint_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_chain_glint_line.antialiased = true
	_chain_glint_line.visible = false
	add_child(_chain_glint_line)

func _set_chain_glint_visible(on: bool) -> void:
	if _chain_glint_line:
		_chain_glint_line.visible = on
	if _chain_glint_glow:
		_chain_glint_glow.visible = on

func _update_chain_glint() -> void:
	if _active_chain_path.size() < 2:
		_set_chain_glint_visible(false)
		return
	var ahead := _point_on_chain(min(_chain_glint_t + 0.035, 1.0))
	var back := _point_on_chain(max(_chain_glint_t - 0.035, 0.0))
	var pts := PackedVector2Array([back, ahead])
	if _chain_glint_line:
		_chain_glint_line.points = pts
	if _chain_glint_glow:
		_chain_glint_glow.points = pts
	_set_chain_glint_visible(true)

func _point_on_chain(progress: float) -> Vector2:
	if _active_chain_path.size() == 0:
		return Vector2.ZERO
	if _active_chain_path.size() == 1:
		return _grid_to_local(_active_chain_path[0])

	var points := []
	var total := 0.0
	for p in _active_chain_path:
		points.append(_grid_to_local(p))
	for i in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
	if total <= 0.0:
		return points[0]

	var target := progress * total
	var walked := 0.0
	for i in range(1, points.size()):
		var a: Vector2 = points[i - 1]
		var b: Vector2 = points[i]
		var seg := a.distance_to(b)
		if seg <= 0.0:
			continue
		if walked + seg >= target:
			var t := (target - walked) / seg
			return a.lerp(b, t)
		walked += seg
	return points[points.size() - 1]
