#!/usr/bin/env python3
"""
Generate a comprehensive abilities.json file with ALL Pokemon abilities
from Generation 3 (Ruby/Sapphire) through Generation 9 (Scarlet/Violet + DLC).

Output: data/abilities.json
"""

import json
import os

ABILITIES = {
    # =====================================================================
    # GENERATION 3 — Ruby / Sapphire / Emerald  (abilities #1-76)
    # =====================================================================
    "stench":          {"name": "Stench",          "name_fr": "Puanteur",          "desc": "May cause the target to flinch when dealing damage.", "gen": 3, "hooks": ["modify_damage"]},
    "drizzle":         {"name": "Drizzle",         "name_fr": "Crachin",           "desc": "Summons rain when entering battle.", "gen": 3, "hooks": ["on_switch_in", "on_weather"]},
    "speed_boost":     {"name": "Speed Boost",     "name_fr": "Turbo",             "desc": "Speed rises at the end of each turn.", "gen": 3, "hooks": ["on_end_of_turn", "modify_speed"]},
    "battle_armor":    {"name": "Battle Armor",    "name_fr": "Armurbaston",       "desc": "Protects from critical hits.", "gen": 3, "hooks": ["prevent_crit"]},
    "sturdy":          {"name": "Sturdy",          "name_fr": "Fermeté",           "desc": "Cannot be KO'd from full HP in one hit. Immune to OHKO moves.", "gen": 3, "hooks": ["on_before_hit"]},
    "damp":            {"name": "Damp",            "name_fr": "Moiteur",           "desc": "Prevents the use of Self-Destruct, Explosion, and Aftermath.", "gen": 3, "hooks": ["on_before_hit"]},
    "limber":          {"name": "Limber",          "name_fr": "Échauffement",      "desc": "Prevents paralysis.", "gen": 3, "hooks": ["prevent_status"]},
    "sand_veil":       {"name": "Sand Veil",       "name_fr": "Voile Sable",       "desc": "Boosts evasion in sandstorm. Immune to sandstorm damage.", "gen": 3, "hooks": ["modify_accuracy", "on_weather"]},
    "static":          {"name": "Static",          "name_fr": "Statik",            "desc": "30% chance to paralyze on contact.", "gen": 3, "hooks": ["on_after_contact"]},
    "volt_absorb":     {"name": "Volt Absorb",     "name_fr": "Absorb Volt",       "desc": "Heals 25% HP when hit by an Electric move.", "gen": 3, "hooks": ["on_before_hit"]},
    "water_absorb":    {"name": "Water Absorb",    "name_fr": "Absorb Eau",        "desc": "Heals 25% HP when hit by a Water move.", "gen": 3, "hooks": ["on_before_hit"]},
    "oblivious":       {"name": "Oblivious",       "name_fr": "Benêt",             "desc": "Prevents Attract, Taunt, and Intimidate.", "gen": 3, "hooks": ["prevent_status", "prevent_stat_drop"]},
    "cloud_nine":      {"name": "Cloud Nine",      "name_fr": "Air Lock",          "desc": "Negates all weather effects while on the field.", "gen": 3, "hooks": ["on_switch_in", "on_weather"]},
    "compound_eyes":   {"name": "Compound Eyes",   "name_fr": "Œil Composé",       "desc": "Boosts accuracy by 30%.", "gen": 3, "hooks": ["modify_accuracy"]},
    "insomnia":        {"name": "Insomnia",        "name_fr": "Insomnia",          "desc": "Prevents sleep.", "gen": 3, "hooks": ["prevent_status"]},
    "color_change":    {"name": "Color Change",    "name_fr": "Caméléon",          "desc": "Changes type to the type of the move that hit it.", "gen": 3, "hooks": ["on_before_hit"]},
    "immunity":        {"name": "Immunity",        "name_fr": "Immunité",          "desc": "Prevents poison.", "gen": 3, "hooks": ["prevent_status"]},
    "flash_fire":      {"name": "Flash Fire",      "name_fr": "Torche",            "desc": "Immune to Fire moves; powers up own Fire moves when hit by one.", "gen": 3, "hooks": ["on_before_hit", "modify_damage"]},
    "shield_dust":     {"name": "Shield Dust",     "name_fr": "Écran Poudre",      "desc": "Blocks additional effects of incoming moves.", "gen": 3, "hooks": ["on_before_hit"]},
    "own_tempo":       {"name": "Own Tempo",       "name_fr": "Tempo Perso",       "desc": "Prevents confusion. Also blocks Intimidate.", "gen": 3, "hooks": ["prevent_status", "prevent_stat_drop"]},
    "suction_cups":    {"name": "Suction Cups",    "name_fr": "Ventouses",         "desc": "Prevents forced switching.", "gen": 3, "hooks": ["on_before_hit"]},
    "intimidate":      {"name": "Intimidate",      "name_fr": "Intimidation",      "desc": "Lowers opposing Attack by one stage on entry.", "gen": 3, "hooks": ["on_switch_in"]},
    "shadow_tag":      {"name": "Shadow Tag",      "name_fr": "Marque Ombre",      "desc": "Prevents opponents from switching out.", "gen": 3, "hooks": ["on_switch_in"]},
    "rough_skin":      {"name": "Rough Skin",      "name_fr": "Peau Dure",         "desc": "Damages attacker for 1/8 max HP on contact.", "gen": 3, "hooks": ["on_after_contact"]},
    "wonder_guard":    {"name": "Wonder Guard",    "name_fr": "Garde Mystik",      "desc": "Only super-effective moves deal damage.", "gen": 3, "hooks": ["on_before_hit"]},
    "levitate":        {"name": "Levitate",        "name_fr": "Lévitation",        "desc": "Immune to Ground-type moves.", "gen": 3, "hooks": ["on_before_hit"]},
    "effect_spore":    {"name": "Effect Spore",    "name_fr": "Pose Spore",        "desc": "30% chance to inflict poison, paralysis, or sleep on contact.", "gen": 3, "hooks": ["on_after_contact"]},
    "synchronize":     {"name": "Synchronize",     "name_fr": "Synchro",           "desc": "Passes poison, paralysis, or burn to the inflicter.", "gen": 3, "hooks": ["prevent_status"]},
    "clear_body":      {"name": "Clear Body",      "name_fr": "Corps Sain",        "desc": "Prevents stat reductions from other Pokemon.", "gen": 3, "hooks": ["prevent_stat_drop"]},
    "natural_cure":    {"name": "Natural Cure",    "name_fr": "Médic Nature",      "desc": "Heals status conditions on switch-out.", "gen": 3, "hooks": ["on_switch_out"]},
    "lightning_rod":   {"name": "Lightning Rod",   "name_fr": "Paratonnerre",      "desc": "Draws Electric moves; boosts Sp. Atk instead of taking damage.", "gen": 3, "hooks": ["on_before_hit", "modify_stat"]},
    "serene_grace":    {"name": "Serene Grace",    "name_fr": "Sérénité",          "desc": "Doubles the chance of additional move effects.", "gen": 3, "hooks": ["modify_damage"]},
    "swift_swim":      {"name": "Swift Swim",      "name_fr": "Glissade",          "desc": "Doubles Speed in rain.", "gen": 3, "hooks": ["modify_speed", "on_weather"]},
    "chlorophyll":     {"name": "Chlorophyll",     "name_fr": "Chlorophylle",      "desc": "Doubles Speed in harsh sunlight.", "gen": 3, "hooks": ["modify_speed", "on_weather"]},
    "illuminate":      {"name": "Illuminate",      "name_fr": "Lumiattirance",     "desc": "No competitive battle effect.", "gen": 3, "hooks": []},
    "trace":           {"name": "Trace",           "name_fr": "Calque",            "desc": "Copies the opponent's ability on entry.", "gen": 3, "hooks": ["on_switch_in"]},
    "huge_power":      {"name": "Huge Power",      "name_fr": "Énorme Pouvoir",    "desc": "Doubles Attack stat.", "gen": 3, "hooks": ["modify_stat"]},
    "poison_point":    {"name": "Poison Point",    "name_fr": "Point Poison",      "desc": "30% chance to poison on contact.", "gen": 3, "hooks": ["on_after_contact"]},
    "inner_focus":     {"name": "Inner Focus",     "name_fr": "Attention",         "desc": "Prevents flinching and Intimidate.", "gen": 3, "hooks": ["prevent_status", "prevent_stat_drop"]},
    "magma_armor":     {"name": "Magma Armor",     "name_fr": "Armumagma",         "desc": "Prevents freezing.", "gen": 3, "hooks": ["prevent_status"]},
    "water_veil":      {"name": "Water Veil",      "name_fr": "Voile Eau",         "desc": "Prevents burn.", "gen": 3, "hooks": ["prevent_status"]},
    "magnet_pull":     {"name": "Magnet Pull",     "name_fr": "Magnépiège",        "desc": "Traps Steel-type Pokemon.", "gen": 3, "hooks": ["on_switch_in"]},
    "soundproof":      {"name": "Soundproof",      "name_fr": "Anti-Bruit",        "desc": "Immune to sound-based moves.", "gen": 3, "hooks": ["on_before_hit"]},
    "rain_dish":       {"name": "Rain Dish",       "name_fr": "Cuvette",           "desc": "Recovers 1/16 HP each turn in rain.", "gen": 3, "hooks": ["on_end_of_turn", "on_weather"]},
    "sand_stream":     {"name": "Sand Stream",     "name_fr": "Sable Volant",      "desc": "Summons sandstorm on entry.", "gen": 3, "hooks": ["on_switch_in", "on_weather"]},
    "pressure":        {"name": "Pressure",        "name_fr": "Pression",          "desc": "Opposing moves use 2 PP instead of 1.", "gen": 3, "hooks": ["on_switch_in"]},
    "thick_fat":       {"name": "Thick Fat",       "name_fr": "Isograisse",        "desc": "Halves damage from Fire and Ice moves.", "gen": 3, "hooks": ["modify_damage"]},
    "early_bird":      {"name": "Early Bird",      "name_fr": "Matinal",           "desc": "Wakes from sleep twice as fast.", "gen": 3, "hooks": ["on_end_of_turn"]},
    "flame_body":      {"name": "Flame Body",      "name_fr": "Corps Ardent",      "desc": "30% chance to burn on contact.", "gen": 3, "hooks": ["on_after_contact"]},
    "run_away":        {"name": "Run Away",        "name_fr": "Fuite",             "desc": "Guarantees escape from wild battles.", "gen": 3, "hooks": []},
    "keen_eye":        {"name": "Keen Eye",        "name_fr": "Regard Vif",        "desc": "Prevents accuracy reduction.", "gen": 3, "hooks": ["prevent_stat_drop"]},
    "hyper_cutter":    {"name": "Hyper Cutter",    "name_fr": "Hyper Cutter",      "desc": "Prevents Attack from being lowered.", "gen": 3, "hooks": ["prevent_stat_drop"]},
    "pickup":          {"name": "Pickup",          "name_fr": "Ramassage",         "desc": "May pick up items after battle.", "gen": 3, "hooks": ["on_end_of_turn"]},
    "truant":          {"name": "Truant",          "name_fr": "Absentéisme",       "desc": "Can only attack every other turn.", "gen": 3, "hooks": ["on_end_of_turn"]},
    "hustle":          {"name": "Hustle",          "name_fr": "Agitation",         "desc": "Boosts Attack by 50% but lowers physical accuracy by 20%.", "gen": 3, "hooks": ["modify_stat", "modify_accuracy"]},
    "cute_charm":      {"name": "Cute Charm",      "name_fr": "Joli Sourire",      "desc": "30% chance to infatuate on contact.", "gen": 3, "hooks": ["on_after_contact"]},
    "plus":            {"name": "Plus",            "name_fr": "Plus",              "desc": "Boosts Sp. Atk if ally has Plus or Minus.", "gen": 3, "hooks": ["modify_stat"]},
    "minus":           {"name": "Minus",           "name_fr": "Minus",             "desc": "Boosts Sp. Atk if ally has Plus or Minus.", "gen": 3, "hooks": ["modify_stat"]},
    "forecast":        {"name": "Forecast",        "name_fr": "Météo",             "desc": "Changes Castform's type based on weather.", "gen": 3, "hooks": ["on_switch_in", "on_weather"]},
    "sticky_hold":     {"name": "Sticky Hold",     "name_fr": "Glu",               "desc": "Prevents item theft.", "gen": 3, "hooks": ["on_before_hit"]},
    "shed_skin":       {"name": "Shed Skin",       "name_fr": "Mue",               "desc": "33% chance to heal status each turn.", "gen": 3, "hooks": ["on_end_of_turn"]},
    "guts":            {"name": "Guts",            "name_fr": "Cran",              "desc": "Boosts Attack by 50% when statused.", "gen": 3, "hooks": ["modify_stat"]},
    "marvel_scale":    {"name": "Marvel Scale",    "name_fr": "Écaille Spéciale",  "desc": "Boosts Defense by 50% when statused.", "gen": 3, "hooks": ["modify_stat"]},
    "liquid_ooze":     {"name": "Liquid Ooze",     "name_fr": "Suintement",        "desc": "HP-draining moves damage the user instead.", "gen": 3, "hooks": ["on_before_hit"]},
    "overgrow":        {"name": "Overgrow",        "name_fr": "Engrais",           "desc": "Boosts Grass moves by 50% at low HP.", "gen": 3, "hooks": ["modify_damage"]},
    "blaze":           {"name": "Blaze",           "name_fr": "Brasier",           "desc": "Boosts Fire moves by 50% at low HP.", "gen": 3, "hooks": ["modify_damage"]},
    "torrent":         {"name": "Torrent",         "name_fr": "Torrent",           "desc": "Boosts Water moves by 50% at low HP.", "gen": 3, "hooks": ["modify_damage"]},
    "swarm":           {"name": "Swarm",           "name_fr": "Essaim",            "desc": "Boosts Bug moves by 50% at low HP.", "gen": 3, "hooks": ["modify_damage"]},
    "rock_head":       {"name": "Rock Head",       "name_fr": "Tête de Roc",       "desc": "Prevents recoil damage.", "gen": 3, "hooks": ["modify_damage"]},
    "drought":         {"name": "Drought",         "name_fr": "Sécheresse",        "desc": "Summons harsh sunlight on entry.", "gen": 3, "hooks": ["on_switch_in", "on_weather"]},
    "arena_trap":      {"name": "Arena Trap",      "name_fr": "Piège de Sable",    "desc": "Traps grounded opponents.", "gen": 3, "hooks": ["on_switch_in"]},
    "vital_spirit":    {"name": "Vital Spirit",    "name_fr": "Esprit Vital",      "desc": "Prevents sleep.", "gen": 3, "hooks": ["prevent_status"]},
    "white_smoke":     {"name": "White Smoke",     "name_fr": "Écran Fumée",       "desc": "Prevents stat reductions.", "gen": 3, "hooks": ["prevent_stat_drop"]},
    "pure_power":      {"name": "Pure Power",      "name_fr": "Force Pure",        "desc": "Doubles Attack stat.", "gen": 3, "hooks": ["modify_stat"]},
    "shell_armor":     {"name": "Shell Armor",     "name_fr": "Armure",            "desc": "Protects from critical hits.", "gen": 3, "hooks": ["prevent_crit"]},
    "air_lock":        {"name": "Air Lock",        "name_fr": "Verrou Climatique", "desc": "Negates all weather effects.", "gen": 3, "hooks": ["on_switch_in", "on_weather"]},

    # =====================================================================
    # GENERATION 4 — Diamond / Pearl / Platinum  (abilities #77-123)
    # =====================================================================
    "tangled_feet":    {"name": "Tangled Feet",    "name_fr": "Pieds Confus",      "desc": "Raises evasion when confused.", "gen": 4, "hooks": ["modify_accuracy"]},
    "motor_drive":     {"name": "Motor Drive",     "name_fr": "Moteur",            "desc": "Immune to Electric; boosts Speed when hit by one.", "gen": 4, "hooks": ["on_before_hit", "modify_speed"]},
    "rivalry":         {"name": "Rivalry",         "name_fr": "Rivalité",          "desc": "+25% damage vs same gender, -25% vs opposite.", "gen": 4, "hooks": ["modify_damage"]},
    "steadfast":       {"name": "Steadfast",       "name_fr": "Impassible",        "desc": "Boosts Speed when flinching.", "gen": 4, "hooks": ["modify_speed"]},
    "snow_cloak":      {"name": "Snow Cloak",      "name_fr": "Rideau Neige",      "desc": "Boosts evasion in hail/snow. Immune to hail damage.", "gen": 4, "hooks": ["modify_accuracy", "on_weather"]},
    "gluttony":        {"name": "Gluttony",        "name_fr": "Gloutonnerie",      "desc": "Eats Berries at 50% HP instead of 25%.", "gen": 4, "hooks": ["on_end_of_turn"]},
    "anger_point":     {"name": "Anger Point",     "name_fr": "Colérique",         "desc": "Maxes Attack after taking a critical hit.", "gen": 4, "hooks": ["on_before_hit", "modify_stat"]},
    "unburden":        {"name": "Unburden",        "name_fr": "Délestage",         "desc": "Doubles Speed when held item is consumed or lost.", "gen": 4, "hooks": ["modify_speed"]},
    "heatproof":       {"name": "Heatproof",       "name_fr": "Ignifugé",          "desc": "Halves Fire damage and burn damage.", "gen": 4, "hooks": ["modify_damage"]},
    "simple":          {"name": "Simple",          "name_fr": "Simple",            "desc": "Doubles stat change effects.", "gen": 4, "hooks": ["modify_stat"]},
    "dry_skin":        {"name": "Dry Skin",        "name_fr": "Peau Sèche",        "desc": "Absorbs Water moves; weak to Fire. Heals in rain, hurt in sun.", "gen": 4, "hooks": ["on_before_hit", "on_end_of_turn", "on_weather", "modify_damage"]},
    "download":        {"name": "Download",        "name_fr": "Téléchargement",    "desc": "Raises Atk or Sp. Atk based on foe's lower defensive stat.", "gen": 4, "hooks": ["on_switch_in", "modify_stat"]},
    "iron_fist":       {"name": "Iron Fist",       "name_fr": "Poing de Fer",      "desc": "Boosts punching moves by 20%.", "gen": 4, "hooks": ["modify_damage"]},
    "poison_heal":     {"name": "Poison Heal",     "name_fr": "Soin Poison",       "desc": "Heals 1/8 HP per turn when poisoned instead of taking damage.", "gen": 4, "hooks": ["on_end_of_turn"]},
    "adaptability":    {"name": "Adaptability",    "name_fr": "Adaptabilité",      "desc": "STAB becomes 2x instead of 1.5x.", "gen": 4, "hooks": ["modify_damage"]},
    "skill_link":      {"name": "Skill Link",      "name_fr": "Multi-Coups",       "desc": "Multi-hit moves always hit the maximum number of times.", "gen": 4, "hooks": ["modify_damage"]},
    "hydration":       {"name": "Hydration",       "name_fr": "Hydratation",       "desc": "Heals status in rain at end of turn.", "gen": 4, "hooks": ["on_end_of_turn", "on_weather"]},
    "solar_power":     {"name": "Solar Power",     "name_fr": "Solaire",           "desc": "Boosts Sp. Atk by 50% in sun but loses 1/8 HP per turn.", "gen": 4, "hooks": ["modify_stat", "on_end_of_turn", "on_weather"]},
    "quick_feet":      {"name": "Quick Feet",      "name_fr": "Pied Véloce",       "desc": "Boosts Speed by 50% when statused.", "gen": 4, "hooks": ["modify_speed"]},
    "normalize":       {"name": "Normalize",       "name_fr": "Normalise",         "desc": "All moves become Normal type with a power boost.", "gen": 4, "hooks": ["modify_damage"]},
    "sniper":          {"name": "Sniper",          "name_fr": "Sniper",            "desc": "Critical hits deal 2.25x damage instead of 1.5x.", "gen": 4, "hooks": ["modify_damage"]},
    "magic_guard":     {"name": "Magic Guard",     "name_fr": "Garde Magik",       "desc": "Only takes damage from direct attacks.", "gen": 4, "hooks": ["on_end_of_turn", "on_weather"]},
    "no_guard":        {"name": "No Guard",        "name_fr": "Annule Garde",      "desc": "All moves by and against this Pokemon always hit.", "gen": 4, "hooks": ["modify_accuracy"]},
    "stall":           {"name": "Stall",           "name_fr": "Frein",             "desc": "Always moves last in its priority bracket.", "gen": 4, "hooks": ["modify_speed"]},
    "technician":      {"name": "Technician",      "name_fr": "Technicien",        "desc": "Boosts moves with base power 60 or less by 50%.", "gen": 4, "hooks": ["modify_damage"]},
    "leaf_guard":      {"name": "Leaf Guard",      "name_fr": "Feuil. Garde",      "desc": "Prevents status in harsh sunlight.", "gen": 4, "hooks": ["prevent_status", "on_weather"]},
    "klutz":           {"name": "Klutz",           "name_fr": "Maladresse",        "desc": "Cannot use held items (can still Fling them).", "gen": 4, "hooks": []},
    "mold_breaker":    {"name": "Mold Breaker",    "name_fr": "Brise Moule",       "desc": "Moves ignore the target's ability.", "gen": 4, "hooks": ["on_switch_in", "modify_damage"]},
    "super_luck":      {"name": "Super Luck",      "name_fr": "Chance",            "desc": "Raises critical-hit ratio by one stage.", "gen": 4, "hooks": ["modify_damage"]},
    "aftermath":       {"name": "Aftermath",       "name_fr": "Boom Final",        "desc": "Deals 1/4 HP damage to attacker if KO'd by contact.", "gen": 4, "hooks": ["on_after_contact"]},
    "anticipation":    {"name": "Anticipation",    "name_fr": "Anticipation",      "desc": "Warns if foe has a super-effective or OHKO move.", "gen": 4, "hooks": ["on_switch_in"]},
    "forewarn":        {"name": "Forewarn",        "name_fr": "Prescience",        "desc": "Reveals the foe's strongest move on entry.", "gen": 4, "hooks": ["on_switch_in"]},
    "unaware":         {"name": "Unaware",         "name_fr": "Inconscient",       "desc": "Ignores the target's stat changes.", "gen": 4, "hooks": ["modify_stat"]},
    "tinted_lens":     {"name": "Tinted Lens",     "name_fr": "Lentiteintée",      "desc": "Doubles the power of not-very-effective moves.", "gen": 4, "hooks": ["modify_damage"]},
    "filter":          {"name": "Filter",          "name_fr": "Filtre",            "desc": "Reduces super-effective damage by 25%.", "gen": 4, "hooks": ["modify_damage"]},
    "slow_start":      {"name": "Slow Start",      "name_fr": "Début Calme",       "desc": "Halves Attack and Speed for the first 5 turns.", "gen": 4, "hooks": ["on_switch_in", "modify_stat", "modify_speed", "on_end_of_turn"]},
    "scrappy":         {"name": "Scrappy",         "name_fr": "Querelleur",        "desc": "Normal/Fighting moves can hit Ghost types.", "gen": 4, "hooks": ["modify_damage"]},
    "storm_drain":     {"name": "Storm Drain",     "name_fr": "Absorbeur",         "desc": "Draws Water moves; boosts Sp. Atk instead of taking damage.", "gen": 4, "hooks": ["on_before_hit", "modify_stat"]},
    "ice_body":        {"name": "Ice Body",        "name_fr": "Corps Gel",         "desc": "Recovers 1/16 HP per turn in hail. Immune to hail.", "gen": 4, "hooks": ["on_end_of_turn", "on_weather"]},
    "solid_rock":      {"name": "Solid Rock",      "name_fr": "Roche Solide",      "desc": "Reduces super-effective damage by 25%.", "gen": 4, "hooks": ["modify_damage"]},
    "snow_warning":    {"name": "Snow Warning",    "name_fr": "Alerte Neige",      "desc": "Summons hail/snow on entry.", "gen": 4, "hooks": ["on_switch_in", "on_weather"]},
    "honey_gather":    {"name": "Honey Gather",    "name_fr": "Cherche Miel",      "desc": "May gather Honey after battle. No battle effect.", "gen": 4, "hooks": []},
    "frisk":           {"name": "Frisk",           "name_fr": "Fouille",           "desc": "Reveals the foe's held item on entry.", "gen": 4, "hooks": ["on_switch_in"]},
    "reckless":        {"name": "Reckless",        "name_fr": "Témérité",          "desc": "Boosts recoil moves by 20%.", "gen": 4, "hooks": ["modify_damage"]},
    "multitype":       {"name": "Multitype",       "name_fr": "Multitype",         "desc": "Changes Arceus's type based on held Plate.", "gen": 4, "hooks": ["on_switch_in"]},
    "flower_gift":     {"name": "Flower Gift",     "name_fr": "Don Floral",        "desc": "Boosts Attack and Sp. Def of allies in sun.", "gen": 4, "hooks": ["modify_stat", "on_weather"]},
    "bad_dreams":      {"name": "Bad Dreams",      "name_fr": "Mauvais Rêve",      "desc": "Reduces sleeping foes' HP by 1/8 each turn.", "gen": 4, "hooks": ["on_end_of_turn"]},

    # =====================================================================
    # GENERATION 5 — Black / White / B2W2  (abilities #124-164)
    # =====================================================================
    "pickpocket":      {"name": "Pickpocket",      "name_fr": "Pickpocket",        "desc": "Steals the attacker's item on contact.", "gen": 5, "hooks": ["on_after_contact"]},
    "sheer_force":     {"name": "Sheer Force",     "name_fr": "Sans Limite",       "desc": "Removes secondary effects to boost move power by 30%.", "gen": 5, "hooks": ["modify_damage"]},
    "contrary":        {"name": "Contrary",        "name_fr": "Esprit Contraire",  "desc": "Inverts all stat changes.", "gen": 5, "hooks": ["modify_stat"]},
    "unnerve":         {"name": "Unnerve",         "name_fr": "Tension",           "desc": "Prevents foes from eating Berries.", "gen": 5, "hooks": ["on_switch_in"]},
    "defiant":         {"name": "Defiant",         "name_fr": "Acharné",           "desc": "Sharply raises Attack when any stat is lowered.", "gen": 5, "hooks": ["modify_stat"]},
    "defeatist":       {"name": "Defeatist",       "name_fr": "Défaitiste",        "desc": "Halves Attack and Sp. Atk below 50% HP.", "gen": 5, "hooks": ["modify_stat"]},
    "cursed_body":     {"name": "Cursed Body",     "name_fr": "Corps Maudit",      "desc": "30% chance to disable the move used on it.", "gen": 5, "hooks": ["on_after_contact"]},
    "healer":          {"name": "Healer",          "name_fr": "Cœur Soin",         "desc": "30% chance to heal an ally's status each turn.", "gen": 5, "hooks": ["on_end_of_turn"]},
    "friend_guard":    {"name": "Friend Guard",    "name_fr": "Garde Amie",        "desc": "Reduces damage to allies by 25%.", "gen": 5, "hooks": ["modify_damage"]},
    "weak_armor":      {"name": "Weak Armor",      "name_fr": "Armure Fragile",    "desc": "Physical hits lower Def but raise Speed by 2.", "gen": 5, "hooks": ["on_before_hit", "modify_stat", "modify_speed"]},
    "heavy_metal":     {"name": "Heavy Metal",     "name_fr": "Métal Lourd",       "desc": "Doubles the Pokemon's weight.", "gen": 5, "hooks": ["modify_stat"]},
    "light_metal":     {"name": "Light Metal",     "name_fr": "Métal Léger",       "desc": "Halves the Pokemon's weight.", "gen": 5, "hooks": ["modify_stat"]},
    "multiscale":      {"name": "Multiscale",      "name_fr": "Multi-Écaille",     "desc": "Halves damage when HP is full.", "gen": 5, "hooks": ["modify_damage"]},
    "toxic_boost":     {"name": "Toxic Boost",     "name_fr": "Boost Poison",      "desc": "Boosts physical moves by 50% when poisoned.", "gen": 5, "hooks": ["modify_damage"]},
    "flare_boost":     {"name": "Flare Boost",     "name_fr": "Boost Brûlure",     "desc": "Boosts special moves by 50% when burned.", "gen": 5, "hooks": ["modify_damage"]},
    "harvest":         {"name": "Harvest",         "name_fr": "Récolte",           "desc": "50% chance to regrow a Berry. 100% in sun.", "gen": 5, "hooks": ["on_end_of_turn", "on_weather"]},
    "telepathy":       {"name": "Telepathy",       "name_fr": "Télépathie",        "desc": "Avoids damage from allies' moves.", "gen": 5, "hooks": ["on_before_hit"]},
    "moody":           {"name": "Moody",           "name_fr": "Lunatique",         "desc": "Raises one random stat +2 and lowers another -1 each turn.", "gen": 5, "hooks": ["on_end_of_turn", "modify_stat"]},
    "overcoat":        {"name": "Overcoat",        "name_fr": "Envelocape",        "desc": "Immune to weather damage and powder/spore moves.", "gen": 5, "hooks": ["on_before_hit", "on_weather"]},
    "poison_touch":    {"name": "Poison Touch",    "name_fr": "Toxitouche",        "desc": "30% chance to poison on contact.", "gen": 5, "hooks": ["on_after_contact"]},
    "regenerator":     {"name": "Regenerator",     "name_fr": "Régénération",      "desc": "Heals 1/3 max HP on switch-out.", "gen": 5, "hooks": ["on_switch_out"]},
    "big_pecks":       {"name": "Big Pecks",       "name_fr": "Poitrail",          "desc": "Prevents Defense from being lowered.", "gen": 5, "hooks": ["prevent_stat_drop"]},
    "sand_rush":       {"name": "Sand Rush",       "name_fr": "Baigne Sable",      "desc": "Doubles Speed in sandstorm. Immune to sandstorm.", "gen": 5, "hooks": ["modify_speed", "on_weather"]},
    "wonder_skin":     {"name": "Wonder Skin",     "name_fr": "Peau Miracle",      "desc": "Status moves have only 50% accuracy against it.", "gen": 5, "hooks": ["modify_accuracy"]},
    "analytic":        {"name": "Analytic",        "name_fr": "Analyste",          "desc": "Boosts move power by 30% when moving last.", "gen": 5, "hooks": ["modify_damage"]},
    "illusion":        {"name": "Illusion",        "name_fr": "Illusion",          "desc": "Enters disguised as the last party member.", "gen": 5, "hooks": ["on_switch_in", "on_before_hit"]},
    "imposter":        {"name": "Imposter",        "name_fr": "Imposteur",         "desc": "Transforms into the opposing Pokemon on entry.", "gen": 5, "hooks": ["on_switch_in"]},
    "infiltrator":     {"name": "Infiltrator",     "name_fr": "Infiltrateur",      "desc": "Bypasses Reflect, Light Screen, Safeguard, Substitute.", "gen": 5, "hooks": ["modify_damage"]},
    "mummy":           {"name": "Mummy",           "name_fr": "Momie",             "desc": "Contact changes the attacker's ability to Mummy.", "gen": 5, "hooks": ["on_after_contact"]},
    "moxie":           {"name": "Moxie",           "name_fr": "Impudence",         "desc": "Raises Attack by 1 stage after KOing a Pokemon.", "gen": 5, "hooks": ["modify_stat"]},
    "justified":       {"name": "Justified",       "name_fr": "Cœur Noble",        "desc": "Raises Attack when hit by a Dark move.", "gen": 5, "hooks": ["on_before_hit", "modify_stat"]},
    "rattled":         {"name": "Rattled",         "name_fr": "Phobique",          "desc": "Bug/Dark/Ghost hits and Intimidate boost Speed.", "gen": 5, "hooks": ["on_before_hit", "modify_speed"]},
    "magic_bounce":    {"name": "Magic Bounce",    "name_fr": "Miroir Magik",      "desc": "Reflects status moves back at the user.", "gen": 5, "hooks": ["on_before_hit"]},
    "sap_sipper":      {"name": "Sap Sipper",      "name_fr": "Herbivore",         "desc": "Immune to Grass moves; boosts Attack when hit by one.", "gen": 5, "hooks": ["on_before_hit", "modify_stat"]},
    "prankster":       {"name": "Prankster",       "name_fr": "Farceur",           "desc": "Status moves gain +1 priority (fail vs Dark types in Gen 7+).", "gen": 5, "hooks": ["modify_speed"]},
    "sand_force":      {"name": "Sand Force",      "name_fr": "Force Sable",       "desc": "Boosts Rock/Ground/Steel moves by 30% in sandstorm.", "gen": 5, "hooks": ["modify_damage", "on_weather"]},
    "iron_barbs":      {"name": "Iron Barbs",      "name_fr": "Épine de Fer",      "desc": "Deals 1/8 HP damage to attacker on contact.", "gen": 5, "hooks": ["on_after_contact"]},
    "zen_mode":        {"name": "Zen Mode",        "name_fr": "Mode Transe",       "desc": "Changes Darmanitan's form below 50% HP.", "gen": 5, "hooks": ["on_end_of_turn"]},
    "victory_star":    {"name": "Victory Star",    "name_fr": "Victorieux",        "desc": "Boosts accuracy of all allies by 10%.", "gen": 5, "hooks": ["modify_accuracy"]},
    "turboblaze":      {"name": "Turboblaze",      "name_fr": "Turbo Brasier",     "desc": "Moves ignore the target's ability.", "gen": 5, "hooks": ["on_switch_in", "modify_damage"]},
    "teravolt":        {"name": "Teravolt",        "name_fr": "Téra Voltage",      "desc": "Moves ignore the target's ability.", "gen": 5, "hooks": ["on_switch_in", "modify_damage"]},

    # =====================================================================
    # GENERATION 6 — X / Y / ORAS  (abilities #165-191)
    # =====================================================================
    "aroma_veil":      {"name": "Aroma Veil",      "name_fr": "Aroma-Voile",       "desc": "Protects allies from Taunt, Torment, Encore, Disable, etc.", "gen": 6, "hooks": ["prevent_status"]},
    "flower_veil":     {"name": "Flower Veil",     "name_fr": "Flora-Voile",       "desc": "Grass-type allies can't have stats lowered or be statused.", "gen": 6, "hooks": ["prevent_stat_drop", "prevent_status"]},
    "cheek_pouch":     {"name": "Cheek Pouch",     "name_fr": "Bajoues",           "desc": "Heals 33% HP when eating a Berry.", "gen": 6, "hooks": ["on_end_of_turn"]},
    "protean":         {"name": "Protean",         "name_fr": "Protéen",           "desc": "Changes type to match the move about to be used (once per switch-in).", "gen": 6, "hooks": ["modify_damage"]},
    "fur_coat":        {"name": "Fur Coat",        "name_fr": "Toison Épaisse",    "desc": "Halves physical damage taken.", "gen": 6, "hooks": ["modify_damage"]},
    "magician":        {"name": "Magician",        "name_fr": "Magicien",          "desc": "Steals the target's item when landing a move.", "gen": 6, "hooks": ["modify_damage"]},
    "bulletproof":     {"name": "Bulletproof",     "name_fr": "Pare-Balles",       "desc": "Immune to ball and bomb moves.", "gen": 6, "hooks": ["on_before_hit"]},
    "competitive":     {"name": "Competitive",     "name_fr": "Battant",           "desc": "Sharply raises Sp. Atk when any stat is lowered.", "gen": 6, "hooks": ["modify_stat"]},
    "strong_jaw":      {"name": "Strong Jaw",      "name_fr": "Mâchoire Forte",    "desc": "Boosts biting moves by 50%.", "gen": 6, "hooks": ["modify_damage"]},
    "refrigerate":     {"name": "Refrigerate",     "name_fr": "Peau Gelée",        "desc": "Normal moves become Ice type with a 20% power boost.", "gen": 6, "hooks": ["modify_damage"]},
    "sweet_veil":      {"name": "Sweet Veil",      "name_fr": "Doux Voile",        "desc": "Prevents allies from falling asleep.", "gen": 6, "hooks": ["prevent_status"]},
    "stance_change":   {"name": "Stance Change",   "name_fr": "Déclic Tactique",   "desc": "Changes Aegislash between Blade and Shield Forme.", "gen": 6, "hooks": ["on_before_hit"]},
    "gale_wings":      {"name": "Gale Wings",      "name_fr": "Ailes Bourrasque",  "desc": "Flying moves gain +1 priority at full HP.", "gen": 6, "hooks": ["modify_speed"]},
    "mega_launcher":   {"name": "Mega Launcher",   "name_fr": "Méga Blaster",      "desc": "Boosts pulse/aura moves by 50%.", "gen": 6, "hooks": ["modify_damage"]},
    "grass_pelt":      {"name": "Grass Pelt",      "name_fr": "Toison Herbue",     "desc": "Boosts Defense by 50% on Grassy Terrain.", "gen": 6, "hooks": ["modify_stat", "on_terrain"]},
    "symbiosis":       {"name": "Symbiosis",       "name_fr": "Symbiose",          "desc": "Passes held item to an ally that uses theirs.", "gen": 6, "hooks": ["on_end_of_turn"]},
    "tough_claws":     {"name": "Tough Claws",     "name_fr": "Griffe Dure",       "desc": "Boosts contact moves by 33%.", "gen": 6, "hooks": ["modify_damage"]},
    "pixilate":        {"name": "Pixilate",        "name_fr": "Peau Féérique",     "desc": "Normal moves become Fairy type with a 20% power boost.", "gen": 6, "hooks": ["modify_damage"]},
    "gooey":           {"name": "Gooey",           "name_fr": "Poisseux",          "desc": "Lowers attacker's Speed by 1 stage on contact.", "gen": 6, "hooks": ["on_after_contact"]},
    "aerilate":        {"name": "Aerilate",        "name_fr": "Peau Céleste",      "desc": "Normal moves become Flying type with a 20% power boost.", "gen": 6, "hooks": ["modify_damage"]},
    "parental_bond":   {"name": "Parental Bond",   "name_fr": "Amour Filial",      "desc": "Attacks twice; second hit does 25% damage.", "gen": 6, "hooks": ["modify_damage"]},
    "dark_aura":       {"name": "Dark Aura",       "name_fr": "Aura Ténébreuse",   "desc": "Boosts all Dark moves on the field by 33%.", "gen": 6, "hooks": ["on_switch_in", "modify_damage"]},
    "fairy_aura":      {"name": "Fairy Aura",      "name_fr": "Aura Féérique",     "desc": "Boosts all Fairy moves on the field by 33%.", "gen": 6, "hooks": ["on_switch_in", "modify_damage"]},
    "aura_break":      {"name": "Aura Break",      "name_fr": "Aura Inversée",     "desc": "Reverses Dark Aura and Fairy Aura effects.", "gen": 6, "hooks": ["on_switch_in", "modify_damage"]},
    "primordial_sea":  {"name": "Primordial Sea",  "name_fr": "Mer Primaire",      "desc": "Sets heavy rain that blocks Fire moves.", "gen": 6, "hooks": ["on_switch_in", "on_weather", "modify_damage"]},
    "desolate_land":   {"name": "Desolate Land",   "name_fr": "Terre Finale",      "desc": "Sets extreme sun that blocks Water moves.", "gen": 6, "hooks": ["on_switch_in", "on_weather", "modify_damage"]},
    "delta_stream":    {"name": "Delta Stream",    "name_fr": "Souffle Delta",     "desc": "Sets strong winds that negate Flying weaknesses.", "gen": 6, "hooks": ["on_switch_in", "on_weather", "modify_damage"]},

    # =====================================================================
    # GENERATION 7 — Sun / Moon / USUM  (abilities #192-233)
    # =====================================================================
    "stamina":           {"name": "Stamina",           "name_fr": "Endurance",           "desc": "Raises Defense by 1 stage when hit.", "gen": 7, "hooks": ["on_before_hit", "modify_stat"]},
    "wimp_out":          {"name": "Wimp Out",          "name_fr": "Déguerpi",            "desc": "Switches out when HP drops below 50%.", "gen": 7, "hooks": ["on_before_hit"]},
    "emergency_exit":    {"name": "Emergency Exit",    "name_fr": "Repli Tactique",      "desc": "Switches out when HP drops below 50%.", "gen": 7, "hooks": ["on_before_hit"]},
    "water_compaction":  {"name": "Water Compaction",  "name_fr": "Sable Humide",        "desc": "Sharply raises Defense when hit by a Water move.", "gen": 7, "hooks": ["on_before_hit", "modify_stat"]},
    "merciless":         {"name": "Merciless",         "name_fr": "Impitoyable",         "desc": "Always crits poisoned targets.", "gen": 7, "hooks": ["modify_damage"]},
    "shields_down":      {"name": "Shields Down",      "name_fr": "Bouclier-Carène",     "desc": "Changes Minior's form below 50% HP. Immune to status while shielded.", "gen": 7, "hooks": ["on_end_of_turn", "prevent_status"]},
    "stakeout":          {"name": "Stakeout",          "name_fr": "Filature",            "desc": "Doubles damage against targets that just switched in.", "gen": 7, "hooks": ["modify_damage"]},
    "water_bubble":      {"name": "Water Bubble",      "name_fr": "Hydro-Bulle",         "desc": "Doubles Water moves, halves Fire damage, prevents burn.", "gen": 7, "hooks": ["modify_damage", "prevent_status"]},
    "steelworker":       {"name": "Steelworker",       "name_fr": "Aciérie",             "desc": "Boosts Steel moves by 50%.", "gen": 7, "hooks": ["modify_damage"]},
    "berserk":           {"name": "Berserk",           "name_fr": "Berserk",             "desc": "Raises Sp. Atk when HP drops below 50%.", "gen": 7, "hooks": ["on_before_hit", "modify_stat"]},
    "slush_rush":        {"name": "Slush Rush",        "name_fr": "Chasse-Neige",        "desc": "Doubles Speed in hail/snow.", "gen": 7, "hooks": ["modify_speed", "on_weather"]},
    "long_reach":        {"name": "Long Reach",        "name_fr": "Long Bec",            "desc": "Attacks never make contact.", "gen": 7, "hooks": ["modify_damage"]},
    "liquid_voice":      {"name": "Liquid Voice",      "name_fr": "Voix Mouillée",       "desc": "Sound moves become Water type.", "gen": 7, "hooks": ["modify_damage"]},
    "triage":            {"name": "Triage",            "name_fr": "Triage",              "desc": "Healing moves gain +3 priority.", "gen": 7, "hooks": ["modify_speed"]},
    "galvanize":         {"name": "Galvanize",         "name_fr": "Peau Électrique",     "desc": "Normal moves become Electric type with a 20% boost.", "gen": 7, "hooks": ["modify_damage"]},
    "surge_surfer":      {"name": "Surge Surfer",      "name_fr": "Surf Caudale",        "desc": "Doubles Speed on Electric Terrain.", "gen": 7, "hooks": ["modify_speed", "on_terrain"]},
    "schooling":         {"name": "Schooling",         "name_fr": "Banc",                "desc": "Wishiwashi forms a school above 25% HP (Lv20+).", "gen": 7, "hooks": ["on_switch_in", "on_end_of_turn"]},
    "disguise":          {"name": "Disguise",          "name_fr": "Déguisement",         "desc": "Blocks one attack, then the disguise breaks.", "gen": 7, "hooks": ["on_before_hit"]},
    "battle_bond":       {"name": "Battle Bond",       "name_fr": "Synergie",            "desc": "Greninja transforms after KOing a foe (boosted stats).", "gen": 7, "hooks": ["modify_stat"]},
    "power_construct":   {"name": "Power Construct",   "name_fr": "Rassemblement",       "desc": "Zygarde transforms to Complete Forme below 50% HP.", "gen": 7, "hooks": ["on_end_of_turn"]},
    "corrosion":         {"name": "Corrosion",         "name_fr": "Corrosion",           "desc": "Can poison Steel and Poison types.", "gen": 7, "hooks": ["modify_damage"]},
    "comatose":          {"name": "Comatose",          "name_fr": "Coma",                "desc": "Always considered asleep but can still attack. Immune to other statuses.", "gen": 7, "hooks": ["prevent_status", "modify_damage"]},
    "queenly_majesty":   {"name": "Queenly Majesty",   "name_fr": "Prestance Royale",    "desc": "Blocks opponents' priority moves.", "gen": 7, "hooks": ["on_before_hit"]},
    "innards_out":       {"name": "Innards Out",       "name_fr": "Expuls'Organes",      "desc": "When KO'd, deals damage equal to last HP to the attacker.", "gen": 7, "hooks": ["on_before_hit"]},
    "dancer":            {"name": "Dancer",            "name_fr": "Danseuse",            "desc": "Copies any dance move used by another Pokemon.", "gen": 7, "hooks": ["modify_damage"]},
    "battery":           {"name": "Battery",           "name_fr": "Batterie",            "desc": "Boosts allies' special moves by 30%.", "gen": 7, "hooks": ["modify_damage"]},
    "fluffy":            {"name": "Fluffy",            "name_fr": "Boule de Poils",      "desc": "Halves contact damage, but doubles Fire damage.", "gen": 7, "hooks": ["modify_damage"]},
    "dazzling":          {"name": "Dazzling",          "name_fr": "Corps Coloré",        "desc": "Blocks opponents' priority moves.", "gen": 7, "hooks": ["on_before_hit"]},
    "soul_heart":        {"name": "Soul-Heart",        "name_fr": "Animacœur",           "desc": "Raises Sp. Atk by 1 stage whenever any Pokemon faints.", "gen": 7, "hooks": ["modify_stat"]},
    "tangling_hair":     {"name": "Tangling Hair",     "name_fr": "Mèches Rebelles",     "desc": "Lowers attacker's Speed by 1 on contact.", "gen": 7, "hooks": ["on_after_contact"]},
    "receiver":          {"name": "Receiver",          "name_fr": "Receveur",            "desc": "Inherits a fainted ally's ability.", "gen": 7, "hooks": ["on_switch_in"]},
    "power_of_alchemy":  {"name": "Power of Alchemy",  "name_fr": "Alchimie",           "desc": "Inherits a fainted ally's ability.", "gen": 7, "hooks": ["on_switch_in"]},
    "beast_boost":       {"name": "Beast Boost",       "name_fr": "Ultra-Boost",         "desc": "Raises highest stat by 1 stage after KOing a Pokemon.", "gen": 7, "hooks": ["modify_stat"]},
    "rks_system":        {"name": "RKS System",        "name_fr": "Système Alpha",       "desc": "Changes Silvally's type based on held Memory.", "gen": 7, "hooks": ["on_switch_in"]},
    "electric_surge":    {"name": "Electric Surge",    "name_fr": "Créa-Élec",           "desc": "Sets Electric Terrain on entry.", "gen": 7, "hooks": ["on_switch_in", "on_terrain"]},
    "psychic_surge":     {"name": "Psychic Surge",     "name_fr": "Créa-Psy",            "desc": "Sets Psychic Terrain on entry.", "gen": 7, "hooks": ["on_switch_in", "on_terrain"]},
    "misty_surge":       {"name": "Misty Surge",       "name_fr": "Créa-Brume",          "desc": "Sets Misty Terrain on entry.", "gen": 7, "hooks": ["on_switch_in", "on_terrain"]},
    "grassy_surge":      {"name": "Grassy Surge",      "name_fr": "Créa-Herbe",          "desc": "Sets Grassy Terrain on entry.", "gen": 7, "hooks": ["on_switch_in", "on_terrain"]},
    "full_metal_body":   {"name": "Full Metal Body",   "name_fr": "Métallo-Garde",       "desc": "Prevents stat reductions from other Pokemon.", "gen": 7, "hooks": ["prevent_stat_drop"]},
    "shadow_shield":     {"name": "Shadow Shield",     "name_fr": "Spectro-Bouclier",    "desc": "Halves damage when HP is full.", "gen": 7, "hooks": ["modify_damage"]},
    "prism_armor":       {"name": "Prism Armor",       "name_fr": "Prisme-Armure",       "desc": "Reduces super-effective damage by 25%.", "gen": 7, "hooks": ["modify_damage"]},
    "neuroforce":        {"name": "Neuroforce",        "name_fr": "Neuro-Force",         "desc": "Boosts super-effective moves by 25%.", "gen": 7, "hooks": ["modify_damage"]},

    # =====================================================================
    # GENERATION 8 — Sword / Shield + DLC  (abilities #234-267)
    # =====================================================================
    "intrepid_sword":     {"name": "Intrepid Sword",     "name_fr": "Lame Indomptable",     "desc": "Raises Attack by 1 stage on entry (once per battle).", "gen": 8, "hooks": ["on_switch_in", "modify_stat"]},
    "dauntless_shield":   {"name": "Dauntless Shield",   "name_fr": "Bouclier Ferme",       "desc": "Raises Defense by 1 stage on entry (once per battle).", "gen": 8, "hooks": ["on_switch_in", "modify_stat"]},
    "libero":             {"name": "Libero",             "name_fr": "Libéro",               "desc": "Changes type to match the move about to be used (once per switch-in).", "gen": 8, "hooks": ["modify_damage"]},
    "ball_fetch":         {"name": "Ball Fetch",         "name_fr": "Ramasse Ball",         "desc": "Retrieves first failed Poké Ball. No competitive effect.", "gen": 8, "hooks": []},
    "cotton_down":        {"name": "Cotton Down",        "name_fr": "Effilochage",          "desc": "Lowers Speed of all other Pokemon when hit.", "gen": 8, "hooks": ["on_before_hit"]},
    "propeller_tail":     {"name": "Propeller Tail",     "name_fr": "Hélice Caudale",       "desc": "Ignores redirection (Follow Me, Storm Drain, etc.).", "gen": 8, "hooks": ["modify_damage"]},
    "mirror_armor":       {"name": "Mirror Armor",       "name_fr": "Armure Miroir",        "desc": "Bounces back stat-lowering effects.", "gen": 8, "hooks": ["prevent_stat_drop"]},
    "gulp_missile":       {"name": "Gulp Missile",       "name_fr": "Eng-Loutissement",     "desc": "Catches prey with Surf/Dive; spits it at attackers.", "gen": 8, "hooks": ["on_before_hit", "on_after_contact"]},
    "stalwart":           {"name": "Stalwart",           "name_fr": "Nerfs d'Acier",        "desc": "Ignores redirection.", "gen": 8, "hooks": ["modify_damage"]},
    "steam_engine":       {"name": "Steam Engine",       "name_fr": "Machine à Vapeur",     "desc": "Drastically raises Speed when hit by Fire or Water.", "gen": 8, "hooks": ["on_before_hit", "modify_speed"]},
    "punk_rock":          {"name": "Punk Rock",          "name_fr": "Punk Rock",            "desc": "Boosts sound moves by 30% and halves sound damage taken.", "gen": 8, "hooks": ["modify_damage"]},
    "sand_spit":          {"name": "Sand Spit",          "name_fr": "Crache-Sable",         "desc": "Summons sandstorm when hit by an attack.", "gen": 8, "hooks": ["on_before_hit", "on_weather"]},
    "ice_scales":         {"name": "Ice Scales",         "name_fr": "Écailles Glacées",     "desc": "Halves special damage taken.", "gen": 8, "hooks": ["modify_damage"]},
    "ripen":              {"name": "Ripen",              "name_fr": "Maturité",             "desc": "Doubles Berry effects.", "gen": 8, "hooks": ["on_end_of_turn"]},
    "ice_face":           {"name": "Ice Face",           "name_fr": "Tête de Gel",          "desc": "Blocks one physical hit. Reforms in hail/snow.", "gen": 8, "hooks": ["on_before_hit", "on_weather"]},
    "power_spot":         {"name": "Power Spot",         "name_fr": "Point Énergie",        "desc": "Boosts allies' moves by 30%.", "gen": 8, "hooks": ["modify_damage"]},
    "mimicry":            {"name": "Mimicry",            "name_fr": "Mimétisme",            "desc": "Changes type based on active terrain.", "gen": 8, "hooks": ["on_switch_in", "on_terrain"]},
    "screen_cleaner":     {"name": "Screen Cleaner",     "name_fr": "Brise-Écran",          "desc": "Removes screens (Reflect, Light Screen, Aurora Veil) on entry.", "gen": 8, "hooks": ["on_switch_in"]},
    "steely_spirit":      {"name": "Steely Spirit",      "name_fr": "Esprit d'Acier",       "desc": "Boosts allies' Steel moves by 50%.", "gen": 8, "hooks": ["modify_damage"]},
    "perish_body":        {"name": "Perish Body",        "name_fr": "Corps Condamné",       "desc": "Both Pokemon get perish count on contact.", "gen": 8, "hooks": ["on_after_contact"]},
    "wandering_spirit":   {"name": "Wandering Spirit",   "name_fr": "Âme Vagabonde",        "desc": "Swaps abilities with attacker on contact.", "gen": 8, "hooks": ["on_after_contact"]},
    "gorilla_tactics":    {"name": "Gorilla Tactics",    "name_fr": "Gorille Tactique",     "desc": "Boosts Attack by 50% but locks into one move.", "gen": 8, "hooks": ["modify_stat"]},
    "neutralizing_gas":   {"name": "Neutralizing Gas",   "name_fr": "Gaz Inhibiteur",       "desc": "Suppresses all other abilities while on the field.", "gen": 8, "hooks": ["on_switch_in"]},
    "pastel_veil":        {"name": "Pastel Veil",        "name_fr": "Voile Pastel",         "desc": "Prevents self and allies from being poisoned.", "gen": 8, "hooks": ["prevent_status", "on_switch_in"]},
    "hunger_switch":      {"name": "Hunger Switch",      "name_fr": "Déclic Fringale",      "desc": "Changes Morpeko's form each turn.", "gen": 8, "hooks": ["on_end_of_turn"]},
    "quick_draw":         {"name": "Quick Draw",         "name_fr": "Tir Vif",              "desc": "30% chance to act first.", "gen": 8, "hooks": ["modify_speed"]},
    "unseen_fist":        {"name": "Unseen Fist",        "name_fr": "Poing Invisible",      "desc": "Contact moves bypass Protect.", "gen": 8, "hooks": ["modify_damage"]},
    "curious_medicine":   {"name": "Curious Medicine",   "name_fr": "Breuvage Suspect",     "desc": "Resets allies' stat changes on entry.", "gen": 8, "hooks": ["on_switch_in"]},
    "transistor":         {"name": "Transistor",         "name_fr": "Transistor",           "desc": "Boosts Electric moves by 30% (50% pre-Gen 9).", "gen": 8, "hooks": ["modify_damage"]},
    "dragons_maw":        {"name": "Dragon's Maw",       "name_fr": "Dent de Dragon",       "desc": "Boosts Dragon moves by 50%.", "gen": 8, "hooks": ["modify_damage"]},
    "chilling_neigh":     {"name": "Chilling Neigh",     "name_fr": "Blanche Ruade",        "desc": "Raises Attack after KOing a Pokemon.", "gen": 8, "hooks": ["modify_stat"]},
    "grim_neigh":         {"name": "Grim Neigh",         "name_fr": "Sombre Ruade",         "desc": "Raises Sp. Atk after KOing a Pokemon.", "gen": 8, "hooks": ["modify_stat"]},
    "as_one_ice":         {"name": "As One (Ice Rider)",     "name_fr": "Unisson (Cavalier du Froid)",    "desc": "Combines Unnerve + Chilling Neigh.", "gen": 8, "hooks": ["on_switch_in", "modify_stat"]},
    "as_one_shadow":      {"name": "As One (Shadow Rider)",  "name_fr": "Unisson (Cavalier d'Effroi)",   "desc": "Combines Unnerve + Grim Neigh.", "gen": 8, "hooks": ["on_switch_in", "modify_stat"]},

    # =====================================================================
    # GENERATION 9 — Scarlet / Violet + DLC  (abilities #268-310)
    # =====================================================================
    "lingering_aroma":           {"name": "Lingering Aroma",           "name_fr": "Odeur Tenace",              "desc": "Contact changes attacker's ability to Lingering Aroma.", "gen": 9, "hooks": ["on_after_contact"]},
    "seed_sower":                {"name": "Seed Sower",                "name_fr": "Semeur de Graines",         "desc": "Sets Grassy Terrain when hit.", "gen": 9, "hooks": ["on_before_hit", "on_terrain"]},
    "thermal_exchange":          {"name": "Thermal Exchange",          "name_fr": "Conversion Thermique",      "desc": "Raises Attack when hit by Fire. Immune to burn.", "gen": 9, "hooks": ["on_before_hit", "modify_stat", "prevent_status"]},
    "anger_shell":               {"name": "Anger Shell",               "name_fr": "Carapace d'Ire",            "desc": "Below 50% HP: lowers Def/Sp.Def, raises Atk/Sp.Atk/Speed.", "gen": 9, "hooks": ["on_before_hit", "modify_stat"]},
    "purifying_salt":            {"name": "Purifying Salt",            "name_fr": "Sel Purificateur",          "desc": "Immune to status. Halves Ghost damage.", "gen": 9, "hooks": ["prevent_status", "modify_damage"]},
    "well_baked_body":           {"name": "Well-Baked Body",           "name_fr": "Corps Bien Cuit",           "desc": "Immune to Fire; sharply raises Defense when hit by Fire.", "gen": 9, "hooks": ["on_before_hit", "modify_stat"]},
    "wind_rider":                {"name": "Wind Rider",                "name_fr": "Aérodynamique",             "desc": "Immune to wind moves; raises Attack from Tailwind.", "gen": 9, "hooks": ["on_before_hit", "modify_stat"]},
    "guard_dog":                 {"name": "Guard Dog",                 "name_fr": "Chien de Garde",            "desc": "Intimidate boosts Attack instead. Cannot be forced out.", "gen": 9, "hooks": ["prevent_stat_drop", "modify_stat"]},
    "rocky_payload":             {"name": "Rocky Payload",             "name_fr": "Charge Rocheuse",           "desc": "Boosts Rock moves by 50%.", "gen": 9, "hooks": ["modify_damage"]},
    "wind_power":                {"name": "Wind Power",                "name_fr": "Énergie Éolienne",          "desc": "Gains Charge when hit by a wind move (boosts next Electric move).", "gen": 9, "hooks": ["on_before_hit", "modify_damage"]},
    "zero_to_hero":              {"name": "Zero to Hero",              "name_fr": "Supermutation",             "desc": "Palafin transforms into Hero Form on switch-out/in.", "gen": 9, "hooks": ["on_switch_out", "on_switch_in"]},
    "commander":                 {"name": "Commander",                 "name_fr": "Commandant",                "desc": "Enters Dondozo in Doubles, boosting all its stats.", "gen": 9, "hooks": ["on_switch_in", "modify_stat"]},
    "electromorphosis":          {"name": "Electromorphosis",          "name_fr": "Électromorphose",           "desc": "Gains Charge when hit by any attack.", "gen": 9, "hooks": ["on_before_hit", "modify_damage"]},
    "protosynthesis":            {"name": "Protosynthesis",            "name_fr": "Paléosynthèse",             "desc": "Boosts highest stat in sun or with Booster Energy.", "gen": 9, "hooks": ["on_switch_in", "modify_stat", "on_weather"]},
    "quark_drive":               {"name": "Quark Drive",               "name_fr": "Activation Quantique",      "desc": "Boosts highest stat on Electric Terrain or with Booster Energy.", "gen": 9, "hooks": ["on_switch_in", "modify_stat", "on_terrain"]},
    "good_as_gold":              {"name": "Good as Gold",              "name_fr": "Corps en Or",               "desc": "Immune to status moves.", "gen": 9, "hooks": ["on_before_hit", "prevent_status"]},
    "vessel_of_ruin":            {"name": "Vessel of Ruin",            "name_fr": "Vase de Ruine",             "desc": "Lowers all other Pokemon's Sp. Atk by 25%.", "gen": 9, "hooks": ["on_switch_in", "modify_stat"]},
    "sword_of_ruin":             {"name": "Sword of Ruin",             "name_fr": "Épée de Ruine",             "desc": "Lowers all other Pokemon's Defense by 25%.", "gen": 9, "hooks": ["on_switch_in", "modify_stat"]},
    "tablets_of_ruin":           {"name": "Tablets of Ruin",           "name_fr": "Tablettes de Ruine",        "desc": "Lowers all other Pokemon's Attack by 25%.", "gen": 9, "hooks": ["on_switch_in", "modify_stat"]},
    "beads_of_ruin":             {"name": "Beads of Ruin",             "name_fr": "Perles de Ruine",           "desc": "Lowers all other Pokemon's Sp. Def by 25%.", "gen": 9, "hooks": ["on_switch_in", "modify_stat"]},
    "orichalcum_pulse":          {"name": "Orichalcum Pulse",          "name_fr": "Pouls d'Orichalque",        "desc": "Sets sun on entry; boosts Attack 1.3x in sun.", "gen": 9, "hooks": ["on_switch_in", "modify_stat", "on_weather"]},
    "hadron_engine":             {"name": "Hadron Engine",             "name_fr": "Moteur à Hadrons",          "desc": "Sets Electric Terrain on entry; boosts Sp. Atk 1.3x on it.", "gen": 9, "hooks": ["on_switch_in", "modify_stat", "on_terrain"]},
    "opportunist":               {"name": "Opportunist",               "name_fr": "Opportuniste",              "desc": "Copies any stat boosts the opponent gains.", "gen": 9, "hooks": ["modify_stat"]},
    "cud_chew":                  {"name": "Cud Chew",                  "name_fr": "Rumination",                "desc": "Eats consumed Berry again at end of next turn.", "gen": 9, "hooks": ["on_end_of_turn"]},
    "sharpness":                 {"name": "Sharpness",                 "name_fr": "Lame Aiguisée",             "desc": "Boosts slicing moves by 50%.", "gen": 9, "hooks": ["modify_damage"]},
    "supreme_overlord":          {"name": "Supreme Overlord",          "name_fr": "Généralissime",             "desc": "Boosts Atk/Sp.Atk by 10% per fainted party member.", "gen": 9, "hooks": ["on_switch_in", "modify_damage"]},
    "costar":                    {"name": "Costar",                    "name_fr": "Partenariat",               "desc": "Copies ally's stat changes on entry.", "gen": 9, "hooks": ["on_switch_in", "modify_stat"]},
    "toxic_debris":              {"name": "Toxic Debris",              "name_fr": "Débris Toxiques",           "desc": "Sets Toxic Spikes when hit by a physical move.", "gen": 9, "hooks": ["on_before_hit"]},
    "armor_tail":                {"name": "Armor Tail",                "name_fr": "Queue Armurée",             "desc": "Blocks opponents' priority moves.", "gen": 9, "hooks": ["on_before_hit"]},
    "earth_eater":               {"name": "Earth Eater",               "name_fr": "Géophagie",                 "desc": "Immune to Ground; heals HP when hit by Ground.", "gen": 9, "hooks": ["on_before_hit"]},
    "mycelium_might":            {"name": "Mycelium Might",            "name_fr": "Force Fongique",            "desc": "Status moves ignore abilities but always move last.", "gen": 9, "hooks": ["modify_speed", "modify_damage"]},
    "minds_eye":                 {"name": "Mind's Eye",                "name_fr": "Œil Mental",                "desc": "Ignores evasion; Normal/Fighting hit Ghost types.", "gen": 9, "hooks": ["modify_accuracy", "modify_damage"]},
    "supersweet_syrup":          {"name": "Supersweet Syrup",          "name_fr": "Sirop Doux",                "desc": "Lowers foes' evasion on first entry.", "gen": 9, "hooks": ["on_switch_in"]},
    "hospitality":               {"name": "Hospitality",               "name_fr": "Hospitalité",               "desc": "Heals ally for 25% of their max HP on entry.", "gen": 9, "hooks": ["on_switch_in"]},
    "toxic_chain":               {"name": "Toxic Chain",               "name_fr": "Chaîne Toxique",            "desc": "30% chance to badly poison when attacking.", "gen": 9, "hooks": ["modify_damage"]},
    "embody_aspect_teal":        {"name": "Embody Aspect (Teal Mask)",        "name_fr": "Incarnation (Masque Turquoise)",   "desc": "Raises Speed on entry.", "gen": 9, "hooks": ["on_switch_in", "modify_speed"]},
    "embody_aspect_wellspring":  {"name": "Embody Aspect (Wellspring Mask)",  "name_fr": "Incarnation (Masque du Puits)",    "desc": "Raises Sp. Def on entry.", "gen": 9, "hooks": ["on_switch_in", "modify_stat"]},
    "embody_aspect_hearthflame": {"name": "Embody Aspect (Hearthflame Mask)", "name_fr": "Incarnation (Masque du Fourneau)", "desc": "Raises Attack on entry.", "gen": 9, "hooks": ["on_switch_in", "modify_stat"]},
    "embody_aspect_cornerstone": {"name": "Embody Aspect (Cornerstone Mask)", "name_fr": "Incarnation (Masque de la Pierre)","desc": "Raises Defense on entry.", "gen": 9, "hooks": ["on_switch_in", "modify_stat"]},
    "tera_shift":                {"name": "Tera Shift",                "name_fr": "Téra-Morphose",             "desc": "Changes Terapagos to Terastal Form on entry.", "gen": 9, "hooks": ["on_switch_in"]},
    "tera_shell":                {"name": "Tera Shell",                "name_fr": "Téra-Carapace",             "desc": "All moves are not very effective at full HP.", "gen": 9, "hooks": ["modify_damage"]},
    "teraform_zero":             {"name": "Teraform Zero",             "name_fr": "Téra-Formation Zéro",       "desc": "Removes all weather and terrain effects.", "gen": 9, "hooks": ["on_switch_in", "on_weather", "on_terrain"]},
    "poison_puppeteer":          {"name": "Poison Puppeteer",          "name_fr": "Empoisonneur",              "desc": "Pecharunt's exclusive. Poisoned foes also become confused.", "gen": 9, "hooks": ["modify_damage"]},
}


