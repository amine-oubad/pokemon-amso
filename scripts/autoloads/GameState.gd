extends Node
## Singleton — état dynamique de la partie.
## Persisté via SaveManager (Phase 2).

const PokemonInstance = preload("res://scripts/data/PokemonInstance.gd")
# ── Joueur ─────────────────────────────────────────────────────────────────────
var player_name: String = "RED"
var money: int = 3000

# ── Équipe (max 6 PokemonInstance) ─────────────────────────────────────────────
var team: Array = []

# ── PC ─────────────────────────────────────────────────────────────────────────
var pc_boxes: Array = []

# ── Inventaire — { item_id: count } ───────────────────────────────────────────
var bag: Dictionary = {"potion": 3, "poke_ball": 5}

# ── Badges ─────────────────────────────────────────────────────────────────────
var badges: Array = []

# ── Flags d'événements ─────────────────────────────────────────────────────────
var flags: Dictionary = {}

# ── Dresseurs vaincus ─────────────────────────────────────────────────────────
var defeated_trainers: Array = []

# ── Pokédex ────────────────────────────────────────────────────────────────────
var pokedex_seen: Array = []
var pokedex_caught: Array = []

# ── Combat en attente ──────────────────────────────────────────────────────────
## Rempli par la map courante avant de charger BattleScene.
## { "enemy_data": {...}, "is_trainer": false, "trainer_id": "", "trainer_team": [], "reward_money": 0 }
var pending_battle: Dictionary = {}

## Scène overworld à reprendre après un combat.
var return_to_scene: String = "res://scenes/overworld/maps/PalletTown.tscn"

## Position de spawn à appliquer au chargement de la prochaine map.
## Vector2.ZERO = utiliser la position par défaut de la map.
var pending_spawn_position: Vector2 = Vector2.ZERO

## Repousse — nombre de pas restants avant expiration.
var repel_steps: int = 0

func _ready() -> void:
	print("[GameState] Initialisé — joueur : " + player_name)
	# L'équipe reste vide → l'écran de choix du starter s'affiche au lancement

# ── Badges ─────────────────────────────────────────────────────────────────────

func has_badge(badge_id: String) -> bool:
	return badge_id in badges

func add_badge(badge_id: String) -> void:
	if not has_badge(badge_id):
		badges.append(badge_id)
		EventBus.badge_earned.emit(badge_id)

# ── Dresseurs vaincus ─────────────────────────────────────────────────────────

func is_trainer_defeated(trainer_id: String) -> bool:
	return trainer_id in defeated_trainers

func mark_trainer_defeated(trainer_id: String) -> void:
	if not is_trainer_defeated(trainer_id):
		defeated_trainers.append(trainer_id)

# ── CS / HMs ──────────────────────────────────────────────────────────────────

func can_use_hm(hm_id: String) -> bool:
	var required_badges := {
		"cut": "boulder_badge",
		"flash": "boulder_badge",
		"surf": "cascade_badge",
		"strength": "rainbow_badge",
		"fly": "thunder_badge",
	}
	var badge: String = required_badges.get(hm_id, "")
	return badge == "" or has_badge(badge)

# ── Inventaire ─────────────────────────────────────────────────────────────────

func add_item(item_id: String, count: int = 1) -> void:
	bag[item_id] = bag.get(item_id, 0) + count

func remove_item(item_id: String, count: int = 1) -> bool:
	if bag.get(item_id, 0) < count:
		return false
	bag[item_id] -= count
	if bag[item_id] <= 0:
		bag.erase(item_id)
	return true

func has_item(item_id: String, count: int = 1) -> bool:
	return bag.get(item_id, 0) >= count

# ── Flags ──────────────────────────────────────────────────────────────────────

func set_flag(flag_id: String, value: bool = true) -> void:
	flags[flag_id] = value

func get_flag(flag_id: String) -> bool:
	return flags.get(flag_id, false)

# ── Pokédex ────────────────────────────────────────────────────────────────────

func register_seen(pokemon_id: String) -> void:
	if pokemon_id not in pokedex_seen:
		pokedex_seen.append(pokemon_id)

func register_caught(pokemon_id: String) -> void:
	register_seen(pokemon_id)
	if pokemon_id not in pokedex_caught:
		pokedex_caught.append(pokemon_id)

# ── Équipe ─────────────────────────────────────────────────────────────────────

func get_first_alive() -> PokemonInstance:
	for pkmn: PokemonInstance in team:
		if not pkmn.is_fainted():
			return pkmn
	return null

func heal_team() -> void:
	for pkmn: PokemonInstance in team:
		pkmn.full_heal()

# ── Repousse ─────────────────────────────────────────────────────────────────

func is_repel_active() -> bool:
	return repel_steps > 0

func tick_repel() -> void:
	if repel_steps > 0:
		repel_steps = maxi(0, repel_steps - 1)
