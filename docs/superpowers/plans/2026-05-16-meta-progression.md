# Meta-Progression System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a roguelite meta-progression loop: runs earn Skulls and Boss Tokens, spent between runs to unlock items, skills, and classes with unique passive mechanics.

**Architecture:** Two meta-currencies (Skulls from run score, Boss Tokens from boss kills) stored in GameState persist across runs. After each run, a RunSummary panel shows earnings, then a Crypt panel lets the player spend them. Classes have passive effects wired into ChainResolver. All UI is built programmatically in Main.gd following the existing items-panel pattern.

**Tech Stack:** Godot 4, GDScript, no external test framework (verify by running the game)

---

## File Map

| File | Change |
|------|--------|
| `scripts/core/GameState.gd` | Add `skulls`, `boss_tokens`, `unlocked_item_ids`, `unlocked_skill_ids` |
| `scripts/data/ClassCatalog.gd` | NEW — 4 class definitions with passive keys |
| `scripts/core/RunState.gd` | Apply class `starting_modifiers` + set `class_passive` on run start; add `gold_bonus_pct` to `add_gold` |
| `scripts/battle/ChainResolver.gd` | Handle `rogue_coin_attack`, `vampire_heart_shield`, `alchemist_poison` |
| `scripts/battle/Battle.gd` | Track `_bosses_killed`, pass to `run_finished` payload |
| `scripts/data/EquipmentCatalog.gd` | Add `get_available_items()` filtering by `GameState.unlocked_item_ids` |
| `scripts/Main.gd` | Award skulls/tokens in `_on_run_finished`; add RunSummary panel; add Crypt panel (3 tabs) |

---

### Task 1: GameState — Add Meta Fields

**Files:**
- Modify: `scripts/core/GameState.gd`

- [ ] **Step 1: Add new fields after existing field declarations (around line 21)**

Open `scripts/core/GameState.gd`. After `var skill_pool_ids: Array = []` add:

```gdscript
var skulls: int = 0
var boss_tokens: int = 0
var unlocked_item_ids: Array = []
var unlocked_skill_ids: Array = []
```

- [ ] **Step 2: Add fields to `to_dict()` (around line 23)**

In `to_dict()`, add these four entries to the returned Dictionary:

```gdscript
"skulls": skulls,
"boss_tokens": boss_tokens,
"unlocked_item_ids": unlocked_item_ids,
"unlocked_skill_ids": unlocked_skill_ids,
```

- [ ] **Step 3: Add fields to `from_dict()` (around line 39)**

After the existing `if data.has("skill_pool_ids")` block, add:

```gdscript
if data.has("skulls"):
    skulls = int(data["skulls"])
if data.has("boss_tokens"):
    boss_tokens = int(data["boss_tokens"])
if data.has("unlocked_item_ids") and data["unlocked_item_ids"] is Array:
    unlocked_item_ids = data["unlocked_item_ids"].duplicate()
if data.has("unlocked_skill_ids") and data["unlocked_skill_ids"] is Array:
    unlocked_skill_ids = data["unlocked_skill_ids"].duplicate()
```

- [ ] **Step 4: Verify**

Launch game. Open DevTools or add a debug print in Main.gd `_ready()`:
```gdscript
print("skulls: ", GameState.skulls, " tokens: ", GameState.boss_tokens)
```
Expected: prints `skulls: 0 tokens: 0` on first run. After save/reload the values persist.

- [ ] **Step 5: Commit**

```bash
cd "D:/Gotot/GameTwo"
git add scripts/core/GameState.gd
git commit -m "feat: add skulls, boss_tokens, unlocked_item/skill_ids to GameState"
```

---

### Task 2: ClassCatalog — New Data File

**Files:**
- Create: `scripts/data/ClassCatalog.gd`

- [ ] **Step 1: Create ClassCatalog.gd**

```gdscript
extends RefCounted
class_name ClassCatalog

const DEFINITIONS := {
	"warrior": {
		"id": "warrior",
		"title": "Warrior",
		"description": "Balanced fighter. Starts with bonus max HP and sword power.",
		"icon_text": "WAR",
		"token_cost": 0,
		"starting_modifiers": {"sword_damage_bonus": 1},
		"class_passive": "",
		"max_hp_bonus": 2,
	},
	"rogue": {
		"id": "rogue",
		"title": "Rogue",
		"description": "Coin chains deal 1 damage per coin to enemies. Gold income +30%.",
		"icon_text": "ROG",
		"token_cost": 1,
		"starting_modifiers": {"gold_bonus_pct": 0.30},
		"class_passive": "rogue_coin_attack",
		"max_hp_bonus": 0,
	},
	"vampire": {
		"id": "vampire",
		"title": "Vampire",
		"description": "Starts with 10% vampirism. Heart chains also grant +1 shield per heart.",
		"icon_text": "VAM",
		"token_cost": 2,
		"starting_modifiers": {"vampirism": 0.10},
		"class_passive": "vampire_heart_shield",
		"max_hp_bonus": 0,
	},
	"alchemist": {
		"id": "alchemist",
		"title": "Alchemist",
		"description": "On enemy kill: 40% chance to deal 1 poison damage to a random adjacent enemy.",
		"icon_text": "ALC",
		"token_cost": 3,
		"starting_modifiers": {},
		"class_passive": "alchemist_poison",
		"max_hp_bonus": 0,
	},
}

static func get_class(class_id: String) -> Dictionary:
	return DEFINITIONS.get(class_id, DEFINITIONS["warrior"]).duplicate(true)

static func get_all_classes() -> Array:
	var result := []
	for raw_id in ["warrior", "rogue", "vampire", "alchemist"]:
		result.append(get_class(str(raw_id)))
	return result

static func is_unlocked(class_id: String) -> bool:
	if class_id == "warrior":
		return true
	return GameState.unlocked_classes.has(class_id)

static func unlock_cost_skulls(_class_id: String) -> int:
	return 0  # classes cost boss_tokens, not skulls

static func rarity_color_for(class_id: String) -> Color:
	match class_id:
		"warrior":  return Color(0.74, 0.76, 0.82, 1.0)
		"rogue":    return Color(0.42, 0.84, 0.48, 1.0)
		"vampire":  return Color(0.72, 0.16, 0.22, 1.0)
		"alchemist":return Color(0.34, 1.0, 0.32, 1.0)
	return Color(0.74, 0.76, 0.82, 1.0)
```

