# Meta-Progression System Design
Date: 2026-05-16

## Goal
Roguelite loop: each run earns persistent resources that make future runs stronger,
allowing players to gradually overcome harder levels.

## Meta-Currencies

### Skulls
- Earned at end of every run: `waves_cleared * 10 + bosses_killed * 25 + (survived ? 15 : 0)`
- Stored in `GameState.skulls` (persists across runs)
- Spent to: unlock items into shop pool, add skills to skill pool

### Boss Tokens
- 1 token per boss killed, accumulated globally across all runs
- Stored in `GameState.boss_tokens`
- Spent exclusively to unlock classes

## Run Flow
```
End of run -> RunSummary screen (show skulls/tokens earned)
  -> Crypt screen (meta shop, 2 tabs)
      -> "Equipment" tab: spend skulls to unlock items
      -> "Classes" tab: spend boss tokens to unlock classes
  -> Level select -> Class select -> Start run
```

## Classes (4 initial)

| Class     | Cost   | Passive Effect                                                    |
|-----------|--------|-------------------------------------------------------------------|
| Warrior   | free   | +2 max HP, +1 sword_damage_bonus starting modifier               |
| Rogue     | 1 token| Coin chains deal 1 damage to enemies; gold bonus +30%            |
| Vampire   | 2 tokens| vampirism 0.10 starting; heart chains also grant +1 shield      |
| Alchemist | 3 tokens| On enemy kill: 40% chance to apply poison to a random neighbor  |

Classes stored in `ClassCatalog.gd`. Applied via `starting_modifiers` + `class_passive` key in RunState.
ChainResolver reads `class_passive` to handle rogue coin-attack and alchemist poison spread.

## Item Unlocking

Starting pool: items with `shop_enabled: true` (6 items across 6 slots).
All other items in EquipmentCatalog are locked until purchased.

Unlock costs by rarity:
| Rarity    | Skulls |
|-----------|--------|
| common    | 15     |
| uncommon  | 30     |
| rare      | 60     |
| epic      | 120    |
| legendary | 250    |
| mythic    | 500    |

`GameState.unlocked_item_ids: Array` tracks purchased items.
`EquipmentCatalog.get_available_items()` returns shop_enabled items + unlocked items.

## Skill Pool Expansion

Current: `GameState.skill_pool_ids` holds 8 of 10 skills — fixed.
New: all 10 skills start locked except 4 starter skills.
Cost: 20 skulls per skill added to pool.
Effect: unlocked skills appear in level-up choices during runs.

## Crypt Screen (UI)

New scene: `scenes/ui/CryptScreen.tscn`
- Header: skull count + boss token count
- Tab "Equipment": scrollable grid, locked items show cost + rarity color, tap = buy
- Tab "Classes": 4 cards with passive description, locked show token cost
- "Play" button -> level select

## Run Summary Screen (UI)

New scene: `scenes/ui/RunSummary.tscn`
- Shows: waves cleared, bosses killed, gold earned, score
- Animated: +N skulls, +N tokens earned this run
- "Continue" -> Crypt screen

## Files Changed

### New files
- `scripts/data/ClassCatalog.gd`
- `scripts/ui/CryptScreen.gd` + `scenes/ui/CryptScreen.tscn`
- `scripts/ui/RunSummary.gd` + `scenes/ui/RunSummary.tscn`

### Modified files
- `GameState.gd` — add skulls, boss_tokens, unlocked_item_ids, unlocked_skill_ids
- `Battle.gd` — track bosses_killed per run, pass to run_finished
- `ChainResolver.gd` — handle class_passive (rogue_coin_attack, alchemist_poison)
- `RunState.gd` — apply class starting_modifiers + class_passive on start
- `EquipmentCatalog.gd` — add get_available_items() respecting unlocked_item_ids
- `SaveSystem.gd` — persist new GameState fields
- `Main.gd` / `scenes/Main.tscn` — wire RunSummary -> Crypt -> LevelSelect flow
- `EventBus.gd` — add run_finished with new fields if needed
