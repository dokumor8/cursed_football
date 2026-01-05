extends Node2D

@onready var terrain_layer: TileMapLayer = $TileMapLayer
@onready var highlight_layer: TileMapLayer = $HighlightLayer
var obstacles: Dictionary = {}

var UnitScene: PackedScene = preload("res://scenes/game/unit.tscn")
var UnitSelectionScene: PackedScene = preload("res://scenes/game/unit_selection.tscn")
var unit_selection: UnitSelection


var start_locations_1 = [Vector2i(3, 8), Vector2i(4, 8), Vector2i(5, 8)]
var home_location_1 = Vector2i(4, 9)
var start_locations_2 = [Vector2i(3, 3), Vector2i(4, 4), Vector2i(5, 3)]
var home_location_2 = Vector2i(4, 3)

var relic_timer: int = 0
var relic_speed_effect: Array[int] = [-2, -1, 0, 1, 2]

var selected_tile: Vector2i
var selected_unit: Unit

# Turn tracking
var current_player: int = 1  # 1 = Red player (bottom), 2 = Blue player (top)

# UI elements
@onready var turn_indicator: Label = $UILayer/MainUIContainer/TopBar/TurnIndicator
@onready var relic_status: Label = $UILayer/MainUIContainer/TopBar/RelicStatus
@onready var end_turn_button: Button = $UILayer/MainUIContainer/BottomBar/EndTurnButton
@onready var revive_button: Button = $UILayer/MainUIContainer/BottomBar/ReviveButton
@onready var revive_count: Label = $UILayer/MainUIContainer/BottomBar/ReviveCount



# Called when the node enters the scene tree for the first time.
func _ready() -> void:

    unit_selection = UnitSelectionScene.instantiate()
    unit_selection.visible = false
    add_child(unit_selection)

    for location in start_locations_1:
        _spawn_unit_at_tile(UnitScene, location, 1)
    for location in start_locations_2:
        _spawn_unit_at_tile(UnitScene, location, 2)

    # Initialize UI
    _update_turn_indicator()
    _update_relic_status()
    _update_revive_ui()

    # Connect End Turn button signal
    end_turn_button.pressed.connect(_on_end_turn_button_pressed)

    # Initialize movements for starting player (Red)
    _reset_player_unit_movements()


func _is_walkable(coords: Vector2i) -> bool:
    if terrain_layer.get_cell_source_id(coords) == -1:
        return false
    if not obstacles.has(coords):
        return true
    return not obstacles[coords]


func _spawn_unit_at_tile(spawning_scene: PackedScene, grid_pos: Vector2i, side=1):
    var unit = spawning_scene.instantiate()
    unit.conflict_side = side
    add_child(unit)
    unit.grid_position = grid_pos
    obstacles[grid_pos] = true
    
    var local_pos = terrain_layer.map_to_local(grid_pos)
    var global_pos = terrain_layer.to_global(local_pos)
    unit.global_position = global_pos


func select_tile(coords: Vector2i) -> void:
    selected_tile = coords

    # Check if clicking on a unit
    for unit: Unit in get_tree().get_nodes_in_group("units"):
        if unit.grid_position == coords:
            # Only allow selecting units belonging to current player
            if unit.conflict_side == current_player:
                select_unit(unit)
            else:
                print("Cannot select opponent's unit during your turn")
            return

    # If we have a selected unit, try to move it
    if selected_unit:
        var unit_coords = selected_unit.grid_position
        print("Unit from", unit_coords)
        print("walks to", coords)
        var reachable = get_reachable_tiles(unit_coords, selected_unit.movement_left)
        if reachable.has(coords):
            move_unit(selected_unit, coords)
            clear_selection()
            clear_walkable_highlight()
            # Note: Turn no longer switches automatically after moving
            # Player must click "End Turn" button to end their turn
        else:
            # Clicked on a tile that's not reachable - clear selection
            print("Tile not reachable")
            clear_selection()
            clear_walkable_highlight()
    else:
        # Clicked on empty tile with no unit selected - clear any existing selection
        clear_selection()
        clear_walkable_highlight()