- [ ] **Step 2: Verify the file parses**

Launch Godot. In the Output panel, it should show no parse errors for ClassCatalog.gd.

- [ ] **Step 3: Commit**

```bash
cd "D:/Gotot/GameTwo"
git add scripts/data/ClassCatalog.gd
git commit -m "feat: add ClassCatalog with warrior/rogue/vampire/alchemist"
```

---

### Task 3: RunState — Apply Class on Run Start

**Files:**
- Modify: `scripts/core/RunState.gd`

- [ ] **Step 1: Add preload and class_passive field**

At the top of RunState.gd, after the other preloads, add:

```gdscript
const ClassCatalogScript := preload("res://scripts/data/ClassCatalog.gd")
```

After `var active_class: String = "warrior"` add:

```gdscript
var class_passive: String = ""
```

- [ ] **Step 2: Reset class_passive in reset()**

In `reset()`, after `active_class = GameState.selected_class` add:

```gdscript
class_passive = ""
```

- [ ] **Step 3: Apply class bonuses in start_level_run()**

In `start_level_run()`, after `modifiers = base_modifiers.duplicate(true)` add:

```gdscript
var class_def := ClassCatalogScript.get_class(active_class)
var class_mods: Dictionary = class_def.get("starting_modifiers", {})
for key in class_mods.keys():
    add_mod(str(key), class_mods[key])
var hp_bonus := int(class_def.get("max_hp_bonus", 0))
if hp_bonus > 0:
    max_hp += hp_bonus
    hp = max_hp
class_passive = str(class_def.get("class_passive", ""))
```

- [ ] **Step 4: Handle gold_bonus_pct in add_gold()**

In `add_gold()`, replace the first line `gold += amount` with:

```gdscript
var gold_pct := float(mod("gold_bonus_pct", 0.0))
if gold_pct > 0.0:
    amount = int(ceil(float(amount) * (1.0 + gold_pct)))
gold += amount
```

- [ ] **Step 5: Verify**

Launch game, start a battle as Warrior. In Battle.gd add a debug print in `_ready()`:
```gdscript
print("class: ", RunState.active_class, " passive: ", RunState.class_passive)
```
Expected: `class: warrior passive: ` (empty passive for warrior).

- [ ] **Step 6: Commit**

```bash
cd "D:/Gotot/GameTwo"
git add scripts/core/RunState.gd
git commit -m "feat: apply class starting_modifiers and class_passive in RunState"
```

---

### Task 4: ChainResolver — Class Passive Effects

**Files:**
- Modify: `scripts/battle/ChainResolver.gd`

- [ ] **Step 1: Add rogue_coin_attack and vampire_heart_shield in resolve()**

In `resolve()`, after the `# --- Золото ---` block (after `result.gold_gained = int(...)`), add:

```gdscript
# --- Class passives (resolve phase) ---
var class_passive: String = str(run.class_passive) if "class_passive" in run else ""
if class_passive == "rogue_coin_attack" and coins > 0 and result.enemies_in_chain.size() > 0:
    result.damage_to_enemies += coins
if class_passive == "vampire_heart_shield" and hearts > 0:
    result.shield_gained += hearts
```

- [ ] **Step 2: Add alchemist_poison in apply()**

In `apply()`, at the very end just before `return to_clear`, add:

```gdscript
# --- Alchemist poison spread ---
if "class_passive" in run and str(run.class_passive) == "alchemist_poison":
    var poison_additions: Array = []
    for ep in result.enemies_in_chain:
        var t = board.get_tile(ep)
        if t.kind == TileType.Kind.ENEMY and int(t.get("hp", 1)) <= 0:
            var poisoned_pos := _find_poison_target(board, ep)
            if poisoned_pos.x >= 0:
                var pt = board.get_tile(poisoned_pos)
                pt.hp = maxi(0, int(pt.hp) - 1)
                EventBus.emit_signal("enemy_damaged", poisoned_pos, 1)
                if int(pt.hp) <= 0:
                    result.killed_enemies.append(pt.duplicate(true))
                    EventBus.emit_signal("enemy_killed", poisoned_pos)
                    poison_additions.append(poisoned_pos)
    to_clear.append_array(poison_additions)
```