def main():
    valid_hooks = {
        "on_switch_in", "on_switch_out", "on_before_hit", "on_after_contact",
        "on_end_of_turn", "modify_damage", "modify_stat", "prevent_status",
        "prevent_stat_drop", "prevent_crit", "modify_speed", "modify_accuracy",
        "on_weather", "on_terrain"
    }

    # Validate
    errors = 0
    for aid, data in ABILITIES.items():
        for hook in data.get("hooks", []):
            if hook not in valid_hooks:
                print(f"ERROR: Invalid hook '{hook}' in '{aid}'")
                errors += 1
        for field in ("name", "name_fr", "desc", "gen", "hooks"):
            if field not in data:
                print(f"ERROR: Missing '{field}' in '{aid}'")
                errors += 1

    if errors:
        print(f"\n{errors} error(s) found. Aborting.")
        return

    # Stats
    gen_counts = {}
    for data in ABILITIES.values():
        g = data["gen"]
        gen_counts[g] = gen_counts.get(g, 0) + 1

    # Write
    out = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data", "abilities.json")
    os.makedirs(os.path.dirname(out), exist_ok=True)

    with open(out, "w", encoding="utf-8") as f:
        json.dump(ABILITIES, f, indent=2, ensure_ascii=False)

    print(f"Generated: {out}")
    print(f"Total abilities: {len(ABILITIES)}")
    print("By generation:")
    for g in sorted(gen_counts):
        print(f"  Gen {g}: {gen_counts[g]}")


if __name__ == "__main__":
    main()
