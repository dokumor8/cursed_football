class_name Unit
extends Node2D

const GC = preload("res://scripts/config/GameConstants.gd")

@export var conflict_side: int = 1
@export var grid_position: Vector2i
@export var speed: int = GC.UNIT_SPEED
var movement_left: int = GC.UNIT_SPEED  # How much movement this unit has left this turn

# Combat stats
@export var max_hp: int = GC.UNIT_MAX_HP
var current_hp: int = GC.UNIT_MAX_HP
@export var attack_power: int = GC.UNIT_ATTACK_POWER  # Damage dealt per attack
var has_attacked_this_turn: bool = false

# Relic stats
var is_relic_holder: bool = false

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
    if not is_relic_holder:
        movement_left = speed
    # Relic holders get their movement from apply_relic_effects() called by game scene
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
    if not has_attacked_this_turn and attack_power > 0:
        target.take_damage(attack_power)
        has_attacked_this_turn = true
        # After attacking, movement left drops to zero
        movement_left = 0
        print("Unit attacked. Can't move anymore this turn.")
    elif attack_power <= 0:
        print("Unit cannot attack (attack power is 0)")

# Become a relic holder (timer passed from game scene)
func become_relic_holder(timer: int) -> void:
    is_relic_holder = true
    _update_relic_sprite()
    apply_relic_effects(timer)
    movement_left = 0
    print("Unit became relic holder with timer:", timer)

# Update sprite based on relic holder status
func _update_relic_sprite() -> void:
    if is_relic_holder:
        if conflict_side == 1:
            sprite.texture = preload("res://assets/images/objects/relic_holder_red.png")
        else:
            sprite.texture = preload("res://assets/images/objects/relic_holder_blue.png")
    else:
        if conflict_side == 1:
            sprite.texture = preload("res://assets/images/objects/unit_red.png")
        else:
            sprite.texture = preload("res://assets/images/objects/unit_blue.png")

# Apply relic effects based on global timer
func apply_relic_effects(timer: int) -> void:
    if not is_relic_holder:
        return

    # According to PROJECT.md relic progression:
    # Turn 1: 0 speed, 0 damage (stunned)
    # Turns 2-3: 1 speed, 0 damage (slowed, can't attack)
    # Turns 4-5: 2 speed, 1 damage (normal)
    # Turns 6-7: 3 speed, 1 damage (speed boost)
    # Turns 8-9: 4 speed, 1 damage (maximum speed)
    # Turns 10-11: 4 speed, 2 damage (maximum speed, double damage)
    # Turn 12+: 4 speed, 3 damage (maximum speed, one-shot attack)

    match timer:
        0:  # Just picked up - stunned
            movement_left = 0
            attack_power = 0
        1, 2:  # Turns 2-3 - slowed, can't attack
            movement_left = 1
            attack_power = 0
        3, 4:  # Turns 4-5 - normal
            movement_left = 2
            attack_power = 1
        5, 6:  # Turns 6-7 - speed boost
            movement_left = 3
            attack_power = 1
        7, 8:  # Turns 8-9 - maximum speed
            movement_left = 4
            attack_power = 1
        9, 10:  # Turns 10-11 - maximum speed, double damage
            movement_left = 4
            attack_power = 2
        _:  # Turn 12+ - maximum speed, one-shot attack
            movement_left = 4
            attack_power = 3

    print("Relic holder effects: timer=", timer, ", speed=", movement_left, ", attack=", attack_power)

# Transfer relic from another unit (for stealing) - timer passed from game scene
func transfer_relic(timer: int) -> void:
    is_relic_holder = true
    _update_relic_sprite()
    apply_relic_effects(timer)
    movement_left = 0
    print("Relic transferred to unit. Global timer:", timer)

# Drop relic (when unit dies or otherwise loses relic)
func drop_relic() -> void:
    is_relic_holder = false
    _update_relic_sprite()
    # Reset to normal stats
    movement_left = speed
    attack_power = 1
    print("Unit dropped relic")


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
        if current_hp <= 2:
            hp_label.add_theme_color_override("font_color", Color.YELLOW)
        if current_hp <= 1:
            hp_label.add_theme_color_override("font_color", Color.RED)
