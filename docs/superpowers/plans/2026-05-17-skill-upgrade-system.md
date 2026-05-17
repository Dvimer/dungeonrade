# Skill Upgrade System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add per-skill meta-upgrade levels bought with skulls in the Crypt; each upgrade tier improves specific skill parameters (cooldown, sweep count, crit multiplier, bonuses).

**Architecture:** `GameState.skill_levels` persists meta-levels. `SkillCatalog.compute_at_level()` bakes upgrade deltas into a skill dict at run-start. `EffectScript.apply()` receives the full skill dict so effects can read computed params. `Main.gd` Crypt Skills tab gains upgrade buttons. Multi-sweep (sweep_count > 1) is driven by Battle after each board refill.

**Tech Stack:** GDScript 4, Godot 4, autoloads: GameState, RunState, EventBus, Localization, SaveSystem

---

## Files

| File | Change |
|---|---|
| `scripts/core/GameState.gd` | Add `skill_levels` dict + persist |
| `scripts/data/SkillCatalog.gd` | Add `compute_at_level()`, `upgrade_cost()`, upgrade arrays for all 16 skills |
| `scripts/data/SkillType.gd` | Add `animation_id` field (placeholder) |
| `scripts/data/SkillEffect.gd` | Add `skill` param to `apply()` |
| `scripts/data/effects/EffectCollectGold.gd` | Accept `skill` param |
| `scripts/data/effects/EffectDamageAll.gd` | Accept `skill` param |
| `scripts/data/effects/EffectSweepRows.gd` | Accept `skill` param |
| `scripts/data/effects/EffectFullHeal.gd` | Accept `skill` param |
| `scripts/data/effects/EffectResetTimers.gd` | Accept `skill` param; use `freeze_turns` |
| `scripts/data/effects/EffectNextCrit.gd` | Accept `skill` param; write `next_crit_forced_mult` |
| `scripts/core/RunState.gd` | Wire `compute_at_level` in `_apply_skill_pick`; pass skill to effect; add `next_crit_forced_mult`, `pending_skill_sweeps`, `_pending_sweep_skill_id`, `do_pending_sweep()` |
| `scripts/battle/ChainResolver.gd` | Use `run.next_crit_forced_mult` for crit damage |
| `scripts/battle/Battle.gd` | Handle pending sweeps after board refill |
| `scripts/core/Localization.gd` | Add upgrade desc keys (EN + RU) |
| `scripts/Main.gd` | Upgrade UI in `_build_crypt_skills_tab()` |

---

### Task 1: GameState — add skill_levels

**Files:**
- Modify: `scripts/core/GameState.gd`

- [ ] **Step 1: Add skill_levels field and persist it**

In `scripts/core/GameState.gd`, after line `var unlocked_skill_ids: Array = []`, add:

```gdscript
var skill_levels: Dictionary = {}   # skill_id -> int (1 = base, 2-5 = upgraded)
```

In `to_dict()`, after `"unlocked_skill_ids": unlocked_skill_ids,`, add:

```gdscript
		"skill_levels": skill_levels,
```

In `from_dict()`, after the `unlocked_skill_ids` block, add:

```gdscript
	if data.has("skill_levels") and data["skill_levels"] is Dictionary:
		skill_levels = data["skill_levels"].duplicate()
```

- [ ] **Step 2: Commit**

```bash
git add scripts/core/GameState.gd
git commit -m "feat: add skill_levels to GameState meta-save"
```

---

### Task 2: SkillCatalog — compute_at_level, upgrade_cost, upgrade data

**Files:**
- Modify: `scripts/data/SkillCatalog.gd`

- [ ] **Step 1: Add compute_at_level() and upgrade_cost() functions**

At the end of `scripts/data/SkillCatalog.gd`, after `describe_bonus_block()`, add:

```gdscript
# Returns a copy of base_def with all upgrade deltas for the given level applied.
# level 1 = base (no changes). level 2 applies upgrades[0], level 3 applies [0,1], etc.
static func compute_at_level(base_def: Dictionary, level: int) -> Dictionary:
	var result := base_def.duplicate(true)
	var upgrades: Array = base_def.get("upgrades", [])
	var tiers := mini(level - 1, upgrades.size())
	for i in range(tiers):
		var u: Dictionary = upgrades[i]
		if u.has("cooldown_delta"):
			result["cooldown_base"] = maxi(1, int(result.get("cooldown_base", 0)) + int(u["cooldown_delta"]))
		if u.has("sweep_count"):
			result["sweep_count"] = int(u["sweep_count"])
		if u.has("crit_damage_mult"):
			result["crit_damage_mult"] = float(u["crit_damage_mult"])
		if u.has("freeze_turns"):
			result["freeze_turns"] = int(u["freeze_turns"])
		if u.has("bonus_delta") and u["bonus_delta"] is Dictionary:
			var bonuses: Dictionary = result.get("bonuses", {}).duplicate()
			for k in u["bonus_delta"].keys():
				bonuses[str(k)] = float(bonuses.get(str(k), 0.0)) + float(u["bonus_delta"][k])
			result["bonuses"] = bonuses
	result["meta_level"] = level
	return result

# Cost in skulls to upgrade skill to target_level (target_level must be >= 2).
static func upgrade_cost(base_def: Dictionary, target_level: int) -> int:
	var base: int = int(base_def.get("upgrade_cost_base", 50))
	var step: int = int(base_def.get("upgrade_cost_step", 25))
	return base + (target_level - 2) * step
```