- [ ] **Step 3: Add _find_poison_target() static function**

At the bottom of the file, after `_attack_base_damage`, add:

```gdscript
static func _find_poison_target(board: BoardLogic, origin: Vector2) -> Vector2:
	if randf() >= 0.40:
		return Vector2(-1, -1)
	var candidates := []
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var np := Vector2(int(origin.x) + dx, int(origin.y) + dy)
			if not board.in_bounds(np):
				continue
			var nt = board.get_tile(np)
			if nt.kind == TileType.Kind.ENEMY and int(nt.get("hp", 0)) > 0:
				candidates.append(np)
	if candidates.is_empty():
		return Vector2(-1, -1)
	return candidates[randi() % candidates.size()]
```

- [ ] **Step 4: Verify**

Launch game. Play as Warrior — no rogue/vampire/alchemist effects. Verify normal combat works unchanged.
(Class selection UI comes in Task 9, but logic is in place now.)

- [ ] **Step 5: Commit**

```bash
cd "D:/Gotot/GameTwo"
git add scripts/battle/ChainResolver.gd
git commit -m "feat: add rogue_coin_attack, vampire_heart_shield, alchemist_poison passives in ChainResolver"
```

---

### Task 5: Battle — Track Bosses Killed

**Files:**
- Modify: `scripts/battle/Battle.gd`

- [ ] **Step 1: Add _bosses_killed field**

After `var _run_finished: bool = false` add:

```gdscript
var _bosses_killed: int = 0
```

- [ ] **Step 2: Increment in _on_chain_resolved**

In `_on_chain_resolved()`, inside the `for enemy in result.killed_enemies:` loop, after `if bool(enemy.get("is_boss", false)):` line add:

```gdscript
			_bosses_killed += 1
```

The full loop should look like:
```gdscript
for enemy in result.killed_enemies:
    xp_gain += 5 + int(enemy.get("xp_bonus", 0))
    if bool(enemy.get("is_boss", false)):
        _boss_killed_this_turn = true
        _bosses_killed += 1
```

- [ ] **Step 3: Pass bosses_killed in _finish_run()**

In `_finish_run()`, add `"bosses_killed": _bosses_killed` to the emitted dictionary:

```gdscript
EventBus.run_finished.emit({
    "won": won,
    "level_id": RunState.level_id,
    "level_title": RunState.level_title,
    "wave": RunState.wave,
    "total_waves": RunState.total_waves,
    "gold": RunState.gold,
    "xp": RunState.xp,
    "bosses_killed": _bosses_killed,
})
```

- [ ] **Step 4: Verify**

Play a run and kill a boss. In Main.gd `_on_run_finished` add a debug print:
```gdscript
print("bosses_killed: ", result.get("bosses_killed", 0))
```
Expected: prints `bosses_killed: 1` after killing the bone_lord.

- [ ] **Step 5: Commit**

```bash
cd "D:/Gotot/GameTwo"
git add scripts/battle/Battle.gd
git commit -m "feat: track bosses_killed per run and pass in run_finished payload"
```

---

### Task 6: EquipmentCatalog — Available Items Filter

**Files:**
- Modify: `scripts/data/EquipmentCatalog.gd`
- Modify: `scripts/core/RunState.gd`

- [ ] **Step 1: Add get_available_items() to EquipmentCatalog**

In `EquipmentCatalog.gd`, after `get_shop_items()`, add:

```gdscript
static func get_available_items() -> Array:
	var result := []
	for item in get_all_items("rarity"):
		var item_id := str(item.get("id", ""))
		if bool(item.get("shop_enabled", false)) or GameState.unlocked_item_ids.has(item_id):
			result.append(item)
	return result

static func skull_cost_for_rarity(rarity: String) -> int:
	match rarity:
		"common":    return 15
		"uncommon":  return 30
		"rare":      return 60
		"epic":      return 120
		"legendary": return 250
		"mythic":    return 500
	return 30
```

- [ ] **Step 2: Update RunState._roll_shop_choices() to use get_available_items()**

In `RunState.gd`, in `_roll_shop_choices()`, replace:

```gdscript
for item in EquipmentCatalogScript.get_shop_items():
```

with:

```gdscript
for item in EquipmentCatalogScript.get_available_items():
```

- [ ] **Step 3: Verify**

Launch game. Start a run. Trigger the shop (earn gold). The shop should still show items (same 6 shop_enabled ones since no unlocked_item_ids yet).

- [ ] **Step 4: Commit**

```bash
cd "D:/Gotot/GameTwo"
git add scripts/data/EquipmentCatalog.gd scripts/core/RunState.gd
git commit -m "feat: add get_available_items() respecting GameState.unlocked_item_ids"
```

---

### Task 7: Main — Award Skulls/Tokens and RunSummary Panel

**Files:**
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add meta vars and summary panel refs at the top of Main.gd**

After `var _item_sort_key: String = "rarity"` add:

```gdscript
var _summary_panel: PanelContainer = null
var _summary_title_label: Label = null
var _summary_stats_label: Label = null
var _summary_earned_label: Label = null
var _summary_continue_button: Button = null
var _last_run_result: Dictionary = {}
```

