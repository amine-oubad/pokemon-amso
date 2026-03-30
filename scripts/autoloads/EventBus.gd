extends Node
## Bus de signaux global.
## Permet aux systèmes de communiquer sans références directes entre eux.
## Usage : EventBus.player_stepped.connect(_on_step) | EventBus.player_stepped.emit(pos)

# ── Overworld ──────────────────────────────────────────────────────────────────
signal player_stepped(world_position: Vector2)
signal zone_transition_requested(zone_id: String, spawn_id: String)
signal dialogue_requested(lines: Array, speaker: String)
signal dialogue_finished

# ── Combat ─────────────────────────────────────────────────────────────────────
signal battle_started(enemy_data: Dictionary, is_trainer: bool)
signal trainer_battle_started(trainer_id: String)
signal battle_ended(result: String)  # "win" | "lose" | "flee" | "caught"
signal pokemon_caught(pokemon_id: String)
signal badge_earned(badge_id: String)

# ── UI ─────────────────────────────────────────────────────────────────────────
signal menu_opened(menu_id: String)
signal menu_closed(menu_id: String)

# ── Cinematiques ──────────────────────────────────────────────────────────────
signal cinematic_started(cinematic_id: String)
signal cinematic_finished(cinematic_id: String)
signal mega_evolution_triggered(pokemon_id: String, mega_form: String)

# ── Sauvegarde ─────────────────────────────────────────────────────────────────
signal save_requested()
signal load_requested(slot: int)