- [ ] **Step 2: Add upgrade data to active skills in DEFINITIONS**

Replace the 6 active skill entries in `DEFINITIONS` with these (keep all existing fields, only add the three new ones):

For `"gold_sweep"` — after `"max_level": 5,`, add:
```gdscript
		"upgrade_cost_base": 40,
		"upgrade_cost_step": 20,
		"upgrades": [
			{"desc_key": "upgrade.gold_sweep.1", "cooldown_delta": -1},
			{"desc_key": "upgrade.gold_sweep.2", "sweep_count": 2},
			{"desc_key": "upgrade.gold_sweep.3", "cooldown_delta": -1},
			{"desc_key": "upgrade.gold_sweep.4", "sweep_count": 3},
		],
```

For `"wrath"` — after `"max_level": 5,`, add:
```gdscript
		"upgrade_cost_base": 45,
		"upgrade_cost_step": 25,
		"upgrades": [
			{"desc_key": "upgrade.wrath.1", "cooldown_delta": -1},
			{"desc_key": "upgrade.wrath.2", "bonus_delta": {"sword_damage_bonus": 1}},
			{"desc_key": "upgrade.wrath.3", "cooldown_delta": -1},
			{"desc_key": "upgrade.wrath.4", "bonus_delta": {"sword_damage_bonus": 1}},
		],
```

For `"row_sweep"` — after `"max_level": 5,`, add:
```gdscript
		"upgrade_cost_base": 40,
		"upgrade_cost_step": 20,
		"upgrades": [
			{"desc_key": "upgrade.row_sweep.1", "cooldown_delta": -1},
			{"desc_key": "upgrade.row_sweep.2", "sweep_count": 2},
			{"desc_key": "upgrade.row_sweep.3", "cooldown_delta": -1},
			{"desc_key": "upgrade.row_sweep.4", "sweep_count": 3},
		],
```

For `"full_heal"` — after `"max_level": 5,`, add:
```gdscript
		"upgrade_cost_base": 50,
		"upgrade_cost_step": 25,
		"upgrades": [
			{"desc_key": "upgrade.full_heal.1", "cooldown_delta": -2},
			{"desc_key": "upgrade.full_heal.2", "bonus_delta": {"vampirism": 0.05}},
			{"desc_key": "upgrade.full_heal.3", "cooldown_delta": -2},
			{"desc_key": "upgrade.full_heal.4", "bonus_delta": {"vampirism": 0.05}},
		],
```

For `"stasis"` — after `"max_level": 5,`, add:
```gdscript
		"upgrade_cost_base": 40,
		"upgrade_cost_step": 20,
		"upgrades": [
			{"desc_key": "upgrade.stasis.1", "cooldown_delta": -1},
			{"desc_key": "upgrade.stasis.2", "freeze_turns": 2},
			{"desc_key": "upgrade.stasis.3", "cooldown_delta": -1},
			{"desc_key": "upgrade.stasis.4", "freeze_turns": 3},
		],
```

For `"predator"` — after `"max_level": 5,`, add:
```gdscript
		"upgrade_cost_base": 40,
		"upgrade_cost_step": 20,
		"upgrades": [
			{"desc_key": "upgrade.predator.1", "cooldown_delta": -1},
			{"desc_key": "upgrade.predator.2", "crit_damage_mult": 2.5},
			{"desc_key": "upgrade.predator.3", "cooldown_delta": -1},
			{"desc_key": "upgrade.predator.4", "crit_damage_mult": 3.0},
		],
```

- [ ] **Step 3: Add upgrade data to passive skills in DEFINITIONS**

For each passive skill, add after its existing closing brace (before the comma). Pattern: 4 upgrades, alternating between stat boost and another stat boost.

For `"bone_crown"`:
```gdscript
		"upgrade_cost_base": 30,
		"upgrade_cost_step": 15,
		"upgrades": [
			{"desc_key": "upgrade.bone_crown.1", "bonus_delta": {"sword_damage_bonus": 1}},
			{"desc_key": "upgrade.bone_crown.2", "bonus_delta": {"sword_damage_bonus": 1}},
			{"desc_key": "upgrade.bone_crown.3", "bonus_delta": {"sword_damage_bonus": 1}},
			{"desc_key": "upgrade.bone_crown.4", "bonus_delta": {"crit_chance": 0.05}},
		],
```

For `"arc_star"`:
```gdscript
		"upgrade_cost_base": 35,
		"upgrade_cost_step": 20,
		"upgrades": [
			{"desc_key": "upgrade.arc_star.1", "bonus_delta": {"crit_chance": 0.03}},
			{"desc_key": "upgrade.arc_star.2", "crit_damage_mult": 2.5},
			{"desc_key": "upgrade.arc_star.3", "bonus_delta": {"crit_chance": 0.04}},
			{"desc_key": "upgrade.arc_star.4", "crit_damage_mult": 3.0},
		],
```

