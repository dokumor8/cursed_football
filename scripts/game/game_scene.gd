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



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    
    unit_selection = UnitSelectionScene.instantiate()
    unit_selection.visible = false
    add_child(unit_selection)
    
    for location in start_locations_1:
        _spawn_unit_at_tile(UnitScene, location, 1)
    for location in start_locations_2:
        _spawn_unit_at_tile(UnitScene, location, 2)


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
    for unit: Unit in get_tree().get_nodes_in_group("units"):
        if unit.grid_position == coords:
            select_unit(unit)
            return
    if selected_unit:
        var unit_coords = selected_unit.grid_position
        print("Unit from", unit_coords)
        print("walks to", coords)
        var reachable = get_reachable_tiles(unit_coords, selected_unit.speed)
        if reachable.has(coords):
            move_unit(selected_unit, coords)
            clear_selection()
            clear_walkable_highlight()


func clear_walkable_highlight() -> void:
    for coord in highlight_layer.get_used_cells():
        highlight_layer.erase_cell(coord)


func highlight_walkable_tiles(unit) -> void:
    var starting_coord = unit.grid_position
    clear_walkable_highlight()

    var reachable = get_reachable_tiles(starting_coord, unit.speed)
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


func move_unit(unit, target_cell) -> void:
    obstacles[unit.grid_position] = false
    unit.grid_position = target_cell
    unit.global_position = terrain_layer.to_global(terrain_layer.map_to_local(target_cell))
    obstacles[target_cell] = true
