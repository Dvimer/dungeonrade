extends Control
class_name HPFlask

# Большая колба с HP. Рисуется через _draw, без внешних ассетов.
# Подписывается на сигналы EventBus и плавно меняет уровень заполнения.

const COLOR_GLASS_BG := Color(0.09, 0.035, 0.040, 1.0)
const COLOR_LIQUID := Color(0.70, 0.07, 0.07, 1.0)
const COLOR_LIQUID_HIGHLIGHT := Color(1.0, 0.38, 0.30, 0.72)
const COLOR_OUTLINE := Color(0.035, 0.030, 0.035, 1.0)
const COLOR_NECK := Color(0.33, 0.25, 0.17, 1.0)
const COLOR_CAP := Color(0.78, 0.63, 0.39, 1.0)
const COLOR_FOIL := Color(0.95, 0.82, 0.48, 1.0)

var fill_ratio: float = 1.0
var _shake: float = 0.0
var _font: Font

func _ready() -> void:
	custom_minimum_size = Vector2(120, 220)
	_font = ThemeDB.fallback_font
	EventBus.player_damaged.connect(_on_damaged)
	EventBus.player_healed.connect(_on_healed)
	_recompute(false)

func _process(delta: float) -> void:
	# Тряска при уроне затухает сама.
	if _shake > 0.0:
		_shake = max(0.0, _shake - delta * 12.0)
		queue_redraw()

func _on_damaged(_x: int) -> void:
	_shake = 1.0
	_recompute(true)

func _on_healed(_x: int) -> void:
	_recompute(true)

func _recompute(animate: bool) -> void:
	var target: float = 0.0
	if RunState.max_hp > 0:
		target = float(RunState.hp) / float(RunState.max_hp)
	target = clamp(target, 0.0, 1.0)
	if animate:
		var tw := create_tween()
		tw.tween_property(self, "fill_ratio", target, 0.35) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tw.tween_callback(queue_redraw)
		# и параллельно перерисовка кадрами:
		var tw2 := create_tween()
		tw2.set_loops(int(0.35 * 60))
		tw2.tween_callback(queue_redraw).set_delay(1.0/60.0)
	else:
		fill_ratio = target
	queue_redraw()

func _draw() -> void:
	var s := size
	var off := Vector2(randf_range(-_shake, _shake) * 4.0, randf_range(-_shake, _shake) * 4.0)

	# --- Шейка (neck) ---
	var neck_w: float = s.x * 0.28
	var neck_h: float = s.y * 0.13
	var neck_rect := Rect2(off.x + (s.x - neck_w) * 0.5, off.y, neck_w, neck_h)
	draw_rect(neck_rect, COLOR_NECK)
	# крышка
	var cap_w: float = s.x * 0.36
	var cap_h: float = s.y * 0.05
	draw_rect(Rect2(off.x + (s.x - cap_w) * 0.5, off.y, cap_w, cap_h), COLOR_CAP)

	# --- Тело колбы ---
	var body_top: float = off.y + neck_h
	var body := Rect2(off.x + s.x * 0.05, body_top, s.x * 0.9, s.y - neck_h)
	draw_rect(body.grow(8.0), Color(0, 0, 0, 0.45), true)
	# фон стекла
	draw_rect(body, COLOR_GLASS_BG)
	# жидкость снизу
	var liq_h: float = body.size.y * fill_ratio
	var liq := Rect2(body.position.x, body.position.y + body.size.y - liq_h, body.size.x, liq_h)
	draw_rect(liq, COLOR_LIQUID)
	# блик жидкости (узкая полоска сверху)
	if liq_h > 4.0:
		draw_rect(Rect2(liq.position.x + 4, liq.position.y, liq.size.x - 8, 3), COLOR_LIQUID_HIGHLIGHT)
		var bubble_y := liq.position.y + liq.size.y * 0.45
		draw_circle(Vector2(body.position.x + body.size.x * 0.30, bubble_y), 3.0, Color(1, 0.65, 0.55, 0.32))
		draw_circle(Vector2(body.position.x + body.size.x * 0.66, bubble_y + 18.0), 2.2, Color(1, 0.65, 0.55, 0.24))
	# вертикальный стеклянный блик слева
	draw_rect(Rect2(body.position.x + 6, body.position.y + 8, 5, body.size.y - 16),
			Color(1, 1, 1, 0.10))

	# обводка тела
	draw_rect(body, COLOR_OUTLINE, false, 4.0)
	draw_rect(body.grow(-6.0), COLOR_FOIL, false, 1.0)
	# обводка горлышка
	draw_rect(neck_rect, COLOR_OUTLINE, false, 3.0)

	# --- Цифры HP/MAX ---
	if _font:
		var fs := 22
		var text := "%d / %d" % [RunState.hp, RunState.max_hp]
		var ts := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		var tx: float = off.x + (s.x - ts.x) * 0.5
		var ty: float = body.position.y + body.size.y * 0.5 + ts.y * 0.3
		# тень
		draw_string(_font, Vector2(tx + 1, ty + 1), text,
				HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(0, 0, 0, 0.7))
		draw_string(_font, Vector2(tx, ty), text,
				HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color.WHITE)