For `"violet_blade"`:
```gdscript
		"upgrade_cost_base": 30,
		"upgrade_cost_step": 15,
		"upgrades": [
			{"desc_key": "upgrade.violet_blade.1", "bonus_delta": {"sword_damage_bonus": 1}},
			{"desc_key": "upgrade.violet_blade.2", "bonus_delta": {"sword_damage_bonus": 1}},
			{"desc_key": "upgrade.violet_blade.3", "bonus_delta": {"sword_damage_bonus": 1}},
			{"desc_key": "upgrade.violet_blade.4", "bonus_delta": {"crit_chance": 0.05}},
		],
```

For `"frost_sigils"`:
```gdscript
		"upgrade_cost_base": 35,
		"upgrade_cost_step": 20,
		"upgrades": [
			{"desc_key": "upgrade.frost_sigils.1", "bonus_delta": {"enemy_power_delta": -0.10}},
			{"desc_key": "upgrade.frost_sigils.2", "bonus_delta": {"crit_chance": 0.03}},
			{"desc_key": "upgrade.frost_sigils.3", "bonus_delta": {"enemy_power_delta": -0.10}},
			{"desc_key": "upgrade.frost_sigils.4", "bonus_delta": {"crit_chance": 0.05}},
		],
```

For `"coin_furnace"`:
```gdscript
		"upgrade_cost_base": 30,
		"upgrade_cost_step": 15,
		"upgrades": [
			{"desc_key": "upgrade.coin_furnace.1", "bonus_delta": {"shop_charge_bonus": 1}},
			{"desc_key": "upgrade.coin_furnace.2", "bonus_delta": {"crit_chance": 0.05}},
			{"desc_key": "upgrade.coin_furnace.3", "bonus_delta": {"shop_charge_bonus": 1}},
			{"desc_key": "upgrade.coin_furnace.4", "bonus_delta": {"shop_charge_bonus": 2}},
		],
```

For `"thorn_mail"`:
```gdscript
		"upgrade_cost_base": 30,
		"upgrade_cost_step": 15,
		"upgrades": [
			{"desc_key": "upgrade.thorn_mail.1", "bonus_delta": {"max_shield_bonus": 1}},
			{"desc_key": "upgrade.thorn_mail.2", "bonus_delta": {"crit_chance": 0.05}},
			{"desc_key": "upgrade.thorn_mail.3", "bonus_delta": {"max_shield_bonus": 1}},
			{"desc_key": "upgrade.thorn_mail.4", "bonus_delta": {"max_shield_bonus": 1}},
		],
```

For `"blood_well"`:
```gdscript
		"upgrade_cost_base": 35,
		"upgrade_cost_step": 20,
		"upgrades": [
			{"desc_key": "upgrade.blood_well.1", "bonus_delta": {"vampirism": 0.04}},
			{"desc_key": "upgrade.blood_well.2", "bonus_delta": {"crit_chance": 0.05}},
			{"desc_key": "upgrade.blood_well.3", "bonus_delta": {"vampirism": 0.04}},
			{"desc_key": "upgrade.blood_well.4", "bonus_delta": {"vampirism": 0.04}},
		],
```

For `"grave_tempo"`:
```gdscript
		"upgrade_cost_base": 30,
		"upgrade_cost_step": 15,
		"upgrades": [
			{"desc_key": "upgrade.grave_tempo.1", "bonus_delta": {"crit_chance": 0.03}},
			{"desc_key": "upgrade.grave_tempo.2", "bonus_delta": {"shop_charge_bonus": 1}},
			{"desc_key": "upgrade.grave_tempo.3", "bonus_delta": {"crit_chance": 0.03}},
			{"desc_key": "upgrade.grave_tempo.4", "bonus_delta": {"shop_charge_bonus": 1}},
		],
```

For `"moon_ward"`:
```gdscript
		"upgrade_cost_base": 30,
		"upgrade_cost_step": 15,
		"upgrades": [
			{"desc_key": "upgrade.moon_ward.1", "bonus_delta": {"max_shield_bonus": 1}},
			{"desc_key": "upgrade.moon_ward.2", "bonus_delta": {"max_shield_bonus": 1}},
			{"desc_key": "upgrade.moon_ward.3", "bonus_delta": {"max_shield_bonus": 1}},
			{"desc_key": "upgrade.moon_ward.4", "bonus_delta": {"crit_chance": 0.05}},
		],
```

For `"venom_burst"`:
```gdscript
		"upgrade_cost_base": 35,
		"upgrade_cost_step": 20,
		"upgrades": [
			{"desc_key": "upgrade.venom_burst.1", "bonus_delta": {"sword_damage_bonus": 1}},
			{"desc_key": "upgrade.venom_burst.2", "bonus_delta": {"crit_chance": 0.03}},
			{"desc_key": "upgrade.venom_burst.3", "bonus_delta": {"sword_damage_bonus": 1}},
			{"desc_key": "upgrade.venom_burst.4", "bonus_delta": {"crit_chance": 0.05}},
		],
```

- [ ] **Step 4: Commit**

```bash
git add scripts/data/SkillCatalog.gd
git commit -m "feat: add compute_at_level, upgrade_cost, and upgrade data to all 16 skills"
```

---

### Task 3: SkillEffect API — add skill param to all effects

