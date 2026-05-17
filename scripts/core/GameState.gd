extends Node

# Мета-прогресс между забегами: разблокировки, перманентные апгрейды,
# рекорды, выбранный класс. Сохраняется через SaveSystem.

var unlocked_classes: Array = ["warrior"]
var selected_class: String = "warrior"
var meta_upgrades: Dictionary = {}    # id -> level
var best_score: int = 0
var total_runs: int = 0
var completed_level_ids: Array = []
var unlocked_level_ids: Array = []
var selected_level_id: String = ""
var last_played_level_id: String = ""
var level_definitions: Array = []
var skill_pool_ids: Array = []
var skulls: int = 0
var boss_tokens: int = 0
var unlocked_item_ids: Array = []
var unlocked_skill_ids: Array = []
var skill_levels: Dictionary = {}   # skill_id -> int (1 = base, 2-5 = upgraded)
var settings: Dictionary = {
	"music_volume": 0.7,
	"sfx_volume": 1.0,
	"audio_enabled": true,
	"language": "ru",
}
var active_run: Dictionary = {}   # снимок RunState активного забега

func to_dict() -> Dictionary:
	return {
		"unlocked_classes": unlocked_classes,
		"selected_class": selected_class,
		"meta_upgrades": meta_upgrades,
		"best_score": best_score,
		"total_runs": total_runs,
		"completed_level_ids": completed_level_ids,
		"unlocked_level_ids": unlocked_level_ids,
		"selected_level_id": selected_level_id,
		"last_played_level_id": last_played_level_id,
		"level_definitions": level_definitions,
		"skill_pool_ids": skill_pool_ids,
		"skulls": skulls,
		"boss_tokens": boss_tokens,
		"unlocked_item_ids": unlocked_item_ids,
		"unlocked_skill_ids": unlocked_skill_ids,
		"skill_levels": skill_levels,
		"settings": settings,
		"active_run": active_run.duplicate(true),
	}

func from_dict(data: Dictionary) -> void:
	if data.has("unlocked_classes"): unlocked_classes = data["unlocked_classes"]
	if data.has("selected_class"):   selected_class = data["selected_class"]
	if data.has("meta_upgrades"):    meta_upgrades = data["meta_upgrades"]
	if data.has("best_score"):       best_score = int(data["best_score"])
	if data.has("total_runs"):       total_runs = int(data["total_runs"])
	if data.has("completed_level_ids") and data["completed_level_ids"] is Array:
		completed_level_ids = data["completed_level_ids"].duplicate()
	if data.has("unlocked_level_ids") and data["unlocked_level_ids"] is Array:
		unlocked_level_ids = data["unlocked_level_ids"].duplicate()
	if data.has("selected_level_id"):
		selected_level_id = str(data["selected_level_id"])
	if data.has("last_played_level_id"):
		last_played_level_id = str(data["last_played_level_id"])
	if data.has("level_definitions") and data["level_definitions"] is Array:
		level_definitions = data["level_definitions"].duplicate(true)
	if data.has("skill_pool_ids") and data["skill_pool_ids"] is Array:
		skill_pool_ids = data["skill_pool_ids"].duplicate()
	if data.has("skulls"):
		skulls = int(data["skulls"])
	if data.has("boss_tokens"):
		boss_tokens = int(data["boss_tokens"])
	if data.has("unlocked_item_ids") and data["unlocked_item_ids"] is Array:
		unlocked_item_ids = data["unlocked_item_ids"].duplicate()
	if data.has("unlocked_skill_ids") and data["unlocked_skill_ids"] is Array:
		unlocked_skill_ids = data["unlocked_skill_ids"].duplicate()
	if data.has("skill_levels") and data["skill_levels"] is Dictionary:
		skill_levels = data["skill_levels"].duplicate()
	if data.has("active_run") and data["active_run"] is Dictionary:
		active_run = data["active_run"].duplicate(true)
	if data.has("settings") and data["settings"] is Dictionary:
		var loaded_settings: Dictionary = data["settings"]
		for key in loaded_settings.keys():
			settings[key] = loaded_settings[key]
