extends RefCounted
class_name SkillType

var id: String = ""
var title: String = ""
var short_title: String = ""
var description: String = ""
var icon_text: String = "*"
var color: Color = Color(0.58, 0.34, 0.92, 1.0)
var max_level: int = 5
var skill_kind: String = "passive"
var cooldown_base: int = 0
var cooldown_reduction_per_level: int = 1
var effect_id: String = ""
var animation_id: String = ""

func _init(data: Dictionary = {}) -> void:
	id = str(data.get("id", id))
	title = str(data.get("title", title))
	short_title = str(data.get("short_title", short_title))
	description = str(data.get("description", description))
	icon_text = str(data.get("icon_text", icon_text))
	color = data.get("color", color)
	max_level = maxi(1, int(data.get("max_level", max_level)))
	skill_kind = str(data.get("skill_kind", skill_kind))
	cooldown_base = int(data.get("cooldown_base", cooldown_base))
	cooldown_reduction_per_level = int(data.get("cooldown_reduction_per_level", cooldown_reduction_per_level))
	effect_id = str(data.get("effect_id", effect_id))
	animation_id = str(data.get("animation_id", animation_id))

func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"title": title,
		"short_title": short_title,
		"description": description,
		"icon_text": icon_text,
		"color": color,
		"max_level": max_level,
		"skill_kind": skill_kind,
		"cooldown_base": cooldown_base,
		"cooldown_reduction_per_level": cooldown_reduction_per_level,
		"effect_id": effect_id,
		"animation_id": animation_id,
	}
