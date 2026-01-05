class_name Unit
extends Node2D
@export var conflict_side: int = 1
@export var grid_position: Vector2i
@export var speed: int = 2
var movement_left: int = 2  # How much movement this unit has left this turn

# Combat stats
@export var max_hp: int = 2
var current_hp: int = 2
@export var attack_power: int = 1  # Damage dealt per attack
var has_attacked_this_turn: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_label: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # Set the appropriate sprite based on conflict side
    if conflict_side == 1:
        sprite.texture = preload("res://assets/images/objects/unit_red.png")
    else:
        sprite.texture = preload("res://assets/images/objects/unit_blue.png")
    # Initialize movement for first turn
    movement_left = speed
    # Initialize HP
    current_hp = max_hp

    # Create HP label
    _create_hp_label()
    _update_hp_label()

# Reset movement and attack status at start of player's turn
func reset_turn() -> void:
    movement_left = speed
    has_attacked_this_turn = false

# Take damage from an attack
func take_damage(damage: int) -> void:
    current_hp -= damage
    if current_hp < 0:
        current_hp = 0
    print("Unit took ", damage, " damage. HP: ", current_hp, "/", max_hp)
    # Update HP label
    _update_hp_label()

# Check if unit is dead
func is_dead() -> bool:
    return current_hp <= 0

# Attack another unit
func attack(target: Unit) -> void:
    if not has_attacked_this_turn:
        target.take_damage(attack_power)
        has_attacked_this_turn = true
        # After attacking, movement left drops to zero
        movement_left = 0
        print("Unit attacked. Can't move anymore this turn.")


func _create_hp_label() -> void:
    # Create a label to show HP above the unit
    hp_label = Label.new()
    hp_label.name = "HPLabel"
    hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    hp_label.position = Vector2(0, -25)  # Position above the unit
    hp_label.add_theme_font_size_override("font_size", 16)
    hp_label.add_theme_color_override("font_color", Color.WHITE)
    add_child(hp_label)


func _update_hp_label() -> void:
    # Update the HP label text
    if hp_label:
        hp_label.text = str(current_hp) + "/" + str(max_hp)
        # Change color based on HP
        if current_hp <= max_hp / 2:
            hp_label.add_theme_color_override("font_color", Color.YELLOW)
        if current_hp <= 1:
            hp_label.add_theme_color_override("font_color", Color.RED)
