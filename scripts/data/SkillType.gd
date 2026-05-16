extends RefCounted
class_name SkillType

var id: String = ""
var title: String = ""
var short_title: String = ""
var description: String = ""
var icon_text: String = "*"
var color: Color = Color(0.58, 0.34, 0.92, 1.0)
var max_level: int = 5

func _init(data: Dictionary = {}) -> void:
	id = str(data.get("id", id))
	title = str(data.get("title", title))
	short_title = str(data.get("short_title", short_title))
	description = str(data.get("description", description))
	icon_text = str(data.get("icon_text", icon_text))
	color = data.get("color", color)
	max_level = maxi(1, int(data.get("max_level", max_level)))

func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"title": title,
		"short_title": short_title,
		"description": description,
		"icon_text": icon_text,
		"color": color,
		"max_level": max_level,
	}
