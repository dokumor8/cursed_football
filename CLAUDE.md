# Hex-Based Tactics Game - Project Documentation

## Project Overview

**Game Type**: Hex-based tactical strategy game (similar to football/soccer on a hex grid)
**Engine**: Godot 4.5 (GL Compatibility mode)
**Target Platform**: Web browser (Godot's HTML5 export)
**Current Phase**: Early prototype / Proof of concept
**Project Name**: Hex Relic Tactics

## Current Implementation Status (as of 2026-01-05)

### ✅ **Implemented Features**
1. **Hex Grid System**
   - TileMapLayer with hexagonal tiles
   - Coordinate system (Vector2i) for grid positions
   - Obstacle tracking for occupied tiles

2. **Unit System**
   - Enhanced Unit class with: `conflict_side`, `grid_position`, `speed`, `movement_left`
   - Two teams (Red vs Blue) with different sprites (`unit_red.png`, `unit_blue.png`)
   - Unit spawning at designated start positions
   - HP system: 2 HP per unit with visual HP labels
   - Combat stats: `attack_power`, `has_attacked_this_turn`

3. **Turn-Based Gameplay**
   - Player turn tracking (Red vs Blue alternating)
   - "End Turn" button for explicit turn switching
   - Per-unit movement tracking (`movement_left` resets each turn)
   - Attack once per turn restriction

4. **Selection & Movement**
   - Click-to-select units with visual indicator
   - BFS algorithm for reachable tile calculation (`get_reachable_tiles`)
   - Walkable tile highlighting based on remaining movement
   - Unit movement with obstacle updates
   - Movement cost: 1 per tile

5. **Combat System**
   - Adjacency-based attacks (range 1)
   - Damage calculation: 1 damage per attack
   - HP tracking with visual indicators above units
   - Death mechanics: Units removed when HP ≤ 0
   - Attack highlighting: Enemy units in range are highlighted
   - Post-attack penalty: `movement_left = 0`

6. **Revive System**
   - Revive token tracking per player
   - Kill rewards: Gain revive token when killing enemy unit
   - UI integration: Revive button and counter
   - (Note: Actual revive mechanics not yet implemented)

7. **UI/HUD System**
   - CanvasLayer-based UI architecture
   - Turn indicator showing current player (color-coded)
   - "End Turn" button for turn management
   - Revive UI with button and counter
   - Relic status placeholder
   - Professional container layout (MarginContainer, HBoxContainer)

8. **Input Handling**
   - Mouse click detection on hex tiles
   - Tile coordinate conversion
   - Smart click logic: Attack > Move > Select

9. **Visual Assets**
   - Hex tile textures (normal and highlight variants)
   - Unit sprites: `unit_red.png`, `unit_blue.png`
   - Selection indicator graphic
   - HP labels with color coding (white → yellow → red)

### ❌ **Missing / Planned Features**
1. **Relic System** - Central game mechanic not implemented
2. **Goal/Scoring** - No win conditions or goal tiles
3. **Revive Mechanics** - UI exists but actual revival not implemented
4. **Audio** - No sound effects or music
5. **Online Multiplayer** - Hotseat only (local player switching)
6. **Polish** - Limited visual feedback for attacks
7. **Balance & Testing** - Game balance needs tuning

### 📝 **Recent Changes (2026-01-05 Session)**
- **Project Reorganization**: Moved files to `scenes/`, `scripts/`, `assets/` structure
- **Faction Sprites**: Added red/blue unit sprites with dynamic loading
- **Turn System**: Implemented player turns with "End Turn" button
- **Movement Tracking**: Added `movement_left` per unit, resets each turn
- **Combat System**: Full HP/damage system with adjacency attacks
- **Death Mechanics**: Unit removal and revive token tracking
- **UI Overhaul**: CanvasLayer with turn indicator, revive UI, proper layout
- **Attack Highlighting**: Enemy units in range highlighted when unit selected
- **Bug Fixes**: Fixed attack logic for enemy unit clicking

## Game Mechanics & Rules

### Core Concept
A hex-based tactical game similar to football (soccer):
- Two players/teams on opposite sides of a hex grid
- Central **Relic** that must be captured and delivered to opponent's goal
- Goal: Grab relic → Move to opponent's goal tile → Score

### Field Layout
```
[Player 2 Base]
   Goal Tile (center of base)
   Three surrounding spawn tiles (for unit respawn)

[Hex Grid - playing field]

[Player 1 Base]
   Goal Tile (center of base)
   Three surrounding spawn tiles (for unit respawn)
```

### Unit Mechanics
- **Health**: 2 HP per unit
- **Damage**: 1 damage per attack (normal units)
- **Movement**: 2 tiles per turn (normal units)
- **Combat**: Adjacent units can attack (range 1)
- **Respawn**: Units respawn next turn on spawn tiles (no movement that turn)
  - Prevents permanent unit loss
  - Encourages aggressive play

### Relic Mechanics (Central Game Mechanic)
- Located at center of grid at game start
- **Relic Holder Effects**:
  - **Stunned**: Cannot move or attack (initial state after pickup)
  - **Speed Progression**: 1 → 2 → 3 → 4 tiles per turn (increases over time)
  - **Damage Boost**: Eventually deals 2 damage (one-shots enemies)
  - **Glass Cannon**: Never gains extra HP (stays vulnerable)
- **Speed Effect Array**: `[-2, -1, 0, 1, 2]` - planned progression system
- **Stealing**: Opponent can attack relic holder to steal relic

### Turn Structure (Planned)
1. **Player 1 Turn**
   - Move units (up to speed limit)
   - Attack adjacent enemies (optional)
   - Respawn dead units on spawn tiles (no movement)
2. **Player 2 Turn** (same actions)
3. **Relic Effects Update** (timer progression)

### Victory Conditions
- Deliver relic to opponent's goal tile
- Game ends immediately upon scoring

### Anti-Turtling Mechanics
- Relic power increases over time (speed + damage)
- Encourages aggressive play rather than defensive camping
- Respawning units prevent permanent advantage

## Planned Features & Development Roadmap

### Phase 1: Core Gameplay (COMPLETED ✅)
- [x] **Combat System**: HP, damage, adjacency attacks, death mechanics
- [x] **Turn-Based Structure**: Player turns, "End Turn" button, movement tracking
- [x] **Basic UI**: Turn indicator, revive UI, CanvasLayer architecture
- [x] **Project Organization**: Proper folder structure (`scenes/`, `scripts/`, `assets/`)
- [x] **Visual Feedback**: HP labels, attack highlighting, unit selection

### Phase 2: Game Completion (Current Focus)
- [ ] **Relic Mechanics**: Pickup, carrying, speed progression, stealing
- [ ] **Goal & Scoring**: Goal tiles, win conditions, score tracking
- [ ] **Revive Implementation**: Actual unit revival on spawn tiles
- [ ] **Hotseat Polish**: Improved UI feedback, turn timer, game state display
- [ ] **Balance Testing**: Tune movement, attack values, revive costs

### Phase 3: Multiplayer & Polish
- [ ] **Online Multiplayer**: Network synchronization for browser play
- [ ] **Enhanced Visuals**: Attack animations, death effects, better highlights
- [ ] **Audio System**: Sound effects for moves, attacks, deaths, UI
- [ ] **UI Polish**: Improved layouts, tooltips, game state explanations
- [ ] **Mobile Optimization**: Touch controls, responsive UI scaling

### Phase 4: Advanced Features
- [ ] **AI Opponent**: Single-player mode with difficulty levels
- [ ] **Multiple Maps**: Different grid layouts and starting positions
- [ ] **Game Statistics**: Win/loss tracking, move history, replay system
- [ ] **Player Customization**: Unit colors, names, cosmetic options
- [ ] **Tutorial System**: In-game instructions for new players

### Technical Goals
- **Browser Deployment**: Export as HTML5 for web play
- **Simple Multiplayer**: Direct peer-to-peer or simple server architecture
- **Mobile-Friendly**: Responsive controls for touch devices
- **Performance**: Optimized for smooth gameplay on lower-end devices

## Technical Architecture

### Current Code Structure
```
scripts/game/
├── game_scene.gd           # Main game logic (~350 lines)
│   ├── Grid management (TileMapLayer, obstacles)
│   ├── Turn tracking (current_player, _switch_player_turn)
│   ├── Movement system (get_reachable_tiles, move_unit)
│   ├── Combat logic (attack handling, death processing)
│   ├── UI management (turn indicator, revive UI updates)
│   ├── Input handling (select_tile, _handle_tile_click)
│   └── Game state (obstacles, selected_unit, revive counts)
│
├── unit.gd                 # Enhanced Unit class definition
│   ├── Basic properties (conflict_side, grid_position, speed)
│   ├── Combat stats (max_hp, current_hp, attack_power)
│   ├── Turn tracking (movement_left, has_attacked_this_turn)
│   ├── Combat methods (take_damage, attack, is_dead)
│   ├── Turn management (reset_turn)
│   ├── Visual components (sprite, hp_label)
│   └── HP label management (_create_hp_label, _update_hp_label)
│
└── unit_selection.gd       # Visual selection indicator

scenes/game/
├── game_scene.tscn         # Main game scene
│   ├── TileMapLayer (terrain)
│   ├── HighlightLayer (walkable/attack highlights)
│   ├── UILayer (CanvasLayer with UI containers)
│   └── Unit instances
│
├── unit.tscn               # Unit scene template
│   ├── Node2D root
│   └── Sprite2D (texture set in code)
│
└── unit_selection.tscn     # Selection indicator scene

scenes/ui/
└── main_menu.tscn          # Placeholder main menu

assets/
├── textures/
│   ├── tiles/             # Hex tile textures
│   ├── objects/           # Unit sprites (unit_red.png, unit_blue.png)
│   └── ui/               # UI elements
└── images/               # Legacy images folder
```

### Key Algorithms & Systems
1. **Movement Range**: BFS in `get_reachable_tiles()` using `movement_left`
2. **Combat Resolution**: Adjacency check + damage calculation
3. **Turn Management**: Player switching with unit state reset
4. **UI Architecture**: CanvasLayer with container-based layout
5. **Input Processing**: Smart click logic (Attack > Move > Select)
6. **Obstacle Tracking**: Dictionary-based tile occupancy system

### Scene Structure
- **`game_scene.tscn`**: Root scene with TileMapLayers, CanvasLayer UI
- **`unit.tscn`**: Template for units (dynamically colored via code)
- **`unit_selection.tscn`**: Visual indicator for selected units
- **UI Hierarchy**: `UILayer` → `MainUIContainer` → `TopBar`/`BottomBar`

### Design Patterns
- **Component-based Units**: Stats and behavior in `unit.gd`, visuals in scene
- **Event-driven Input**: `_unhandled_input()` → `_handle_tile_click()` → `select_tile()`
- **State Management**: Central game state in `game_scene.gd`
- **UI Separation**: CanvasLayer ensures UI stays above game world
- **Resource Management**: Texture preloading for performance

## Project Structure (IMPLEMENTED ✅)

### Current Structure (As Implemented)
```
/
├── scenes/                    # All .tscn files (IMPLEMENTED)
│   ├── game/                 # Gameplay scenes
│   │   ├── game_scene.tscn
│   │   ├── unit.tscn
│   │   └── unit_selection.tscn
│   └── ui/                   # UI scenes
│       └── main_menu.tscn
│
├── scripts/                  # All .gd files (IMPLEMENTED)
│   └── game/                 # Gameplay logic
│       ├── game_scene.gd     # Main game logic (includes combat/turns)
│       ├── unit.gd           # Enhanced unit class with combat
│       └── unit_selection.gd # Selection indicator
│
├── assets/                   # All visual assets (PARTIALLY IMPLEMENTED)
│   ├── textures/            # Images, sprites
│   │   ├── tiles/          # Hex tiles
│   │   ├── objects/        # Unit sprites (unit_red.png, unit_blue.png)
│   │   └── ui/             # UI elements
│   └── images/             # Legacy folder (some images still here)
│
└── project.godot           # Godot project config
```

### Structure Status
✅ **COMPLETED**:
- Scene organization (`scenes/game/`, `scenes/ui/`)
- Script organization (`scripts/game/`)
- Basic asset structure (`assets/textures/`)

🔄 **PARTIAL**:
- Some images still in legacy `images/` folder
- No `audio/` or `fonts/` folders yet (not needed currently)

📋 **RECOMMENDED NEXT STEPS**:
1. Move remaining images from `images/` to `assets/textures/`
2. Create `config/` folder for game balance constants
3. Add `audio/` folder when sound effects are implemented
4. Consider separating `combat.gd` and `turn_manager.gd` if code grows

## Development Notes

### Development Environment
- **AI Collaboration**: Using Claude Code with DeepSeek model
- **Godot Editor**: Primary development tool with visual scene editing
- **Version Control**: Git with basic commit history

### Design Philosophy
- **"Board Game Simplicity"**: Like Connect Four, not complex like Catan
- **Minimal Rules**: Easy to learn, hard to master
- **Fast Paced**: Turns should be quick, game length ~10-15 minutes
- **Social Focus**: Primarily designed for playing with friends

### Technical Constraints
- **Browser Target**: Must work well as HTML5 export
- **Multiplayer First**: Design decisions should consider networking implications
- **Mobile Consideration**: Touch-friendly interface for potential mobile play

### Balance Considerations
- Relic power progression needs testing
- Respawn mechanics vs. aggressive play balance
- Speed/damage scaling over time
- Map size and unit count optimization

### Known Issues & TODOs
1. **Attack Feedback**: Limited visual distinction between walkable and attackable tiles
2. **Revive Mechanics**: UI exists but actual revival not implemented
3. **Relic System**: Core game mechanic still missing
4. **Win Conditions**: No goal tiles or scoring system
5. **Balance Issues**: Movement/attack values may need tuning
6. **UI Polish**: Could use more visual feedback for attacks and deaths
7. **Code Organization**: `game_scene.gd` is getting large (~350 lines)

---

## For Future AI Sessions

### Key Context Points
- **Hex-based tactics game** with football/soccer inspiration
- **Core gameplay loop implemented**: Combat + turns + movement
- **Current state**: Functional hotseat multiplayer with combat system
- **Missing**: Relic mechanics, win conditions, revive implementation
- **Project organized**: Proper folder structure with scenes/scripts/assets

### Current Architecture
- **Main scene**: `game_scene.tscn` with TileMapLayers and CanvasLayer UI
- **Unit system**: Enhanced `unit.gd` with HP, combat, turn tracking
- **Turn system**: Player switching with "End Turn" button
- **Combat**: Adjacency-based attacks with HP tracking
- **UI**: CanvasLayer with turn indicator, revive UI, proper containers

### Development Priorities (Next Session)
1. **Relic Mechanics**: Implement pickup, carrying, speed progression
2. **Goal System**: Add goal tiles and win conditions
3. **Revive Implementation**: Complete the revive mechanics
4. **UI Polish**: Better visual feedback for attacks and game state
5. **Balance Testing**: Tune movement, attack, and revive values

### Testing Focus
- Relic power progression balance
- Combat effectiveness and unit survivability
- Turn pacing and game length
- Hotseat gameplay experience
- UI clarity and player feedback

---

*Last Updated: 2026-01-05* (Major update - combat system, turns, UI)
*Maintained for Claude Code AI collaboration*