**Files:**
- Modify: `scripts/data/SkillEffect.gd`
- Modify: `scripts/data/SkillType.gd`
- Modify: `scripts/data/effects/EffectCollectGold.gd`
- Modify: `scripts/data/effects/EffectDamageAll.gd`
- Modify: `scripts/data/effects/EffectSweepRows.gd`
- Modify: `scripts/data/effects/EffectFullHeal.gd`
- Modify: `scripts/data/effects/EffectResetTimers.gd`
- Modify: `scripts/data/effects/EffectNextCrit.gd`

- [ ] **Step 1: Update SkillEffect base class**

Replace the entire `scripts/data/SkillEffect.gd` with:

```gdscript
extends RefCounted
class_name SkillEffect

# Базовый класс для активных эффектов навыков.
# apply() возвращает словарь для Battle/RunState:
#   "tiles_cleared": Array[Vector2]  — позиции для consume_and_refill
#   "next_crit_set": bool            — флаг форсированного крита установлен
#   "damage_dealt": int              — суммарный урон
func apply(run: Node, board_logic: BoardLogic, skill: Dictionary) -> Dictionary:
	return {}
```

- [ ] **Step 2: Add animation_id to SkillType**

In `scripts/data/SkillType.gd`, after `var effect_id: String = ""`, add:

```gdscript
var animation_id: String = ""
```

In `_init()`, after `effect_id = str(data.get("effect_id", effect_id))`, add:

```gdscript
	animation_id = str(data.get("animation_id", animation_id))
```

In `to_dictionary()`, after `"effect_id": effect_id,`, add:

```gdscript
		"animation_id": animation_id,
```

- [ ] **Step 3: Update EffectCollectGold**

Replace `scripts/data/effects/EffectCollectGold.gd` with:

```gdscript
extends SkillEffect

func apply(run: Node, board_logic: BoardLogic, skill: Dictionary) -> Dictionary:
	var positions: Array = []
	var gold := 0
	for y in range(board_logic.height):
		for x in range(board_logic.width):
			var p := Vector2(x, y)
			var t: Dictionary = board_logic.get_tile(p)
			if t.kind == TileType.Kind.COIN:
				gold += 1
				positions.append(p)
	if gold > 0:
		run.add_gold(gold)
	return {"tiles_cleared": positions}
```

- [ ] **Step 4: Update EffectDamageAll**

Replace `scripts/data/effects/EffectDamageAll.gd` with:

```gdscript
extends SkillEffect

func apply(run: Node, board_logic: BoardLogic, skill: Dictionary) -> Dictionary:
	var dmg: int = run.sword_power()
	var total := 0
	var to_clear: Array = []
	for y in range(board_logic.height):
		for x in range(board_logic.width):
			var p := Vector2(x, y)
			var t: Dictionary = board_logic.get_tile(p)
			if t.kind == TileType.Kind.ENEMY:
				t.hp -= dmg
				total += dmg
				EventBus.emit_signal("enemy_damaged", p, dmg)
				if t.hp <= 0:
					EventBus.emit_signal("enemy_killed", p)
					to_clear.append(p)
	return {"tiles_cleared": to_clear, "damage_dealt": total}
```

- [ ] **Step 5: Update EffectSweepRows**

Replace `scripts/data/effects/EffectSweepRows.gd` with:

```gdscript
extends SkillEffect

# Собирает всё содержимое двух нижних рядов доски.
func apply(run: Node, board_logic: BoardLogic, skill: Dictionary) -> Dictionary:
	var positions: Array = []
	var gold := 0
	var healed := 0
	var shield_gained := 0
	var bottom: int = board_logic.height - 1
	for row in [bottom, bottom - 1]:
		if row < 0:
			continue
		for x in range(board_logic.width):
			var p := Vector2(x, row)
			var t: Dictionary = board_logic.get_tile(p)
			match t.kind:
				TileType.Kind.COIN:
					gold += 1
					positions.append(p)
				TileType.Kind.HEART:
					healed += 1
					positions.append(p)
				TileType.Kind.SHIELD:
					shield_gained += 1
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
	if gold > 0:
		run.add_gold(gold)
	if shield_gained > 0:
		run.add_shield(shield_gained)
	if healed > 0:
		run.heal(healed)
	return {"tiles_cleared": positions}
```

- [ ] **Step 6: Update EffectFullHeal**

Replace `scripts/data/effects/EffectFullHeal.gd` with:

```gdscript
extends SkillEffect

func apply(run: Node, board_logic: BoardLogic, skill: Dictionary) -> Dictionary:
	var amount: int = run.max_hp - run.hp
	if amount > 0:
		run.heal(amount)
	return {}
```

- [ ] **Step 7: Update EffectResetTimers — use freeze_turns from skill**

Replace `scripts/data/effects/EffectResetTimers.gd` with:

```gdscript
extends SkillEffect

# Сбрасывает таймеры всех врагов. freeze_turns > 1 устанавливает фиксированное
# значение вместо attack_cooldown (блокирует атаки на несколько ходов).
func apply(run: Node, board_logic: BoardLogic, skill: Dictionary) -> Dictionary:
	var freeze_turns: int = int(skill.get("freeze_turns", 0))
	for y in range(board_logic.height):
		for x in range(board_logic.width):
			var t: Dictionary = board_logic.get_tile(Vector2(x, y))
			if t.kind == TileType.Kind.ENEMY:
				if freeze_turns > 0:
					t["timer"] = freeze_turns
				else:
					t["timer"] = int(t.get("attack_cooldown", 3))
	return {}
```

