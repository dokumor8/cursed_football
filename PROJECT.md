# Hex-Based Tactics Game - Project Documentation

- [Hex-Based Tactics Game - Project Documentation](#hex-based-tactics-game---project-documentation)
  - [Project Overview](#project-overview)
  - [Game Mechanics \& Rules](#game-mechanics--rules)
    - [Core Concept](#core-concept)
    - [Field Layout](#field-layout)
    - [Unit Mechanics](#unit-mechanics)
    - [Relic Mechanics (Central Game Mechanic)](#relic-mechanics-central-game-mechanic)
    - [Round Structure](#round-structure)
      - [Turn structure](#turn-structure)
    - [Victory Conditions](#victory-conditions)
    - [Turtling and Snowballing considerations](#turtling-and-snowballing-considerations)
  - [Planned Features \& Development Roadmap](#planned-features--development-roadmap)
    - [Phase 1: Core Gameplay (COMPLETED)](#phase-1-core-gameplay-completed)
    - [Phase 2: Game Completion (In progress)](#phase-2-game-completion-in-progress)
    - [Phase 3: Multiplayer \& Polish](#phase-3-multiplayer--polish)
    - [Phase 4: More Polish](#phase-4-more-polish)
    - [Phase 5: Advanced Potential Features](#phase-5-advanced-potential-features)
    - [Phase 6: Another game](#phase-6-another-game)
    - [Technical Goals](#technical-goals)
  - [Technical Architecture](#technical-architecture)
    - [Current Code Structure](#current-code-structure)
    - [Key Algorithms \& Systems](#key-algorithms--systems)
    - [Scene Structure](#scene-structure)
    - [Design Patterns](#design-patterns)
    - [Structure Status](#structure-status)
  - [Development Notes](#development-notes)
    - [Development Environment](#development-environment)
    - [Design Philosophy](#design-philosophy)
    - [Technical Constraints](#technical-constraints)
    - [Balance Considerations](#balance-considerations)
    - [Known Issues \& TODOs](#known-issues--todos)
  - [Current Implementation Status (as of 2026-01-05)](#current-implementation-status-as-of-2026-01-05)
    - [✅ **Implemented Features**](#-implemented-features)
    - [❌ **Missing / Planned Features**](#-missing--planned-features)
    - [📝 **Recent Changes (2026-01-05 Session)**](#-recent-changes-2026-01-05-session)
  - [For Future AI Sessions](#for-future-ai-sessions)
    - [Key Context Points](#key-context-points)
    - [Current Architecture](#current-architecture)
    - [Development Priorities (Next Session)](#development-priorities-next-session)
    - [Testing Focus](#testing-focus)


## Project Overview

**Game Type**: Hex-based tactical strategy game
**Engine**: Godot 4.5 (GL Compatibility mode)
**Target Platform**: Web browser (Godot's HTML5 export)
**Current Phase**: Early prototype
**Project Name**: Hex Relic Tactics

## Game Mechanics & Rules

### Core Concept
A hex-based tactical game with sport elements:
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
   Three surrounding spawn tiles (for unit respawn)
   Goal Tile (center of base)
```

### Unit Mechanics
- **Health**: 3 HP per unit
- **Damage**: 1 damage per attack (normal units)
- **Movement**: 2 tiles per turn (normal units)
- **Combat**: Adjacent units can attack (range 1)
- **Respawn**: Units respawn next turn on spawn tiles (no movement that turn)

### Relic Mechanics (Central Game Mechanic)
- Located at center of grid at game start
- **Relic Holder Effects**:
  - **Speed and Damage Progression**: 
    - Turn 1 after pickup: 0 speed, 0 damage (relic holder is stunned).
    - Turn 2: can move 1 tile per turn, but can't attack.
    - Turn 3+: the debuff slowly wears out and turns into a buff (precise numbers are decided during the balancing stage)
  - **Glass Cannon**: Never gains extra HP (stays vulnerable)
- **Stealing**: Opponent can attack relic holder to steal relic. Speed and damage progression does **not** reset. If a relic holder with speed 4 and attack 2 is defeated, the unit that dealt the last hit becomes a new relic holder with speed 4 and attack 2, without the stun or slow effects.
- **No Passing**: units of the same team cannot pass the relic to each other.

### Round Structure
- Player 1's turn
- Player 2's turn
- Relic effect upgrade (timing might be changed based on who picked the relic first, will be clear in testing)

#### Turn structure
Every unit can make the following actions:

- Move (up to speed limit)
- Attack adjacent enemy (once per turn, can't move after attack)
- Take the relic from its starting position (can't move afterwards)

During their turn, the player can respawn dead units on spawn tiles. The units can't move on the same turn when they were respawned.

Movement order is free. A player may, for example, move UnitA one tile, then respawn UnitB, move UnitC two tiles, attack with UnitC, then move UnitA one last tile and attack with UnitA. 

### Victory Conditions
- Deliver relic to opponent's goal tile
- Game ends immediately upon scoring

### Turtling and Snowballing considerations

Anti-turtling:

- Relic power increases over time (speed + damage), giving the advantage to the team holding the relic (attackers).

Anti-snowballing
- Goal is close to the enemy respawn point, so the defending team just has to spawn units to defend the goal, while the attacking team must bring the units from the other side of the field.
- Relic holder does not get extra HP, so while they are strong during later stages of the game, they are also fragile.


## Planned Features & Development Roadmap

### Phase 1: Core Gameplay (COMPLETED)
- [x] Combat, turns, basic UI

### Phase 2: Game Completion (In progress)
At this point the project is playable.

- [x] Relic mechanics, scoring, revives, hotseat version, UI

### Phase 3: Multiplayer & Polish
At this point the playable project can be considered a game, and not just a prototype for fun. A jam-level game.

- [ ] **Enhanced Visuals**: Better sprites, improved UI highlights and hints.
- [ ] **UI Polish**: Improved layouts, tooltips, game state explanations.
- [ ] **Online Multiplayer**: Network synchronization for browser play.
  - [ ] Technical step: separation of game state for multiplayer and for a potential Undo feature.
- [ ] **Audio System**: Sound effects for moves, attacks, deaths, UI.

### Phase 4: More Polish
At this point the game just becomes more user-friendly.

- [ ] **Developer Mode**: Configurable game constants for balancing.
- [ ] **Turn reset**: "Undo" functionality.
- [ ] **Mobile Optimization**: Touch controls, responsive UI scaling.

### Phase 5: Advanced Potential Features
At this point the game is no longer jam-level.

- [ ] **AI Opponent**: Single-player mode
- [ ] **Multiple Maps**: Different grid layouts and starting positions
- [ ] **Game Statistics**: Win/loss tracking, move history, replay system
- [ ] **Tutorial System**: In-game instructions for new players

### Phase 6: Another game
Other unit types, other mechanics, other win conditions. Using the hex grid, the game base and other features as a foundation for a more complex game project.


### Technical Goals
- **Browser Deployment**: Export as HTML5 for web play
- **Simple Multiplayer**: Direct peer-to-peer or simple server architecture

## Technical Architecture

### Current Code Structure
```
scripts/game/
├── game_scene.gd           # Main game logic. Handling input, managing units on the game board.
├── unit.gd                 # Unit class definition. Managing interations of units with other objects - combat, relic buffs, unit UI
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
├── images/
│   ├── tiles/             # Hex tile textures
│   ├── objects/           # Unit sprites (unit_red.png, unit_blue.png)
│   └── ui/               # UI elements
└── images/               # Legacy images folder


project.godot             # Godot project config
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


### Structure Status

📋 **RECOMMENDED NEXT STEPS**:
1. Create `config/` folder for game balance constants
2. Add `audio/` folder when sound effects are implemented
3. Consider separating `combat.gd` and `turn_manager.gd` if code grows

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