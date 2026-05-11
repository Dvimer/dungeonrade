extends Node2D
class_name Tile

# Визуал одной клетки. Логика хранится отдельно (в BoardLogic),
# тайл получает данные через update_view().

const COLORS := {
	TileType.Kind.SWORD:  Color(0.90, 0.30, 0.30),
	TileType.Kind.SHIELD: Color(0.35, 0.55, 0.95),
	TileType.Kind.COIN:   Color(0.95, 0.80, 0.25),
	TileType.Kind.HEART:  Color(0.40, 0.85, 0.45),
	TileType.Kind.ENEMY:  Color(0.45, 0.30, 0.55),
	TileType.Kind.EMPTY:  Color(0.15, 0.16, 0.20),
}

# SVG-иконки. Лежат в res://assets/icons/.
const ICONS := {
	TileType.Kind.SWORD:  preload("res://assets/icons/sword.svg"),
	TileType.Kind.SHIELD: preload("res://assets/icons/shield.svg"),
	TileType.Kind.COIN:   preload("res://assets/icons/coin.svg"),
	TileType.Kind.HEART:  preload("res://assets/icons/heart.svg"),
	TileType.Kind.ENEMY:  preload("res://assets/icons/skull.svg"),
}

@export var tile_size: float = 96.0
@export var icon_scale: float = 1.0  # коэффициент относительно базовых 64×64

var board_pos: Vector2 = Vector2.ZERO
var data: Dictionary = {"kind": TileType.Kind.EMPTY}
var highlighted: bool = false
var dimmed: bool = false
var _chain_dimmed: bool = false
var _hover_dimmed: bool = false
var hovered: bool = false
var _tween: Tween = null
var _dim_tween: Tween = null
var _hover_tween: Tween = null
var _hover_scale_tween: Tween = null
var _hover_bg_tween: Tween = null

@onready var _bg: ColorRect = $Background
@onready var _icon: Sprite2D = $Icon
@onready var _stats: Label = $Stats
@onready var _hover_frame: Line2D = $HoverFrame
@onready var _selected_strike: Line2D = $SelectedStrike

func _ready() -> void:
	# Корень тайла находится в его центре, чтобы scale работал красиво.
	_bg.size = Vector2(tile_size, tile_size)
	_bg.position = -_bg.size / 2

	# Иконки 64×64; растягиваем под тайл с небольшим запасом.
	var s: float = (tile_size / 64.0) * 0.8 * icon_scale
	_icon.scale = Vector2(s, s)

	# Полоска статов — снизу тайла, только для врагов.
	_stats.size = Vector2(tile_size, tile_size * 0.28)
	_stats.position = Vector2(-tile_size / 2.0, tile_size / 2.0 - _stats.size.y - 2)

	# Hover-рамка вокруг тайла (отступ 6px наружу, замкнутый контур).
	var hp: float = tile_size * 0.5 + 6.0
	_hover_frame.points = PackedVector2Array([
		Vector2(-hp, -hp),
		Vector2(hp, -hp),
		Vector2(hp, hp),
		Vector2(-hp, hp),
	])
	if _selected_strike:
		var sp: float = tile_size * 0.34
		_selected_strike.points = PackedVector2Array([
			Vector2(-sp, -sp),
			Vector2(sp, sp),
		])

	update_view(data)

func setup(pos: Vector2, tile_data: Dictionary) -> void:
	board_pos = pos
	data = tile_data
	if is_inside_tree():
		update_view(data)

func update_view(tile_data: Dictionary) -> void:
	data = tile_data
	var k: int = data.get("kind", TileType.Kind.EMPTY)
	if _bg:
		_bg.color = COLORS.get(k, Color(0.2, 0.2, 0.2))
	if _icon:
		var tex: Texture2D = ICONS.get(k, null)
		_icon.texture = tex
		_icon.visible = tex != null
	if _stats:
		if k == TileType.Kind.ENEMY:
			_stats.text = "%d  ⏳%d" % [int(data.get("hp", 0)), int(data.get("timer", 0))]
			_stats.visible = true
		else:
			_stats.text = ""
			_stats.visible = false

