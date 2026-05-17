# Movement & Battle Sounds Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add fantasy-style sound effects to all key game events (chain building, resolution, combat, tile physics) via a centralized AudioManager autoload.

**Architecture:** `AudioManager.gd` autoload subscribes to EventBus signals and plays the appropriate `.wav` from a pool of 6 `AudioStreamPlayer` nodes. Sound files are generated manually via sfxr.me and placed in `res://audio/`.

**Tech Stack:** Godot 4, GDScript, sfxr.me (jsfxr), `.wav` audio files

---

## File Map

| Action | File |
|--------|------|
| Create | `res://audio/` — directory for all 9 sound files |
| Create | `res://scripts/core/AudioManager.gd` |
| Modify | `project.godot` — register AudioManager as autoload |

---

## Task 1: Generate sounds via sfxr.me

**Files:**
- Create: `res://audio/chain_start.wav`
- Create: `res://audio/chain_tick.wav`
- Create: `res://audio/chain_cancel.wav`
- Create: `res://audio/resolve_sword.wav`
- Create: `res://audio/resolve_heart.wav`
- Create: `res://audio/resolve_shield.wav`
- Create: `res://audio/resolve_coin.wav`
- Create: `res://audio/enemy_hit.wav`
- Create: `res://audio/enemy_die.wav`

- [ ] **Step 1: Открой sfxr.me в браузере**

Перейди на `https://sfxr.me`

- [ ] **Step 2: Создай папку audio в проекте**

```bash
mkdir -p "D:/Gotot/GameTwo/audio"
```

- [ ] **Step 3: Сгенерируй chain_start.wav**

В sfxr.me: нажми **Blip/Select** → нажми "Mutate" 2-3 раза пока не понравится → **Export WAV** → сохрани как `chain_start.wav` в `D:/Gotot/GameTwo/audio/`

- [ ] **Step 4: Сгенерируй chain_tick.wav**

В sfxr.me: нажми **Blip/Select** → в параметрах увеличь "Start Frequency" примерно до 0.6–0.7 (звук выше) → уменьши "Sustain Time" до ~0.05 (очень короткий) → **Export WAV** → `chain_tick.wav`

- [ ] **Step 5: Сгенерируй chain_cancel.wav**

В sfxr.me: нажми **Hit/Hurt** → уменьши "Start Frequency" до ~0.2 (ниже) → уменьши "Volume" → **Export WAV** → `chain_cancel.wav`

- [ ] **Step 6: Сгенерируй resolve_sword.wav**

В sfxr.me: нажми **Hit/Hurt** → нажми "Mutate" пока не получится резкий удар → **Export WAV** → `resolve_sword.wav`

- [ ] **Step 7: Сгенерируй resolve_heart.wav**

В sfxr.me: нажми **Powerup** → нажми "Mutate" пока не получится восходящий мягкий звук → **Export WAV** → `resolve_heart.wav`

- [ ] **Step 8: Сгенерируй resolve_shield.wav**

В sfxr.me: нажми **Hit/Hurt** → уменьши "Start Frequency" до ~0.15 (тупой, низкий) → **Export WAV** → `resolve_shield.wav`

- [ ] **Step 9: Сгенерируй resolve_coin.wav**

В sfxr.me: нажми **Pickup/Coin** → нажми "Mutate" 1-2 раза → **Export WAV** → `resolve_coin.wav`

- [ ] **Step 10: Сгенерируй enemy_hit.wav**

В sfxr.me: нажми **Hit/Hurt** → увеличь "Start Frequency" до ~0.5 (резкий, средний) → **Export WAV** → `enemy_hit.wav`

- [ ] **Step 11: Сгенерируй enemy_die.wav**

В sfxr.me: нажми **Explosion** → уменьши "Sustain Time" до ~0.15 (небольшой взрыв) → **Export WAV** → `enemy_die.wav`

- [ ] **Step 12: Проверь что все 9 файлов лежат в папке**

```bash
ls "D:/Gotot/GameTwo/audio/"
```

Ожидаемый вывод: все 9 `.wav` файлов.

---

## Task 2: Создай AudioManager.gd

**Files:**
- Create: `res://scripts/core/AudioManager.gd`

- [ ] **Step 1: Создай файл AudioManager.gd**

Создай `D:/Gotot/GameTwo/scripts/core/AudioManager.gd` со следующим содержимым:

```gdscript
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
```

- [ ] **Step 2: Коммит**

```bash
git add scripts/core/AudioManager.gd
git commit -m "feat: add AudioManager autoload for sound effects"
```

---

## Task 3: Зарегистрируй AudioManager как autoload

**Files:**
- Modify: `project.godot` — добавить строку в секцию `[autoload]`

- [ ] **Step 1: Добавь строку в project.godot**

Найди секцию `[autoload]` в `project.godot`. Она выглядит так:

```ini
[autoload]

EventBus="*res://scripts/core/EventBus.gd"
GameState="*res://scripts/core/GameState.gd"
RunState="*res://scripts/core/RunState.gd"
SaveSystem="*res://scripts/core/SaveSystem.gd"
YandexSDK="*res://scripts/core/YandexSDK.gd"
Localization="*res://scripts/core/Localization.gd"
```

Добавь в конец секции:

```ini
AudioManager="*res://scripts/core/AudioManager.gd"
```

Итоговый вид секции:

```ini
[autoload]

EventBus="*res://scripts/core/EventBus.gd"
GameState="*res://scripts/core/GameState.gd"
RunState="*res://scripts/core/RunState.gd"
SaveSystem="*res://scripts/core/SaveSystem.gd"
YandexSDK="*res://scripts/core/YandexSDK.gd"
Localization="*res://scripts/core/Localization.gd"
AudioManager="*res://scripts/core/AudioManager.gd"
```

- [ ] **Step 2: Коммит**

```bash
git add project.godot
git commit -m "feat: register AudioManager as autoload"
```

---

## Task 4: Добавь звуковые файлы в git и проверь в игре

**Files:**
- Modify: `res://audio/*.wav` — добавить в git

- [ ] **Step 1: Добавь все wav и их import-файлы в git**

После того как Godot импортирует файлы (откроешь проект — Godot сделает это автоматически), в папке `audio/` появятся `.import`-файлы. Закоммить всё:

```bash
git add audio/
git commit -m "feat: add generated sfx wav files"
```

- [ ] **Step 2: Запусти игру и проверь звуки**

Запусти игру (F5). Проверь в бою:

| Действие | Ожидаемый звук |
|----------|---------------|
| Тач на первый тайл | `chain_start` |
| Перемещение по тайлам | `chain_tick` (не чаще раза в 80мс) |
| Отпустить без цепи | `chain_cancel` |
| Атака мечом | `resolve_sword` |
| Лечение | `resolve_heart` |
| Щит | `resolve_shield` |
| Монеты | `resolve_coin` |
| Враг получает урон | `enemy_hit` |
| Враг умирает | `enemy_die` |

- [ ] **Step 3: Проверь Output на предупреждения**

В консоли Godot не должно быть:
```
AudioManager: missing sound file: ...
```

Если есть — значит файл не попал в `res://audio/` или имя файла не совпадает.