- [ ] **Step 2: Build the RunSummary panel in _ensure_items_codex_ui()**

At the end of `_ensure_items_codex_ui()`, after `_refresh_items_panel_text()`, add:

```gdscript
_build_summary_panel()
```

Then add the method after `_ensure_items_codex_ui()`:

```gdscript
func _build_summary_panel() -> void:
	_summary_panel = PanelContainer.new()
	_summary_panel.visible = false
	_summary_panel.custom_minimum_size = Vector2(560, 0)
	_summary_panel.set_anchors_preset(Control.PRESET_CENTER)
	_summary_panel.anchor_left = 0.5
	_summary_panel.anchor_top = 0.5
	_summary_panel.anchor_right = 0.5
	_summary_panel.anchor_bottom = 0.5
	_summary_panel.offset_left = -280.0
	_summary_panel.offset_top = -280.0
	_summary_panel.offset_right = 280.0
	_summary_panel.offset_bottom = 280.0
	_menu_root.add_child(_summary_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	_summary_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	_summary_title_label = Label.new()
	_summary_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_title_label.add_theme_font_size_override("font_size", 32)
	_summary_title_label.add_theme_color_override("font_color", Color(0.952941, 0.823529, 0.478431, 1.0))
	vbox.add_child(_summary_title_label)

	_summary_stats_label = Label.new()
	_summary_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_stats_label.add_theme_font_size_override("font_size", 22)
	_summary_stats_label.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88, 1.0))
	_summary_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_summary_stats_label)

	_summary_earned_label = Label.new()
	_summary_earned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_earned_label.add_theme_font_size_override("font_size", 26)
	_summary_earned_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.34, 1.0))
	_summary_earned_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_summary_earned_label)

	_summary_continue_button = Button.new()
	_summary_continue_button.custom_minimum_size = Vector2(0, 60)
	_summary_continue_button.add_theme_font_size_override("font_size", 22)
	_summary_continue_button.text = "Continue"
	_summary_continue_button.pressed.connect(_on_summary_continue_pressed)
	vbox.add_child(_summary_continue_button)
```

- [ ] **Step 3: Replace _on_run_finished to award resources and show summary**

Replace the entire `_on_run_finished()` method with:

```gdscript
func _on_run_finished(result: Dictionary) -> void:
	if _active_battle != null and is_instance_valid(_active_battle):
		_active_battle.queue_free()
		_active_battle = null
	_last_run_result = result

	var won := bool(result.get("won", false))
	var level_id := str(result.get("level_id", ""))
	var waves := int(result.get("wave", 0))
	var bosses := int(result.get("bosses_killed", 0))

	GameState.total_runs += 1
	if won and level_id != "":
		LevelCatalogScript.mark_level_completed(level_id)

	# Award skulls and boss tokens
	var skulls_earned := waves * 10 + bosses * 25 + (15 if won else 0)
	var tokens_earned := bosses
	GameState.skulls += skulls_earned
	GameState.boss_tokens += tokens_earned

	SaveSystem.save()
	_show_run_summary(result, skulls_earned, tokens_earned)

func _show_run_summary(result: Dictionary, skulls_earned: int, tokens_earned: int) -> void:
	if _summary_panel == null:
		_show_menu()
		return
	var won := bool(result.get("won", false))
	var waves := int(result.get("wave", 0))
	var total_waves := int(result.get("total_waves", 0))
	var bosses := int(result.get("bosses_killed", 0))
	var gold := int(result.get("gold", 0))

	_summary_title_label.text = "Victory!" if won else "Defeated"
	_summary_title_label.add_theme_color_override("font_color",
		Color(0.952941, 0.823529, 0.478431, 1.0) if won else Color(0.9, 0.3, 0.3, 1.0))

	_summary_stats_label.text = "Waves: %d / %d    Bosses: %d    Gold: %d" % [waves, total_waves, bosses, gold]

	var earned_lines := []
	if skulls_earned > 0:
		earned_lines.append("+ %d Skulls" % skulls_earned)
	if tokens_earned > 0:
		earned_lines.append("+ %d Boss Token%s" % [tokens_earned, "s" if tokens_earned > 1 else ""])
	if earned_lines.is_empty():
		earned_lines.append("No rewards earned")
	_summary_earned_label.text = "\n".join(PackedStringArray(earned_lines))

	_summary_continue_button.text = "Open Crypt  (%d skulls  %d tokens)" % [GameState.skulls, GameState.boss_tokens]

	_menu_root.visible = true
	_summary_panel.visible = true

func _on_summary_continue_pressed() -> void:
	_summary_panel.visible = false
	_open_crypt_panel()
```

- [ ] **Step 4: Verify**

Play a run, die or win. You should see the RunSummary panel with stats and earned skulls. "Continue" closes it (and calls `_open_crypt_panel` which doesn't exist yet — that's OK for now, it will print an error but not crash).

- [ ] **Step 5: Commit**

```bash
cd "D:/Gotot/GameTwo"
git add scripts/Main.gd
git commit -m "feat: award skulls/tokens on run end, show RunSummary panel"
```

---

### Task 8: Main — Crypt Panel (Equipment Tab)

**Files:**
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add crypt panel vars**

After `_summary_continue_button` var declarations, add:

