extends Node

# Обёртка над Yandex Games SDK.
# В редакторе/десктопе все вызовы — no-op, чтобы код игры был платформо-независимым.
# На веб-сборке нужно подключить плагин (например godot-yandex-games-sdk)
# и заменить заглушки на реальные JS-вызовы через JavaScriptBridge.

signal sdk_ready
signal ad_started
signal ad_finished(rewarded: bool)

var _ready_state := false

func _ready() -> void:
	if not is_available():
		# В редакторе — сразу считаем "готово".
		call_deferred("_emit_ready")

func is_available() -> bool:
	# Запускаемся ли мы в HTML5-сборке с Yandex SDK.
	# В Godot 4 фича называется "web" (HTML5 — alias).
	return OS.has_feature("web") and Engine.has_singleton("YandexSDK")

func _emit_ready() -> void:
	_ready_state = true
	sdk_ready.emit()

# --- Сейвы ---
func save_data(data: Dictionary) -> void:
	if not is_available():
		return
	# Реальная реализация: Engine.get_singleton("YandexSDK").save_data(data)
	pass

func load_data(callback: Callable) -> void:
	if not is_available():
		callback.call(null)
		return
	# Реальная реализация: подписаться на сигнал плагина.
	callback.call(null)

# --- Реклама ---
func show_fullscreen_ad() -> void:
	if not is_available():
		ad_finished.emit(false)
		return
	ad_started.emit()
	# Engine.get_singleton("YandexSDK").show_fullscreen_adv()

func show_rewarded_ad(callback: Callable = Callable()) -> void:
	if not is_available():
		if callback.is_valid():
			callback.call(false)
		return
	# Engine.get_singleton("YandexSDK").show_rewarded_video(...)

# --- Лидерборды ---
func submit_score(leaderboard: String, score: int) -> void:
	if not is_available():
		return
	# Engine.get_singleton("YandexSDK").submit_score(leaderboard, score)

# --- Пауза игры по требованию платформы ---
func pause_game() -> void:
	get_tree().paused = true

func resume_game() -> void:
	get_tree().paused = false
