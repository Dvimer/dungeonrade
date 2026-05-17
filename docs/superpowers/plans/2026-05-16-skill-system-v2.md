# Skill System v2: Active Skills + Cooldowns Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace passive-only skill slots with a mixed active/passive system — 4 slots, active skills tap-to-use with per-skill cooldowns (decremented each turn), passive skills always-on; both types reuse the same `SkillEffect` base class so weapons can reference effects by ID.

**Architecture:** Each skill effect is a separate GDScript class extending `SkillEffect` (Variant B — polimorphism). `SkillCatalog` maps `effect_id` strings to preloaded scripts. `RunState` owns cooldown state and calls `activate_skill()`; Board/Battle handle visual consequences via `EventBus.tiles_skill_cleared`. HUD renders tappable cards with cooldown overlays.

**Tech Stack:** Godot 4 / GDScript, no external test runner — verification is done by running the game in Godot editor and checking console + visual output.

---

## File Map

**Create:**
- `scripts/data/SkillEffect.gd` — base class, `apply(run, board_logic) -> Dictionary`
- `scripts/data/effects/EffectCollectGold.gd` — collect all COIN tiles
- `scripts/data/effects/EffectDamageAll.gd` — deal sword_power damage to every enemy
- `scripts/data/effects/EffectSweepRows.gd` — collect all tiles in bottom 2 rows
- `scripts/data/effects/EffectFullHeal.gd` — restore HP to max
- `scripts/data/effects/EffectResetTimers.gd` — reset all enemy timers to their max
- `scripts/data/effects/EffectNextCrit.gd` — set next_crit_forced flag in RunState

**Modify:**
- `scripts/data/SkillType.gd` — add `skill_kind`, `cooldown_base`, `cooldown_reduction_per_level`, `effect_id`
- `scripts/data/SkillCatalog.gd` — add 6 active skill definitions + `get_effect_script(effect_id)`
- `scripts/core/RunState.gd` — add `skill_cooldowns`, `next_crit_forced`, `activate_skill()`, `_tick_skill_cooldowns()` on turn_ended
- `scripts/core/EventBus.gd` — add `skill_tapped`, `tiles_skill_cleared`
- `scripts/battle/ChainResolver.gd` — check `next_crit_forced` flag, fix type annotation bug
- `scripts/battle/Battle.gd` — connect `tiles_skill_cleared` → `board.consume_and_refill`
- `scripts/ui/HUD.gd` — tappable active skill cards with cooldown overlay, subscribe to `skills_changed` for refresh

---

## Task 0: Quick Fixes

**Files:**
- Modify: `scripts/battle/ChainResolver.gd:119`
- Modify: `scripts/battle/Battle.gd` — investigate gold float label

- [ ] **Step 1: Fix type annotation error in ChainResolver.gd**

At line 119, change:
```gdscript
# Before
		var kill_gold_actual := run.add_gold(kill_gold_bonus)

# After
		var kill_gold_actual: int = run.add_gold(kill_gold_bonus)
```

- [ ] **Step 2: Find gold chain display bug**

In `Battle.gd`, `_show_chain_rewards()` (line 166) calls:
```gdscript
board.show_float_at_grid(anchor, Localization.t("reward.gold", [result.gold_gained]), ...)
```
This is called from `_on_chain_resolved` which is connected to `EventBus.chain_resolved`. Check `SwipeController.gd` — if `chain_resolved` is emitted BEFORE `ChainResolver.apply()` is called, then `result.gold_gained` is still the raw tile count (not post-bonus). Fix: ensure `chain_resolved` is emitted with the result only AFTER `ChainResolver.apply()` has run.

- [ ] **Step 3: Verify chain_resolved emit order in SwipeController.gd**

Read `scripts/battle/SwipeController.gd`. Find the line that emits `chain_resolved`. Confirm whether `apply()` runs before or after emit. If `chain_resolved` is emitted before `apply()`:

```gdscript
# Wrong order (emits raw result before apply)
EventBus.chain_resolved.emit(result)
var to_clear = ChainResolver.apply(board.logic, result, RunState)

# Correct order
var to_clear = ChainResolver.apply(board.logic, result, RunState)
EventBus.chain_resolved.emit(result)
```