- [ ] **Step 8: Update EffectNextCrit — write crit_damage_mult**

Replace `scripts/data/effects/EffectNextCrit.gd` with:

```gdscript
extends SkillEffect

func apply(run: Node, board_logic: BoardLogic, skill: Dictionary) -> Dictionary:
	run.next_crit_forced = true
	run.next_crit_forced_mult = float(skill.get("crit_damage_mult", 2.0))
	return {"next_crit_set": true}
```

- [ ] **Step 9: Commit**

```bash
git add scripts/data/SkillEffect.gd scripts/data/SkillType.gd scripts/data/effects/
git commit -m "feat: add skill param to EffectScript API; EffectNextCrit uses crit_damage_mult; EffectResetTimers uses freeze_turns"
```

---

### Task 4: RunState — wire compute_at_level + crit mult + pending sweeps

**Files:**
- Modify: `scripts/core/RunState.gd`

- [ ] **Step 1: Add new state variables**

After `var next_crit_forced: bool = false`, add:

```gdscript
var next_crit_forced_mult: float = 2.0
var pending_skill_sweeps: int = 0
var _pending_sweep_skill_id: String = ""
```

- [ ] **Step 2: Reset new variables in reset()**

After `next_crit_forced = false`, add:

```gdscript
	next_crit_forced_mult = 2.0
	pending_skill_sweeps = 0
	_pending_sweep_skill_id = ""
```

- [ ] **Step 3: Update _apply_skill_pick to use compute_at_level**

Find `_apply_skill_pick(skill_id: String)`. The block that adds a new skill currently reads:

```gdscript
	if active_skills.size() < 4:
		var skill := SkillCatalogScript.get_skill(skill_id)
		skill["level"] = 1
		active_skills.append(skill)
		skill_cooldowns[skill_id] = 0
```

Replace it with:

```gdscript
	if active_skills.size() < 4:
		var base_def: Dictionary = SkillCatalogScript.DEFINITIONS.get(skill_id, {})
		var meta_level: int = int(GameState.skill_levels.get(skill_id, 1))
		var computed := SkillCatalogScript.compute_at_level(base_def, meta_level)
		var skill := SkillCatalogScript.localize_skill(SkillTypeScript.new(computed).to_dictionary())
		skill["level"] = 1
		# Preserve bonuses from compute_at_level (they include meta-upgrade deltas)
		if computed.has("bonuses"):
			skill["bonuses"] = computed["bonuses"].duplicate()
		if computed.has("sweep_count"):
			skill["sweep_count"] = computed["sweep_count"]
		if computed.has("crit_damage_mult"):
			skill["crit_damage_mult"] = computed["crit_damage_mult"]
		if computed.has("freeze_turns"):
			skill["freeze_turns"] = computed["freeze_turns"]
		active_skills.append(skill)
		skill_cooldowns[skill_id] = 0
```

Note: `SkillTypeScript` is already preloaded in RunState as `preload("res://scripts/data/SkillType.gd")`. Verify the variable name is `SkillTypeScript` — if not, use the correct preload variable name from the top of RunState.gd.

- [ ] **Step 4: Update activate_skill to pass skill dict to effect.apply()**

Find this line in `activate_skill()`:

```gdscript
	var result: Dictionary = effect.apply(self, board_logic)
```

Replace with:

```gdscript
	var result: Dictionary = effect.apply(self, board_logic, skill_data)
	var sweep_count := int(skill_data.get("sweep_count", 1))
	if sweep_count > 1 and not result.get("tiles_cleared", []).is_empty():
		pending_skill_sweeps = sweep_count - 1
		_pending_sweep_skill_id = skill_id
```

- [ ] **Step 5: Add do_pending_sweep() function**

After `activate_skill()`, add:

```gdscript
# Called by Battle after each board refill when pending_skill_sweeps > 0.
# Returns positions to clear (already applies side effects like add_gold).
func do_pending_sweep(board_logic: BoardLogic) -> Array:
	if _pending_sweep_skill_id == "":
		return []
	var skill_data: Dictionary = {}
	for s in active_skills:
		if str(s.get("id", "")) == _pending_sweep_skill_id:
			skill_data = s
			break
	if skill_data.is_empty():
		_pending_sweep_skill_id = ""
		return []
	var effect_id := str(skill_data.get("effect_id", ""))
	var script = SkillCatalogScript.get_effect_script(effect_id)
	if script == null:
		return []
	var effect: SkillEffect = script.new()
	var result: Dictionary = effect.apply(self, board_logic, skill_data)
	return result.get("tiles_cleared", [])
```

- [ ] **Step 6: Commit**

```bash
git add scripts/core/RunState.gd
git commit -m "feat: RunState wires compute_at_level, crit_damage_mult, pending_skill_sweeps"
```

---

### Task 5: ChainResolver — use next_crit_forced_mult

**Files:**
- Modify: `scripts/battle/ChainResolver.gd`

- [ ] **Step 1: Use configurable crit multiplier**

In `ChainResolver.resolve()`, find the forced-crit block and damage calculation:

```gdscript
	# Форсированный крит от активного навыка
	if not result.crit and "next_crit_forced" in run and bool(run.next_crit_forced):
		result.crit = true
		run.next_crit_forced = false
```

Replace with:

```gdscript
	# Форсированный крит от активного навыка
	var _forced_crit := false
	if not result.crit and "next_crit_forced" in run and bool(run.next_crit_forced):
		result.crit = true
		_forced_crit = true
		run.next_crit_forced = false
```

Then find:

```gdscript
		if result.crit:
			dmg = int(round(dmg * 2.0))
```

Replace with:

```gdscript
		if result.crit:
			var crit_mult := 2.0
			if _forced_crit and "next_crit_forced_mult" in run:
				crit_mult = float(run.next_crit_forced_mult)
				run.next_crit_forced_mult = 2.0
			dmg = int(round(dmg * crit_mult))
```

- [ ] **Step 2: Commit**

```bash
git add scripts/battle/ChainResolver.gd
git commit -m "feat: ChainResolver uses configurable crit multiplier from predator skill"
```

---

### Task 6: Battle — multi-sweep after board refill

**Files:**
- Modify: `scripts/battle/Battle.gd`

- [ ] **Step 1: Update _on_tiles_skill_cleared to drive pending sweeps**

Find `_on_tiles_skill_cleared` in `scripts/battle/Battle.gd`:

```gdscript
func _on_tiles_skill_cleared(positions: Array) -> void:
	if board == null or positions.is_empty():
		return
	await board.consume_and_refill(positions)
	board.sync_view()
```

Replace with:

```gdscript
func _on_tiles_skill_cleared(positions: Array) -> void:
	if board == null or positions.is_empty():
		return
	await board.consume_and_refill(positions)
	board.sync_view()
	while RunState.pending_skill_sweeps > 0 and board != null and not board.is_animating:
		RunState.pending_skill_sweeps -= 1
		var next_positions := RunState.do_pending_sweep(board.logic)
		if next_positions.is_empty():
			RunState.pending_skill_sweeps = 0
			break
		await board.consume_and_refill(next_positions)
		board.sync_view()
```

- [ ] **Step 2: Commit**

```bash
git add scripts/battle/Battle.gd
git commit -m "feat: Battle drives multi-sweep after board refill"
```

---

### Task 7: Localization — upgrade description keys

**Files:**
- Modify: `scripts/core/Localization.gd`

- [ ] **Step 1: Add English upgrade keys**

In the `"en"` dictionary, find the end of the existing keys and add (follow the existing key format in the file):

```gdscript
			"upgrade.gold_sweep.1": "Cooldown -1",
			"upgrade.gold_sweep.2": "Collect twice",
			"upgrade.gold_sweep.3": "Cooldown -1",
			"upgrade.gold_sweep.4": "Collect 3 times",
			"upgrade.wrath.1": "Cooldown -1",
			"upgrade.wrath.2": "+1 Sword damage",
			"upgrade.wrath.3": "Cooldown -1",
			"upgrade.wrath.4": "+1 Sword damage",
			"upgrade.row_sweep.1": "Cooldown -1",
			"upgrade.row_sweep.2": "Sweep twice",
			"upgrade.row_sweep.3": "Cooldown -1",
			"upgrade.row_sweep.4": "Sweep 3 times",
			"upgrade.full_heal.1": "Cooldown -2",
			"upgrade.full_heal.2": "+5% Vampirism",
			"upgrade.full_heal.3": "Cooldown -2",
			"upgrade.full_heal.4": "+5% Vampirism",
			"upgrade.stasis.1": "Cooldown -1",
			"upgrade.stasis.2": "Freeze 2 turns",
			"upgrade.stasis.3": "Cooldown -1",
			"upgrade.stasis.4": "Freeze 3 turns",
			"upgrade.predator.1": "Cooldown -1",
			"upgrade.predator.2": "Crit x2.5",
			"upgrade.predator.3": "Cooldown -1",
			"upgrade.predator.4": "Crit x3.0",
			"upgrade.bone_crown.1": "+1 Sword",
			"upgrade.bone_crown.2": "+1 Sword",
			"upgrade.bone_crown.3": "+1 Sword",
			"upgrade.bone_crown.4": "+5% Crit",
			"upgrade.arc_star.1": "+3% Crit",
			"upgrade.arc_star.2": "Crit x2.5",
			"upgrade.arc_star.3": "+4% Crit",
			"upgrade.arc_star.4": "Crit x3.0",
			"upgrade.violet_blade.1": "+1 Sword",
			"upgrade.violet_blade.2": "+1 Sword",
			"upgrade.violet_blade.3": "+1 Sword",
			"upgrade.violet_blade.4": "+5% Crit",
			"upgrade.frost_sigils.1": "Enemy power -10%",
			"upgrade.frost_sigils.2": "+3% Crit",
			"upgrade.frost_sigils.3": "Enemy power -10%",
			"upgrade.frost_sigils.4": "+5% Crit",
			"upgrade.coin_furnace.1": "+1 Shop charge",
			"upgrade.coin_furnace.2": "+5% Crit",
			"upgrade.coin_furnace.3": "+1 Shop charge",
			"upgrade.coin_furnace.4": "+2 Shop charge",
			"upgrade.thorn_mail.1": "+1 Max shield",
			"upgrade.thorn_mail.2": "+5% Crit",
			"upgrade.thorn_mail.3": "+1 Max shield",
			"upgrade.thorn_mail.4": "+1 Max shield",
			"upgrade.blood_well.1": "+4% Vampirism",
			"upgrade.blood_well.2": "+5% Crit",
			"upgrade.blood_well.3": "+4% Vampirism",
			"upgrade.blood_well.4": "+4% Vampirism",
			"upgrade.grave_tempo.1": "+3% Crit",
			"upgrade.grave_tempo.2": "+1 Shop charge",
			"upgrade.grave_tempo.3": "+3% Crit",
			"upgrade.grave_tempo.4": "+1 Shop charge",
			"upgrade.moon_ward.1": "+1 Max shield",
			"upgrade.moon_ward.2": "+1 Max shield",
			"upgrade.moon_ward.3": "+1 Max shield",
			"upgrade.moon_ward.4": "+5% Crit",
			"upgrade.venom_burst.1": "+1 Sword",
			"upgrade.venom_burst.2": "+3% Crit",
			"upgrade.venom_burst.3": "+1 Sword",
			"upgrade.venom_burst.4": "+5% Crit",
```

