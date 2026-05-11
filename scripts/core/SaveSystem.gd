extends Node

# Сохранение/загрузка. На вебе — через YandexSDK (облачный сейв),
# в редакторе и на десктопе — в user://save.json.

const SAVE_PATH := "user://save.json"

func _ready() -> void:
	call_deferred("load_save")

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
	var localization := get_node_or_null("/root/Localization")
	if localization:
		localization.apply_saved_language()

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
	var localization := get_node_or_null("/root/Localization")
	if localization:
		localization.apply_saved_language()
