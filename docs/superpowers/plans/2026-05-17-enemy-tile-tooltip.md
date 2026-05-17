# Enemy Tile Tooltip Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show a floating tooltip with the monster's name and full description when hovering over an ENEMY tile on the board.

**Architecture:** `EventBus` carries two new signals (`tile_hovered`, `tile_unhovered`). `Tile.set_hovered()` emits them when kind is ENEMY. `HUD._ready()` creates a `PanelContainer` tooltip programmatically, subscribes to signals, populates and fades the panel in/out, and tracks mouse position in `_process()`.

**Tech Stack:** GDScript 4, Godot 4, EventBus autoload, Localization autoload

---

## Files

| File | Change |
|---|---|
| `scripts/core/EventBus.gd` | Add 2 signals |
| `scripts/core/Localization.gd` | Add tooltip keys (en + ru) |
| `scripts/battle/Tile.gd` | Emit signals in `set_hovered()` |
| `scripts/ui/HUD.gd` | Create tooltip panel, subscribe to signals, `_process` for position |

---

### Task 1: EventBus signals + Localization keys

**Files:**
- Modify: `scripts/core/EventBus.gd`
- Modify: `scripts/core/Localization.gd`

- [ ] **Step 1: Add signals to EventBus.gd**

Open `scripts/core/EventBus.gd`. After the `# --- Навыки ---` block (after line 41), add:

```gdscript
# --- UI подсказки ---
signal tile_hovered(tile_data: Dictionary)   # ENEMY-тайл под курсором
signal tile_unhovered()                      # курсор ушёл с тайла
```

- [ ] **Step 2: Add localization keys — English section**

In `scripts/core/Localization.gd`, in the `"en"` dictionary, after the line `"monster.bone_lord": "Bone Lord",` add:

```gdscript
		"tooltip.enemy.heal_on_attack": "Heals on attack (x%.1f)",
		"tooltip.enemy.explode": "Explodes on attack (radius %d, dmg %d)",
		"tooltip.enemy.reset_timer": "Resets timer on hit",
		"tooltip.enemy.remove_on_attack": "Vanishes after attack",
		"tooltip.enemy.boss": "BOSS",
```

- [ ] **Step 3: Add localization keys — Russian section**

In `scripts/core/Localization.gd`, in the `"ru"` dictionary, after the line `"monster.bone_lord": "Костяной лорд",` add:

```gdscript
		"tooltip.enemy.heal_on_attack": "Лечится при атаке (x%.1f)",
		"tooltip.enemy.explode": "Взрывается при атаке (радиус %d, урон %d)",
		"tooltip.enemy.reset_timer": "Сбрасывает ход при ударе",
		"tooltip.enemy.remove_on_attack": "Исчезает после атаки",
		"tooltip.enemy.boss": "БОСС",
```

- [ ] **Step 4: Commit**

```bash
git add scripts/core/EventBus.gd scripts/core/Localization.gd
git commit -m "feat: add tile_hovered signals and monster tooltip localization keys"
```

---

### Task 2: Tile emits hover signals

**Files:**
- Modify: `scripts/battle/Tile.gd` — `set_hovered()` function (lines 296–339)

- [ ] **Step 1: Emit signals inside set_hovered()**

Find `set_hovered(on: bool)` in `scripts/battle/Tile.gd`. The function starts with:

```gdscript
func set_hovered(on: bool) -> void:
	# Курсор над тайлом. Не показываем на затемнённых тайлах.
	if on and dimmed:
		return
	if on == hovered:
		return
	hovered = on
```

Immediately after `hovered = on`, add:

```gdscript
	if on and data.get("kind", TileType.Kind.EMPTY) == TileType.Kind.ENEMY:
		EventBus.tile_hovered.emit(data)
	elif not on:
		EventBus.tile_unhovered.emit()
```

The function body after the insertion should look like:

```gdscript
func set_hovered(on: bool) -> void:
	# Курсор над тайлом. Не показываем на затемнённых тайлах.
	if on and dimmed:
		return
	if on == hovered:
		return
	hovered = on
	if on and data.get("kind", TileType.Kind.EMPTY) == TileType.Kind.ENEMY:
		EventBus.tile_hovered.emit(data)
	elif not on:
		EventBus.tile_unhovered.emit()
	if on:
		# ... rest of existing code unchanged
```

- [ ] **Step 2: Commit**

```bash
git add scripts/battle/Tile.gd
git commit -m "feat: tile emits tile_hovered/tile_unhovered on enemy hover"
```

---

### Task 3: HUD tooltip panel

**Files:**
- Modify: `scripts/ui/HUD.gd`

- [ ] **Step 1: Add tooltip instance variables**

In `scripts/ui/HUD.gd`, after the line `var _ui_texture_cache: Dictionary = {}`, add:

```gdscript
var _tooltip_panel: PanelContainer = null
var _tooltip_label: RichTextLabel = null
var _tooltip_visible: bool = false
var _tooltip_tween: Tween = null
```

- [ ] **Step 2: Wire up in _ready()**

At the end of `_ready()`, after `_refresh_all()`, add:

```gdscript
	_setup_tooltip()
	EventBus.tile_hovered.connect(_on_tile_hovered)
	EventBus.tile_unhovered.connect(_on_tile_unhovered)
```

- [ ] **Step 3: Add _setup_tooltip() function**

Add this function after the `_setup_shimmer()` function:

