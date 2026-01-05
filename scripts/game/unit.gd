class_name Unit
extends Node2D
@export var conflict_side: int = 1
@export var grid_position: Vector2i
@export var speed: int = 2
var movement_left: int = 2  # How much movement this unit has left this turn

@onready var sprite: Sprite2D = $Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # Set the appropriate sprite based on conflict side
    if conflict_side == 1:
        sprite.texture = preload("res://assets/images/objects/unit_red.png")
    else:
        sprite.texture = preload("res://assets/images/objects/unit_blue.png")
    # Initialize movement for first turn
    movement_left = speed

# Reset movement at start of player's turn
func reset_movement() -> void:
    movement_left = speed
