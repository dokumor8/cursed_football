# AGENTS.md - Hex Relic Tactics

This file provides guidance for AI agents working on this Godot 4.5 project.

## Project Overview

**Hex Relic Tactics** is a hex-based tactical strategy game built with Godot 4.5 (GL Compatibility mode). The game features hotseat multiplayer with football/soccer-inspired mechanics where players must capture a central relic and deliver it to the opponent's goal.

## Development Commands

### Running the Game
- **Manual Testing**: The human user manually runs and tests the game through Godot Editor
- **No automated test suite**: Godot doesn't have built-in unit testing for GDScript
- **Run in Editor**: Press F5 or click "Run Project" in Godot Editor

### Code Quality
- **Formatting**: Use Godot Editor's built-in formatter (Ctrl+Alt+F)
- **No linter**: Godot doesn't have a separate linter for GDScript
- **Syntax Checking**: Godot Editor provides real-time syntax checking

### Export Commands
- **HTML5 Export**: Target platform is web browser (HTML5 export)
- **Export Presets**: Configured in `export_presets.cfg`
- **Manual Export**: Use Godot Editor's Export dialog

## Code Style Guidelines

### File Organization
```
scripts/           # All GDScript files
├── game/          # Core game logic
├── ui/            # User interface scripts
└── config/        # Configuration and constants

scenes/            # Godot scene files (.tscn)
├── game/          # Game scenes
└── ui/            # UI scenes

assets/            # All game assets
├── images/        # Textures and sprites
│   ├── tiles/     # Hex tile textures
│   ├── objects/   # Unit and object sprites
│   └── ui/        # UI elements
```

### GDScript Conventions

#### Imports and Extends
```gdscript
# Always use @onready for scene references
@onready var terrain_layer: TileMapLayer = $TileMapLayer

# Use class_name for reusable classes
class_name Unit
extends Node2D

# Preload scenes at top of file
var UnitScene: PackedScene = preload("res://scenes/game/unit.tscn")
```

#### Variable Naming
- **snake_case** for variables and functions: `current_hp`, `get_reachable_tiles()`
- **UPPER_SNAKE_CASE** for constants: `UNIT_MAX_HP`, `PLAYER_RED`
- **PascalCase** for class names: `Unit`, `GameConstants`
- **Prefixes**: Use `is_` for booleans: `is_relic_holder`, `has_attacked_this_turn`

#### Type Annotations
```gdscript
# Always include type annotations
@export var grid_position: Vector2i
@export var speed: int = GC.UNIT_SPEED
var movement_left: int = GC.UNIT_SPEED

# Function return types
func get_reachable_tiles(start: Vector2i, movement: int) -> Array[Vector2i]:
    return []
```

#### Constants and Configuration
- **Central Constants**: Use `GameConstants.gd` for all game balance values
- **No Magic Numbers**: Reference constants via `GC.CONSTANT_NAME`
- **Player Constants**: Use `GC.PLAYER_RED` and `GC.PLAYER_BLUE` instead of 1/2

#### Error Handling
```gdscript
# Use push_error for invalid states
func get_spawn_positions(player: int) -> Array[Vector2i]:
    match player:
        GC.PLAYER_RED:
            return GC.RED_SPAWN_POSITIONS
        GC.PLAYER_BLUE:
            return GC.BLUE_SPAWN_POSITIONS
        _:
            push_error("Invalid player number: " + str(player))
            return []
```

#### Notes

Function `is_connected` exists in the Node class, so other classes (such as Multiplayer) should use some other name (for example, `is_connected_m`).

### Scene Structure Patterns

#### Node Organization
- **Root Nodes**: Use appropriate Node2D or Control nodes as scene roots
- **Layers**: Separate game world and UI using CanvasLayer
- **Containers**: Use MarginContainer, HBoxContainer, VBoxContainer for UI layout

#### Component-Based Design
- **Unit System**: Stats/behavior in `unit.gd`, visuals in `unit.tscn`
- **Game Controller**: Main logic in `game_scene.gd`
- **UI Separation**: UI logic in separate scripts under `scripts/ui/`

### Design Patterns

#### State Management
- **Central Game State**: Manage game state in `game_scene.gd`
- **Turn Tracking**: Use explicit turn switching with "End Turn" button
- **Unit State**: Track `movement_left`, `has_attacked_this_turn` per unit

#### Input Processing
```gdscript
# Event-driven input handling
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        _handle_tile_click(event.position)

# Smart click priority: Attack > Move > Select
```

#### Resource Management
- **Texture Preloading**: Preload textures in `_ready()` functions
- **Scene Instancing**: Use `preload()` and `instantiate()` for dynamic spawning
- **Memory Management**: Godot handles most memory automatically

### Commenting and Documentation

#### Code Comments
- **Minimal Comments**: Code should be self-documenting
- **Complex Logic**: Add brief comments for non-obvious algorithms
- **TODO Comments**: Use `# TODO:` for planned features

#### Documentation Files
- **PROJECT.md**: Comprehensive project documentation
- **CLAUDE.md**: AI collaboration guidelines
- **AGENTS.md**: This file - agent instructions

### Testing Approach

#### Manual Testing
- **Hotseat Testing**: Test multiplayer by playing both sides
- **Edge Cases**: Test movement limits, combat, relic mechanics
- **UI Testing**: Verify all UI elements work correctly

#### Debugging
- **Print Statements**: Use `print()` for debugging (remove before commits)
- **Godot Debugger**: Use Godot Editor's built-in debugger
- **Error Checking**: Check for `push_error()` outputs

## Development Workflow

### Before Making Changes
1. Read `PROJECT.md` for project context
2. Check `CLAUDE.md` for specific guidelines
3. Understand the current architecture

### When Writing Code
1. Follow existing patterns in similar files
2. Use constants from `GameConstants.gd`
3. Maintain component-based architecture
4. Keep `game_scene.gd` under 400 lines (consider splitting if larger)

### After Making Changes
1. Format code with Ctrl+Alt+F
2. Test manually in Godot Editor
3. Verify no syntax errors
4. Check that hotseat gameplay still works

## Project-Specific Notes

### Target Platform
- **Primary**: Web browser (HTML5 export)
- **Consideration**: Keep performance suitable for browser play
- **UI Design**: Ensure touch-friendly for potential mobile play

### Game Design Philosophy
- **"Board Game Simplicity"**: Easy to learn, hard to master
- **Fast Paced**: Turns should be quick
- **Social Focus**: Designed for playing with friends

### Current Development Phase
- **Phase 2**: Game completion (relic mechanics, scoring, hotseat polish)
- **Next Priorities**: Relic power progression, goal system, UI polish
- **Technical Debt**: Consider separating large files if they grow

## Common Tasks Reference

### Adding New Features
1. Check if constants need adding to `GameConstants.gd`
2. Follow existing patterns in similar features
3. Test hotseat gameplay after implementation

### Modifying Game Balance
1. Update values in `GameConstants.gd`
2. Test with various gameplay scenarios
3. Consider impact on both players

### Creating New Scenes
1. Place in appropriate `scenes/` subfolder
2. Create companion script in `scripts/`
3. Follow existing scene structure patterns

### Debugging Issues
1. Check `push_error()` outputs in Godot console
2. Add temporary `print()` statements
3. Test specific edge cases manually

## Important Files Reference

- `scripts/game/game_scene.gd`: Main game controller (keep under 400 lines)
- `scripts/game/unit.gd`: Unit class definition
- `scripts/config/GameConstants.gd`: All game balance constants
- `scenes/game/game_scene.tscn`: Main game scene
- `project.godot`: Godot project configuration

*Last Updated: 2026-01-12*