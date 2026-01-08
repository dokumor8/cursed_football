# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **hex-based tactical strategy game** built with **Godot 4.5** (GL Compatibility mode). The game is inspired by football/soccer mechanics with a central relic that must be captured and delivered to the opponent's goal. It's currently in early prototype stage with hotseat multiplayer functionality.

## Development Commands

### Running and Testing
The human user manually runs and tests the game.

### Code Quality
- **GDScript Formatting**: Use Godot Editor's built-in formatter (Ctrl+Alt+F)
- **No linter**: Godot doesn't have a separate linter for GDScript

## Architecture Overview

### Core Systems
1. **Game Controller** ([scripts/game/game_scene.gd](scripts/game/game_scene.gd)): Main game logic (~350 lines)
   - Manages game state (turn tracking, obstacles, selected unit)
   - Handles input processing and tile selection
   - Coordinates movement, combat, and turn transitions

2. **Unit System** ([scripts/game/unit.gd](scripts/game/unit.gd)): Enhanced Unit class
   - Properties: HP, speed, attack power, turn tracking
   - Combat methods: take_damage, attack, is_dead
   - Visual components: sprite, HP labels

3. **Movement System**: BFS algorithm in `get_reachable_tiles()` for pathfinding
   - Movement cost: 1 per tile
   - Obstacle tracking via dictionary

4. **Combat System**: Adjacency-based attacks (range 1)
   - Damage calculation: 1 damage per attack
   - Death mechanics with revive token rewards

5. **Turn Management**: Player switching (Red vs Blue)
   - "End Turn" button for explicit turn switching
   - Unit state reset at turn start

### Scene Structure
- **Main Scene**: [scenes/game/game_scene.tscn](scenes/game/game_scene.tscn)
  - TileMapLayer (terrain)
  - HighlightLayer (walkable/attack highlights)
  - UILayer (CanvasLayer with UI containers)
  - Unit instances (dynamically spawned)

- **UI Architecture**: CanvasLayer-based UI separation
  - Container-based layout (MarginContainer, HBoxContainer)
  - Dynamic updates for turn indicator, revive UI

### Key Design Patterns
- **Component-based Units**: Stats and behavior in `unit.gd`, visuals in scene
- **Event-driven Input**: `_unhandled_input()` → `_handle_tile_click()` → `select_tile()`
- **State Management**: Central game state in `game_scene.gd`
- **UI Separation**: CanvasLayer ensures UI stays above game world

## Current Development Status

### ✅ Implemented Features
- Hex grid system with coordinate system
- Unit system with two teams (Red vs Blue)
- Turn-based gameplay with "End Turn" button
- Selection & movement with BFS pathfinding
- Combat system with adjacency attacks
- Revive system
- UI/HUD with turn indicator and revive UI
- Relic Mechanics
- Goal & scoring

### ❌ Missing / Planned Features (Phase 2 Focus)
1. **Hotseat Polish**: Improved UI feedback, turn timer, game state display

## Important Files

- [PROJECT.md](PROJECT.md): Comprehensive project documentation (380+ lines)
- [project.godot](project.godot): Godot project configuration
- [scripts/game/game_scene.gd](scripts/game/game_scene.gd): Main game controller
- [scripts/game/unit.gd](scripts/game/unit.gd): Unit class definition
- [scenes/game/game_scene.tscn](scenes/game/game_scene.tscn): Main game scene

## Development Notes

- **Target Platform**: Web browser (HTML5 export planned)
- **Game Type**: Hex-based tactical strategy with sport elements
- **Current Phase**: Early prototype, hotseat multiplayer only
- **AI Collaboration**: Using Claude Code with DeepSeek model
- **Design Philosophy**: "Board Game Simplicity" - easy to learn, hard to master

## Code Organization Guidelines

1. **Scripts go in `scripts/`**: Organized by system (game/, ui/, etc.)
2. **Scenes go in `scenes/`**: Organized by type (game/, ui/, etc.)
3. **Assets go in `assets/`**: Organized by type (images/, audio/, etc.)
4. **Game constants**: Consider creating `config/` folder for balance values
5. **Large systems**: Consider separating if `game_scene.gd` grows beyond 400 lines

## For Future Development Sessions

When working on this project:
1. If comprehensive contest in needed, check [PROJECT.md](PROJECT.md)
2. Maintain the component-based architecture
3. Consider browser target when making technical decisions
