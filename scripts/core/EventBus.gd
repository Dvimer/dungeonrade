extends Node

# Глобальная шина событий.
# Любая система может подписаться/эмитить — это единственный способ "общения"
# между логикой, UI и эффектами. Не превращай это в свалку — добавляй сигналы
# только когда они действительно нужны нескольким подписчикам.

# --- Свайп / цепочка ---
signal chain_started(start_pos)         # Vector2
signal chain_extended(positions)        # Array<Vector2>
signal chain_cancelled()
signal chain_resolved(result)           # ChainResult

# --- Бой ---
signal enemy_damaged(pos, dmg)          # Vector2, int
signal enemy_killed(pos)                # Vector2
signal player_damaged(dmg)              # int
signal player_healed(amount)            # int
signal shield_changed(value)            # int
signal gold_changed(value)              # int
signal shop_charge_changed(current, needed) # int, int
signal xp_changed(current, needed)      # int, int
signal level_up(new_level)              # int
signal rounds_changed(value)            # int
signal skills_changed()
signal equipment_changed()

# --- Ход / волна ---
signal turn_ended()
signal wave_started(wave_index)
signal wave_cleared(wave_index)
signal player_died()
signal main_menu_requested()
signal shop_ready()
signal shop_offered(choices)            # Array
signal shop_picked(item)                # Dictionary

# --- Навыки ---
signal skill_tapped(skill_id)           # String — HUD запрашивает активацию
signal tiles_skill_cleared(positions)   # Array[Vector2] — Battle очищает тайлы

# --- Мета ---
signal upgrade_offered(choices)         # Array
signal upgrade_picked(upgrade)
signal run_started()
signal run_finished(result)             # Dictionary
