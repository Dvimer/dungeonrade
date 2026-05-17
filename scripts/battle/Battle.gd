extends Node2D

# Корневая нода боя. Связывает всё вместе и реагирует на ход (turn_ended):
# тикает врагов и применяет их атаки.

@export var board_path: NodePath
@export var hud_path: NodePath

const WaveCatalogScript := preload("res://scripts/data/WaveCatalog.gd")
const LevelCatalogScript := preload("res://scripts/data/LevelCatalog.gd")
const EnemyScalingCatalogScript := preload("res://scripts/data/EnemyScalingCatalog.gd")

@onready var board: Board = get_node(board_path)
@onready var hud: Node = get_node(hud_path) if hud_path != NodePath("") else null

var _combo_label: Label
var _boss_killed_this_turn: bool = false
var _run_finished: bool = false
var _bosses_killed: int = 0

func _ready() -> void:
	LevelCatalogScript.ensure_initialized()
	var selected_level := LevelCatalogScript.get_level(GameState.selected_level_id)
	RunState.start_level_run(selected_level)
	EventBus.turn_ended.connect(_on_turn_ended)
	EventBus.chain_resolved.connect(_on_chain_resolved)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_died.connect(_on_player_died)
	EventBus.skill_tapped.connect(_on_skill_tapped)
	EventBus.tiles_skill_cleared.connect(_on_tiles_skill_cleared)
	EventBus.run_started.emit()
	_setup_combo_label()
	_start_next_wave()
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
	_refresh_enemy_scaling()
	var attackers: Array = board.logic.tick_enemies()
	if attackers.size() > 0:
		await board.play_enemy_attacks(attackers)
	var consumed_attackers: Array = []
	var consumed_keys := {}
	var total_enemy_damage := 0
	for ep in attackers:
		var t = board.logic.get_tile(ep)
		if t.kind == TileType.Kind.ENEMY:
			var attack_damage := int(t.dmg)
			total_enemy_damage += attack_damage
			if bool(t.get("heal_on_attack", false)):
				var intended_heal := int(ceil(float(attack_damage) * float(t.get("heal_on_attack_ratio", 1.0))))
				var before_hp := int(t.hp)
				var after_hp := mini(int(t.get("max_hp", before_hp)), before_hp + intended_heal)
				var actual_heal := after_hp - before_hp
				if actual_heal > 0:
					t.hp = after_hp
					board.show_float_at_grid(ep, "+%d" % [actual_heal], Color(1.0, 0.25, 0.35), Vector2(0, -54))
			if bool(t.get("explode_on_attack", false)):
				var blast_damage := int(t.get("explosion_player_damage", 0))
				if blast_damage > 0:
					total_enemy_damage += blast_damage
					board.show_float_at_grid(ep, "-%d" % [blast_damage], Color(1.0, 0.62, 0.24), Vector2(0, -78))
				for blast_pos in _collect_explosion_positions(ep, int(t.get("explosion_radius", 1))):
					var blast_key := "%d,%d" % [int(blast_pos.x), int(blast_pos.y)]
					if consumed_keys.has(blast_key):
						continue
					consumed_keys[blast_key] = true
					consumed_attackers.append(blast_pos)
			elif bool(t.get("remove_on_attack", false)):
				var attacker_key := "%d,%d" % [int(ep.x), int(ep.y)]
				if not consumed_keys.has(attacker_key):
					consumed_keys[attacker_key] = true
					consumed_attackers.append(ep)
	if total_enemy_damage > 0:
		RunState.take_damage(total_enemy_damage)
	if consumed_attackers.size() > 0:
		await board.consume_and_refill(consumed_attackers)
	else:
		board.sync_view()
	_advance_wave_if_needed()

func _collect_explosion_positions(center: Vector2, radius: int) -> Array:
	var affected := []
	for y in range(int(center.y) - radius, int(center.y) + radius + 1):
		for x in range(int(center.x) - radius, int(center.x) + radius + 1):
			var pos := Vector2(x, y)
			if not board.logic.in_bounds(pos):
				continue
			affected.append(pos)
	return affected

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
		if bool(enemy.get("is_boss", false)):
			_boss_killed_this_turn = true
			_bosses_killed += 1
	if xp_gain > 0:
		RunState.add_xp(xp_gain)

func _on_player_died() -> void:
	print("Player died — game over")
	_finish_run(false)

func _on_skill_tapped(skill_id: String) -> void:
	if board == null or board.is_animating:
		return
	RunState.activate_skill(skill_id, board.logic)

