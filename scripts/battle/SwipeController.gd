extends Node2D
class_name SwipeController

# Обработка ввода: палец/мышь ведёт по тайлам, формирует path.
# При отпускании — резолвим цепь через ChainResolver.

@export var board_path: NodePath
@export var debug_log: bool = true   # отключи, когда не нужно

var board: Board
var path: Array = []
var dragging: bool = false
var _last_drag_world: Vector2 = Vector2.ZERO

func _ready() -> void:
	board = get_node(board_path) as Board

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		var world := get_global_mouse_position()
		if event.pressed:
			_start_at(world)
		else:
			_finish()
		return

	if event is InputEventMouseMotion:
		var world := get_global_mouse_position()
		if debug_log:
			print("[INPUT] mouse motion world=", world, " screen=", event.position)
		if dragging:
			_extend_to(world)
		else:
			board.set_hover_at_world(world)
		return

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_at(_event_world_pos(event))
		else:
			_finish()
	elif event is InputEventScreenDrag:
		if dragging:
			_extend_to(_event_world_pos(event))

func _event_world_pos(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		return get_global_mouse_position()
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		return get_canvas_transform().affine_inverse() * event.position
	return Vector2.ZERO

func _start_at(world: Vector2) -> void:
	if board == null or board.is_animating:
		return
	var t: Tile = board.get_tile_at_world(world)
	if debug_log:
		print("[SWIPE] start_at world=", world, " tile=", t.board_pos if t else "null",
			" kind=", t.data.kind if t else -1)
	if t == null or t.data.kind == TileType.Kind.EMPTY or t.data.kind == TileType.Kind.ENEMY:
		if debug_log: print("[SWIPE] start ABORTED (empty/null)")
		return
	dragging = true
	path = [t.board_pos]
	_last_drag_world = world
	board.clear_hover()
	board.focus_kind(int(t.data.kind))
	board.highlight_path(path)
	board.show_chain_preview(path, world)
	EventBus.chain_started.emit(t.board_pos)

# Расширение цепи: семплирует ОТ последней позиции мыши ДО текущей,
# чтобы быстрые движения не пропускали промежуточные тайлы.
func _extend_to(world: Vector2) -> void:
	if board == null or board.is_animating:
		return
	var step: float = max(8.0, board.tile_size * 0.4)
	var dist: float = _last_drag_world.distance_to(world)
	var samples: int = max(1, int(ceil(dist / step)))
	for i in range(1, samples + 1):
		var sample: Vector2 = _last_drag_world.lerp(world, float(i) / float(samples))
		_try_extend_at(sample)
	_last_drag_world = world
	board.show_chain_preview(path, world)

func _try_extend_at(world: Vector2) -> void:
	var t: Tile = board.get_tile_at_world(world)
	if t == null:
		return
	var p: Vector2 = t.board_pos

	# Если возвращаемся на предыдущий — обрезаем хвост.
	if path.size() >= 2 and path[path.size() - 2] == p:
		path.pop_back()
		board.highlight_path(path)
		board.show_chain_preview(path, world)
		EventBus.chain_extended.emit(path.duplicate())
		if debug_log: print("[SWIPE] trim → path=", path)
		return

	# Уже в пути — игнорируем.
	for q in path:
		if q == p:
			return

	if path.size() == 0:
		return
	var last: Vector2 = path[path.size() - 1]
	if not BoardLogic.are_neighbors(last, p):
		if debug_log: print("[SWIPE] skip ", p, " → not neighbor of ", last)
		return
	var last_kind: int = board.logic.get_tile(last).kind
	var cur_kind: int = board.logic.get_tile(p).kind
	if not TileType.can_link(last_kind, cur_kind):
		if debug_log: print("[SWIPE] skip ", p, " → can_link(", last_kind, ",", cur_kind, ")=false")
		return

	path.append(p)
	board.highlight_path(path)
	board.show_chain_preview(path, world)
	EventBus.chain_extended.emit(path.duplicate())
	if debug_log: print("[SWIPE] append ", p, " kind=", cur_kind, " path_len=", path.size())

func _finish() -> void:
	if not dragging:
		return
	dragging = false
	board.clear_chain_preview()
	board.clear_highlights()
	board.unfocus_all()
	if debug_log: print("[SWIPE] finish path_len=", path.size())

	if not board.logic.is_valid_chain(path):
		if debug_log: print("[SWIPE] chain INVALID — cancelled")
		path.clear()
		EventBus.chain_cancelled.emit()
		return

	var result := ChainResolver.resolve(board.logic, path, RunState)
	var consumed: Array = ChainResolver.apply(board.logic, result, RunState)
	await board.consume_and_refill(consumed)
	path.clear()
	EventBus.chain_resolved.emit(result)
	EventBus.turn_ended.emit()
