# Hex Tactics

This is a **hex-based tactical strategy game** built with **Godot 4.5** (GL Compatibility mode). The game features turn-based tactical gameplay with very simple rules. Current focus of development is multiplayer functionality.

## Development considerations

The human user manually runs and tests the game. Automatic tests are not needed.

Currently the multiplayer logic is being transformed from a P2P Host-Client model to a Client1-Client2-Server model with a dedicated server.

## Project structure

### Scripts

1. **Game Controller**, `scripts/game/game_scene.gd`
   - Handles input processing and player actions
   - Uses game state to control UI
   - Coordinates movement, combat and turn transitions
2. **Game State**, `scripts/game/game_state.gd`
   - Manages game state, including serialization
   - Manages multiplayer actions that modify game state
3. **Unit System**, `scripts/game/unit.gd`
   - Manages the states of individual units
   - Handles visuals of units, including UI
4. **Multiplayer Lobby**, `scripts/ui/lobby.gd`
   - Player connection, client-server separation

### Scenes
- **Main Scene**, `scenes/game/game_scene.tscn`
  - TileMapLayer (terrain)
  - HighlightLayer (walkable/attack highlights)
  - UILayer (CanvasLayer with UI containers)
  - Unit instances (dynamically spawned)
- **Menus**, `scenes/ui/lobby.tscn`, `scenes/ui/main_menu.tscn`
- **Units and Objects**, `scenes/game/unit.tscn`, `scenes/game/relic.tscn`

### Organization

If comprehensive contest in needed, check `.ai_workplace/PROJECT.md`.

The folder `.ai_workplace` contains some files with structure and organization, but the project was developed faster than these files were updated. It might be easier to set up a new system to keep track of things.

## Current Development Status

### ✅ Implemented Features
- Hex grid system with coordinate system
- Unit system with two teams (Red vs Blue)
- Turn-based gameplay
- Selection & movement with BFS pathfinding
- Combat system with adjacency attacks
- Revive system
- UI/HUD with turn indicator and revive UI
- Relic Mechanics
- Goal & scoring

### ❌ Missing / Planned Features

- Multiplayer (works, but has many bugs)
- General polish

## Code Organization Guidelines

1. **Scripts go in `scripts/`**: Organized by system (game/, ui/, etc.)
2. **Scenes go in `scenes/`**: Organized by type (game/, ui/, etc.)
3. **Assets go in `assets/`**: Organized by type (images/, audio/, etc.)