```gdscript
var _crypt_panel: PanelContainer = null
var _crypt_skulls_label: Label = null
var _crypt_tokens_label: Label = null
var _crypt_tab_buttons: Dictionary = {}
var _crypt_content_box: VBoxContainer = null
var _crypt_play_button: Button = null
var _crypt_active_tab: String = "equipment"
```

- [ ] **Step 2: Build the Crypt panel**

Add `_build_crypt_panel()` call at the end of `_build_summary_panel()`:
```gdscript
_build_crypt_panel()
```

Then add the method:

```gdscript
func _build_crypt_panel() -> void:
	_crypt_panel = PanelContainer.new()
	_crypt_panel.visible = false
	_crypt_panel.custom_minimum_size = Vector2(1020, 0)
	_crypt_panel.set_anchors_preset(Control.PRESET_CENTER)
	_crypt_panel.anchor_left = 0.5
	_crypt_panel.anchor_top = 0.5
	_crypt_panel.anchor_right = 0.5
	_crypt_panel.anchor_bottom = 0.5
	_crypt_panel.offset_left = -510.0
	_crypt_panel.offset_top = -380.0
	_crypt_panel.offset_right = 510.0
	_crypt_panel.offset_bottom = 380.0
	_menu_root.add_child(_crypt_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	_crypt_panel.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 14)
	margin.add_child(root_vbox)

	# Header
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 40)
	root_vbox.add_child(header)

	var crypt_title := Label.new()
	crypt_title.text = "The Crypt"
	crypt_title.add_theme_font_size_override("font_size", 30)
	crypt_title.add_theme_color_override("font_color", Color(0.952941, 0.823529, 0.478431, 1.0))
	header.add_child(crypt_title)

	_crypt_skulls_label = Label.new()
	_crypt_skulls_label.add_theme_font_size_override("font_size", 22)
	_crypt_skulls_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.34, 1.0))
	header.add_child(_crypt_skulls_label)

	_crypt_tokens_label = Label.new()
	_crypt_tokens_label.add_theme_font_size_override("font_size", 22)
	_crypt_tokens_label.add_theme_color_override("font_color", Color(0.95, 0.62, 0.25, 1.0))
	header.add_child(_crypt_tokens_label)

	# Tabs
	var tab_row := HBoxContainer.new()
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_row.add_theme_constant_override("separation", 12)
	root_vbox.add_child(tab_row)

	for tab_id in ["equipment", "classes", "skills"]:
		var tab_btn := Button.new()
		tab_btn.custom_minimum_size = Vector2(200, 48)
		tab_btn.toggle_mode = true
		tab_btn.add_theme_font_size_override("font_size", 18)
		match tab_id:
			"equipment": tab_btn.text = "Equipment"
			"classes":   tab_btn.text = "Classes"
			"skills":    tab_btn.text = "Skills"
		tab_btn.pressed.connect(_crypt_switch_tab.bind(tab_id))
		tab_row.add_child(tab_btn)
		_crypt_tab_buttons[tab_id] = tab_btn

	# Content area (rebuilt each tab switch)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 480)
	root_vbox.add_child(scroll)

	_crypt_content_box = VBoxContainer.new()
	_crypt_content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_crypt_content_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_crypt_content_box)

	# Play button
	_crypt_play_button = Button.new()
	_crypt_play_button.custom_minimum_size = Vector2(0, 60)
	_crypt_play_button.add_theme_font_size_override("font_size", 22)
	_crypt_play_button.text = "Play"
	_crypt_play_button.pressed.connect(_on_crypt_play_pressed)
	root_vbox.add_child(_crypt_play_button)
```

- [ ] **Step 3: Add _open_crypt_panel() and tab switching**

```gdscript
func _open_crypt_panel() -> void:
	if _crypt_panel == null:
		_show_menu()
		return
	_crypt_active_tab = "equipment"
	_crypt_panel.visible = true
	_menu_root.visible = true
	_crypt_skulls_label.text = "Skulls: %d" % GameState.skulls
	_crypt_tokens_label.text = "Tokens: %d" % GameState.boss_tokens
	_crypt_switch_tab("equipment")

func _crypt_switch_tab(tab_id: String) -> void:
	_crypt_active_tab = tab_id
	for raw_id in _crypt_tab_buttons.keys():
		var btn: Button = _crypt_tab_buttons[str(raw_id)]
		btn.button_pressed = str(raw_id) == tab_id
	_clear_container(_crypt_content_box)
	match tab_id:
		"equipment": _build_crypt_equipment_tab()
		"classes":   _build_crypt_classes_tab()
		"skills":    _build_crypt_skills_tab()

func _on_crypt_play_pressed() -> void:
	_crypt_panel.visible = false
	_show_menu()
```

- [ ] **Step 4: Build the Equipment tab**

