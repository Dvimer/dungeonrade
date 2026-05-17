# Design: Skill Upgrade System

**Date:** 2026-05-17

## Goal

Allow players to upgrade skills in the Crypt using `skulls` (existing meta-currency). Each skill has up to 4 upgrade tiers (levels 2–5). Each tier gives a specific bonus defined in `SkillCatalog.DEFINITIONS`. Upgrades persist across runs via `GameState`.

## Scope

- Skill leveling: levels 1–5, stored in `GameState.skill_levels`
- Upgrade data defined per-skill in `SkillCatalog.DEFINITIONS`
- CryptPanel shows upgrade UI for each unlocked skill
- EffectScripts receive skill data dict (with computed level params) so they can branch behavior
- Animation placeholder: `animation_id` field added to SkillType, unused until visual pass

Out of scope:
- Visual animations for skill activation
- Rework of passive skill descriptions (bone_crown/venom_burst)
- HUD skill tooltip (separate task)

---

## Architecture

### Data flow

```
GameState.skill_levels          # persistent: skill_id → level (int)
    ↓
SkillCatalog.compute_at_level(base_def, level)
    → applies upgrade deltas cumulatively
    → returns effective skill dict with computed params
    ↓
RunState._rebuild_active_skills()
    → each active skill carries its computed params
    ↓
RunState.activate_skill(skill_id, board_logic)
    → passes computed skill dict to EffectScript.apply()
    ↓
EffectScript reads skill.get("sweep_count", 1) etc.
```

---

## Files Changed

| File | Change |
|---|---|
| `scripts/core/GameState.gd` | Add `skill_levels: Dictionary`, persist in `to_dict`/`from_dict` |
| `scripts/data/SkillCatalog.gd` | Add `upgrades` arrays to all 16 skills; add `compute_at_level()`, `upgrade_cost()` |
| `scripts/data/SkillType.gd` | Add `level: int = 1`, `animation_id: String = ""` fields |
| `scripts/core/RunState.gd` | `activate_skill` passes skill dict to `effect.apply()`; `_rebuild_active_skills` applies level from GameState |
| `scripts/data/effects/EffectCollectGold.gd` | Accept `skill` param; use `sweep_count` |
| `scripts/data/effects/EffectDamageAll.gd` | Accept `skill` param |
| `scripts/data/effects/EffectSweepRows.gd` | Accept `skill` param; use `sweep_count` |
| `scripts/data/effects/EffectFullHeal.gd` | Accept `skill` param |
| `scripts/data/effects/EffectResetTimers.gd` | Accept `skill` param |
| `scripts/data/effects/EffectNextCrit.gd` | Accept `skill` param; use `crit_damage_mult` |
| `scripts/ui/CryptPanel.gd` | Add upgrade button + cost label per skill card |

---

## Data Model

### GameState additions

```gdscript
var skill_levels: Dictionary = {}   # "gold_sweep" -> 3

# in to_dict():
"skill_levels": skill_levels,

# in from_dict():
if data.has("skill_levels") and data["skill_levels"] is Dictionary:
    skill_levels = data["skill_levels"].duplicate()
```

### SkillCatalog upgrade entries

Upgrade delta keys:
- `cooldown_delta: int` — reduces effective cooldown (applied at compute time)
- `sweep_count: int` — replaces default 1 (EffectCollectGold, EffectSweepRows)
- `crit_damage_mult: float` — crit multiplier (default 2.0); EffectNextCrit writes to run
- `bonus_delta: Dictionary` — added to passive `bonuses` dict

Cost formula: `upgrade_cost_base + (target_level - 2) * upgrade_cost_step`
(target_level 2 costs base, level 3 costs base+step, etc.)

### Example definitions

