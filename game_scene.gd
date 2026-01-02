extends Node2D

@onready var tilemap_layer: TileMapLayer = $TileMapLayer  # Adjust path
@export var unit_scene: PackedScene = preload("res://unit.tscn")
@export var unit_selection: PackedScene = preload("res://unit_selection.tscn")

var selected_unit_marker: Sprite2D

var start_locations_1 = [Vector2i(3, 8), Vector2i(4, 8), Vector2i(5, 8)]
var home_location_1 = Vector2i(4, 9)
var start_locations_2 = [Vector2i(3, 3), Vector2i(4, 4), Vector2i(5, 3)]
var home_location_2 = Vector2i(4, 3)

var selected_tile: Vector2i
var selected_unit: Unit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	for location in start_locations_1:
		_spawn_unit_at_tile(unit_scene, location, 1)
	for location in start_locations_2:
		_spawn_unit_at_tile(unit_scene, location, 2)


func _spawn_unit_at_tile(spawning_scene: PackedScene, grid_pos: Vector2i, side=1):
	var unit = spawning_scene.instantiate()
	unit.conflict_side = side
	add_child(unit)
	unit.grid_position = grid_pos
	var local_pos = tilemap_layer.map_to_local(grid_pos)
	var global_pos = tilemap_layer.to_global(local_pos)
	unit.global_position = global_pos


func select_tile(coords: Vector2i) -> void:
	selected_tile = coords
	for unit: Unit in get_tree().get_nodes_in_group("units"):
		if unit.grid_position == coords:
			select_unit(unit)
			return


func select_unit(unit: Unit) -> void:
	
	selected_unit = unit

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		
		var local_pos: Vector2 = tilemap_layer.to_local(get_global_mouse_position())
		var tile_coords: Vector2i = tilemap_layer.local_to_map(local_pos)
		# Get the tile coordinates under the mouse (in one line!)
		#var tile_coords: Vector2i = local_to_map(get_local_mouse_position())
		
		# Optional: Check if a tile actually exists there
		if tilemap_layer.get_cell_source_id(tile_coords) != -1:
			print("Selected tile at: ", tile_coords)  # Or emit a signal/store in a var
			select_tile(tile_coords)  # Your turn-based logic here


#func _unhandled_input(event: InputEvent) -> void:
	# ... same if-condition ...

	# ... rest same ...