```gdscript
func _build_crypt_equipment_tab() -> void:
	var skull_header := Label.new()
	skull_header.text = "Unlock items to make them available in the in-run shop."
	skull_header.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78, 1.0))
	skull_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_crypt_content_box.add_child(skull_header)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_crypt_content_box.add_child(grid)

	var all_items := EquipmentCatalogScript.get_all_items("rarity")
	for item in all_items:
		grid.add_child(_make_crypt_item_card(item))

func _make_crypt_item_card(item: Dictionary) -> Button:
	var item_id := str(item.get("id", ""))
	var rarity := str(item.get("rarity", "common"))
	var is_available := bool(item.get("shop_enabled", false)) or GameState.unlocked_item_ids.has(item_id)
	var cost := EquipmentCatalogScript.skull_cost_for_rarity(rarity)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(226, 110)
	btn.clip_text = true
	btn.add_theme_font_size_override("font_size", 15)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER

	var title := Localization.item_name(item_id, str(item.get("title", "Item")))
	var icon := Localization.item_icon_text(item_id, str(item.get("icon_text", "*")))
	var rarity_cap := rarity.capitalize()

	if is_available:
		btn.text = "%s\n%s\n%s  [unlocked]" % [icon, title, rarity_cap]
		btn.modulate = EquipmentCatalogScript.rarity_color(rarity)
		btn.disabled = true
	else:
		btn.text = "%s\n%s\n%s  — %d skulls" % [icon, title, rarity_cap, cost]
		btn.modulate = EquipmentCatalogScript.rarity_color(rarity) * Color(0.6, 0.6, 0.6, 1.0)
		if GameState.skulls >= cost:
			btn.pressed.connect(_unlock_item.bind(item_id, cost, btn))
		else:
			btn.disabled = true
	return btn

func _unlock_item(item_id: String, cost: int, btn: Button) -> void:
	if GameState.skulls < cost:
		return
	if GameState.unlocked_item_ids.has(item_id):
		return
	GameState.skulls -= cost
	GameState.unlocked_item_ids.append(item_id)
	SaveSystem.save()
	_crypt_skulls_label.text = "Skulls: %d" % GameState.skulls
	btn.text = btn.text.replace("— %d skulls" % cost, "[unlocked]")
	btn.modulate = EquipmentCatalogScript.rarity_color(str(EquipmentCatalogScript.get_item(item_id).get("rarity", "common")))
	btn.disabled = true
	btn.set_pressed_no_signal(false)
```

- [ ] **Step 5: Verify**

Launch game, finish a run (get some skulls). Open Crypt. Equipment tab should show all items, locked ones grayed with skull cost, clicking an affordable one unlocks it (modulate changes, text changes to [unlocked]).

- [ ] **Step 6: Commit**

```bash
cd "D:/Gotot/GameTwo"
git add scripts/Main.gd
git commit -m "feat: add Crypt panel with equipment unlock tab"
```

---

### Task 9: Main — Crypt Panel (Classes Tab + Skills Tab)

**Files:**
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add preload for ClassCatalog in Main.gd**

At the top of `scripts/Main.gd`, after the existing `const` preloads, add:

```gdscript
const ClassCatalogScript := preload("res://scripts/data/ClassCatalog.gd")
```

- [ ] **Step 2: Add _build_crypt_classes_tab()**

```gdscript
func _build_crypt_classes_tab() -> void:
	var header := Label.new()
	header.text = "Unlock classes with Boss Tokens earned by killing bosses."
	header.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78, 1.0))
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_crypt_content_box.add_child(header)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	_crypt_content_box.add_child(grid)

	for class_def in ClassCatalogScript.get_all_classes():
		grid.add_child(_make_crypt_class_card(class_def))

func _make_crypt_class_card(class_def: Dictionary) -> PanelContainer:
	var class_id := str(class_def.get("id", "warrior"))
	var cost := int(class_def.get("token_cost", 0))
	var is_unlocked := ClassCatalogScript.is_unlocked(class_id)
	var is_selected := GameState.selected_class == class_id

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 130)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_top", 14)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(m)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	m.add_child(vbox)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	vbox.add_child(title_row)

	var icon_label := Label.new()
	icon_label.text = str(class_def.get("icon_text", "?"))
	icon_label.add_theme_font_size_override("font_size", 28)
	icon_label.add_theme_color_override("font_color", ClassCatalogScript.rarity_color_for(class_id))
	title_row.add_child(icon_label)

	var name_label := Label.new()
	name_label.text = str(class_def.get("title", class_id))
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color(0.952941, 0.823529, 0.478431, 1.0))
	title_row.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = str(class_def.get("description", ""))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_color_override("font_color", Color(0.86, 0.86, 0.86, 1.0))
	vbox.add_child(desc_label)

	var action_btn := Button.new()
	action_btn.custom_minimum_size = Vector2(0, 40)
	action_btn.add_theme_font_size_override("font_size", 17)

	if is_unlocked and is_selected:
		action_btn.text = "[Selected]"
		action_btn.disabled = true
	elif is_unlocked:
		action_btn.text = "Select"
		action_btn.pressed.connect(_select_class.bind(class_id, panel))
	elif GameState.boss_tokens >= cost:
		action_btn.text = "Unlock  (%d token%s)" % [cost, "s" if cost > 1 else ""]
		action_btn.pressed.connect(_unlock_class.bind(class_id, cost, action_btn))
	else:
		action_btn.text = "Locked  (%d token%s needed)" % [cost, "s" if cost > 1 else ""]
		action_btn.disabled = true

	vbox.add_child(action_btn)
	return panel

func _unlock_class(class_id: String, cost: int, btn: Button) -> void:
	if GameState.boss_tokens < cost:
		return
	GameState.boss_tokens -= cost
	GameState.unlocked_classes.append(class_id)
	SaveSystem.save()
	_crypt_tokens_label.text = "Tokens: %d" % GameState.boss_tokens
	btn.text = "Select"
	btn.set_pressed_no_signal(false)
	btn.pressed.disconnect(_unlock_class.bind(class_id, cost, btn))
	btn.pressed.connect(_select_class.bind(class_id, btn.get_parent().get_parent().get_parent()))

func _select_class(class_id: String, _panel: Node) -> void:
	GameState.selected_class = class_id
	SaveSystem.save()
	# Rebuild tab to update selected state
	_crypt_switch_tab("classes")
```