- [ ] **Step 4: Commit quick fixes**
```bash
cd D:/Gotot/GameTwo
git add scripts/battle/ChainResolver.gd scripts/battle/SwipeController.gd
git commit -m "fix: type annotation in ChainResolver, fix gold float showing tile count"
```

---

## Task 1: SkillEffect Base Class

**Files:**
- Create: `scripts/data/SkillEffect.gd`

- [ ] **Step 1: Create base class**

```gdscript
# scripts/data/SkillEffect.gd
extends RefCounted
class_name SkillEffect

# Subclasses override apply() to implement the effect.
# Returns a Dictionary with zero or more of these keys:
#   "gold_gained": int          — add this gold to RunState
#   "healed": int               — call RunState.heal()
#   "tiles_cleared": Array      — Array[Vector2], emit tiles_skill_cleared
#   "next_crit_set": bool       — set RunState.next_crit_forced = true
#   "timers_reset": bool        — enemy timers were reset inside apply()
#   "damage_dealt": int         — total damage dealt (for float labels)
func apply(run: Node, board_logic: BoardLogic) -> Dictionary:
	return {}
```

- [ ] **Step 2: Verify file loads in Godot**

Run game in editor, check Output for parse errors. No errors expected.

---

## Task 2: Six Active Skill Effect Files

**Files:**
- Create: `scripts/data/effects/EffectCollectGold.gd`
- Create: `scripts/data/effects/EffectDamageAll.gd`
- Create: `scripts/data/effects/EffectSweepRows.gd`
- Create: `scripts/data/effects/EffectFullHeal.gd`
- Create: `scripts/data/effects/EffectResetTimers.gd`
- Create: `scripts/data/effects/EffectNextCrit.gd`

- [ ] **Step 1: Create EffectCollectGold**

```gdscript
# scripts/data/effects/EffectCollectGold.gd
extends SkillEffect

func apply(run: Node, board_logic: BoardLogic) -> Dictionary:
	var positions: Array = []
	for y in range(board_logic.height):
		for x in range(board_logic.width):
			var p := Vector2(x, y)
			var t = board_logic.get_tile(p)
			if t.kind == TileType.Kind.COIN:
				positions.append(p)
	var gold := positions.size()
	return {"gold_gained": gold, "tiles_cleared": positions}
```

- [ ] **Step 2: Create EffectDamageAll**

```gdscript
# scripts/data/effects/EffectDamageAll.gd
extends SkillEffect

func apply(run: Node, board_logic: BoardLogic) -> Dictionary:
	var dmg: int = run.sword_power()
	var total := 0
	var to_clear: Array = []
	for y in range(board_logic.height):
		for x in range(board_logic.width):
			var p := Vector2(x, y)
			var t = board_logic.get_tile(p)
			if t.kind == TileType.Kind.ENEMY:
				t.hp -= dmg
				total += dmg
				EventBus.emit_signal("enemy_damaged", p, dmg)
				if t.hp <= 0:
					EventBus.emit_signal("enemy_killed", p)
					to_clear.append(p)
	return {"damage_dealt": total, "tiles_cleared": to_clear}
```

- [ ] **Step 3: Create EffectSweepRows (bottom 2 rows)**

```gdscript
# scripts/data/effects/EffectSweepRows.gd
extends SkillEffect

func apply(run: Node, board_logic: BoardLogic) -> Dictionary:
	var positions: Array = []
	var gold := 0
	var healed := 0
	var shield := 0
	var bottom := board_logic.height - 1
	for row in [bottom, bottom - 1]:
		if row < 0:
			continue
		for x in range(board_logic.width):
			var p := Vector2(x, row)
			var t = board_logic.get_tile(p)
			match t.kind:
				TileType.Kind.COIN:
					gold += 1
					positions.append(p)
				TileType.Kind.HEART:
					healed += 1
					positions.append(p)
				TileType.Kind.SHIELD:
					shield += 1
					positions.append(p)
				TileType.Kind.SWORD:
					positions.append(p)
				TileType.Kind.ENEMY:
					var dmg: int = run.sword_power()
					t.hp -= dmg
					EventBus.emit_signal("enemy_damaged", p, dmg)
					if t.hp <= 0:
						EventBus.emit_signal("enemy_killed", p)
						positions.append(p)
	if shield > 0:
		run.add_shield(shield)
	if healed > 0:
		run.heal(healed)
	return {"gold_gained": gold, "tiles_cleared": positions}
```

