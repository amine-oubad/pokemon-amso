# Pokemon AMSO

Fan-game Pokémon 2D from scratch — Godot 4 (GDScript).
Inspiré de Pokémon Rouge Feu / Vert Feuille, avec une histoire, des routes et un équilibrage entièrement originaux.

## Stack

- **Moteur :** Godot 4 (GDScript)
- **Rendu :** GL Compatibility (pixel art, filtre nearest-neighbor)
- **Résolution interne :** 320×240 (scalée avec `canvas_items` stretch)
- **Tile size :** 16px

## Lancer le projet

1. Télécharger [Godot 4](https://godotengine.org/download)
2. Ouvrir Godot → **Import** → sélectionner `project.godot`
3. Lancer avec F5 (ou le bouton Play)

**Contrôles :**
| Action | Touches |
|--------|---------|
| Déplacement | ZQSD ou Flèches |
| Confirmer | Z ou Entrée |
| Annuler / Menu | X ou Échap |

## Contenu actuel

### Monde
- **30+ maps** : Bourg Palette, Route 1-8, Jadielle, Forêt de Jade, Argenta, Azuria, Carmin-sur-Mer, Céladopole, Safrania, Parmanie (Fuchsia), Cramois'Île, Plateau Indigo + 8 arènes
- **8 Arènes** : Pierre, Ondine, Major Bob, Erika, Koga, Auguste (Sabrina), Blaine + Champion
- **Ligue Pokémon** : 4 membres de l'Élite + Rival champion (combats enchaînés)
- PNJ, panneaux, dialogues, boutiques par ville
- Transitions bidirectionnelles entre toutes les zones

### Combat
- Système Gen 3 complet : dégâts, STAB, efficacité de type, coups critiques
- **128 moves** avec effets : statuts (brûlure, paralysie, sommeil, gel, poison), stat stages, flinch, high crit, drain, fixed damage, leech seed
- **Effets avancés** : Two-turn (Solar Beam), Double Team (esquive +1), Protect (blocage total), Rain Dance (pluie 5 tours : Water x1.5, Fire x0.5), Baton Pass (switch + transfert stat stages)
- Capture (formule Gen 3), fuite, items en combat
- XP, level-up, apprentissage de moves, évolution (annulable)
- IA dresseur avec scoring (power × effectiveness × STAB)

### Pokémon
- **151 Pokémon** (Gen 1 complet) avec stats, types, movesets, évolutions
- Rencontres sauvages via `WildEncounterZone` (Area2D réutilisable, support Repel)
- Tables de rencontres pondérées par route (JSON)

### Systèmes
- Sauvegarde/chargement (3 slots)
- Menu pause complet : équipe, sac (heal/status cure/revive/repel en overworld), Pokédex, badges, save
- Boutiques configurables par ville (JSON)
- Système de badges + CS-blocks
- Repel (décompte par pas)

## Structure

```
pokemon-amso/
├── project.godot
├── scripts/
│   ├── autoloads/          # Singletons (EventBus, GameData, GameState)
│   ├── overworld/          # Player, NPC, Trainer, Sign, MapTransition, WildEncounterZone
│   │   └── maps/           # 30+ maps (villes, routes, arènes)
│   ├── battle/             # BattleScene, BattleCalc, MoveEffects, LeagueArena
│   ├── data/               # PokemonInstance, MoveInstance
│   ├── systems/            # SaveManager
│   └── ui/                 # PauseMenu, ShopMenu, StarterSelect, GameOverScreen
├── scenes/
│   ├── overworld/
│   │   ├── entities/       # Player.tscn
│   │   └── maps/           # Toutes les maps (.tscn)
│   └── battle/             # BattleScene.tscn
├── data/                   # JSON (pokemon, moves, trainers, gyms, encounters, shops, dialogues, type_chart)
└── assets/                 # Sprites, tilesets, audio (à venir)
```

## Phases de développement

| Phase | Objectif | Statut |
|-------|----------|--------|
| 0 | Joueur qui marche, collisions | Done |
| 1 | Premier combat jouable | Done |
| 2 | Combat complet (capture, statuts, items) | Done |
| 3 | Overworld vivant (PNJ, dialogues, zones) | Done |
| 4 | Progression (badges, Arènes, CS) | Done |
| 5 | Contenu complet (8 arènes, Ligue, 75 Pokémon) | Done |
| 6 | Effets avancés (two-turn, protect, weather, baton pass) | Done |
| 7 | Polish & release (sprites, musique, équilibrage final) | En cours |

## Données

Toutes les données de jeu sont dans `data/` en JSON — éditables sans recompiler :
- `pokemon.json` — stats, types, moves par niveau, évolutions
- `moves.json` — puissance, précision, PP, effets
- `trainers.json` — équipes des dresseurs et récompenses
- `gyms.json` — arènes, leaders, badges
- `encounters/` — tables de rencontres sauvages par route
- `shops.json` — inventaire des boutiques
- `dialogues.json` — textes PNJ et panneaux
- `type_chart.json` — table d'efficacité des types

## Licence

Fan-game non commercial. Pokémon est une marque déposée de Nintendo / Game Freak / The Pokémon Company.
