# GameConstants.gd
# Central configuration file for game balance and constants
# Access constants via GameConstants.CONSTANT_NAME

extends Node2D


# Player side constants - use these instead of magic numbers 1 and 2
var PLAYER_RED: int = 1    # Red player (bottom)
var PLAYER_BLUE: int = 2   # Blue player (top)

# Player spawn positions
var RED_SPAWN_POSITIONS: Array[Vector2i] = [
    Vector2i(3, 5),
    Vector2i(4, 5),
    Vector2i(5, 5)
]

var BLUE_SPAWN_POSITIONS: Array[Vector2i] = [
    Vector2i(3, 0),
    Vector2i(4, 1),
    Vector2i(5, 0)
]

# Goal positions
var RED_GOAL_POSITION: Vector2i = Vector2i(4, 6)
var BLUE_GOAL_POSITION: Vector2i = Vector2i(4, 0)

# Relic configuration
var INITIAL_RELIC_POSITION: Vector2i = Vector2i(4, 3)  # Center of map
var RELIC_HOLDER_SPEED: Array[int] =  [0, 1, 1, 2, 2, 3, 3, 4, 4, 4, 4, 4, 4]
var RELIC_HOLDER_ATTACK: Array[int] = [0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 3, 3]

# Tile atlas coordinates for highlighting
var REVIVAL_HIGHLIGHT_ATLAS: Vector2i = Vector2i(1, 0)
var ATTACK_HIGHLIGHT_ATLAS: Vector2i = Vector2i(2, 0)
var GOAL_HIGHLIGHT_ATLAS: Vector2i = Vector2i(0, 1)

# Unit base stats
var UNIT_MAX_HP: int = 3
var UNIT_SPEED: int = 2
var UNIT_ATTACK_POWER: int = 1

# Game rules
var REVIVE_TOKEN_REWARD: int = 1  # Tokens gained per enemy unit killed

# Helper functions to get player-specific data
func get_spawn_positions(player: int) -> Array[Vector2i]:
    match player:
        PLAYER_RED:
            return RED_SPAWN_POSITIONS
        PLAYER_BLUE:
            return BLUE_SPAWN_POSITIONS
        _:
            push_error("Invalid player number: " + str(player))
            return []

func get_goal_position(player: int) -> Vector2i:
    match player:
        PLAYER_RED:
            return RED_GOAL_POSITION
        PLAYER_BLUE:
            return BLUE_GOAL_POSITION
        _:
            push_error("Invalid player number: " + str(player))
            return Vector2i.ZERO