func _on_tiles_skill_cleared(positions: Array) -> void:
	if board == null or positions.is_empty():
		return
	await board.consume_and_refill(positions)
	board.sync_view()
	while RunState.pending_skill_sweeps > 0 and board != null and not board.is_animating:
		RunState.pending_skill_sweeps -= 1
		var next_positions := RunState.do_pending_sweep(board.logic)
		if next_positions.is_empty():
			RunState.pending_skill_sweeps = 0
			break
		await board.consume_and_refill(next_positions)
		board.sync_view()

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
		board.show_float_at_grid(anchor, Localization.t("reward.gold", [result.gold_gained]), Color(0.98, 0.82, 0.34), Vector2(0, -48 - pop_index * 24))
		pop_index += 1
	if result.shield_gained > 0:
		board.show_float_at_grid(anchor, Localization.t("reward.shield", [result.shield_gained]), Color(0.58, 0.76, 1.0), Vector2(0, -48 - pop_index * 24))
		pop_index += 1
	if result.heal_amount > 0:
		board.show_float_at_grid(anchor, Localization.t("reward.heal", [result.heal_amount]), Color(1.0, 0.42, 0.52), Vector2(0, -48 - pop_index * 24))
		pop_index += 1
	if result.crit:
		board.show_float_at_grid(anchor, Localization.t("combat.crit"), Color(1.0, 0.42, 0.20), Vector2(0, -48 - pop_index * 24))

func _draw_vignette(s: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(s.x, 90)), Color(0, 0, 0, 0.22), true)
	draw_rect(Rect2(Vector2(0, s.y - 110), Vector2(s.x, 110)), Color(0, 0, 0, 0.30), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(38, s.y)), Color(0, 0, 0, 0.28), true)
	draw_rect(Rect2(Vector2(s.x - 38, 0), Vector2(38, s.y)), Color(0, 0, 0, 0.28), true)

func _start_next_wave() -> void:
	if RunState.wave >= RunState.total_waves:
		_finish_run(true)
		return
	var next_index := RunState.wave + 1
	var wave = WaveCatalogScript.get_wave_for_level(RunState.current_level, next_index)
	RunState.start_wave(wave.to_dictionary())
	board.apply_wave_profile(RunState.current_wave, next_index == 1)
	_refresh_enemy_scaling()
	_show_combo(Localization.t("hud.wave", [RunState.wave, RunState.rounds_left]))

func _refresh_enemy_scaling() -> void:
	if board == null or board.logic == null:
		return
	var runtime_wave := EnemyScalingCatalogScript.build_runtime_wave(RunState.current_wave, RunState.total_turns_taken)
	RunState.current_wave["monster_profile"] = runtime_wave.get("monster_profile", {}).duplicate(true)
	RunState.current_wave["enemy_spawn_chance"] = float(runtime_wave.get("enemy_spawn_chance", RunState.current_wave.get("enemy_spawn_chance", 0.0)))
	board.refresh_enemy_scaling(
		float(runtime_wave.get("enemy_spawn_chance", 0.0)),
		runtime_wave.get("monster_profile", {})
	)

func _advance_wave_if_needed() -> void:
	if RunState.boss_active:
		if board.logic.has_boss():
			_boss_killed_this_turn = false
			return
		_boss_killed_this_turn = false
		RunState.clear_wave()
		if RunState.wave >= RunState.total_waves:
			_finish_run(true)
			return
		_start_next_wave()
		return
	if not RunState.is_wave_timer_done():
		return
	var wave_config := RunState.current_wave
	if _should_start_boss(wave_config):
		_start_boss_phase(wave_config)
	else:
		RunState.clear_wave()
		if RunState.wave >= RunState.total_waves:
			_finish_run(true)
			return
		_start_next_wave()

func _should_start_boss(wave_config: Dictionary) -> bool:
	var boss_id := str(wave_config.get("boss_id", ""))
	var chance := float(wave_config.get("boss_chance", 0.0))
	return boss_id != "" and board.logic.rng.randf() < chance

func _start_boss_phase(wave_config: Dictionary) -> void:
	var boss_id := str(wave_config.get("boss_id", ""))
	var pos := board.spawn_monster(boss_id)
	if pos.x < 0:
		RunState.clear_wave()
		_start_next_wave()
		return
	RunState.start_boss_phase(int(wave_config.get("boss_turns", 5)))
	if pos.x >= 0:
		board.show_float_at_grid(pos, Localization.t("combat.boss"), Color(1.0, 0.66, 0.24), Vector2(0, -58))
	_show_combo(Localization.t("combat.boss"))

func _finish_run(won: bool) -> void:
	if _run_finished:
		return
	_run_finished = true
	EventBus.run_finished.emit({
		"won": won,
		"level_id": RunState.level_id,
		"level_title": RunState.level_title,
		"wave": RunState.wave,
		"total_waves": RunState.total_waves,
		"gold": RunState.gold,
		"xp": RunState.xp,
		"bosses_killed": _bosses_killed,
	})