- [ ] **Step 4: Create EffectFullHeal**

```gdscript
# scripts/data/effects/EffectFullHeal.gd
extends SkillEffect

func apply(run: Node, board_logic: BoardLogic) -> Dictionary:
	var amount := run.max_hp - run.hp
	if amount > 0:
		run.heal(amount)
	return {"healed": amount}
```

- [ ] **Step 5: Create EffectResetTimers**

```gdscript
# scripts/data/effects/EffectResetTimers.gd
extends SkillEffect

func apply(run: Node, board_logic: BoardLogic) -> Dictionary:
	for y in range(board_logic.height):
		for x in range(board_logic.width):
			var t = board_logic.get_tile(Vector2(x, y))
			if t.kind == TileType.Kind.ENEMY:
				var max_timer: int = int(t.get("max_timer", t.get("timer", 3)))
				t.timer = max_timer
	return {"timers_reset": true}
```

- [ ] **Step 6: Create EffectNextCrit**

```gdscript
# scripts/data/effects/EffectNextCrit.gd
extends SkillEffect

func apply(run: Node, board_logic: BoardLogic) -> Dictionary:
	run.next_crit_forced = true
	return {"next_crit_set": true}
```

- [ ] **Step 7: Commit**
```bash
git add scripts/data/SkillEffect.gd scripts/data/effects/
git commit -m "feat: add SkillEffect base class and 6 active effect implementations"
```

---

## Task 3: Update SkillType and SkillCatalog

**Files:**
- Modify: `scripts/data/SkillType.gd`
- Modify: `scripts/data/SkillCatalog.gd`

- [ ] **Step 1: Extend SkillType with active-skill fields**

Add after `max_level` field:
```gdscript
var skill_kind: String = "passive"          # "passive" or "active"
var cooldown_base: int = 0                  # turns cooldown at level 1
var cooldown_reduction_per_level: int = 1   # reduce cooldown by this per level
var effect_id: String = ""                  # maps to EffectXxx class in SkillCatalog
```

In `_init()`, add after `max_level =`:
```gdscript
skill_kind = str(data.get("skill_kind", skill_kind))
cooldown_base = int(data.get("cooldown_base", cooldown_base))
cooldown_reduction_per_level = int(data.get("cooldown_reduction_per_level", cooldown_reduction_per_level))
effect_id = str(data.get("effect_id", effect_id))
```

In `to_dictionary()`, add to the return dict:
```gdscript
"skill_kind": skill_kind,
"cooldown_base": cooldown_base,
"cooldown_reduction_per_level": cooldown_reduction_per_level,
"effect_id": effect_id,
```

- [ ] **Step 2: Add active skill definitions to SkillCatalog**

Add to `DEFINITIONS` dict after the last passive skill:
```gdscript
"gold_sweep": {
    "id": "gold_sweep",
    "title": "Gold Sweep",
    "short_title": "Sweep",
    "description": "Collect all gold from the board instantly.",
    "icon_text": "SWEEP",
    "color": Color(0.98, 0.80, 0.22, 1.0),
    "skill_kind": "active",
    "cooldown_base": 6,
    "cooldown_reduction_per_level": 1,
    "effect_id": "collect_gold",
    "max_level": 5,
},
"wrath": {
    "id": "wrath",
    "title": "Wrath",
    "short_title": "Wrath",
    "description": "Deal sword damage to every enemy on the board.",
    "icon_text": "WRATH",
    "color": Color(1.0, 0.32, 0.28, 1.0),
    "skill_kind": "active",
    "cooldown_base": 8,
    "cooldown_reduction_per_level": 1,
    "effect_id": "damage_all",
    "max_level": 5,
},
"row_sweep": {
    "id": "row_sweep",
    "title": "Row Sweep",
    "short_title": "Rows",
    "description": "Collect everything in the bottom two rows.",
    "icon_text": "ROWS",
    "color": Color(0.42, 0.72, 1.0, 1.0),
    "skill_kind": "active",
    "cooldown_base": 7,
    "cooldown_reduction_per_level": 1,
    "effect_id": "sweep_rows",
    "max_level": 5,
},
"full_heal": {
    "id": "full_heal",
    "title": "Full Heal",
    "short_title": "Heal",
    "description": "Restore HP to maximum.",
    "icon_text": "HEAL",
    "color": Color(0.40, 1.0, 0.58, 1.0),
    "skill_kind": "active",
    "cooldown_base": 12,
    "cooldown_reduction_per_level": 1,
    "effect_id": "full_heal",
    "max_level": 5,
},
"stasis": {
    "id": "stasis",
    "title": "Stasis",
    "short_title": "Stasis",
    "description": "Reset all enemy timers to their maximum.",
    "icon_text": "STOP",
    "color": Color(0.62, 0.88, 1.0, 1.0),
    "skill_kind": "active",
    "cooldown_base": 9,
    "cooldown_reduction_per_level": 1,
    "effect_id": "reset_timers",
    "max_level": 5,
},
"predator": {
    "id": "predator",
    "title": "Predator",
    "short_title": "Pred",
    "description": "Your next chain is a guaranteed critical hit.",
    "icon_text": "CRIT",
    "color": Color(1.0, 0.60, 0.18, 1.0),
    "skill_kind": "active",
    "cooldown_base": 5,
    "cooldown_reduction_per_level": 1,
    "effect_id": "next_crit",
    "max_level": 5,
},
```