- [ ] **Step 2: Add Russian upgrade keys**

In the `"ru"` dictionary, add the same keys with Russian text:

```gdscript
			"upgrade.gold_sweep.1": "Кулдаун -1",
			"upgrade.gold_sweep.2": "Собрать дважды",
			"upgrade.gold_sweep.3": "Кулдаун -1",
			"upgrade.gold_sweep.4": "Собрать трижды",
			"upgrade.wrath.1": "Кулдаун -1",
			"upgrade.wrath.2": "+1 Урон меча",
			"upgrade.wrath.3": "Кулдаун -1",
			"upgrade.wrath.4": "+1 Урон меча",
			"upgrade.row_sweep.1": "Кулдаун -1",
			"upgrade.row_sweep.2": "Смести дважды",
			"upgrade.row_sweep.3": "Кулдаун -1",
			"upgrade.row_sweep.4": "Смести трижды",
			"upgrade.full_heal.1": "Кулдаун -2",
			"upgrade.full_heal.2": "+5% Вампиризм",
			"upgrade.full_heal.3": "Кулдаун -2",
			"upgrade.full_heal.4": "+5% Вампиризм",
			"upgrade.stasis.1": "Кулдаун -1",
			"upgrade.stasis.2": "Заморозить 2 хода",
			"upgrade.stasis.3": "Кулдаун -1",
			"upgrade.stasis.4": "Заморозить 3 хода",
			"upgrade.predator.1": "Кулдаун -1",
			"upgrade.predator.2": "Крит x2.5",
			"upgrade.predator.3": "Кулдаун -1",
			"upgrade.predator.4": "Крит x3.0",
			"upgrade.bone_crown.1": "+1 Меч",
			"upgrade.bone_crown.2": "+1 Меч",
			"upgrade.bone_crown.3": "+1 Меч",
			"upgrade.bone_crown.4": "+5% Крит",
			"upgrade.arc_star.1": "+3% Крит",
			"upgrade.arc_star.2": "Крит x2.5",
			"upgrade.arc_star.3": "+4% Крит",
			"upgrade.arc_star.4": "Крит x3.0",
			"upgrade.violet_blade.1": "+1 Меч",
			"upgrade.violet_blade.2": "+1 Меч",
			"upgrade.violet_blade.3": "+1 Меч",
			"upgrade.violet_blade.4": "+5% Крит",
			"upgrade.frost_sigils.1": "Сила врагов -10%",
			"upgrade.frost_sigils.2": "+3% Крит",
			"upgrade.frost_sigils.3": "Сила врагов -10%",
			"upgrade.frost_sigils.4": "+5% Крит",
			"upgrade.coin_furnace.1": "+1 Заряд магазина",
			"upgrade.coin_furnace.2": "+5% Крит",
			"upgrade.coin_furnace.3": "+1 Заряд магазина",
			"upgrade.coin_furnace.4": "+2 Заряд магазина",
			"upgrade.thorn_mail.1": "+1 Макс щит",
			"upgrade.thorn_mail.2": "+5% Крит",
			"upgrade.thorn_mail.3": "+1 Макс щит",
			"upgrade.thorn_mail.4": "+1 Макс щит",
			"upgrade.blood_well.1": "+4% Вампиризм",
			"upgrade.blood_well.2": "+5% Крит",
			"upgrade.blood_well.3": "+4% Вампиризм",
			"upgrade.blood_well.4": "+4% Вампиризм",
			"upgrade.grave_tempo.1": "+3% Крит",
			"upgrade.grave_tempo.2": "+1 Заряд магазина",
			"upgrade.grave_tempo.3": "+3% Крит",
			"upgrade.grave_tempo.4": "+1 Заряд магазина",
			"upgrade.moon_ward.1": "+1 Макс щит",
			"upgrade.moon_ward.2": "+1 Макс щит",
			"upgrade.moon_ward.3": "+1 Макс щит",
			"upgrade.moon_ward.4": "+5% Крит",
			"upgrade.venom_burst.1": "+1 Меч",
			"upgrade.venom_burst.2": "+3% Крит",
			"upgrade.venom_burst.3": "+1 Меч",
			"upgrade.venom_burst.4": "+5% Крит",
```

- [ ] **Step 3: Commit**

```bash
git add scripts/core/Localization.gd
git commit -m "feat: add upgrade description localization keys (EN + RU) for all 16 skills"
```

