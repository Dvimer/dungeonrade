extends Node2D

# Корневая нода боя. Связывает всё вместе и реагирует на ход (turn_ended):
# тикает врагов и применяет их атаки.

@export var board_path: NodePath
@export var hud_path: NodePath

@onready var board: Board = get_node(board_path)
@onready var hud: Node = get_node(hud_path) if hud_path != NodePath("") else null

var _combo_label: Label
func _ready() -> void:
	RunState.reset()
	EventBus.turn_ended.connect(_on_turn_ended)
	EventBus.chain_resolved.connect(_on_chain_resolved)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_died.connect(_on_player_died)
	_setup_combo_label()
	queue_redraw()

func _draw() -> void:
	var s := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.025, 0.023, 0.030), true)
	draw_circle(Vector2(s.x * 0.12, s.y * 0.78), 240.0, Color(0.45, 0.17, 0.05, 0.10))
	draw_circle(Vector2(s.x * 0.88, s.y * 0.78), 240.0, Color(0.45, 0.17, 0.05, 0.10))
	draw_circle(Vector2(s.x * 0.50, s.y * 0.06), 260.0, Color(0.62, 0.46, 0.18, 0.08))

	var block_h := 86.0
	for y in range(-1, int(ceil(s.y / block_h)) + 1):
		var block_w := 118.0
		for x in range(-1, int(ceil(s.x / block_w)) + 1):
			var ox := 0.0 if y % 2 == 0 else block_w * 0.5
			var pos := Vector2(x * block_w - ox, y * block_h)
			var shade := 0.045 + float((x * 7 + y * 11) % 5) * 0.006
			draw_rect(Rect2(pos, Vector2(block_w - 2.0, block_h - 2.0)), Color(shade, shade * 0.95, shade * 1.15, 0.54), true)
			draw_rect(Rect2(pos, Vector2(block_w - 2.0, block_h - 2.0)), Color(0, 0, 0, 0.28), false, 1.0)

	draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.22), false, 18.0)
	_draw_vignette(s)

func _on_turn_ended() -> void:
	RunState.spend_round(1)
	var attackers: Array = board.logic.tick_enemies()
	if attackers.size() > 0:
		await board.play_enemy_attacks(attackers)
	var consumed_attackers: Array = []
	for ep in attackers:
		var t = board.logic.get_tile(ep)
		if t.kind == TileType.Kind.ENEMY:
			var attack_damage := int(t.dmg)
			RunState.take_damage(attack_damage)
			if bool(t.get("heal_on_attack", false)):
				var intended_heal := int(ceil(float(attack_damage) * float(t.get("heal_on_attack_ratio", 1.0))))
				var before_hp := int(t.hp)
				var after_hp := mini(int(t.get("max_hp", before_hp)), before_hp + intended_heal)
				var actual_heal := after_hp - before_hp
				if actual_heal > 0:
					t.hp = after_hp
					board.show_float_at_grid(ep, "+%d" % [actual_heal], Color(1.0, 0.25, 0.35), Vector2(0, -54))
			if bool(t.get("remove_on_attack", true)):
				consumed_attackers.append(ep)
	if consumed_attackers.size() > 0:
		await board.consume_and_refill(consumed_attackers)
	else:
		board.sync_view()

func _on_chain_resolved(result) -> void:
	# Сюда повесим juicy-эффекты: тряска, текст комбо, slow-mo.
	if result.label != "":
		print("COMBO: ", result.label)
		_show_combo(result.label)
	_show_chain_rewards(result)
	# XP: 2 за каждый тайл в цепи + 5 за каждого убитого врага в этой цепи.
	var xp_gain: int = result.chain_length * 2
	for enemy in result.killed_enemies:
		xp_gain += 5 + int(enemy.get("xp_bonus", 0))
	if xp_gain > 0:
		RunState.add_xp(xp_gain)

func _on_player_died() -> void:
	print("Player died — game over")
	# TODO: переход на экран результатов.

func _on_player_damaged(_amount: int) -> void:
	var original := board.position
	var tween := create_tween()
	tween.tween_property(board, "position", original + Vector2(8, -3), 0.035)
	tween.tween_property(board, "position", original + Vector2(-7, 4), 0.045)
	tween.tween_property(board, "position", original + Vector2(4, 2), 0.035)
	tween.tween_property(board, "position", original, 0.050)

func _setup_combo_label() -> void:
	_combo_label = Label.new()
	_combo_label.visible = false
	_combo_label.size = Vector2(360, 70)
	_combo_label.position = Vector2(180, 170)
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_combo_label.add_theme_font_size_override("font_size", 42)
	_combo_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.48))
	_combo_label.z_index = 500
	add_child(_combo_label)

func _show_combo(label: String) -> void:
	if _combo_label == null:
		return
	_combo_label.text = label
	_combo_label.visible = true
	_combo_label.modulate = Color(1, 1, 1, 1)
	_combo_label.scale = Vector2(0.85, 0.85)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_combo_label, "position:y", 132.0, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_combo_label, "scale", Vector2(1.14, 1.14), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_combo_label, "modulate:a", 0.0, 0.45).set_delay(0.45)
	tween.chain().tween_callback(func():
		_combo_label.visible = false
		_combo_label.position.y = 170.0
	)

func _show_chain_rewards(result) -> void:
	if result.consumed_positions.is_empty():
		return
	var anchor: Vector2 = result.consumed_positions[0]
	var pop_index := 0
	if result.gold_gained > 0:
		board.show_float_at_grid(anchor, "+%d GILT" % [result.gold_gained], Color(0.98, 0.82, 0.34), Vector2(0, -48 - pop_index * 24))
		pop_index += 1
	if result.shield_gained > 0:
		board.show_float_at_grid(anchor, "+%d AEGIS" % [result.shield_gained], Color(0.58, 0.76, 1.0), Vector2(0, -48 - pop_index * 24))
		pop_index += 1
	if result.heal_amount > 0:
		board.show_float_at_grid(anchor, "+%d VITA" % [result.heal_amount], Color(1.0, 0.42, 0.52), Vector2(0, -48 - pop_index * 24))
		pop_index += 1
	if result.crit:
		board.show_float_at_grid(anchor, "CRIT", Color(1.0, 0.42, 0.20), Vector2(0, -48 - pop_index * 24))

func _draw_vignette(s: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(s.x, 90)), Color(0, 0, 0, 0.22), true)
	draw_rect(Rect2(Vector2(0, s.y - 110), Vector2(s.x, 110)), Color(0, 0, 0, 0.30), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(38, s.y)), Color(0, 0, 0, 0.28), true)
	draw_rect(Rect2(Vector2(s.x - 38, 0), Vector2(38, s.y)), Color(0, 0, 0, 0.28), true)