- [ ] **Step 3: Add `get_effect_script()` to SkillCatalog**

Add after the `DEFINITIONS` const:
```gdscript
const EFFECT_SCRIPTS := {
    "collect_gold": preload("res://scripts/data/effects/EffectCollectGold.gd"),
    "damage_all":   preload("res://scripts/data/effects/EffectDamageAll.gd"),
    "sweep_rows":   preload("res://scripts/data/effects/EffectSweepRows.gd"),
    "full_heal":    preload("res://scripts/data/effects/EffectFullHeal.gd"),
    "reset_timers": preload("res://scripts/data/effects/EffectResetTimers.gd"),
    "next_crit":    preload("res://scripts/data/effects/EffectNextCrit.gd"),
}

static func get_effect_script(effect_id: String):
    return EFFECT_SCRIPTS.get(effect_id, null)
```

- [ ] **Step 4: Update `level_bonus()` to return empty for active skills**

In `level_bonus()`, add before the existing code:
```gdscript
static func level_bonus(skill: Dictionary) -> Dictionary:
    if str(skill.get("skill_kind", "passive")) == "active":
        return {}
    var bonuses = skill.get("bonuses", {})
    if bonuses is Dictionary:
        return bonuses.duplicate(true)
    return {}
```

- [ ] **Step 5: Verify in Godot editor — no parse errors**

Run game, check Output tab. No errors expected.

- [ ] **Step 6: Commit**
```bash
git add scripts/data/SkillType.gd scripts/data/SkillCatalog.gd
git commit -m "feat: extend SkillType with active skill fields, add 6 active skill definitions"
```

---

## Task 4: Update EventBus

**Files:**
- Modify: `scripts/core/EventBus.gd`

- [ ] **Step 1: Add two new signals**

After `signal upgrade_picked(upgrade)`:
```gdscript
signal skill_tapped(skill_id)          # String — HUD requests skill activation
signal tiles_skill_cleared(positions)  # Array[Vector2] — Battle clears these tiles
```

- [ ] **Step 2: Commit**
```bash
git add scripts/core/EventBus.gd
git commit -m "feat: add skill_tapped and tiles_skill_cleared signals to EventBus"
```

---

## Task 5: Update RunState

**Files:**
- Modify: `scripts/core/RunState.gd`

- [ ] **Step 1: Add new state variables after `active_equipment`**
```gdscript
var skill_cooldowns: Dictionary = {}   # skill_id -> turns remaining (0 = ready)
var next_crit_forced: bool = false
```

- [ ] **Step 2: Clear new state in `reset()`**

Add after `active_equipment = []`:
```gdscript
skill_cooldowns = {}
next_crit_forced = false
```

- [ ] **Step 3: Connect turn_ended signal in `_ready()`**

Add after existing connects:
```gdscript
EventBus.turn_ended.connect(_tick_skill_cooldowns)
```

- [ ] **Step 4: Add `_tick_skill_cooldowns()` method**

Add after `_recompute_skill_bonuses()`:
```gdscript
func _tick_skill_cooldowns() -> void:
    var changed := false
    for skill_id in skill_cooldowns.keys():
        if skill_cooldowns[skill_id] > 0:
            skill_cooldowns[skill_id] -= 1
            changed = true
    if changed:
        EventBus.emit_signal("skills_changed")
```

