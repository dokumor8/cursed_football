class_name Unit
extends Node2D

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
@onready var hp_label: Label = $HPLabel

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
    # Fill HP label
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
    # Unit is stunned on the same turn it becomes a relic holder
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

    if timer >= len(GC.RELIC_HOLDER_SPEED):
        movement_left = GC.RELIC_HOLDER_SPEED[-1]
        attack_power = GC.RELIC_HOLDER_ATTACK[-1]
    else:
        movement_left = GC.RELIC_HOLDER_SPEED[timer]
        attack_power = GC.RELIC_HOLDER_ATTACK[timer]

    print("Relic holder effects: timer=", timer, ", speed=", movement_left, ", attack=", attack_power)

# Drop relic (when unit dies or otherwise loses relic)
func drop_relic() -> void:
    is_relic_holder = false
    _update_relic_sprite()
    # Reset to normal stats
    movement_left = speed
    attack_power = GC.UNIT_ATTACK_POWER
    print("Unit dropped relic")

func _update_hp_label() -> void:
    # Update the HP label text
    if hp_label:
        hp_label.text = str(current_hp) + "/" + str(max_hp)
        # Change color based on HP
        if current_hp <= 2:
            hp_label.add_theme_color_override("font_color", Color.YELLOW)
        if current_hp <= 1:
            hp_label.add_theme_color_override("font_color", Color.RED)