---

### Task 8: Main.gd — Crypt upgrade UI

**Files:**
- Modify: `scripts/Main.gd`

Context: The Skills tab is built by `_build_crypt_skills_tab()` (around line 1213). Each skill card is made by `_make_crypt_skill_card()` (around line 1229). Skull balance is stored in `GameState.skulls`. The `_crypt_skulls_label` is updated on unlock.

- [ ] **Step 1: Update _make_crypt_skill_card to show level and upgrade button**

Find `func _make_crypt_skill_card(skill: Dictionary) -> Button:` and replace the entire function with:

```gdscript
func _make_crypt_skill_card(skill: Dictionary) -> Control:
	var skill_id := str(skill.get("id", ""))
	const SKILL_COST := 20
	var in_pool := GameState.skill_pool_ids.has(skill_id)
	var title := Localization.skill_name(skill_id, str(skill.get("title", skill_id)))
	var icon := str(skill.get("icon_text", "*"))
	var desc := Localization.skill_description(skill_id, str(skill.get("description", "")))
	var color: Color = skill.get("color", Color(0.7, 0.7, 0.7, 1.0))

	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 4)

	# Unlock / in-pool button
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 52)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", color)
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if in_pool:
		var meta_level := int(GameState.skill_levels.get(skill_id, 1))
		btn.text = "%s  %s\n[Pool — Lv %d / %d]" % [icon, title, meta_level, int(skill.get("max_level", 5))]
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
	panel.add_child(btn)

	# Upgrade button (only for skills already in pool)
	if in_pool:
		var meta_level := int(GameState.skill_levels.get(skill_id, 1))
		var max_level := int(skill.get("max_level", 5))
		var upgrades: Array = SkillCatalogScript.DEFINITIONS.get(skill_id, {}).get("upgrades", [])
		if meta_level < max_level and upgrades.size() >= meta_level:
			var next_upgrade: Dictionary = upgrades[meta_level - 1]
			var next_desc := Localization.t(str(next_upgrade.get("desc_key", "")), [])
			var cost := SkillCatalogScript.upgrade_cost(SkillCatalogScript.DEFINITIONS.get(skill_id, {}), meta_level + 1)
			var upgrade_btn := Button.new()
			upgrade_btn.custom_minimum_size = Vector2(0, 32)
			upgrade_btn.add_theme_font_size_override("font_size", 12)
			if GameState.skulls >= cost:
				upgrade_btn.text = "Upgrade: %s  (%d 💀)" % [next_desc, cost]
				upgrade_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
				upgrade_btn.pressed.connect(_upgrade_skill.bind(skill_id, cost))
			else:
				upgrade_btn.text = "Upgrade: %s  (%d 💀 needed)" % [next_desc, cost]
				upgrade_btn.disabled = true
				upgrade_btn.modulate = Color(0.55, 0.55, 0.55, 1.0)
			panel.add_child(upgrade_btn)

	return panel
```

Note: `SkillCatalogScript` is already declared as a const at the top of `Main.gd` — verify the exact variable name used there.

- [ ] **Step 2: Add _upgrade_skill() function**

After `_unlock_skill()`, add:

```gdscript
func _upgrade_skill(skill_id: String, cost: int) -> void:
	if GameState.skulls < cost:
		return
	var base_def: Dictionary = SkillCatalogScript.DEFINITIONS.get(skill_id, {})
	var max_level := int(base_def.get("max_level", 5))
	var current_level := int(GameState.skill_levels.get(skill_id, 1))
	if current_level >= max_level:
		return
	GameState.skulls -= cost
	GameState.skill_levels[skill_id] = current_level + 1
	SaveSystem.save()
	_crypt_skulls_label.text = "Skulls: %d" % GameState.skulls
	_crypt_switch_tab("skills")
```

- [ ] **Step 3: Update _build_crypt_skills_tab grid to use VBoxContainer cards**

In `_build_crypt_skills_tab()`, find where the grid is created:

```gdscript
	var grid := GridContainer.new()
	grid.columns = 2
```

The grid adds `_make_crypt_skill_card(skill)` children. Currently it expects a `Button`. Now `_make_crypt_skill_card` returns a `Control` (VBoxContainer). The grid still works — no changes needed here. Just verify the grid add_child call still works (it adds any Control).

- [ ] **Step 4: Commit**

```bash
git add scripts/Main.gd
git commit -m "feat: Crypt Skills tab shows upgrade button with next tier desc and skull cost"
```

---

## Manual Test Checklist

After all tasks complete, verify:

1. Open Crypt → Skills tab → unlocked skill shows `[Pool — Lv 1 / 5]`
2. If you have enough skulls, upgrade button shows next tier description + cost
3. Click upgrade → Lv counter increments, skulls deducted, saved
4. At max level (5), no upgrade button shown
5. Start a run → pick arc_star → crit_chance reflects meta-level bonus
6. Use Predator active at Lv 1 meta → crit deals ×2.0; at Lv 3 meta → ×2.5
7. Use Gold Sweep at Lv 1 meta → single collect; at Lv 3 meta → collects, board refills, collects again
8. Use Stasis at Lv 3 meta → enemy timers set to 2, not attack_cooldown
9. Save and reload → skill_levels persists correctly
