extends Node

signal language_changed(language: String)

const AUTO_LANGUAGE := "auto"
const DEFAULT_LANGUAGE := "ru"
const SUPPORTED_LANGUAGES := ["en", "ru"]

const TEXTS := {
	"en": {
		"menu.title": "Dungeon Raid",
		"menu.subtitle": "Campaign Levels",
		"menu.summary": "Completed levels: %d / %d\nNext level: %s",
		"menu.continue": "Continue",
		"menu.new_game": "New Game",
		"menu.skills": "Skills (%d/8)",
		"menu.items": "Items",
		"menu.crypt": "The Crypt  (%d skulls  %d tokens)",
		"menu.items.title": "Item Codex",
		"menu.items.summary": "Items: %d\nSort: %s",
		"menu.items.hover_title": "Item",
		"menu.items.hover_meta": "Hover an item to see its rarity, slot, type, and bonuses.",
		"menu.items.hover_text": "This panel shows every item currently defined in the game.",
		"menu.items.sort.name": "By Name",
		"menu.items.sort.rarity": "By Rarity",
		"menu.items.sort.slot": "By Slot",
		"menu.items.sort.type": "By Type",
		"menu.pick_level": "Choose Level",
		"menu.create_level": "Create Level",
		"menu.edit_level": "Edit Level",
		"menu.language": "Language",
		"menu.lang_ru": "Russian",
		"menu.lang_en": "English",
		"menu.close": "Close",
		"menu.cancel": "Cancel",
		"menu.save": "Save",
		"menu.level_picker.play": "Choose a level",
		"menu.level_picker.edit": "Which level to edit?",
		"menu.level.done": " [completed]",
		"menu.level.open": " [available]",
		"menu.skills.title": "Skill Pool",
		"menu.skills.current": "Current Eight Skills",
		"menu.skills.other": "Other Skills",
		"menu.skills.hover_title": "Skill",
		"menu.skills.hover_text": "Hover a skill to see its name and description.",
		"menu.skills.summary": "Top: current skill pool of eight. Bottom: the rest. Click a bottom skill, then click a top slot to replace it.",
		"menu.skills.summary.replace": "Selected skill [%s]. Click one of the top 8 skills to replace it.",
		"menu.skills.error.replace": "Now click a top skill to replace it.",
		"menu.skills.error.already": "This skill is already in the current eight.",
		"menu.skills.error.replaced": "Skill replaced.",
		"menu.skills.error.min": "You need at least 4 skills.",
		"menu.skills.error.max": "You can choose at most 8 skills.",
		"menu.editor.title.create": "Create Level",
		"menu.editor.title.edit": "Edit Level",
		"menu.editor.help": "Edit the JSON config. This is developer-only for now and can be hidden later.",
		"menu.editor.saved": "Level saved.",
		"menu.editor.invalid_json": "JSON could not be parsed. Check commas, quotes, and object structure.",
		"menu.editor.custom_level_title": "Custom Level %d",
		"menu.editor.custom_level_desc": "Describe this level",
		"hud.title": "DUNGEON RAID",
		"hud.subtitle": "MATCH  ·  SWIPE  ·  SLAY",
		"hud.level": "Lv. %d",
		"hud.xp": "%d / %d XP",
		"hud.wave": "WAVE %d  %d",
		"hud.boss_wave": "BOSS W%d",
		"hud.menu": "Menu",
		"hud.stats": "Stats",
		"hud.wave_turns": "WAVE %d   TURNS %d",
		"hud.wave_boss": "BOSS  WAVE %d",
		"hud.gold": "Gold",
		"hud.enemy": "Skeleton",
		"hud.shield": "Shields",
		"hud.sword": "Sword",
		"hud.hp": "HP",
		"hud.skill_xp": "Skill Upgrade  %d / %d   Lv.%d",
		"hud.shop_charge": "Shop  %d / %d%s",
		"hud.shop_ready": "  READY",
		"hud.empty": "EMPTY",
		"hud.skill.ready": "READY",
		"hud.stats_title": "Current Stats",
		"hud.stats.crit": "Crit chance: %d%%",
		"hud.stats.vamp": "Vampirism: %d%%",
		"hud.stats.hp": "HP: %d / %d",
		"hud.stats.shield": "Shields: %d / %d",
		"hud.stats.sword": "Sword power: %d",
		"hud.stats.enemy": "Skeleton power: %d",
		"hud.stats.shop": "Shop charge: %d / %d",
		"hud.stats.equipment.none": "Equipment: none",
		"hud.stats.equipment": "Equipment: %s",
		"hud.upgrade.title": "Level Up",
		"hud.upgrade.subtitle": "Choose 1 of 3 skills",
		"hud.upgrade.new": "Unlocks a new skill",
		"hud.upgrade.next": "Upgrade to Lv.%d",
		"hud.shop.title": "Shop Open",
		"hud.shop.subtitle": "Choose 1 of 3 items",
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
		"monster.info": "%s\nHP %d  ATK %d  DEF %d  TIMER %d",
		"reward.gold": "+%d GILT",
		"reward.shield": "+%d AEGIS",
		"reward.heal": "+%d VITA",
		"combat.crit": "CRIT",
		"combat.boss": "BOSS",
		"combat.kill": "EXECUTED",
		"monster.skeleton": "Skeleton",
		"monster.bandana_skeleton": "Bone Rogue",
		"monster.vampire": "Vampire",
		"monster.bone_lord": "Bone Lord",
		"tooltip.enemy.heal_on_attack": "Heals on attack (x%.1f)",
		"tooltip.enemy.explode": "Explodes on attack (radius %d, dmg %d)",
		"tooltip.enemy.reset_timer": "Resets timer on hit",
		"tooltip.enemy.remove_on_attack": "Vanishes after attack",
		"tooltip.enemy.boss": "BOSS",
		"skill.bone_crown.title": "Bone Crown",
		"skill.bone_crown.short": "Crown",
		"skill.bone_crown.desc": "More damage against bosses and elites.",
		"skill.bone_crown.icon": "BONE",
		"skill.arc_star.title": "Arc Star",
		"skill.arc_star.short": "Star",
		"skill.arc_star.desc": "Chain length adds bonus critical chance.",
		"skill.arc_star.icon": "STAR",
		"skill.violet_blade.title": "Violet Blade",
		"skill.violet_blade.short": "Blade",
		"skill.violet_blade.desc": "Each sword tile hits harder.",
		"skill.violet_blade.icon": "EDGE",
		"skill.frost_sigils.title": "Frost Sigils",
		"skill.frost_sigils.short": "Frost",
		"skill.frost_sigils.desc": "Enemies lose speed on long chains.",
		"skill.frost_sigils.icon": "FROST",
		"skill.coin_furnace.title": "Coin Furnace",
		"skill.coin_furnace.short": "Coins",
		"skill.coin_furnace.desc": "Shop charge fills faster from gold.",
		"skill.coin_furnace.icon": "GOLD",
		"skill.thorn_mail.title": "Thorn Mail",
		"skill.thorn_mail.short": "Armor",
		"skill.thorn_mail.desc": "Blocked hits return damage.",
		"skill.thorn_mail.icon": "MAIL",
		"skill.blood_well.title": "Blood Well",
		"skill.blood_well.short": "Blood",
		"skill.blood_well.desc": "Healing chains recover extra health.",
		"skill.blood_well.icon": "BLOOD",
		"skill.grave_tempo.title": "Grave Tempo",
		"skill.grave_tempo.short": "Tempo",
		"skill.grave_tempo.desc": "More actions before enemies scale up.",
		"skill.grave_tempo.icon": "TEMPO",
		"skill.moon_ward.title": "Moon Ward",
		"skill.moon_ward.short": "Ward",
		"skill.moon_ward.desc": "Raise shield capacity and resist damage.",
		"skill.moon_ward.icon": "WARD",
		"skill.venom_burst.title": "Venom Burst",
		"skill.venom_burst.short": "Venom",
		"skill.venom_burst.desc": "Enemy kills splash poison damage.",
		"skill.venom_burst.icon": "VENOM",
		"item.iron_sword.title": "Iron Sword",
		"item.iron_sword.desc": "A heavier blade for larger chains.",
		"item.iron_sword.icon": "SWORD",
		"item.hunter_blade.title": "Hunter Blade",
		"item.hunter_blade.desc": "A quick edge with better critical finishers.",
		"item.hunter_blade.icon": "BLADE",
		"item.tower_shield.title": "Tower Shield",
		"item.tower_shield.desc": "Raises the shield cap for longer fights.",
		"item.tower_shield.icon": "SHIELD",
		"item.blood_charm.title": "Blood Charm",
		"item.blood_charm.desc": "Turns each good chain into better sustain.",
		"item.blood_charm.icon": "CHARM",
		"item.merchant_gloves.title": "Merchant Gloves",
		"item.merchant_gloves.desc": "Gold chains fill the shop faster.",
		"item.merchant_gloves.icon": "GOLD",
		"item.bone_lens.title": "Bone Lens",
		"item.bone_lens.desc": "Helps land precise critical hits.",
		"item.bone_lens.icon": "LENS",
		"slot.weapon": "Weapon",
		"slot.shield": "Shield",
		"slot.armor": "Armor",
		"slot.helmet": "Helmet",
		"slot.gloves": "Gloves",
		"slot.boots": "Boots",
		"slot.belt": "Belt",
		"slot.ring": "Ring",
		"slot.amulet": "Amulet",
		"slot.trinket": "Trinket",
		"rarity.common": "Common",
		"rarity.uncommon": "Uncommon",
		"rarity.rare": "Rare",
		"rarity.epic": "Epic",
		"rarity.legendary": "Legendary",
		"rarity.mythic": "Mythic",
		"type.offense": "Offense",
		"type.precision": "Precision",
		"type.defense": "Defense",
		"type.sustain": "Sustain",
		"type.utility": "Utility",
		"type.hybrid": "Hybrid",
		"level.crypt_entry.title": "Crypt Entry",
		"level.crypt_entry.desc": "Tutorial pace: base skeletons and steady sword chains.",
		"level.rogue_catacombs.title": "Rogue Catacombs",
		"level.rogue_catacombs.desc": "Fast bandits punish long setups and hit more often.",
		"level.blood_vault.title": "Blood Vault",
		"level.blood_vault.desc": "Vampires arrive early and scale hard each wave.",
		"bonus.sword_damage_bonus": "+%d sword power",
		"bonus.crit_chance": "+%d%% critical chance",
		"bonus.vampirism": "+%d%% vampirism",
		"bonus.shop_charge_bonus": "+%d shop charge",
		"bonus.max_shield_bonus": "+%d shield cap",
		"bonus.enemy_power_delta": "%.2f enemy power",
		"combo.great": "GREAT",
		"combo.insane": "INSANE",
		"combo.godlike": "GODLIKE",
	},
	"ru": {
		"menu.title": "Dungeon Raid",
		"menu.subtitle": "Кампания уровней",
		"menu.summary": "Пройдено уровней: %d / %d\nСледующий уровень: %s",
		"menu.continue": "Продолжить",
		"menu.new_game": "Новая игра",
		"menu.skills": "Навыки (%d/8)",
		"menu.items": "Предметы",
		"menu.crypt": "Крипта  (%d черепов  %d токенов)",
		"menu.items.title": "Справочник предметов",
		"menu.items.summary": "Предметов: %d\nСортировка: %s",
		"menu.items.hover_title": "Предмет",
		"menu.items.hover_meta": "Наведите на предмет, чтобы увидеть редкость, слот, тип и бонусы.",
		"menu.items.hover_text": "Здесь показаны все предметы, которые сейчас описаны в игре.",
		"menu.items.sort.name": "По названию",
		"menu.items.sort.rarity": "По редкости",
		"menu.items.sort.slot": "По слоту",
		"menu.items.sort.type": "По типу",
		"menu.pick_level": "Выбрать уровень",
		"menu.create_level": "Создать уровень",
		"menu.edit_level": "Редактировать уровень",
		"menu.language": "Язык",
		"menu.lang_ru": "Русский",
		"menu.lang_en": "English",
		"menu.close": "Закрыть",
		"menu.cancel": "Отмена",
		"menu.save": "Сохранить",
		"menu.level_picker.play": "Выберите уровень",
		"menu.level_picker.edit": "Какой уровень редактировать?",
		"menu.level.done": " [пройден]",
		"menu.level.open": " [доступен]",
		"menu.skills.title": "Пул навыков",
		"menu.skills.current": "Текущая восьмёрка навыков",
		"menu.skills.other": "Остальные навыки",
		"menu.skills.hover_title": "Навык",
		"menu.skills.hover_text": "Наведите курсор на навык, чтобы увидеть его название и описание.",
		"menu.skills.summary": "Сверху текущая восьмёрка навыков. Снизу навыки, которые пока не выбраны. Нажмите на нижний навык, затем на верхний слот для замены.",
		"menu.skills.summary.replace": "Выбран навык [%s]. Нажмите на один из верхних 8 навыков, чтобы заменить его.",
		"menu.skills.error.replace": "Теперь нажмите на верхний навык, который нужно заменить.",
		"menu.skills.error.already": "Этот навык уже входит в текущую восьмёрку.",
		"menu.skills.error.replaced": "Навык заменён.",
		"menu.skills.error.min": "Нужно выбрать минимум 4 навыка.",
		"menu.skills.error.max": "Можно выбрать максимум 8 навыков.",
		"menu.editor.title.create": "Создание уровня",
		"menu.editor.title.edit": "Редактирование уровня",
		"menu.editor.help": "Меняйте JSON-конфиг уровня. Доступно только для разработки; позже эту панель можно будет скрыть.",
		"menu.editor.saved": "Уровень сохранён.",
		"menu.editor.invalid_json": "JSON не распознан. Проверьте запятые, кавычки и структуру объекта.",
		"menu.editor.custom_level_title": "Пользовательский уровень %d",
		"menu.editor.custom_level_desc": "Опишите этот уровень",
		"hud.title": "DUNGEON RAID",
		"hud.subtitle": "СОБИРАЙ  ·  ВЕДИ  ·  РУБИ",
		"hud.level": "Ур. %d",
		"hud.xp": "%d / %d ОП",
		"hud.wave": "ВОЛНА %d  %d",
		"hud.boss_wave": "БОСС В%d",
		"hud.menu": "Меню",
		"hud.stats": "Статы",
		"hud.wave_turns": "ВОЛНА %d   ХОДЫ %d",
		"hud.wave_boss": "БОСС  ВОЛНА %d",
		"hud.gold": "Монеты",
		"hud.enemy": "Скелет",
		"hud.shield": "Щиты",
		"hud.sword": "Меч",
		"hud.hp": "Жизни",
		"hud.skill_xp": "Прокачка навыка  %d / %d   Ур.%d",
		"hud.shop_charge": "Магазин  %d / %d%s",
		"hud.shop_ready": "  ГОТОВО",
		"hud.empty": "ПУСТО",
		"hud.skill.ready": "ГОТОВО",
		"hud.stats_title": "Текущие параметры",
		"hud.stats.crit": "Крит шанс: %d%%",
		"hud.stats.vamp": "Вампиризм: %d%%",
		"hud.stats.hp": "Жизни: %d / %d",
		"hud.stats.shield": "Щиты: %d / %d",
		"hud.stats.sword": "Сила меча: %d",
		"hud.stats.enemy": "Сила скелета: %d",
		"hud.stats.shop": "Заряд магазина: %d / %d",
		"hud.stats.equipment.none": "Экипировка: нет",
		"hud.stats.equipment": "Экипировка: %s",
		"hud.upgrade.title": "Новый уровень",
		"hud.upgrade.subtitle": "Выберите 1 из 3 навыков",
		"hud.upgrade.new": "Откроет новый навык",
		"hud.upgrade.next": "Улучшение до Ур.%d",
		"hud.shop.title": "Магазин открыт",
		"hud.shop.subtitle": "Выберите 1 из 3 предметов",
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
		"monster.info": "%s\nЖЗ %d  УРОН %d  ЗАЩ %d  ХОД %d",
		"reward.gold": "+%d ЗЛАТО",
		"reward.shield": "+%d ЭГИДА",
		"reward.heal": "+%d ЖИЗНЬ",
		"combat.crit": "КРИТ",
		"combat.boss": "БОСС",
		"combat.kill": "УБИТ",
		"monster.skeleton": "Скелет",
		"monster.bandana_skeleton": "Костяной разбойник",
		"monster.vampire": "Вампир",
		"monster.bone_lord": "Костяной лорд",
		"tooltip.enemy.heal_on_attack": "Лечится при атаке (x%.1f)",
		"tooltip.enemy.explode": "Взрывается при атаке (радиус %d, урон %d)",
		"tooltip.enemy.reset_timer": "Сбрасывает ход при ударе",
		"tooltip.enemy.remove_on_attack": "Исчезает после атаки",
		"tooltip.enemy.boss": "БОСС",
		"skill.bone_crown.title": "Костяная корона",
		"skill.bone_crown.short": "Корона",
		"skill.bone_crown.desc": "Даёт больше урона против боссов и элиты.",
		"skill.bone_crown.icon": "КОСТЬ",
		"skill.arc_star.title": "Дуговая звезда",
		"skill.arc_star.short": "Звезда",
		"skill.arc_star.desc": "Длинные цепочки повышают шанс крита.",
		"skill.arc_star.icon": "ДУГА",
		"skill.violet_blade.title": "Фиолетовый клинок",
		"skill.violet_blade.short": "Клинок",
		"skill.violet_blade.desc": "Каждый тайл меча бьёт сильнее.",
		"skill.violet_blade.icon": "ЛЕЗВИЕ",
		"skill.frost_sigils.title": "Ледяные сигилы",
		"skill.frost_sigils.short": "Лёд",
		"skill.frost_sigils.desc": "Длинные цепочки ослабляют врагов.",
		"skill.frost_sigils.icon": "ЛЁД",
		"skill.coin_furnace.title": "Печь монет",
		"skill.coin_furnace.short": "Монеты",
		"skill.coin_furnace.desc": "Монеты быстрее заряжают магазин.",
		"skill.coin_furnace.icon": "ЗЛАТО",
		"skill.thorn_mail.title": "Колючая броня",
		"skill.thorn_mail.short": "Броня",
		"skill.thorn_mail.desc": "Блоки делают защиту сильнее.",
		"skill.thorn_mail.icon": "ШИПЫ",
		"skill.blood_well.title": "Кровавый колодец",
		"skill.blood_well.short": "Кровь",
		"skill.blood_well.desc": "Лечащие цепочки восстанавливают больше.",
		"skill.blood_well.icon": "КРОВЬ",
		"skill.grave_tempo.title": "Темп могил",
		"skill.grave_tempo.short": "Темп",
		"skill.grave_tempo.desc": "Даёт темп и ускоряет развитие забега.",
		"skill.grave_tempo.icon": "ТЕМП",
		"skill.moon_ward.title": "Лунный покров",
		"skill.moon_ward.short": "Покров",
		"skill.moon_ward.desc": "Поднимает лимит щитов и стойкость.",
		"skill.moon_ward.icon": "ЛУНА",
		"skill.venom_burst.title": "Ядовитый всплеск",
		"skill.venom_burst.short": "Яд",
		"skill.venom_burst.desc": "Усиливает добивание врагов и криты.",
		"skill.venom_burst.icon": "ЯД",
		"item.iron_sword.title": "Железный меч",
		"item.iron_sword.desc": "Тяжёлый клинок для более сильных цепочек.",
		"item.iron_sword.icon": "МЕЧ",
		"item.hunter_blade.title": "Охотничий клинок",
		"item.hunter_blade.desc": "Быстрое оружие с лучшими критическими ударами.",
		"item.hunter_blade.icon": "КЛИНОК",
		"item.tower_shield.title": "Башенный щит",
		"item.tower_shield.desc": "Увеличивает лимит щитов в долгих боях.",
		"item.tower_shield.icon": "ЩИТ",
		"item.blood_charm.title": "Кровавый талисман",
		"item.blood_charm.desc": "Каждая удачная цепочка лучше лечит.",
		"item.blood_charm.icon": "ТАЛИСМАН",
		"item.merchant_gloves.title": "Перчатки торговца",
		"item.merchant_gloves.desc": "Монеты быстрее открывают магазин.",
		"item.merchant_gloves.icon": "ЗЛАТО",
		"item.bone_lens.title": "Костяная линза",
		"item.bone_lens.desc": "Помогает точнее наносить критические удары.",
		"item.bone_lens.icon": "ЛИНЗА",
		"slot.weapon": "Оружие",
		"slot.shield": "Щит",
		"slot.armor": "Броня",
		"slot.helmet": "Шлем",
		"slot.gloves": "Перчатки",
		"slot.boots": "Сапоги",
		"slot.belt": "Пояс",
		"slot.ring": "Кольцо",
		"slot.amulet": "Амулет",
		"slot.trinket": "Артефакт",
		"rarity.common": "Обычный",
		"rarity.uncommon": "Необычный",
		"rarity.rare": "Редкий",
		"rarity.epic": "Эпический",
		"rarity.legendary": "Легендарный",
		"rarity.mythic": "Мифический",
		"type.offense": "Атака",
		"type.precision": "Точность",
		"type.defense": "Защита",
		"type.sustain": "Выживание",
		"type.utility": "Поддержка",
		"type.hybrid": "Гибрид",
		"level.crypt_entry.title": "Вход в крипту",
		"level.crypt_entry.desc": "Спокойный старт: базовые скелеты и ровные цепочки мечей.",
		"level.rogue_catacombs.title": "Катакомбы разбойников",
		"level.rogue_catacombs.desc": "Быстрые разбойники наказывают за долгую подготовку.",
		"level.blood_vault.title": "Кровавое хранилище",
		"level.blood_vault.desc": "Вампиры приходят рано и быстро усиливаются.",
		"bonus.sword_damage_bonus": "+%d к силе меча",
		"bonus.crit_chance": "+%d%% к шансу крита",
		"bonus.vampirism": "+%d%% к вампиризму",
		"bonus.shop_charge_bonus": "+%d к заряду магазина",
		"bonus.max_shield_bonus": "+%d к лимиту щитов",
		"bonus.enemy_power_delta": "%.2f к силе врагов",
		"combo.great": "МОЩНО",
		"combo.insane": "БЕШЕНО",
		"combo.godlike": "БОЖЕСТВЕННО",
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

func language_label(language: String) -> String:
	return t("menu.lang_%s" % _normalize_language(language))

func skill_name(skill_id: String, fallback: String = "") -> String:
	return _entity_text("skill.%s.title" % skill_id, fallback)

func skill_short_name(skill_id: String, fallback: String = "") -> String:
	return _entity_text("skill.%s.short" % skill_id, fallback)

func skill_description(skill_id: String, fallback: String = "") -> String:
	return _entity_text("skill.%s.desc" % skill_id, fallback)

func skill_icon_text(skill_id: String, fallback: String = "") -> String:
	return _entity_text("skill.%s.icon" % skill_id, fallback)

func item_name(item_id: String, fallback: String = "") -> String:
	return _entity_text("item.%s.title" % item_id, fallback)

func item_description(item_id: String, fallback: String = "") -> String:
	return _entity_text("item.%s.desc" % item_id, fallback)

func item_icon_text(item_id: String, fallback: String = "") -> String:
	return _entity_text("item.%s.icon" % item_id, fallback)

func item_slot(slot_id: String, fallback: String = "") -> String:
	return _entity_text("slot.%s" % slot_id, fallback)

func item_rarity(rarity_id: String, fallback: String = "") -> String:
	return _entity_text("rarity.%s" % rarity_id, fallback)

func item_type(type_id: String, fallback: String = "") -> String:
	return _entity_text("type.%s" % type_id, fallback)

func level_title(level_id: String, fallback: String = "") -> String:
	return _entity_text("level.%s.title" % level_id, fallback)

func level_description(level_id: String, fallback: String = "") -> String:
	return _entity_text("level.%s.desc" % level_id, fallback)

func combo_label(combo_id: String, fallback: String = "") -> String:
	return _entity_text("combo.%s" % combo_id.to_lower(), fallback)

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

func _entity_text(key: String, fallback: String = "") -> String:
	var translated := t(key)
	if translated == key and fallback != "":
		return fallback
	return translated
