extends Node2D

# Корневая нода боя. Связывает всё вместе и реагирует на ход (turn_ended):
# тикает врагов и применяет их атаки.

@export var board_path: NodePath
@export var hud_path: NodePath

@onready var board: Board = get_node(board_path)
@onready var hud: Node = get_node(hud_path) if hud_path != NodePath("") else null

func _ready() -> void:
	RunState.reset()
	EventBus.turn_ended.connect(_on_turn_ended)
	EventBus.chain_resolved.connect(_on_chain_resolved)
	EventBus.player_died.connect(_on_player_died)

func _on_turn_ended() -> void:
	RunState.spend_round(1)
	var attackers: Array = board.logic.tick_enemies()
	var consumed_attackers: Array = []
	for ep in attackers:
		var t = board.logic.get_tile(ep)
		if t.kind == TileType.Kind.ENEMY:
			RunState.take_damage(int(t.dmg))
			consumed_attackers.append(ep)
	if consumed_attackers.size() > 0:
		await board.consume_and_refill(consumed_attackers)
	else:
		board.sync_view()

func _on_chain_resolved(result) -> void:
	# Сюда повесим juicy-эффекты: тряска, текст комбо, slow-mo.
	if result.label != "":
		print("COMBO: ", result.label)
	# XP: 2 за каждый тайл в цепи + 5 за каждого убитого врага в этой цепи.
	var xp_gain: int = result.chain_length * 2
	for ep in result.enemies_in_chain:
		var t = board.logic.get_tile(ep)
		if t.kind == TileType.Kind.ENEMY and t.hp <= 0:
			xp_gain += 5
	if xp_gain > 0:
		RunState.add_xp(xp_gain)

func _on_player_died() -> void:
	print("Player died — game over")
	# TODO: переход на экран результатов.