- [ ] **Step 3: Add _build_crypt_skills_tab()**

```gdscript
func _build_crypt_skills_tab() -> void:
	var header := Label.new()
	header.text = "Unlock skills to add them to your in-run skill pool. Cost: 20 skulls each."
	header.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78, 1.0))
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_crypt_content_box.add_child(header)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	_crypt_content_box.add_child(grid)

	for skill in SkillCatalogScript.get_all_skills():
		grid.add_child(_make_crypt_skill_card(skill))

func _make_crypt_skill_card(skill: Dictionary) -> Button:
	var skill_id := str(skill.get("id", ""))
	const SKILL_COST := 20
	var in_pool := GameState.skill_pool_ids.has(skill_id)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(300, 100)
	btn.clip_text = true
	btn.add_theme_font_size_override("font_size", 16)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER

	var icon := Localization.skill_icon_text(skill_id, str(skill.get("icon_text", "*")))
	var title := Localization.skill_name(skill_id, str(skill.get("title", skill_id)))
	var desc := Localization.skill_description(skill_id, str(skill.get("description", "")))

	if in_pool:
		btn.text = "%s  %s\n[In pool]" % [icon, title]
		btn.disabled = true
		btn.modulate = Color(0.6, 0.9, 0.6, 1.0)
	elif GameState.skulls >= SKILL_COST:
		btn.text = "%s  %s\n%s skulls" % [icon, title, SKILL_COST]
		btn.tooltip_text = desc
		btn.pressed.connect(_unlock_skill.bind(skill_id, SKILL_COST, btn))
	else:
		btn.text = "%s  %s\n%s skulls (need more)" % [icon, title, SKILL_COST]
		btn.disabled = true
		btn.modulate = Color(0.55, 0.55, 0.55, 1.0)
	return btn

func _unlock_skill(skill_id: String, cost: int, btn: Button) -> void:
	if GameState.skulls < cost:
		return
	if GameState.skill_pool_ids.has(skill_id):
		return
	GameState.skulls -= cost
	GameState.skill_pool_ids.append(skill_id)
	GameState.unlocked_skill_ids.append(skill_id)
	SaveSystem.save()
	_crypt_skulls_label.text = "Skulls: %d" % GameState.skulls
	btn.text = btn.text.split("\n")[0] + "\n[In pool]"
	btn.modulate = Color(0.6, 0.9, 0.6, 1.0)
	btn.disabled = true
	btn.set_pressed_no_signal(false)
```

- [ ] **Step 4: Verify**

Open Crypt → Classes tab. Should show 4 class cards. Warrior shows "Select" (already selected shows "[Selected]"). Rogue/Vampire/Alchemist show "Locked (N tokens needed)" until you have enough tokens. Switch to Skills tab — shows all 10 skills. Those already in pool show "[In pool]".

- [ ] **Step 5: Commit**

```bash
cd "D:/Gotot/GameTwo"
git add scripts/Main.gd
git commit -m "feat: add Classes tab and Skills tab to Crypt panel"
```

---

### Task 10: Main — Class Selection at Run Start

**Files:**
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add class select panel vars**

After `_crypt_play_button` var, add:

```gdscript
var _class_select_panel: PanelContainer = null
var _pending_level_id: String = ""
```

- [ ] **Step 2: Build class select panel**

Add `_build_class_select_panel()` call at end of `_build_crypt_panel()`:
```gdscript
_build_class_select_panel()
```

Add the method:

```gdscript
func _build_class_select_panel() -> void:
	_class_select_panel = PanelContainer.new()
	_class_select_panel.visible = false
	_class_select_panel.custom_minimum_size = Vector2(680, 0)
	_class_select_panel.set_anchors_preset(Control.PRESET_CENTER)
	_class_select_panel.anchor_left = 0.5
	_class_select_panel.anchor_top = 0.5
	_class_select_panel.anchor_right = 0.5
	_class_select_panel.anchor_bottom = 0.5
	_class_select_panel.offset_left = -340.0
	_class_select_panel.offset_top = -300.0
	_class_select_panel.offset_right = 340.0
	_class_select_panel.offset_bottom = 300.0
	_menu_root.add_child(_class_select_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	_class_select_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Choose Class"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.952941, 0.823529, 0.478431, 1.0))
	vbox.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	vbox.add_child(grid)

	for class_def in ClassCatalogScript.get_all_classes():
		var class_id := str(class_def.get("id", "warrior"))
		if not ClassCatalogScript.is_unlocked(class_id):
			continue
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(290, 90)
		btn.add_theme_font_size_override("font_size", 17)
		var icon := str(class_def.get("icon_text", "?"))
		var name_text := str(class_def.get("title", class_id))
		var desc := str(class_def.get("description", ""))
		btn.text = "%s  %s\n%s" % [icon, name_text, desc]
		btn.clip_text = false
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if btn.has_method("autowrap_mode") else 0
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.modulate = ClassCatalogScript.rarity_color_for(class_id)
		btn.pressed.connect(_on_class_selected.bind(class_id))
		grid.add_child(btn)

	var back_btn := Button.new()
	back_btn.custom_minimum_size = Vector2(0, 50)
	back_btn.text = "Back"
	back_btn.pressed.connect(func():
		_class_select_panel.visible = false
		_pending_level_id = ""
	)
	vbox.add_child(back_btn)

func _on_class_selected(class_id: String) -> void:
	GameState.selected_class = class_id
	_class_select_panel.visible = false
	if _pending_level_id != "":
		_start_level(_pending_level_id)
		_pending_level_id = ""
```

