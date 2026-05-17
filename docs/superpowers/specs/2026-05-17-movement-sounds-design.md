# Sound System Design — Movement & Battle Sounds

**Date:** 2026-05-17
**Status:** Approved

## Overview

Add sound effects to all key game events: chain building (swipe), chain resolution, enemy combat, and tile physics. Implemented via a centralized `AudioManager` autoload singleton that subscribes to `EventBus`.

No audio files exist in the project yet — all sounds will be generated via [sfxr.me](https://sfxr.me) (jsfxr) and exported as `.wav`.

---

## Sound Files

All files go in `res://audio/`.

| File | Trigger | jsfxr Preset | Notes |
|------|---------|--------------|-------|
| `chain_start.wav` | First tile touched | Blip/Select | Soft, medium pitch |
| `chain_tick.wav` | Each tile added to chain | Blip/Select | Short, higher pitch |
| `chain_cancel.wav` | Chain cancelled | Hit/Hurt | Low pitch, quiet |
| `resolve_sword.wav` | Attack chain resolved | Hit/Hurt | Sharp, medium weight |
| `resolve_heart.wav` | Heal chain resolved | Powerup | Rising, soft |
| `resolve_shield.wav` | Shield chain resolved | Hit/Hurt | Dull, low |
| `resolve_coin.wav` | Coin chain resolved | Pickup/Coin | Bright, short |
| `enemy_hit.wav` | Enemy takes damage | Hit/Hurt | Sharp impact |
| `enemy_die.wav` | Enemy killed | Explosion | Small, decaying |

---

## Architecture

### AudioManager (autoload)

**Path:** `res://scripts/core/AudioManager.gd`
**Registered as autoload** in Project Settings as `AudioManager`.

**Internals:**
- Pool of 6 `AudioStreamPlayer` child nodes for polyphony (round-robin assignment)
- `master_volume: float = 1.0` — global volume multiplier
- `_tick_cooldown: float` — debounce timer for `chain_tick` (80ms minimum between ticks)

**Lifecycle:**
- `_ready()`: preloads all 9 `.wav` files, creates player pool, connects to EventBus
- `_process(delta)`: decrements `_tick_cooldown`

### Event → Sound Mapping

| EventBus Signal | Sound | Condition |
|----------------|-------|-----------|
| `chain_started` | `chain_start` | always |
| `chain_extended` | `chain_tick` | debounce 80ms |
| `chain_cancelled` | `chain_cancel` | always |
| `chain_resolved(result)` | `resolve_sword` | `result.damage_to_enemies > 0` |
| `chain_resolved(result)` | `resolve_heart` | `result.heal_amount > 0` |
| `chain_resolved(result)` | `resolve_shield` | `result.shield_gained > 0` |
| `chain_resolved(result)` | `resolve_coin` | `result.gold_gained > 0` |
| `enemy_damaged` | `enemy_hit` | always |
| `enemy_killed` | `enemy_die` | always |

Note: `chain_resolved` can match multiple conditions (e.g. sword + coin in same chain). All matching sounds play simultaneously via the pool.

---

## File Structure

```
res://
  audio/
    chain_start.wav
    chain_tick.wav
    chain_cancel.wav
    resolve_sword.wav
    resolve_heart.wav
    resolve_shield.wav
    resolve_coin.wav
    enemy_hit.wav
    enemy_die.wav
  scripts/
    core/
      AudioManager.gd   (new)
      EventBus.gd       (unchanged)
```

---

## Out of Scope

- Music / ambient tracks
- UI sounds (menus, shop)
- Volume settings UI (master_volume exists but no settings screen)
- Positional audio (2D AudioStreamPlayer2D)
