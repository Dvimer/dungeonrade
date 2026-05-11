extends Node2D
class_name Tile

# Визуал одной клетки. Логика хранится отдельно (в BoardLogic),
# тайл получает данные через update_view().

const COLORS := {
	TileType.Kind.SWORD:  Color(0.30, 0.19, 0.15),
	TileType.Kind.SHIELD: Color(0.10, 0.19, 0.31),
	TileType.Kind.COIN:   Color(0.35, 0.25, 0.11),
	TileType.Kind.HEART:  Color(0.36, 0.12, 0.20),
	TileType.Kind.ENEMY:  Color(0.18, 0.09, 0.20),
	TileType.Kind.EMPTY:  Color(0.10, 0.11, 0.14),
}

const RIM_COLORS := {
	TileType.Kind.SWORD:  Color(0.60, 0.42, 0.30),
	TileType.Kind.SHIELD: Color(0.34, 0.55, 0.80),
	TileType.Kind.COIN:   Color(0.82, 0.64, 0.28),
	TileType.Kind.HEART:  Color(0.78, 0.32, 0.42),
	TileType.Kind.ENEMY:  Color(0.58, 0.37, 0.48),
	TileType.Kind.EMPTY:  Color(0.26, 0.28, 0.34),
}

const KIND_LABELS := {
	TileType.Kind.SWORD: "BLADE",
	TileType.Kind.SHIELD: "AEGIS",
	TileType.Kind.COIN: "GILT",
	TileType.Kind.HEART: "VITA",
	TileType.Kind.ENEMY: "FOE",
}

const COLOR_STONE_DARK := Color(0.035, 0.035, 0.045)
const COLOR_FOIL := Color(0.78, 0.63, 0.39)
const COLOR_FOIL_HI := Color(0.95, 0.82, 0.48)
const COLOR_INK := Color(0.86, 0.80, 0.68)

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
var _kind_label: Label = null
var _idle_offset_y: float = 0.0
var _danger_alpha: float = 0.0
var _hover_glow_alpha: float = 0.0
var _icon_base_position: Vector2
var _stats_base_position: Vector2
var _label_base_position: Vector2
var _dynamic_icon_cache: Dictionary = {}

@onready var _bg: ColorRect = $Background
@onready var _icon: Sprite2D = $Icon
@onready var _stats: Label = $Stats
@onready var _hover_frame: Line2D = $HoverFrame
@onready var _selected_strike: Line2D = $SelectedStrike

func _ready() -> void:
	set_process(true)
	# Корень тайла находится в его центре, чтобы scale работал красиво.
	_bg.size = Vector2(tile_size - 12.0, tile_size - 12.0)
	_bg.position = -_bg.size / 2
	_bg.z_index = -1

	# Иконки 64×64; растягиваем под тайл с небольшим запасом.
	var s: float = (tile_size / 64.0) * 0.62 * icon_scale
	_icon.scale = Vector2(s, s)
	_icon.position = Vector2(0, -8)
	_icon_base_position = _icon.position
	_icon.z_index = 3

	# Полоска статов — снизу тайла, только для врагов.
	_stats.size = Vector2(tile_size - 16.0, tile_size * 0.23)
	_stats.position = Vector2(-_stats.size.x / 2.0, tile_size / 2.0 - _stats.size.y - 8)
	_stats_base_position = _stats.position
	_stats.add_theme_color_override("font_color", COLOR_INK)
	_stats.add_theme_font_size_override("font_size", 14)
	_stats.z_index = 5

	_kind_label = Label.new()
	_kind_label.size = Vector2(tile_size, 18)
	_kind_label.position = Vector2(-tile_size / 2.0, tile_size / 2.0 - 24.0)
	_label_base_position = _kind_label.position
	_kind_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_kind_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_kind_label.add_theme_color_override("font_color", COLOR_INK)
	_kind_label.add_theme_font_size_override("font_size", 11)
	_kind_label.z_index = 4
	add_child(_kind_label)

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
		_selected_strike.default_color = Color(0.98, 0.82, 0.38, 0.95)
		_selected_strike.width = 4.0

	update_view(data)

func setup(pos: Vector2, tile_data: Dictionary) -> void:
	board_pos = pos
	data = tile_data
	if is_inside_tree():
		update_view(data)

func _process(delta: float) -> void:
	var k: int = data.get("kind", TileType.Kind.EMPTY)
	var previous_offset := _idle_offset_y
	_idle_offset_y = lerpf(_idle_offset_y, 0.0, min(1.0, delta * 12.0))

	var target_danger := 0.0
	if k == TileType.Kind.ENEMY and int(data.get("timer", 3)) <= 1:
		target_danger = 0.18 + 0.22 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006))
	_danger_alpha = lerpf(_danger_alpha, target_danger, min(1.0, delta * 10.0))

	if abs(previous_offset - _idle_offset_y) > 0.001 or _danger_alpha > 0.01:
		_apply_visual_offset()
		queue_redraw()
	if hovered:
		var glow := 0.32 + 0.10 * sin(Time.get_ticks_msec() * 0.006)
		if abs(glow - _hover_glow_alpha) > 0.015:
			_hover_glow_alpha = glow
			queue_redraw()