- [ ] **Step 3: Intercept _start_level to show class selection**

Replace `_start_level()` with:

```gdscript
func _start_level(level_id: String) -> void:
	if level_id == "":
		return
	var unlocked := ClassCatalogScript.get_all_classes().filter(func(c): return ClassCatalogScript.is_unlocked(str(c.get("id", ""))))
	if unlocked.size() > 1:
		# Show class selection if more than one class is unlocked
		_pending_level_id = level_id
		_class_select_panel.visible = true
		_level_list_panel.visible = false
		_skills_panel.visible = false
		_editor_panel.visible = false
		if _items_panel != null: _items_panel.visible = false
		if _crypt_panel != null: _crypt_panel.visible = false
		return
	# Only one class unlocked — start directly
	GameState.selected_level_id = level_id
	GameState.last_played_level_id = level_id
	SaveSystem.save()
	if _active_battle != null and is_instance_valid(_active_battle):
		_active_battle.queue_free()
	_active_battle = BattleScene.instantiate()
	_battle_root.add_child(_active_battle)
	_hide_menu()

func _start_level_direct(level_id: String) -> void:
	GameState.selected_level_id = level_id
	GameState.last_played_level_id = level_id
	SaveSystem.save()
	if _active_battle != null and is_instance_valid(_active_battle):
		_active_battle.queue_free()
	_active_battle = BattleScene.instantiate()
	_battle_root.add_child(_active_battle)
	_hide_menu()
```

Then update `_on_class_selected` to call `_start_level_direct`:
```gdscript
func _on_class_selected(class_id: String) -> void:
	GameState.selected_class = class_id
	_class_select_panel.visible = false
	if _pending_level_id != "":
		_start_level_direct(_pending_level_id)
		_pending_level_id = ""
```

And update `_on_new_game_pressed` to use `_start_level_direct` so it bypasses class select (resets to warrior):
```gdscript
func _on_new_game_pressed() -> void:
	LevelCatalogScript.reset_campaign_progress()
	GameState.selected_class = "warrior"
	SaveSystem.save()
	var first_level := LevelCatalogScript.get_first_level()
	if first_level.is_empty():
		return
	_start_level_direct(str(first_level.get("id", "")))
```

- [ ] **Step 4: Verify the full meta loop**

1. Launch game. Click Continue. Class select shows only Warrior (only 1 unlocked) → battle starts directly.
2. Die. RunSummary shows skulls earned. Click Continue → Crypt opens.
3. In Crypt/Equipment tab, buy an item if you have skulls. It changes to [unlocked].
4. In Crypt/Classes tab, unlock Rogue (if you have 1 token). Select Rogue.
5. Play → Continue → class select shows Warrior and Rogue. Select Rogue.
6. During battle, making a coin chain against an enemy should deal extra damage.

- [ ] **Step 5: Commit**

```bash
cd "D:/Gotot/GameTwo"
git add scripts/Main.gd
git commit -m "feat: add class select panel at run start, wire full meta-progression flow"
```

---

## Self-Review

**Spec coverage check:**
- ✅ Skulls + Boss Tokens as meta-currencies (Tasks 1, 7)
- ✅ Skulls awarded by formula at run end (Task 7)
- ✅ Tokens awarded per boss killed (Tasks 5, 7)
- ✅ Crypt screen with Equipment tab (Task 8)
- ✅ Crypt screen with Classes tab (Task 9)
- ✅ Crypt screen with Skills tab (Task 9)
- ✅ Class passives: warrior/rogue/vampire/alchemist (Tasks 2, 3, 4)
- ✅ Item unlock stored in GameState.unlocked_item_ids (Tasks 1, 6, 8)
- ✅ Unlocked items appear in shop (Task 6)
- ✅ Save/load of all new fields — automatic via GameState.to_dict/from_dict (Task 1)
- ✅ Class select at run start (Task 10)
- ✅ Flow: RunSummary → Crypt → Level Select → Class Select → Battle (Tasks 7, 8, 9, 10)

**No placeholders:** All code blocks are complete.

**Type consistency:** `class_passive` is a `String` in RunState and read as `str(run.class_passive)` in ChainResolver. `ClassCatalogScript` preloaded consistently in both Main.gd and RunState.gd. `EquipmentCatalogScript` method `skull_cost_for_rarity` defined in Task 6 and called in Task 8.