- [ ] **Step 5: Add `get_skill_cooldown()` helper**
```gdscript
func get_skill_cooldown(skill_id: String) -> int:
    return int(skill_cooldowns.get(skill_id, 0))
```

- [ ] **Step 6: Add `activate_skill()` method**

Add after `get_skill_cooldown()`:
```gdscript
func activate_skill(skill_id: String, board_logic: BoardLogic) -> bool:
    if get_skill_cooldown(skill_id) > 0:
        return false
    var skill_data: Dictionary = {}
    for s in active_skills:
        if str(s.get("id", "")) == skill_id:
            skill_data = s
            break
    if skill_data.is_empty():
        return false
    var effect_id := str(skill_data.get("effect_id", ""))
    if effect_id == "":
        return false
    var script = SkillCatalogScript.get_effect_script(effect_id)
    if script == null:
        return false
    var effect: SkillEffect = script.new()
    var result: Dictionary = effect.apply(self, board_logic)
    # Process non-board results
    if result.get("gold_gained", 0) > 0:
        add_gold(int(result["gold_gained"]))
    if result.get("healed", 0) > 0:
        heal(int(result["healed"]))
    if bool(result.get("next_crit_set", false)):
        next_crit_forced = true
    # Board tile clearing — handled by Battle via signal
    var tiles_cleared: Array = result.get("tiles_cleared", [])
    if tiles_cleared.size() > 0:
        EventBus.emit_signal("tiles_skill_cleared", tiles_cleared)
    # Set cooldown
    var level: int = maxi(1, int(skill_data.get("level", 1)))
    var base_cd: int = int(skill_data.get("cooldown_base", 0))
    var reduction: int = int(skill_data.get("cooldown_reduction_per_level", 1))
    var final_cd: int = maxi(1, base_cd - (level - 1) * reduction)
    skill_cooldowns[skill_id] = final_cd
    EventBus.emit_signal("skills_changed")
    return true
```

- [ ] **Step 7: Initialize cooldown to 0 when skill is first picked**

In `_apply_skill_pick()`, after `active_skills.append(skill)`:
```gdscript
    skill_cooldowns[skill_id] = 0
```

- [ ] **Step 8: Verify — run game, level up, pick an active skill, check no errors**

- [ ] **Step 9: Commit**
```bash
git add scripts/core/RunState.gd
git commit -m "feat: add skill cooldown tracking and activate_skill() to RunState"
```

---

## Task 6: Update ChainResolver for next_crit_forced

**Files:**
- Modify: `scripts/battle/ChainResolver.gd`

- [ ] **Step 1: Check and consume `next_crit_forced` in `resolve()`**

In `resolve()`, after the existing crit roll (line ~56), add:
```gdscript
    # Forced crit from active skill
    if not result.crit and "next_crit_forced" in run and bool(run.next_crit_forced):
        result.crit = true
        run.next_crit_forced = false
```

- [ ] **Step 2: Commit**
```bash
git add scripts/battle/ChainResolver.gd
git commit -m "feat: ChainResolver respects next_crit_forced flag from RunState"
```

---

## Task 7: Update Battle.gd for tiles_skill_cleared

**Files:**
- Modify: `scripts/battle/Battle.gd`

- [ ] **Step 1: Connect signal in `_ready()`**

After `EventBus.chain_resolved.connect(...)`:
```gdscript
EventBus.tiles_skill_cleared.connect(_on_tiles_skill_cleared)
EventBus.skill_tapped.connect(_on_skill_tapped)
```

- [ ] **Step 2: Add handlers**

Add after `_on_player_damaged`:
```gdscript
func _on_skill_tapped(skill_id: String) -> void:
    if board == null or board.is_animating:
        return
    RunState.activate_skill(skill_id, board.logic)

func _on_tiles_skill_cleared(positions: Array) -> void:
    if board == null or positions.is_empty():
        return
    await board.consume_and_refill(positions)
    board.sync_view()
```

- [ ] **Step 3: Verify — run game, tap active skill, tiles clear and refill**

- [ ] **Step 4: Commit**
```bash
git add scripts/battle/Battle.gd
git commit -m "feat: Battle handles skill_tapped and tiles_skill_cleared for board effects"
```

---

## Task 8: Update HUD — Tappable Cards + Cooldown Display

