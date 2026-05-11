extends RefCounted
class_name MonsterType

# Data container for one monster archetype.
# Board tiles receive a snapshot of these values, so future scaling/modifiers can
# change one spawned monster without mutating the catalog definition.

var id: String = ""
var display_name: String = ""
var icon_path: String = "res://assets/icons/skull.svg"
var hp: int = 1
var dmg: int = 1
var timer: int = 3
var attack_cooldown: int = 3
var reset_timer_on_hit: bool = false
var hit_timer_reset: int = 3
var remove_on_attack: bool = true
var heal_on_attack: bool = false
var heal_on_attack_ratio: float = 1.0
var spawn_weight: int = 1
var xp_bonus: int = 0
var gold_bonus: int = 0
var tile_color: Color = Color(0.18, 0.09, 0.20)
var rim_color: Color = Color(0.58, 0.37, 0.48)

func _init(data: Dictionary = {}) -> void:
	id = str(data.get("id", id))
	display_name = str(data.get("display_name", display_name))
	icon_path = str(data.get("icon_path", icon_path))
	hp = int(data.get("hp", hp))
	dmg = int(data.get("dmg", dmg))
	timer = int(data.get("timer", timer))
	attack_cooldown = int(data.get("attack_cooldown", data.get("timer", attack_cooldown)))
	reset_timer_on_hit = bool(data.get("reset_timer_on_hit", reset_timer_on_hit))
	hit_timer_reset = int(data.get("hit_timer_reset", hit_timer_reset))
	remove_on_attack = bool(data.get("remove_on_attack", remove_on_attack))
	heal_on_attack = bool(data.get("heal_on_attack", heal_on_attack))
	heal_on_attack_ratio = float(data.get("heal_on_attack_ratio", heal_on_attack_ratio))
	spawn_weight = int(data.get("spawn_weight", spawn_weight))
	xp_bonus = int(data.get("xp_bonus", xp_bonus))
	gold_bonus = int(data.get("gold_bonus", gold_bonus))
	tile_color = data.get("tile_color", tile_color)
	rim_color = data.get("rim_color", rim_color)

func to_enemy_tile() -> Dictionary:
	return {
		"kind": TileType.Kind.ENEMY,
		"monster_id": id,
		"monster_name": display_name,
		"icon_path": icon_path,
		"hp": hp,
		"max_hp": hp,
		"dmg": dmg,
		"timer": timer,
		"attack_cooldown": attack_cooldown,
		"reset_timer_on_hit": reset_timer_on_hit,
		"hit_timer_reset": hit_timer_reset,
		"remove_on_attack": remove_on_attack,
		"heal_on_attack": heal_on_attack,
		"heal_on_attack_ratio": heal_on_attack_ratio,
		"xp_bonus": xp_bonus,
		"gold_bonus": gold_bonus,
		"tile_color": tile_color,
		"rim_color": rim_color,
	}