func clear_walkable_highlight() -> void:
    for coord in highlight_layer.get_used_cells():
        highlight_layer.erase_cell(coord)


func highlight_walkable_tiles(unit) -> void:
    var starting_coord = unit.grid_position
    clear_walkable_highlight()

    var reachable = get_reachable_tiles(starting_coord, unit.movement_left)
    for tile in reachable:
        highlight_layer.set_cell(tile, 0, Vector2i(0, 0))


func select_unit(unit: Unit) -> void:
    unit_selection.global_position = unit.global_position
    unit_selection.visible = true
    selected_unit = unit
    highlight_walkable_tiles(unit)


func _handle_tile_click(tile_coords: Vector2i) -> void:
    # check that tile is in the board
    if terrain_layer.get_cell_source_id(tile_coords) != -1:
        print("Clicked tile at: ", tile_coords)
        
        select_tile(tile_coords)
        
    else:
        clear_selection()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton \
    and event.button_index == MOUSE_BUTTON_LEFT \
    and event.pressed:
        
        var local_pos: Vector2 = terrain_layer.to_local(get_global_mouse_position())
        var tile_coords: Vector2i = terrain_layer.local_to_map(local_pos)

        _handle_tile_click(tile_coords)


func clear_selection():
    unit_selection.visible = false
    selected_unit = null


func get_reachable_tiles(start: Vector2i, max_distance: int) -> Array[Vector2i]:
    var reachable: Array[Vector2i] = []
    var queue: Array[Vector2i] = [start]
    var distances: Dictionary = {start: 0}
    var visited: Dictionary = {start: true}
    
    while not queue.is_empty():
        var current = queue.pop_front()
        var dist = distances[current]
        if dist > max_distance:
            continue
        reachable.append(current)
        
        for neighbor in terrain_layer.get_surrounding_cells(current):
            if neighbor == Vector2i(-1, -1) or visited.has(neighbor) or not _is_walkable(neighbor):
                continue
            visited[neighbor] = true
            distances[neighbor] = dist + 1
            queue.append(neighbor)
    
    return reachable


func move_unit(unit: Unit, target_cell) -> void:
    # Calculate movement cost (1 per tile for now)
    var movement_cost: int = 1

    # Check if unit has enough movement left
    if unit.movement_left >= movement_cost:
        # Update obstacles
        obstacles[unit.grid_position] = false
        unit.grid_position = target_cell
        unit.global_position = terrain_layer.to_global(terrain_layer.map_to_local(target_cell))
        obstacles[target_cell] = true

        # Decrement movement left
        unit.movement_left -= movement_cost
        print("Unit moved. Movement left:", unit.movement_left)
    else:
        print("Unit doesn't have enough movement left")


func _switch_player_turn() -> void:
    # Switch to the other player
    if current_player == 1:
        current_player = 2
        print("Now it's Blue player's turn")
    else:
        current_player = 1
        print("Now it's Red player's turn")

    # Reset movement for all units of the new current player
    _reset_player_unit_movements()

    # Update the UI
    _update_turn_indicator()


func _reset_player_unit_movements() -> void:
    # Reset movement_left for all units belonging to current player
    for unit: Unit in get_tree().get_nodes_in_group("units"):
        if unit.conflict_side == current_player:
            unit.reset_movement()


func _update_turn_indicator() -> void:
    # Update the turn indicator label based on current player
    if current_player == 1:
        turn_indicator.text = "Red Player's Turn"
        turn_indicator.add_theme_color_override("font_color", Color.RED)
    else:
        turn_indicator.text = "Blue Player's Turn"
        turn_indicator.add_theme_color_override("font_color", Color.BLUE)


func _update_relic_status() -> void:
    # Placeholder for relic status updates
    # This will be implemented when relic mechanics are added
    relic_status.text = "Relic: Not Active"


func _update_revive_ui() -> void:
    # Placeholder for revive UI updates
    # This will be implemented when revive mechanics are added
    revive_button.disabled = true
    revive_count.text = "Revives: 0"


func _on_end_turn_button_pressed() -> void:
    # End current player's turn and switch to other player
    print("Ending turn for player", current_player)
    _switch_player_turn()
