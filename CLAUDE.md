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
   - Basic Unit class with properties: `conflict_side`, `grid_position`, `speed`
   - Two teams (side 1 and side 2) with predefined start positions
   - Unit spawning at designated locations

3. **Selection & Movement**
   - Click-to-select units with visual indicator
   - A* pathfinding for movement between tiles
   - BFS algorithm for reachable tile calculation (`get_reachable_tiles`)
   - Walkable tile highlighting based on unit speed
   - Basic unit movement with obstacle updates

4. **Input Handling**
   - Mouse click detection on hex tiles
   - Tile coordinate conversion

5. **Visual Assets**
   - Hex tile textures (normal and highlight variants)
   - Unit sprite (unit1.png)
   - Selection indicator graphic

### ❌ **Missing / Planned Features**
1. **Core Game Rules** - Not implemented yet
2. **Combat System** - No damage or health mechanics
3. **Turn Structure** - No turn-based gameplay
4. **Relic System** - Central game mechanic not implemented
5. **Goal/Scoring** - No win conditions
6. **UI/HUD** - No player interface
7. **Audio** - No sound effects or music
8. **Multiplayer** - Single-player only
9. **Polish** - Minimal visual feedback

### 📝 **Recent Changes**
- Added `relic_timer` and `relic_speed_effect` variables (planned mechanic)
- Basic movement system (commit: "Move units")
- Walkable tile highlighting (commit: "Add highlight to walkable places")
- Unit selection system (commit: "selection")

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

### Phase 1: Core Gameplay (Current Focus)
- [ ] Implement combat system (HP, damage, attacks)
- [ ] Add turn-based structure
- [ ] Implement relic mechanics (pickup, carrying, effects)
- [ ] Add goal tiles and scoring
- [ ] Basic UI (turn indicator, score display)

### Phase 2: Multiplayer & Polish
- [ ] **Hotseat Mode** (local multiplayer - player switching)
- [ ] **Online Multiplayer** (primary goal - play with friends via browser)
- [ ] Enhanced UI (health bars, relic status, turn timer)
- [ ] Visual feedback (attack animations, score effects)
- [ ] Audio system (SFX, background music)

### Phase 3: Advanced Features
- [ ] **AI Opponent** (single-player mode)
- [ ] Game balance testing & tuning
- [ ] Multiple maps/levels
- [ ] Player customization (unit colors, names)
- [ ] Game statistics & replay system

### Technical Goals
- **Browser Deployment**: Export as HTML5 for web play
- **Simple Multiplayer**: Direct peer-to-peer or simple server
- **Mobile-Friendly**: Responsive controls for touch devices

## Technical Architecture

### Current Code Structure
```
game_scene.gd           # Main game logic (602 lines)
├── Grid management (TileMapLayer, obstacles)
├── Pathfinding (AStar2D)
├── Unit movement & selection
├── Input handling
└── Game state variables

unit.gd                 # Unit class definition
├── conflict_side (1 or 2)
├── grid_position
└── speed attribute

unit_selection.gd       # Visual selection indicator
```

### Key Algorithms
1. **Pathfinding**: `AStar2D` for hex grid navigation
2. **Movement Range**: BFS in `get_reachable_tiles()`
3. **Grid Coordination**: `Vector2i` coordinate system with neighbor detection

### Scene Structure
- `game_scene.tscn`: Main game scene with TileMapLayer
- `unit.tscn`: Unit scene with Sprite2D
- `unit_selection.tscn`: Selection indicator scene
- `main_menu.tscn`: Placeholder main menu (minimal)

## Project Structure Recommendations

### Current Problems
- Files scattered in root directory
- No clear separation of concerns
- Assets mixed with code files
- No scene organization

### Recommended Structure
```
/
├── scenes/                    # All .tscn files
│   ├── game/                 # Gameplay scenes
│   │   ├── game_scene.tscn
│   │   ├── unit.tscn
│   │   └── unit_selection.tscn
│   └── ui/                   # UI scenes
│       ├── main_menu.tscn
│       └── (future UI scenes)
├── scripts/                  # All .gd files
│   ├── game/                 # Gameplay logic
│   │   ├── game_scene.gd
│   │   ├── unit.gd
│   │   ├── combat.gd         # Future: combat system
│   │   ├── turn_manager.gd   # Future: turn system
│   │   └── relic.gd          # Future: relic mechanics
│   └── ui/                   # UI logic
│       └── (future UI scripts)
├── assets/                   # All visual/audio assets
│   ├── textures/            # Images, sprites
│   │   ├── tiles/          # Hex tiles
│   │   ├── units/          # Unit sprites
│   │   └── ui/             # UI elements
│   ├── fonts/               # Font files
│   └── audio/               # Sound effects & music
├── config/                  # Configuration files
│   ├── game_config.gd      # Game balance constants
│   └── (other configs)
└── project.godot           # Godot project config
```

### Immediate Improvements
1. **Move .tscn files** to `scenes/` directory
2. **Move .gd files** to `scripts/` directory
3. **Move images** to `assets/textures/` directory
4. **Create scene subfolders** for better organization
5. **Separate concerns** into dedicated scripts (combat, turns, etc.)

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
1. **Combat System**: Needs HP tracking, damage calculation, death/respawn
2. **Turn Management**: Player switching, action limits, turn phases
3. **Relic Implementation**: Pickup, carrying state, speed progression
4. **UI/UX**: Player feedback, status display, controls explanation
5. **Multiplayer**: Network synchronization, connection handling

---

## For Future AI Sessions

### Key Context Points
- This is a **hex-based tactics game**
- Game is football/soccer inspired with a central relic objective
- Focus on **multiplayer browser play** with friends
- Current state: Basic movement/selection only, missing core mechanics
- **Hotseat mode** is first multiplayer target, then online multiplayer

### Development Priorities
1. **Core gameplay loop** (combat + turns + relic)
2. **Hotseat multiplayer** (local player switching)
3. **Browser deployment** testing
4. **Polish & UI** for playability
5. **Online multiplayer** implementation

### Testing Focus
- Relic power progression balance
- Anti-turtling effectiveness
- Game length and pacing
- Multiplayer synchronization

---

*Last Updated: 2026-01-05*
*Maintained for Claude Code/DeepSeek AI collaboration*