```gdscript
"gold_sweep": {
    ...
    "upgrade_cost_base": 40,
    "upgrade_cost_step": 20,
    "upgrades": [
        {"desc_key": "upgrade.gold_sweep.1", "cooldown_delta": -1},
        {"desc_key": "upgrade.gold_sweep.2", "sweep_count": 2},
        {"desc_key": "upgrade.gold_sweep.3", "cooldown_delta": -1},
        {"desc_key": "upgrade.gold_sweep.4", "sweep_count": 3},
    ],
},
"arc_star": {
    ...
    "upgrade_cost_base": 35,
    "upgrade_cost_step": 20,
    "upgrades": [
        {"desc_key": "upgrade.arc_star.1", "bonus_delta": {"crit_chance": 0.03}},
        {"desc_key": "upgrade.arc_star.2", "crit_damage_mult": 2.5},
        {"desc_key": "upgrade.arc_star.3", "bonus_delta": {"crit_chance": 0.04}},
        {"desc_key": "upgrade.arc_star.4", "crit_damage_mult": 3.0},
    ],
},
"predator": {
    ...
    "upgrade_cost_base": 40,
    "upgrade_cost_step": 20,
    "upgrades": [
        {"desc_key": "upgrade.predator.1", "cooldown_delta": -1},
        {"desc_key": "upgrade.predator.2", "crit_damage_mult": 2.5},
        {"desc_key": "upgrade.predator.3", "cooldown_delta": -1},
        {"desc_key": "upgrade.predator.4", "crit_damage_mult": 3.0},
    ],
},
"wrath": {
    ...
    "upgrade_cost_base": 45,
    "upgrade_cost_step": 25,
    "upgrades": [
        {"desc_key": "upgrade.wrath.1", "cooldown_delta": -1},
        {"desc_key": "upgrade.wrath.2", "bonus_delta": {"sword_damage_bonus": 1}},
        {"desc_key": "upgrade.wrath.3", "cooldown_delta": -1},
        {"desc_key": "upgrade.wrath.4", "bonus_delta": {"sword_damage_bonus": 1}},
    ],
},
"row_sweep": {
    ...
    "upgrade_cost_base": 40,
    "upgrade_cost_step": 20,
    "upgrades": [
        {"desc_key": "upgrade.row_sweep.1", "cooldown_delta": -1},
        {"desc_key": "upgrade.row_sweep.2", "sweep_count": 2},
        {"desc_key": "upgrade.row_sweep.3", "cooldown_delta": -1},
        {"desc_key": "upgrade.row_sweep.4", "sweep_count": 3},
    ],
},
"full_heal": {
    ...
    "upgrade_cost_base": 50,
    "upgrade_cost_step": 25,
    "upgrades": [
        {"desc_key": "upgrade.full_heal.1", "cooldown_delta": -2},
        {"desc_key": "upgrade.full_heal.2", "bonus_delta": {"vampirism": 0.05}},
        {"desc_key": "upgrade.full_heal.3", "cooldown_delta": -2},
        {"desc_key": "upgrade.full_heal.4", "bonus_delta": {"vampirism": 0.05}},
    ],
},
"stasis": {
    ...
    "upgrade_cost_base": 40,
    "upgrade_cost_step": 20,
    "upgrades": [
        {"desc_key": "upgrade.stasis.1", "cooldown_delta": -1},
        {"desc_key": "upgrade.stasis.2", "freeze_turns": 2},
        {"desc_key": "upgrade.stasis.3", "cooldown_delta": -1},
        {"desc_key": "upgrade.stasis.4", "freeze_turns": 3},
    ],
},
# Passive skills: each upgrade just adds to bonuses
"bone_crown": {
    ...
    "upgrade_cost_base": 30,
    "upgrade_cost_step": 15,
    "upgrades": [
        {"desc_key": "upgrade.bone_crown.1", "bonus_delta": {"sword_damage_bonus": 1}},
        {"desc_key": "upgrade.bone_crown.2", "bonus_delta": {"sword_damage_bonus": 1}},
        {"desc_key": "upgrade.bone_crown.3", "bonus_delta": {"sword_damage_bonus": 1}},
        {"desc_key": "upgrade.bone_crown.4", "bonus_delta": {"crit_chance": 0.05}},
    ],
},
# (all remaining passives follow same pattern)
```

### compute_at_level()

```gdscript
static func compute_at_level(base_def: Dictionary, level: int) -> Dictionary:
    var result := base_def.duplicate(true)
    var upgrades: Array = base_def.get("upgrades", [])
    var tiers_to_apply := mini(level - 1, upgrades.size())
    for i in range(tiers_to_apply):
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
                bonuses[str(k)] = float(bonuses.get(str(k), 0)) + float(u["bonus_delta"][k])
            result["bonuses"] = bonuses
    result["level"] = level
    return result

static func upgrade_cost(base_def: Dictionary, target_level: int) -> int:
    var base: int = int(base_def.get("upgrade_cost_base", 50))
    var step: int = int(base_def.get("upgrade_cost_step", 25))
    return base + (target_level - 2) * step
```

---

## RunState Changes

### _rebuild_active_skills loads level from GameState

