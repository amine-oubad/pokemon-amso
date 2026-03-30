#!/usr/bin/env python3
"""Add new moves and update existing ones in moves.json."""
import json, os

path = os.path.join(os.path.dirname(__file__), '..', 'data', 'moves.json')
with open(path, encoding='utf-8') as f:
    data = json.load(f)

# === New moves to add ===
new_moves = {
    "double_edge": {"name":"Double-Edge","type":"Normal","category":"physical","power":120,"accuracy":100,"pp":15,"priority":0,"effect":"recoil_third","effect_chance":100},
    "brave_bird": {"name":"Brave Bird","type":"Flying","category":"physical","power":120,"accuracy":100,"pp":15,"priority":0,"effect":"recoil_third","effect_chance":100},
    "flare_blitz": {"name":"Flare Blitz","type":"Fire","category":"physical","power":120,"accuracy":100,"pp":15,"priority":0,"effect":"recoil_third","effect_chance":100},
    "volt_tackle": {"name":"Volt Tackle","type":"Electric","category":"physical","power":120,"accuracy":100,"pp":15,"priority":0,"effect":"recoil_third","effect_chance":100},
    "wild_charge": {"name":"Wild Charge","type":"Electric","category":"physical","power":90,"accuracy":100,"pp":15,"priority":0,"effect":"recoil_quarter","effect_chance":100},
    "wood_hammer": {"name":"Wood Hammer","type":"Grass","category":"physical","power":120,"accuracy":100,"pp":15,"priority":0,"effect":"recoil_third","effect_chance":100},
    "giga_drain": {"name":"Giga Drain","type":"Grass","category":"special","power":75,"accuracy":100,"pp":10,"priority":0,"effect":"drain_half","effect_chance":100},
    "drain_punch": {"name":"Drain Punch","type":"Fighting","category":"physical","power":75,"accuracy":100,"pp":10,"priority":0,"effect":"drain_half","effect_chance":100},
    "leech_life": {"name":"Leech Life","type":"Bug","category":"physical","power":80,"accuracy":100,"pp":10,"priority":0,"effect":"drain_half","effect_chance":100},
    "bullet_seed": {"name":"Bullet Seed","type":"Grass","category":"physical","power":25,"accuracy":100,"pp":30,"priority":0,"effect":"multi_hit_2_5","effect_chance":100},
    "rock_blast": {"name":"Rock Blast","type":"Rock","category":"physical","power":25,"accuracy":90,"pp":10,"priority":0,"effect":"multi_hit_2_5","effect_chance":100},
    "icicle_spear": {"name":"Icicle Spear","type":"Ice","category":"physical","power":25,"accuracy":100,"pp":30,"priority":0,"effect":"multi_hit_2_5","effect_chance":100},
    "stealth_rock": {"name":"Stealth Rock","type":"Rock","category":"status","power":0,"accuracy":0,"pp":20,"priority":0,"effect":"stealth_rock","effect_chance":100},
    "spikes": {"name":"Spikes","type":"Ground","category":"status","power":0,"accuracy":0,"pp":20,"priority":0,"effect":"spikes","effect_chance":100},
    "toxic_spikes": {"name":"Toxic Spikes","type":"Poison","category":"status","power":0,"accuracy":0,"pp":20,"priority":0,"effect":"toxic_spikes","effect_chance":100},
    "defog": {"name":"Defog","type":"Flying","category":"status","power":0,"accuracy":0,"pp":15,"priority":0,"effect":"defog","effect_chance":100},
    "reflect": {"name":"Reflect","type":"Psychic","category":"status","power":0,"accuracy":0,"pp":20,"priority":0,"effect":"reflect","effect_chance":100},
    "light_screen": {"name":"Light Screen","type":"Psychic","category":"status","power":0,"accuracy":0,"pp":30,"priority":0,"effect":"light_screen","effect_chance":100},
    "sunny_day": {"name":"Sunny Day","type":"Fire","category":"status","power":0,"accuracy":0,"pp":5,"priority":0,"effect":"sunny_day","effect_chance":100},
    "sandstorm": {"name":"Sandstorm","type":"Rock","category":"status","power":0,"accuracy":0,"pp":10,"priority":0,"effect":"sandstorm","effect_chance":100},
    "hail": {"name":"Hail","type":"Ice","category":"status","power":0,"accuracy":0,"pp":10,"priority":0,"effect":"hail","effect_chance":100},
    "dragon_dance": {"name":"Dragon Dance","type":"Dragon","category":"status","power":0,"accuracy":0,"pp":20,"priority":0,"effect":"dragon_dance","effect_chance":100},
    "bulk_up": {"name":"Bulk Up","type":"Fighting","category":"status","power":0,"accuracy":0,"pp":20,"priority":0,"effect":"bulk_up","effect_chance":100},
    "calm_mind": {"name":"Calm Mind","type":"Psychic","category":"status","power":0,"accuracy":0,"pp":20,"priority":0,"effect":"calm_mind","effect_chance":100},
    "nasty_plot": {"name":"Nasty Plot","type":"Dark","category":"status","power":0,"accuracy":0,"pp":20,"priority":0,"effect":"raise_self_spatk_2","effect_chance":100},
    "belly_drum": {"name":"Belly Drum","type":"Normal","category":"status","power":0,"accuracy":0,"pp":10,"priority":0,"effect":"belly_drum","effect_chance":100},
    "curse": {"name":"Curse","type":"Ghost","category":"status","power":0,"accuracy":0,"pp":10,"priority":0,"effect":"curse","effect_chance":100},
    "toxic": {"name":"Toxic","type":"Poison","category":"status","power":0,"accuracy":90,"pp":10,"priority":0,"effect":"bad_poison","effect_chance":100},
    "will_o_wisp": {"name":"Will-O-Wisp","type":"Fire","category":"status","power":0,"accuracy":85,"pp":15,"priority":0,"effect":"burn","effect_chance":100},
    "taunt": {"name":"Taunt","type":"Dark","category":"status","power":0,"accuracy":100,"pp":20,"priority":0,"effect":"taunt","effect_chance":100},
    "encore": {"name":"Encore","type":"Normal","category":"status","power":0,"accuracy":100,"pp":5,"priority":0,"effect":"encore","effect_chance":100},
    "knock_off": {"name":"Knock Off","type":"Dark","category":"physical","power":65,"accuracy":100,"pp":20,"priority":0,"effect":"knock_off","effect_chance":100},
    "wish": {"name":"Wish","type":"Normal","category":"status","power":0,"accuracy":0,"pp":10,"priority":0,"effect":"wish","effect_chance":100},
    "pain_split": {"name":"Pain Split","type":"Normal","category":"status","power":0,"accuracy":0,"pp":20,"priority":0,"effect":"pain_split","effect_chance":100},
    "facade": {"name":"Facade","type":"Normal","category":"physical","power":70,"accuracy":100,"pp":20,"priority":0,"effect":"facade","effect_chance":100},
    "extreme_speed": {"name":"Extreme Speed","type":"Normal","category":"physical","power":80,"accuracy":100,"pp":5,"priority":2,"effect":None,"effect_chance":0},
    "mach_punch": {"name":"Mach Punch","type":"Fighting","category":"physical","power":40,"accuracy":100,"pp":30,"priority":1,"effect":None,"effect_chance":0},
    "bullet_punch": {"name":"Bullet Punch","type":"Steel","category":"physical","power":40,"accuracy":100,"pp":30,"priority":1,"effect":None,"effect_chance":0},
    "ice_shard": {"name":"Ice Shard","type":"Ice","category":"physical","power":40,"accuracy":100,"pp":30,"priority":1,"effect":None,"effect_chance":0},
    "aqua_jet": {"name":"Aqua Jet","type":"Water","category":"physical","power":40,"accuracy":100,"pp":20,"priority":1,"effect":None,"effect_chance":0},
    "shadow_sneak": {"name":"Shadow Sneak","type":"Ghost","category":"physical","power":40,"accuracy":100,"pp":30,"priority":1,"effect":None,"effect_chance":0},
    "sucker_punch": {"name":"Sucker Punch","type":"Dark","category":"physical","power":70,"accuracy":100,"pp":5,"priority":1,"effect":None,"effect_chance":0},
    "close_combat": {"name":"Close Combat","type":"Fighting","category":"physical","power":120,"accuracy":100,"pp":5,"priority":0,"effect":"lower_target_def","effect_chance":100},
    "brick_break": {"name":"Brick Break","type":"Fighting","category":"physical","power":75,"accuracy":100,"pp":15,"priority":0,"effect":None,"effect_chance":0},
    "x_scissor": {"name":"X-Scissor","type":"Bug","category":"physical","power":80,"accuracy":100,"pp":15,"priority":0,"effect":None,"effect_chance":0},
    "leaf_blade": {"name":"Leaf Blade","type":"Grass","category":"physical","power":90,"accuracy":100,"pp":15,"priority":0,"effect":"high_crit","effect_chance":100},
    "shadow_claw": {"name":"Shadow Claw","type":"Ghost","category":"physical","power":70,"accuracy":100,"pp":15,"priority":0,"effect":"high_crit","effect_chance":100},
    "stone_edge": {"name":"Stone Edge","type":"Rock","category":"physical","power":100,"accuracy":80,"pp":5,"priority":0,"effect":"high_crit","effect_chance":100},
    "iron_head": {"name":"Iron Head","type":"Steel","category":"physical","power":80,"accuracy":100,"pp":15,"priority":0,"effect":"flinch","effect_chance":30},
    "zen_headbutt": {"name":"Zen Headbutt","type":"Psychic","category":"physical","power":80,"accuracy":90,"pp":15,"priority":0,"effect":"flinch","effect_chance":20},
    "air_slash": {"name":"Air Slash","type":"Flying","category":"special","power":75,"accuracy":95,"pp":15,"priority":0,"effect":"flinch","effect_chance":30},
    "dark_pulse": {"name":"Dark Pulse","type":"Dark","category":"special","power":80,"accuracy":100,"pp":15,"priority":0,"effect":"flinch","effect_chance":20},
    "energy_ball": {"name":"Energy Ball","type":"Grass","category":"special","power":90,"accuracy":100,"pp":10,"priority":0,"effect":"lower_target_spdef","effect_chance":10},
    "focus_blast": {"name":"Focus Blast","type":"Fighting","category":"special","power":120,"accuracy":70,"pp":5,"priority":0,"effect":"lower_target_spdef","effect_chance":10},
    "aura_sphere": {"name":"Aura Sphere","type":"Fighting","category":"special","power":80,"accuracy":0,"pp":20,"priority":0,"effect":None,"effect_chance":0},
    "earth_power": {"name":"Earth Power","type":"Ground","category":"special","power":90,"accuracy":100,"pp":10,"priority":0,"effect":"lower_target_spdef","effect_chance":10},
    "sludge_wave": {"name":"Sludge Wave","type":"Poison","category":"special","power":95,"accuracy":100,"pp":10,"priority":0,"effect":"poison","effect_chance":10},
    "whirlpool": {"name":"Whirlpool","type":"Water","category":"special","power":35,"accuracy":85,"pp":15,"priority":0,"effect":"trap","effect_chance":100},
    "sand_tomb": {"name":"Sand Tomb","type":"Ground","category":"physical","power":35,"accuracy":85,"pp":15,"priority":0,"effect":"trap","effect_chance":100},
    "roar": {"name":"Roar","type":"Normal","category":"status","power":0,"accuracy":0,"pp":20,"priority":-6,"effect":"force_switch","effect_chance":100},
    "whirlwind": {"name":"Whirlwind","type":"Normal","category":"status","power":0,"accuracy":0,"pp":20,"priority":-6,"effect":"force_switch","effect_chance":100},
}

