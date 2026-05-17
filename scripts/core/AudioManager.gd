extends Node

# AudioManager — централизованное управление звуком.
# Подписывается на EventBus, воспроизводит нужный звук по событию.
# Пул из 6 AudioStreamPlayer нодов обеспечивает полифонию.

const POOL_SIZE := 6
const TICK_DEBOUNCE := 0.08  # минимальный интервал между chain_tick (сек)

var master_volume: float = 1.0
var _players: Array = []
var _pool_index: int = 0
var _tick_cooldown: float = 0.0
var _sounds: Dictionary = {}

func _ready() -> void:
	_create_player_pool()
	_load_sounds()
	_connect_events()

func _process(delta: float) -> void:
	if _tick_cooldown > 0.0:
		_tick_cooldown -= delta

func _create_player_pool() -> void:
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)

func _load_sounds() -> void:
	var files := {
		"chain_start":    "res://audio/chain_start.wav",
		"chain_tick":     "res://audio/chain_tick.wav",
		"chain_cancel":   "res://audio/chain_cancel.wav",
		"resolve_sword":  "res://audio/resolve_sword.wav",
		"resolve_heart":  "res://audio/resolve_heart.wav",
		"resolve_shield": "res://audio/resolve_shield.wav",
		"resolve_coin":   "res://audio/resolve_coin.wav",
		"enemy_hit":      "res://audio/enemy_hit.wav",
		"enemy_die":      "res://audio/enemy_die.wav",
	}
	for key in files:
		var path: String = files[key]
		if ResourceLoader.exists(path):
			_sounds[key] = load(path)
		else:
			push_warning("AudioManager: missing sound file: " + path)

func play(sound_name: String) -> void:
	var stream = _sounds.get(sound_name)
	if stream == null:
		return
	var player: AudioStreamPlayer = _players[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	player.stream = stream
	player.volume_db = linear_to_db(master_volume)
	player.play()

func _connect_events() -> void:
	EventBus.chain_started.connect(_on_chain_started)
	EventBus.chain_extended.connect(_on_chain_extended)
	EventBus.chain_cancelled.connect(_on_chain_cancelled)
	EventBus.chain_resolved.connect(_on_chain_resolved)
	EventBus.enemy_damaged.connect(_on_enemy_damaged)
	EventBus.enemy_killed.connect(_on_enemy_killed)

func _on_chain_started(_pos: Vector2) -> void:
	play("chain_start")

func _on_chain_extended(_positions: Array) -> void:
	if _tick_cooldown > 0.0:
		return
	_tick_cooldown = TICK_DEBOUNCE
	play("chain_tick")

func _on_chain_cancelled() -> void:
	play("chain_cancel")

func _on_chain_resolved(result: ChainResult) -> void:
	if result.damage_to_enemies > 0:
		play("resolve_sword")
	if result.heal_amount > 0:
		play("resolve_heart")
	if result.shield_gained > 0:
		play("resolve_shield")
	if result.gold_gained > 0:
		play("resolve_coin")

func _on_enemy_damaged(_pos: Vector2, _dmg: int) -> void:
	play("enemy_hit")

func _on_enemy_killed(_pos: Vector2) -> void:
	play("enemy_die")