func set_highlighted(on: bool) -> void:
	# Идемпотентно: повторный вызов с тем же значением не запускает анимацию.
	if on == highlighted:
		return
	highlighted = on
	if _tween and _tween.is_valid():
		_tween.kill()
	if on:
		_pulse_in()
		if _selected_strike:
			_selected_strike.visible = true
	else:
		_tween = create_tween()
		_tween.tween_property(self, "scale", Vector2(1, 1), 0.08) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if _selected_strike:
			_selected_strike.visible = false

func _pulse_in() -> void:
	# Быстрый "поп" → удержание в увеличенном состоянии.
	scale = Vector2(0.92, 0.92)
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.32, 1.32), 0.09) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2(1.18, 1.18), 0.10) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func set_dim(on: bool) -> void:
	set_chain_dim(on)

func set_chain_dim(on: bool) -> void:
	if on == _chain_dimmed:
		return
	_chain_dimmed = on
	_apply_dim_visual()

func set_hover_dim(on: bool) -> void:
	if on == _hover_dimmed:
		return
	_hover_dimmed = on
	_apply_dim_visual()

func _apply_dim_visual() -> void:
	var was_dimmed := dimmed
	dimmed = _chain_dimmed or _hover_dimmed
	# Если тайл затемнили — сразу убираем hover, он на нём не имеет смысла.
	if dimmed and hovered:
		set_hovered(false)
	var target_a: float = 1.0
	if _chain_dimmed:
		target_a = 0.18
	elif _hover_dimmed:
		target_a = 0.5
	if _dim_tween and _dim_tween.is_valid():
		_dim_tween.kill()
	_dim_tween = create_tween()
	_dim_tween.tween_property(self, "modulate:a", target_a, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if was_dimmed and not dimmed:
		modulate.a = target_a

func set_hovered(on: bool) -> void:
	# Курсор над тайлом. Не показываем на затемнённых тайлах.
	if on and dimmed:
		return
	if on == hovered:
		return
	hovered = on
	if on:
		print("[HOVER] highlight ON cell=", board_pos, " kind=", data.get("kind", TileType.Kind.EMPTY))
		z_index = 100
	else:
		print("[HOVER] highlight OFF cell=", board_pos)
		z_index = 0
	if not _hover_frame:
		return
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	if _hover_scale_tween and _hover_scale_tween.is_valid():
		_hover_scale_tween.kill()
	if _hover_bg_tween and _hover_bg_tween.is_valid():
		_hover_bg_tween.kill()
	if on:
		_hover_frame.visible = true
		_hover_frame.modulate.a = 0.0
		_hover_frame.width = 3.0
		_hover_tween = create_tween().set_parallel(true)
		_hover_tween.tween_property(_hover_frame, "modulate:a", 1.0, 0.09) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_hover_tween.tween_property(_hover_frame, "width", 7.0, 0.14) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_hover_scale_tween = create_tween()
		scale = Vector2(0.985, 0.985)
		_hover_scale_tween.tween_property(self, "scale", Vector2(1.045, 1.045), 0.10) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_hover_scale_tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.08) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		_hover_bg_tween = create_tween()
		_hover_bg_tween.tween_property(_bg, "modulate", Color(1.10, 1.10, 1.10, 1.0), 0.10) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		_hover_tween = create_tween()
		_hover_tween.tween_property(_hover_frame, "modulate:a", 0.0, 0.08)
		_hover_tween.tween_callback(func(): _hover_frame.visible = false)
		if not highlighted:
			_hover_scale_tween = create_tween()
			_hover_scale_tween.tween_property(self, "scale", Vector2.ONE, 0.08) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_hover_bg_tween = create_tween()
		_hover_bg_tween.tween_property(_bg, "modulate", Color(1, 1, 1, 1), 0.08) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# Проверяет, попадает ли мировая точка в этот тайл (квадрат tile_size x tile_size).
func contains_point(world_point: Vector2) -> bool:
	var local := to_local(world_point)
	var half := tile_size / 2
	return abs(local.x) <= half and abs(local.y) <= half