func update_view(tile_data: Dictionary) -> void:
	data = tile_data
	var k: int = data.get("kind", TileType.Kind.EMPTY)
	if _bg:
		_bg.color = COLORS.get(k, Color(0.2, 0.2, 0.2))
	if _icon:
		var tex: Texture2D = _get_icon_texture(k)
		_icon.texture = tex
		_icon.visible = tex != null
		_icon.modulate = Color(1, 0.82, 0.82) if k == TileType.Kind.ENEMY and int(data.get("timer", 3)) <= 1 else Color.WHITE
	if _stats:
		if k == TileType.Kind.ENEMY:
			if bool(data.get("is_boss", false)):
				_stats.text = "BOSS"
			else:
				_stats.text = "%d  %d  %d" % [
					int(data.get("hp", 0)),
					int(data.get("dmg", 0)),
					int(data.get("timer", 0)),
				]
			_stats.visible = true
		else:
			_stats.text = ""
			_stats.visible = false
	if _kind_label:
		_kind_label.text = KIND_LABELS.get(k, "")
		_kind_label.visible = k != TileType.Kind.EMPTY and k != TileType.Kind.ENEMY
	queue_redraw()

func _draw() -> void:
	var half := tile_size / 2.0
	var visual_offset := Vector2(0, _idle_offset_y)
	var outer := Rect2(Vector2(-half, -half) + visual_offset, Vector2(tile_size, tile_size))
	var inner := outer.grow(-6.0)
	var k: int = data.get("kind", TileType.Kind.EMPTY)
	var base: Color = COLORS.get(k, Color(0.12, 0.12, 0.14))
	var rim: Color = RIM_COLORS.get(k, COLOR_FOIL)
	if k == TileType.Kind.ENEMY:
		base = data.get("tile_color", base)
		rim = data.get("rim_color", rim)

	draw_rect(outer.grow(3.0), Color(0, 0, 0, 0.55), true)
	if _hover_glow_alpha > 0.01:
		draw_rect(outer.grow(9.0), Color(1.0, 0.76, 0.25, _hover_glow_alpha * 0.22), true)
		draw_rect(outer.grow(4.0), Color(1.0, 0.92, 0.62, _hover_glow_alpha * 0.45), false, 2.0)
	draw_rect(outer, COLOR_STONE_DARK, true)
	draw_rect(outer.grow(-2.0), rim.darkened(0.38), false, 3.0)
	draw_rect(inner, base, true)
	draw_rect(inner.grow(-2.0), base.lightened(0.10), false, 1.0)
	draw_rect(outer.grow(-7.0), Color(0, 0, 0, 0.45), false, 2.0)
	if _hover_glow_alpha > 0.01:
		var hover_rim := COLOR_FOIL_HI.lightened(0.12)
		hover_rim.a = _hover_glow_alpha
		draw_rect(outer.grow(-3.0), hover_rim, false, 2.0)

	var c := half - 9.0
	var l := 15.0
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var p := Vector2(sx * c, sy * c)
			draw_line(p, p + Vector2(-sx * l, 0), COLOR_FOIL_HI, 1.4)
			draw_line(p, p + Vector2(0, -sy * l), COLOR_FOIL_HI, 1.4)
			draw_circle(p + Vector2(-sx * 4.0, -sy * 4.0), 2.1, COLOR_FOIL)

	if _danger_alpha > 0.01:
		draw_rect(outer.grow(2.0), Color(0.95, 0.18, 0.12, _danger_alpha), false, 4.0)
		draw_circle(visual_offset, tile_size * 0.40, Color(0.95, 0.10, 0.08, _danger_alpha * 0.22))

func set_highlighted(on: bool) -> void:
	# Идемпотентно: повторный вызов с тем же значением не запускает анимацию.
	if on == highlighted:
		return
	highlighted = on
	if _tween and _tween.is_valid():
		_tween.kill()
	if on:
		_idle_offset_y = 0.0
		_apply_visual_offset()
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
		_idle_offset_y = 0.0
		_hover_glow_alpha = 0.34
		_apply_visual_offset()
		z_index = 100
	else:
		_hover_glow_alpha = 0.0
		queue_redraw()
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
		_hover_frame.visible = false
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
		_hover_frame.visible = false
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

func _apply_visual_offset() -> void:
	var offset := Vector2(0, _idle_offset_y)
	if _icon:
		_icon.position = _icon_base_position + offset
	if _stats:
		_stats.position = _stats_base_position + offset
	if _kind_label:
		_kind_label.position = _label_base_position + offset

func _get_icon_texture(kind: int) -> Texture2D:
	if kind == TileType.Kind.ENEMY:
		var icon_path := str(data.get("icon_path", ""))
		if icon_path != "":
			if not _dynamic_icon_cache.has(icon_path):
				_dynamic_icon_cache[icon_path] = load(icon_path)
			var tex = _dynamic_icon_cache[icon_path]
			if tex is Texture2D:
				return tex
	return ICONS.get(kind, null)
