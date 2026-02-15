class_name Unit
extends Node2D

@export var conflict_side: int = GC.PLAYER_RED
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
    if conflict_side == GC.PLAYER_RED:
        sprite.texture = preload("res://assets/images/objects/unit_red2.png")
    else:
        sprite.texture = preload("res://assets/images/objects/unit_blue2.png")
    # Initialize movement for first turn
    movement_left = speed
    # Initialize HP
    current_hp = max_hp
    # Fill HP label
    _update_hp_label()


func serialize() -> Dictionary:
    var unit_data = {
        "grid_pos_x": grid_position.x,
        "grid_pos_y": grid_position.y,
        "current_hp": current_hp,
        "is_relic_holder": is_relic_holder,
        "has_attacked_this_turn": has_attacked_this_turn,
        "attack_power": attack_power,
        "conflict_side": conflict_side,
        "speed": speed,
        "movement_left": movement_left
    }
    return unit_data

# Reset movement and attack status at start of player's turn
func reset_turn() -> void:
    if not is_relic_holder:
        movement_left = speed
    # Relic holders get their movement from apply_relic_effects() called by game scene
    has_attacked_this_turn = false

# Take damage from an attack
func take_damage(damage: int) -> void:
    print("DEBUG: take_damage called with damage=", damage, ", current_hp=", current_hp)
    current_hp -= damage
    if is_dead():
        current_hp = 0
        _handle_unit_death()
    print("Unit took ", damage, " damage. HP: ", current_hp, "/", max_hp)
    # Update HP label
    _update_hp_label()

# TODO: death handling should happen at the end of the action
# so the relic taking works with an existing unit with 0 hp
func _handle_unit_death() -> void:
    # Remove unit from the board
    print("Unit died at", grid_position)

    # Remove the unit node from the scene
    queue_free()
    remove_from_group("units")

    # Increment revive count for the player who lost the unit
    if conflict_side == GC.PLAYER_RED:
        GS.red_revive_count += GC.REVIVE_TOKEN_REWARD # Red player killed a blue unit
        print("Red player gets a revive token. Total:", GS.red_revive_count)
    else:
        GS.blue_revive_count += GC.REVIVE_TOKEN_REWARD # Blue player killed a red unit
        print("Blue player gets a revive token. Total:", GS.blue_revive_count)


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
    else:
        print("Unit has already attacked this turn (has_attacked_this_turn = true)")

# Become a relic holder (timer passed from game scene)
func become_relic_holder(timer: int) -> void:
    GS.relic_holder = self
    is_relic_holder = true
    _update_relic_sprite()
    apply_relic_effects(timer)
    # Unit is stunned on the same turn it becomes a relic holder
    movement_left = 0
    print("Unit became relic holder with timer:", timer)

# Update sprite based on relic holder status
func _update_relic_sprite() -> void:
    if is_relic_holder:
        if conflict_side == GC.PLAYER_RED:
            sprite.texture = preload("res://assets/images/objects/relic_holder_red2.png")
        else:
            sprite.texture = preload("res://assets/images/objects/relic_holder_blue.png")
    else:
        if conflict_side == GC.PLAYER_RED:
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


func _update_hp_label() -> void:
    print_verbose("DEBUG: updating HP UI")
    # Update the HP label text
    if hp_label:
        hp_label.text = str(current_hp) + "/" + str(max_hp)
        # Change color based on HP
        if current_hp <= 2:
            hp_label.add_theme_color_override("font_color", Color.YELLOW)
        if current_hp <= 1:
            hp_label.add_theme_color_override("font_color", Color.RED)