**Files:**
- Modify: `scripts/ui/HUD.gd`

- [ ] **Step 1: Replace `_make_skill_card()` with active/passive-aware version**

Replace the entire `_make_skill_card()` method:
```gdscript
func _make_skill_card(skill: Dictionary) -> Control:
    var skill_id := str(skill.get("id", ""))
    var is_active := str(skill.get("skill_kind", "passive")) == "active"
    var cooldown: int = RunState.get_skill_cooldown(skill_id)
    var is_ready := cooldown <= 0

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(112, 88)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.10, 0.10, 0.18, 0.94)
    var border_col: Color = skill.get("color", Color(0.55, 0.40, 0.95, 1.0))
    if is_active and not is_ready:
        border_col = border_col.darkened(0.55)
        style.bg_color = Color(0.08, 0.08, 0.14, 0.94)
    style.border_color = border_col
    style.border_width_left = 3
    style.border_width_top = 3
    style.border_width_right = 3
    style.border_width_bottom = 3
    style.corner_radius_top_left = 12
    style.corner_radius_top_right = 12
    style.corner_radius_bottom_left = 12
    style.corner_radius_bottom_right = 12
    panel.add_theme_stylebox_override("panel", style)

    var box := VBoxContainer.new()
    box.offset_left = 8
    box.offset_top = 6
    box.offset_right = 104
    box.offset_bottom = 82
    panel.add_child(box)

    var icon := Label.new()
    icon.text = Localization.skill_icon_text(skill_id, str(skill.get("icon_text", "SKILL")))
    icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    icon.add_theme_font_size_override("font_size", 16)
    icon.add_theme_color_override("font_color", border_col)
    box.add_child(icon)

    var title := Label.new()
    title.text = Localization.skill_short_name(skill_id, str(skill.get("short_title", skill.get("title", "Skill"))))
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 18)
    title.add_theme_color_override("font_color", Color(0.95, 0.94, 1.0))
    box.add_child(title)

    var bottom_label := Label.new()
    if is_active:
        if is_ready:
            bottom_label.text = Localization.t("hud.skill.ready", [])
            bottom_label.add_theme_color_override("font_color", Color(0.52, 1.0, 0.62))
        else:
            bottom_label.text = Localization.t("hud.skill.cooldown", [cooldown])
            bottom_label.add_theme_color_override("font_color", Color(0.70, 0.68, 0.82))
    else:
        bottom_label.text = Localization.t("hud.level", [int(skill.get("level", 1))])
        bottom_label.add_theme_color_override("font_color", Color(0.88, 0.82, 1.0))
    bottom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    bottom_label.add_theme_font_size_override("font_size", 18)
    box.add_spacer(false)
    box.add_child(bottom_label)

    if is_active and is_ready:
        panel.mouse_filter = Control.MOUSE_FILTER_STOP
        var btn := Button.new()
        btn.flat = true
        btn.set_anchors_preset(Control.PRESET_FULL_RECT)
        btn.mouse_filter = Control.MOUSE_FILTER_STOP
        btn.pressed.connect(func():
            EventBus.emit_signal("skill_tapped", skill_id)
        )
        panel.add_child(btn)

    return panel
```

- [ ] **Step 2: Add localization keys for hud.skill.ready and hud.skill.cooldown**

In `scripts/core/Localization.gd`, find the EN string table and add:
```gdscript
"hud.skill.ready": "READY",
"hud.skill.cooldown": "%d",  # shows turns remaining
```
Find the RU string table and add:
```gdscript
"hud.skill.ready": "ГОТОВО",
"hud.skill.cooldown": "%d",
```

- [ ] **Step 3: Verify — run game, pick active skill, see READY label, tap it, see cooldown counting down**

Expected: active skill shows "ГОТОВО" / "READY" when available, tapping triggers effect and shows turn countdown. Cooldown decrements each turn. Passive skills show level number as before.

- [ ] **Step 4: Commit**
```bash
git add scripts/ui/HUD.gd scripts/core/Localization.gd
git commit -m "feat: HUD skill cards — tappable active skills with READY/cooldown display"
```

---

## Task 9: Balance Pass and Skill Pool Update

**Files:**
- Modify: `scripts/data/SkillCatalog.gd`

- [ ] **Step 1: Add active skills to default pool**