# === Updates to existing moves ===
updates = {
    "take_down": {"effect": "recoil_quarter", "effect_chance": 100},
    "submission": {"effect": "recoil_quarter", "effect_chance": 100},
    "double_kick": {"effect": "multi_hit_2", "effect_chance": 100},
    "fury_attack": {"effect": "multi_hit_2_5", "effect_chance": 100},
    "fury_swipes": {"effect": "multi_hit_2_5", "effect_chance": 100},
    "pin_missile": {"effect": "multi_hit_2_5", "effect_chance": 100},
    "spike_cannon": {"effect": "multi_hit_2_5", "effect_chance": 100},
    "comet_punch": {"effect": "multi_hit_2_5", "effect_chance": 100},
    "absorb": {"effect": "drain_half", "effect_chance": 100},
    "mega_drain": {"effect": "drain_half", "effect_chance": 100},
    "dream_eater": {"effect": "drain_half", "effect_chance": 100},
    "fire_spin": {"effect": "trap", "effect_chance": 100},
    "wrap": {"effect": "trap", "effect_chance": 100},
    "clamp": {"effect": "trap", "effect_chance": 100},
    "swords_dance": {"effect": "raise_self_atk_2", "effect_chance": 100},
    "agility": {"effect": "raise_self_speed_2", "effect_chance": 100},
    "rapid_spin": {"effect": "rapid_spin", "effect_chance": 100},
    "high_jump_kick": {"effect": "recoil_half", "effect_chance": 100},
}

for mid, upd in updates.items():
    if mid in data:
        data[mid].update(upd)

for mid, mdata in new_moves.items():
    if mid not in data:
        data[mid] = mdata

with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

effects = set()
for m in data.values():
    e = m.get('effect')
    if e: effects.add(e)
print(f"Total moves: {len(data)}")
print(f"Total unique effects: {len(effects)}")
