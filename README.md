# Pokemon AMSO

Fan-game Pokémon 2D from scratch — Godot 4 (GDScript).
Inspiré de Pokémon Rouge Feu / Vert Feuille, avec une histoire, des routes et un équilibrage entièrement originaux.

## Stack

- **Moteur :** Godot 4 (GDScript)
- **Rendu :** GL Compatibility (pixel art, filtre nearest-neighbor)
- **Résolution interne :** 320×240 (scalée avec stretch mode)
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

## Structure

```
pokemon-amso/
├── project.godot
├── scripts/
│   ├── autoloads/          # Singletons globaux (EventBus, GameData, GameState)
│   ├── overworld/          # Joueur, PNJ, Dresseurs, CS-blocks, rencontres
│   │   └── maps/           # 7 zones (PalletTown, Route1/2, Jadielle, Forêt, Argenta, Gyms)
│   ├── battle/             # Combat complet (wild, dresseurs, XP, level-up, évolution)
│   ├── data/               # PokemonInstance, MoveInstance
│   ├── systems/            # SaveManager
│   └── ui/                 # ShopMenu, StarterSelect
├── scenes/
│   ├── overworld/
│   │   ├── entities/       # Player.tscn
│   │   └── maps/           # Toutes les maps du jeu
│   └── battle/             # BattleScene.tscn
├── data/                   # JSON éditables (pokemon, moves, trainers, gyms, type_chart...)
└── assets/                 # Sprites, tilesets, audio (à venir)
```

## Phases de développement

| Phase | Objectif | Statut |
|-------|----------|--------|
| 0 | Joueur qui marche, collisions | ✅ |
| 1 | Premier combat jouable | ✅ |
| 2 | Combat complet (capture, statuts, items) | ✅ |
| 3 | Overworld vivant (PNJ, dialogues, zones) | ✅ |
| 4 | Progression (badges, Arènes, CS) | ✅ |
| 5 | Contenu complet | ✅ |
| 6 | Polish & release | ⬜ |

## Données Pokémon

Les données (stats, moves, types) sont dans `data/` en JSON — éditables sans recompiler.
Workflow d'équilibrage : Google Sheets → export CSV → `tools/csv_to_json.py` → JSON.

## Licence

Fan-game non commercial. Pokémon est une marque déposée de Nintendo / Game Freak / The Pokémon Company.