In `get_default_pool_ids()`, the current implementation returns the first 8 alphabetically sorted skills. With 6 new active skills, the pool now has 16 total. The default 8 will include a mix. Verify that at least 2-3 active skills appear in the default pool by checking alphabetical order:

Active skills added: `full_heal`, `gold_sweep`, `predator`, `row_sweep`, `stasis`, `wrath`
These will be mixed with passives: `arc_star`, `blood_well`, `bone_crown`, `coin_furnace`, `frost_sigils`, `grave_tempo`, `moon_ward`, `thorn_mail`, `venom_burst`, `violet_blade`

Alphabetical first 8: `arc_star`, `blood_well`, `bone_crown`, `coin_furnace`, `frost_sigils`, `full_heal`, `gold_sweep`, `grave_tempo` — so `full_heal` and `gold_sweep` are in default pool. Good enough for testing.

No code change needed unless you want to curate the default pool. If curation needed:
```gdscript
static func get_default_pool_ids() -> Array:
    # Curated default: 5 passives + 3 actives
    return [
        "arc_star", "blood_well", "coin_furnace", "frost_sigils", "thorn_mail",
        "gold_sweep", "predator", "stasis",
    ]
```

- [ ] **Step 2: Review cooldown balance**

Cooldown values (base turns at level 1, reduced by 1 per level):
- `gold_sweep`: 6 turns — collect all gold: strong but gold is usually spread out
- `wrath`: 8 turns — AoE damage at sword_power: useful vs packs
- `row_sweep`: 7 turns — 12 tiles swept: high value, decent cooldown
- `full_heal`: 12 turns — full restore: emergency button, long cooldown correct
- `stasis`: 9 turns — reset timers: panic button, 9 is reasonable
- `predator`: 5 turns — next crit: low impact, low cooldown correct

At level 5 (max), all cooldowns reduced by 4:
- `gold_sweep`: 2 turns — very fast, gold skill, acceptable
- `wrath`: 4 turns — AoE every 4 turns: strong but by level 5 enemies are tough
- `full_heal`: 8 turns — full heal every 8: still meaningful
- `predator`: 1 turn — guaranteed crit every turn at max: maybe too strong; consider raising base to 7

Adjust `predator.cooldown_base` to 7 for final balance.

- [ ] **Step 3: Push all to main**
```bash
git add -A
git commit -m "balance: adjust predator cooldown_base to 7"
git push origin main
```

---

## Self-Review

**Spec coverage:**
- [x] 4 skill slots — RunState already enforces 4 max
- [x] Active skills: tap-to-use → EventBus.skill_tapped → Battle._on_skill_tapped → RunState.activate_skill
- [x] Cooldown in turns, depends on skill level — activate_skill computes final_cd
- [x] Passive skills still work — level_bonus() returns empty dict for active, passive path unchanged
- [x] Both types occupy a slot — _apply_skill_pick() handles both kinds identically
- [x] "Collect all gold" — EffectCollectGold
- [x] "Damage all monsters" — EffectDamageAll
- [x] "Use 2 rows" — EffectSweepRows (bottom 2)
- [x] "Full heal" — EffectFullHeal
- [x] "Reset enemy timers to max" — EffectResetTimers
- [x] "Next hit guaranteed crit" — EffectNextCrit + ChainResolver check
- [x] Passive: increase attack — existing `violet_blade`, `bone_crown` unchanged
- [x] Reusable in weapons — EFFECT_SCRIPTS dict and SkillEffect base class are standalone, weapon catalog can reference same effect_id strings
- [x] Skills not showing in HUD — `_make_skill_card()` fully rewritten, shows all 4 slots with correct data

**Placeholder scan:** No TBD or TODO left. All code blocks complete.

**Type consistency:**
- `SkillEffect.apply()` returns `Dictionary` — all effect files return Dictionary
- `RunState.activate_skill()` calls `script.new()` returns `SkillEffect` — correct, subclasses extend SkillEffect
- `skill_cooldowns` is `Dictionary` (skill_id String → int) — consistent in tick, get, set
- `BoardLogic` type used in `apply(run: Node, board_logic: BoardLogic)` — Board.logic is `BoardLogic` type, passed from Battle
- `tiles_cleared` is `Array` of `Vector2` — EffectCollectGold/SweepRows/DamageAll all use `positions.append(p)` where p is Vector2
