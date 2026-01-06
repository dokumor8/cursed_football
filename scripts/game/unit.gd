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

# Relic stats
var is_relic_holder: bool = false
var relic_timer: int = 0  # How many turns unit has held the relic

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
    # Relic holders get their movement from _apply_relic_effects()
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

# Become a relic holder
func become_relic_holder() -> void:
    is_relic_holder = true
    relic_timer = 0
    _update_relic_sprite()
    _apply_relic_effects()
    print("Unit became relic holder")

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

# Apply relic effects based on timer
func _apply_relic_effects() -> void:
    if not is_relic_holder:
        return

    # According to PROJECT.md relic progression:
    # Turn 1: 0 speed, 0 damage (stunned)
    # Turn 2: 1 speed, 0 damage (slowed, can't attack)
    # Turn 3: 2 speed, 1 damage (normal)
    # Turn 4: 3 speed, 1 damage (speed boost)
    # Turn 5: 4 speed, 1 damage (maximum speed)
    # Turn 6+: 4 speed, 2 damage (maximum speed, one-shot attack)

    match relic_timer:
        0:  # Just picked up - stunned
            movement_left = 0
            attack_power = 0
        1:  # Turn 2 - slowed, can't attack
            movement_left = 1
            attack_power = 0
        2:  # Turn 3 - normal
            movement_left = 2
            attack_power = 1
        3:  # Turn 4 - speed boost
            movement_left = 3
            attack_power = 1
        4:  # Turn 5 - maximum speed
            movement_left = 4
            attack_power = 1
        _:  # Turn 6+ - maximum speed, one-shot attack
            movement_left = 4
            attack_power = 2

    print("Relic holder effects: speed=", movement_left, ", attack=", attack_power)

# Increment relic timer (called at end of each turn)
func increment_relic_timer() -> void:
    if is_relic_holder:
        relic_timer += 1
        _apply_relic_effects()

# Transfer relic from another unit (for stealing)
func transfer_relic_from(previous_holder: Unit) -> void:
    is_relic_holder = true
    relic_timer = previous_holder.relic_timer  # Keep the same timer
    _update_relic_sprite()
    _apply_relic_effects()
    print("Relic transferred to unit. Timer:", relic_timer)

# Drop relic (when unit dies or otherwise loses relic)
func drop_relic() -> void:
    is_relic_holder = false
    relic_timer = 0
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
        if current_hp <= max_hp / 2:
            hp_label.add_theme_color_override("font_color", Color.YELLOW)
        if current_hp <= 1:
            hp_label.add_theme_color_override("font_color", Color.RED)
