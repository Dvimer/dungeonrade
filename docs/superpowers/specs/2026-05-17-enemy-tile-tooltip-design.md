# Design: Enemy Tile Tooltip

**Date:** 2026-05-17

## Goal

Show a floating tooltip when the player hovers over an ENEMY tile on the board.
The tooltip displays the monster's name and full description of its special abilities.

## Scope

- ENEMY tiles only (HEART, SWORD, SHIELD, COIN — no tooltip).
- Desktop/mouse hover only (touch devices: no hover, tooltip not shown).

## Architecture

### Signal flow

```
Tile.set_hovered(true)  [kind == ENEMY]
  → EventBus.tile_hovered.emit(tile_data)

Tile.set_hovered(false)
  → EventBus.tile_unhovered.emit()

HUD._on_tile_hovered(tile_data)
  → populate TooltipPanel, position near mouse, fade in

HUD._on_tile_unhovered()
  → fade out TooltipPanel
```

### New EventBus signals

```gdscript
signal tile_hovered(tile_data: Dictionary)
signal tile_unhovered()
```

### Tile.gd changes

In `set_hovered(on: bool)`:
- If `on == true` and `data.get("kind") == TileType.Kind.ENEMY`:
  `EventBus.tile_hovered.emit(data)`
- If `on == false` and previous state was hovered:
  `EventBus.tile_unhovered.emit()`

### TooltipPanel (added to HUD scene)

Node path: `$Root/TooltipPanel`
Type: `PanelContainer`
- `visible = false` by default
- Contains a `RichTextLabel` (bbcode enabled)
- `mouse_filter = MOUSE_FILTER_IGNORE` (doesn't block input)
- `custom_minimum_size = Vector2(220, 0)`

### Tooltip content

**Title line:** `[b]{monster_name}[/b]`

**Stats line:** `HP: {hp}  Atk: {dmg}  Def: {defense}  Timer: {timer}`

**Special ability lines** (only if flag is set):
- `heal_on_attack == true` → "Heals on attack (x{ratio})"
- `explode_on_attack == true` → "Explodes on attack (r={radius}, dmg={player_dmg})"
- `reset_timer_on_hit == true` → "Resets timer on hit"
- `remove_on_attack == true` → "Vanishes after attack"
- `is_boss == true` → `[color=#ff6666]BOSS[/color]` (shown first)

All strings go through `Localization.t()` with appropriate keys.

### Positioning

```
pos = get_viewport().get_mouse_position() + Vector2(16, 16)
# clamp to viewport so tooltip never goes off-screen
viewport_size = get_viewport().get_visible_rect().size
pos.x = min(pos.x, viewport_size.x - panel.size.x - 8)
pos.y = min(pos.y, viewport_size.y - panel.size.y - 8)
TooltipPanel.global_position = pos
```

`_process()` in HUD updates position every frame while tooltip is visible (follows mouse).

### Animation

Fade in: `modulate.a` from 0 to 1 over 0.12s via Tween.
Fade out: `modulate.a` from 1 to 0 over 0.10s, then `visible = false`.

## Files changed

| File | Change |
|---|---|
| `scripts/core/EventBus.gd` | +2 signals: `tile_hovered`, `tile_unhovered` |
| `scripts/battle/Tile.gd` | emit signals in `set_hovered()` |
| `scripts/ui/HUD.gd` | subscribe to signals, tooltip logic, `_process` for position |
| `scenes/ui/HUD.tscn` | add `TooltipPanel` node with `RichTextLabel` |

## Localization keys needed

```
tooltip.enemy.stats = "HP: %d  Atk: %d  Def: %d  Timer: %d"
tooltip.enemy.heal_on_attack = "Heals on attack (x%.1f)"
tooltip.enemy.explode = "Explodes (r=%d, dmg=%d)"
tooltip.enemy.reset_timer = "Resets timer on hit"
tooltip.enemy.remove_on_attack = "Vanishes after attack"
tooltip.enemy.boss = "BOSS"
```

(Localization file location to be confirmed — follow existing key format.)
