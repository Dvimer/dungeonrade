extends Node

# Сохранение/загрузка. На вебе — через YandexSDK (облачный сейв),
# в редакторе и на десктопе — в user://save.json.

const SAVE_PATH := "user://save.json"

func _ready() -> void:
	call_deferred("load_save")
	# Снимаем RunState после каждого значимого события в забеге
	EventBus.upgrade_picked.connect(func(_u): call_deferred("_snapshot_run"))
	EventBus.shop_picked.connect(func(_i): call_deferred("_snapshot_run"))
	EventBus.wave_cleared.connect(func(_w): call_deferred("_snapshot_run"))

func _snapshot_run() -> void:
	if RunState.level_id == "":
		return
	GameState.active_run = RunState.to_dict()
	save()

func save() -> void:
	var data: Dictionary = GameState.to_dict()
	if YandexSDK.is_available():
		YandexSDK.save_data(data)
		return
	_save_local(data)

func load_save() -> void:
	if YandexSDK.is_available():
		YandexSDK.load_data(Callable(self, "_on_remote_loaded"))
		return
	_load_local()

func _on_remote_loaded(data) -> void:
	if data == null or not (data is Dictionary):
		_load_local()
		return
	GameState.from_dict(data)
	_apply_runtime_settings()

func _save_local(data: Dictionary) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("SaveSystem: cannot write %s" % SAVE_PATH)
		return
	f.store_string(JSON.stringify(data))
	f.close()

func _load_local() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var raw := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	if parsed == null or not (parsed is Dictionary):
		return
	GameState.from_dict(parsed)
	_apply_runtime_settings()

func _apply_runtime_settings() -> void:
	var localization := get_node_or_null("/root/Localization")
	if localization:
		localization.apply_saved_language()
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.apply_saved_settings()
