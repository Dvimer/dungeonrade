extends Node

signal language_changed(language: String)

const AUTO_LANGUAGE := "auto"
const DEFAULT_LANGUAGE := "en"
const SUPPORTED_LANGUAGES := ["en", "ru"]

const TEXTS := {
	"en": {
		"hud.title": "DUNGEON RAID",
		"hud.subtitle": "MATCH  ·  SWIPE  ·  SLAY",
		"hud.level": "Lv. %d",
		"hud.xp": "%d / %d XP",
		"hud.wave": "WAVE %d  %d",
		"hud.boss_wave": "BOSS W%d",
		"tile.sword": "BLADE",
		"tile.shield": "AEGIS",
		"tile.coin": "GILT",
		"tile.heart": "VITA",
		"tile.enemy": "FOE",
		"tile.boss": "BOSS",
		"preview.might": "Might %d x %d = %d",
		"preview.attack": "ATK +%d",
		"preview.heal": "HP +%d",
		"preview.shield": "Shield +%d",
		"preview.gold": "Gold +%d",
		"monster.info": "%s\nHP %d  ATK %d  TIMER %d",
		"reward.gold": "+%d GILT",
		"reward.shield": "+%d AEGIS",
		"reward.heal": "+%d VITA",
		"combat.crit": "CRIT",
		"combat.boss": "BOSS",
		"monster.skeleton": "Skeleton",
		"monster.bandana_skeleton": "Bone Rogue",
		"monster.vampire": "Vampire",
		"monster.bone_lord": "Bone Lord",
	},
	"ru": {
		"hud.title": "DUNGEON RAID",
		"hud.subtitle": "СОБИРАЙ  ·  ВЕДИ  ·  РУБИ",
		"hud.level": "Ур. %d",
		"hud.xp": "%d / %d ОП",
		"hud.wave": "ВОЛНА %d  %d",
		"hud.boss_wave": "БОСС В%d",
		"tile.sword": "МЕЧ",
		"tile.shield": "ЩИТ",
		"tile.coin": "ЗЛАТО",
		"tile.heart": "ЖИЗНЬ",
		"tile.enemy": "ВРАГ",
		"tile.boss": "БОСС",
		"preview.might": "Сила %d x %d = %d",
		"preview.attack": "Урон +%d",
		"preview.heal": "ЖЗ +%d",
		"preview.shield": "Щит +%d",
		"preview.gold": "Золото +%d",
		"monster.info": "%s\nЖЗ %d  УРОН %d  ХОД %d",
		"reward.gold": "+%d ЗЛАТО",
		"reward.shield": "+%d ЭГИДА",
		"reward.heal": "+%d ЖИЗНЬ",
		"combat.crit": "КРИТ",
		"combat.boss": "БОСС",
		"monster.skeleton": "Скелет",
		"monster.bandana_skeleton": "Костяной разбойник",
		"monster.vampire": "Вампир",
		"monster.bone_lord": "Костяной лорд",
	},
}

var current_language: String = DEFAULT_LANGUAGE

func _ready() -> void:
	apply_saved_language()

func apply_saved_language() -> void:
	_set_active_language(_resolve_language(str(GameState.settings.get("language", AUTO_LANGUAGE))))

func set_language(language: String, save_setting: bool = true) -> void:
	var requested := _normalize_language(language)
	GameState.settings["language"] = requested
	_set_active_language(_resolve_language(requested))
	if save_setting:
		SaveSystem.save()

func t(key: String, args: Array = []) -> String:
	var lang_texts: Dictionary = TEXTS.get(current_language, TEXTS[DEFAULT_LANGUAGE])
	var template := str(lang_texts.get(key, TEXTS[DEFAULT_LANGUAGE].get(key, key)))
	if args.is_empty():
		return template
	return template % args

func monster_name(monster_id: String, fallback: String = "") -> String:
	var translated := t("monster.%s" % monster_id)
	if translated.begins_with("monster.") and fallback != "":
		return fallback
	return translated

func available_languages() -> Array:
	return SUPPORTED_LANGUAGES.duplicate()

func _set_active_language(language: String) -> void:
	if current_language == language:
		return
	current_language = language
	TranslationServer.set_locale(language)
	language_changed.emit(current_language)

func _resolve_language(language: String) -> String:
	var normalized := _normalize_language(language)
	if normalized != AUTO_LANGUAGE:
		return normalized
	var platform_language := _platform_language()
	if SUPPORTED_LANGUAGES.has(platform_language):
		return platform_language
	return DEFAULT_LANGUAGE

func _normalize_language(language: String) -> String:
	var normalized := language.strip_edges().to_lower()
	if normalized == "":
		return AUTO_LANGUAGE
	normalized = normalized.replace("-", "_")
	if normalized.contains("_"):
		normalized = normalized.get_slice("_", 0)
	if normalized == AUTO_LANGUAGE or SUPPORTED_LANGUAGES.has(normalized):
		return normalized
	return DEFAULT_LANGUAGE

func _platform_language() -> String:
	var yandex_language := YandexSDK.get_language()
	if yandex_language != "":
		return _normalize_language(yandex_language)
	var locale := OS.get_locale_language()
	if locale == "":
		locale = OS.get_locale()
	return _normalize_language(locale)