```gdscript
func _rebuild_active_skills() -> void:
    active_skills = []
    for skill_id in skill_pool_ids:
        if GameState.unlocked_skill_ids.has(skill_id):
            var base_def := SkillCatalogScript.DEFINITIONS.get(skill_id, {})
            var level: int = int(GameState.skill_levels.get(skill_id, 1))
            var computed := SkillCatalogScript.compute_at_level(base_def, level)
            var skill := SkillCatalogScript.localize_skill(SkillTypeScript.new(computed).to_dictionary())
            active_skills.append(skill)
    _recalculate_modifiers()
```

### activate_skill passes skill dict to effect

```gdscript
var result: Dictionary = effect.apply(self, board_logic, skill_data)
```

---

## EffectScript API

```gdscript
# SkillEffect base:
func apply(run: Node, board_logic: BoardLogic, skill: Dictionary) -> Dictionary:
    return {}
```

Each subclass accepts `skill` and reads computed params:
- `EffectCollectGold`: loops `sweep_count` times (collect → board refill signal → collect again)
- `EffectSweepRows`: same sweep_count loop
- `EffectNextCrit`: writes `run.next_crit_forced = true`; sets `run.next_crit_damage_mult = skill.get("crit_damage_mult", 2.0)`
- `EffectResetTimers`: reads `skill.get("freeze_turns", 1)` to set timers to that value instead of attack_cooldown
- Others: no behavior change from params yet

Note: `sweep_count > 1` requires waiting for board refill between sweeps. This is done by emitting `tiles_skill_cleared` and awaiting the `board_refilled` signal (or via `await get_tree().process_frame` if signal not available). Needs `Battle.gd` to handle multi-sweep via the return dict key `"sweep_again": true`.

---

## CryptPanel UI

Each unlocked skill card in the Skills tab gets:
- Current level display: `Lv 2 / 5`
- Next upgrade description: localized `desc_key` from `upgrades[level - 1]`
- Cost label: `upgrade_cost(base_def, level + 1)` skulls
- Upgrade button: disabled if `level >= max_level` or `GameState.skulls < cost`
- On press: `GameState.skulls -= cost`, `GameState.skill_levels[id] = level + 1`, `SaveSystem.save()`

---

## Localization Keys

All `desc_key` values need entries in both `en` and `ru` Localization dicts:

```
upgrade.gold_sweep.1  = "Cooldown -1" / "Кулдаун -1"
upgrade.gold_sweep.2  = "Collect twice" / "Собрать дважды"
upgrade.gold_sweep.3  = "Cooldown -1" / "Кулдаун -1"
upgrade.gold_sweep.4  = "Collect 3 times" / "Собрать трижды"
# ... (one entry per upgrade per skill)
```

---

## Upgrade Table (all skills)

| Skill | Lv2 | Lv3 | Lv4 | Lv5 |
|---|---|---|---|---|
| gold_sweep | cd-1 | sweep×2 | cd-1 | sweep×3 |
| wrath | cd-1 | +1 sword | cd-1 | +1 sword |
| row_sweep | cd-1 | sweep×2 | cd-1 | sweep×3 |
| full_heal | cd-2 | +5% vamp | cd-2 | +5% vamp |
| stasis | cd-1 | freeze 2t | cd-1 | freeze 3t |
| predator | cd-1 | crit×2.5 | cd-1 | crit×3.0 |
| bone_crown | +1 sword | +1 sword | +1 sword | +5% crit |
| violet_blade | +1 sword | +1 sword | +1 sword | +5% crit |
| arc_star | +3% crit | crit×2.5 | +4% crit | crit×3.0 |
| venom_burst | +1 sword | +3% crit | +1 sword | +5% crit |
| frost_sigils | -0.10 epd | +3% crit | -0.10 epd | +5% crit |
| coin_furnace | +1 shop | +5% crit | +1 shop | +2 shop |
| thorn_mail | +1 shield | +5% crit | +1 shield | +5% crit |
| blood_well | +4% vamp | +5% crit | +4% vamp | +5% crit |
| grave_tempo | +3% crit | +1 shop | +3% crit | +1 shop |
| moon_ward | +1 shield | +1 shield | +1 shield | +5% crit |

---

## Multi-sweep Architecture Note

`sweep_count > 1` introduces async behavior. The simplest approach: return `"tiles_cleared"` from first sweep, then Battle listens for `board_refilled` signal and calls a pending second sweep stored in RunState. Alternatively, Battle handles a new return key `"pending_sweeps": N` and drives each sweep after the board animation completes.

**Recommended:** Battle drives sweeps via `"pending_sweeps"` count — keeps EffectScript simple, Battle already owns the board refill flow.