```gdscript
func _setup_tooltip() -> void:
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.custom_minimum_size = Vector2(220, 0)
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.visible = false
	_tooltip_panel.modulate.a = 0.0
	_tooltip_panel.z_index = 200

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.06, 0.14, 0.96)
	style.border_color = Color(0.58, 0.37, 0.48, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	_tooltip_panel.add_theme_stylebox_override("panel", style)

	_tooltip_label = RichTextLabel.new()
	_tooltip_label.bbcode_enabled = true
	_tooltip_label.fit_content = true
	_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_label.custom_minimum_size = Vector2(196, 0)
	_tooltip_label.add_theme_font_size_override("normal_font_size", 16)
	_tooltip_label.add_theme_font_size_override("bold_font_size", 17)
	_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.add_child(_tooltip_label)

	$Root.add_child(_tooltip_panel)
```

- [ ] **Step 4: Add _on_tile_hovered() and _on_tile_unhovered()**

```gdscript
func _on_tile_hovered(tile_data: Dictionary) -> void:
	_tooltip_label.text = _build_monster_tooltip(tile_data)
	_tooltip_panel.visible = true
	_tooltip_visible = true
	_reposition_tooltip()
	if _tooltip_tween and _tooltip_tween.is_valid():
		_tooltip_tween.kill()
	_tooltip_tween = create_tween()
	_tooltip_tween.tween_property(_tooltip_panel, "modulate:a", 1.0, 0.12)

func _on_tile_unhovered() -> void:
	_tooltip_visible = false
	if _tooltip_tween and _tooltip_tween.is_valid():
		_tooltip_tween.kill()
	_tooltip_tween = create_tween()
	_tooltip_tween.tween_property(_tooltip_panel, "modulate:a", 0.0, 0.10)
	_tooltip_tween.tween_callback(func(): _tooltip_panel.visible = false)
```

- [ ] **Step 5: Add _build_monster_tooltip()**

```gdscript
func _build_monster_tooltip(data: Dictionary) -> String:
	var monster_id := str(data.get("monster_id", ""))
	var name := Localization.monster_name(monster_id, str(data.get("monster_name", "?")))
	var hp := int(data.get("hp", 0))
	var dmg := int(data.get("dmg", 0))
	var defense := int(data.get("defense", 0))
	var timer := int(data.get("timer", 0))

	var text := ""

	if bool(data.get("is_boss", false)):
		text += "[color=#ff6666]" + Localization.t("tooltip.enemy.boss") + "[/color]\n"

	text += "[b]" + name + "[/b]\n"

	var info := Localization.t("monster.info", [name, hp, dmg, defense, timer])
	var parts := info.split("\n")
	if parts.size() > 1:
		text += parts[1] + "\n"

	if bool(data.get("heal_on_attack", false)):
		var ratio := float(data.get("heal_on_attack_ratio", 1.0))
		text += Localization.t("tooltip.enemy.heal_on_attack", [ratio]) + "\n"
	if bool(data.get("explode_on_attack", false)):
		var radius := int(data.get("explosion_radius", 1))
		var pdmg := int(data.get("explosion_player_damage", 0))
		text += Localization.t("tooltip.enemy.explode", [radius, pdmg]) + "\n"
	if bool(data.get("reset_timer_on_hit", false)):
		text += Localization.t("tooltip.enemy.reset_timer") + "\n"
	if bool(data.get("remove_on_attack", false)):
		text += Localization.t("tooltip.enemy.remove_on_attack") + "\n"

	return text.strip_edges()
```

- [ ] **Step 6: Add _reposition_tooltip() and _process()**

```gdscript
func _reposition_tooltip() -> void:
	if _tooltip_panel == null:
		return
	var mp := get_viewport().get_mouse_position()
	var vp_size := get_viewport().get_visible_rect().size
	var panel_size := _tooltip_panel.get_minimum_size()
	if panel_size == Vector2.ZERO:
		panel_size = Vector2(220, 80)
	var pos := mp + Vector2(16.0, 16.0)
	pos.x = minf(pos.x, vp_size.x - panel_size.x - 8.0)
	pos.y = minf(pos.y, vp_size.y - panel_size.y - 8.0)
	_tooltip_panel.position = pos

func _process(_delta: float) -> void:
	if _tooltip_visible:
		_reposition_tooltip()
```

- [ ] **Step 7: Hide tooltip on overlay open (in _refresh_all)**

In `_refresh_all()`, find the existing lines:

```gdscript
	if _upgrade_overlay:
		_upgrade_overlay.visible = false
	if _shop_overlay:
		_shop_overlay.visible = false
```

After them, add:

```gdscript
	_on_tile_unhovered()
```

This ensures the tooltip is dismissed if an upgrade/shop screen appears.

- [ ] **Step 8: Commit**

```bash
git add scripts/ui/HUD.gd
git commit -m "feat: floating enemy tooltip with monster name and abilities"
```

---

## Manual Test Checklist

After all tasks are complete, run the game and verify:

1. Start a battle. Hover mouse over an ENEMY tile → tooltip fades in showing monster name (bold) + HP/ATK/DEF/TIMER stats.
2. Move mouse off the tile → tooltip fades out.
3. Hover a vampire tile → tooltip shows "Лечится при атаке (x1.0)" line.
4. Hover a BOSS tile → tooltip shows "БОСС" label in red at the top.
5. Hover a SWORD/COIN/HEART tile → no tooltip appears.
6. Trigger the upgrade or shop overlay while hovering an enemy → tooltip is dismissed.
7. Switch language to EN in settings, hover monster → stats line shows "HP / ATK / DEF / TIMER" in English.
8. Move mouse near right/bottom screen edge while hovering monster → tooltip clamps inside viewport.
