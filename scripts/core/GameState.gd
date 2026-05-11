extends Node

# Мета-прогресс между забегами: разблокировки, перманентные апгрейды,
# рекорды, выбранный класс. Сохраняется через SaveSystem.

var unlocked_classes: Array = ["warrior"]
var selected_class: String = "warrior"
var meta_upgrades: Dictionary = {}    # id -> level
var best_score: int = 0
var total_runs: int = 0
var settings: Dictionary = {
	"music_volume": 0.7,
	"sfx_volume": 1.0,
	"language": "ru",
}

func to_dict() -> Dictionary:
	return {
		"unlocked_classes": unlocked_classes,
		"selected_class": selected_class,
		"meta_upgrades": meta_upgrades,
		"best_score": best_score,
		"total_runs": total_runs,
		"settings": settings,
	}

func from_dict(data: Dictionary) -> void:
	if data.has("unlocked_classes"): unlocked_classes = data["unlocked_classes"]
	if data.has("selected_class"):   selected_class = data["selected_class"]
	if data.has("meta_upgrades"):    meta_upgrades = data["meta_upgrades"]
	if data.has("best_score"):       best_score = int(data["best_score"])
	if data.has("total_runs"):       total_runs = int(data["total_runs"])
	if data.has("settings"):         settings = data["settings"]
