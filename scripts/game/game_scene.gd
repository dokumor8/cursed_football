extends Node2D

@onready var terrain_layer: TileMapLayer = $TileMapLayer
@onready var highlight_layer: TileMapLayer = $HighlightLayer
var obstacles: Dictionary = {}

var UnitScene: PackedScene = preload("res://scenes/game/unit.tscn")
var UnitSelectionScene: PackedScene = preload("res://scenes/game/unit_selection.tscn")
var RelicScene: PackedScene = preload("res://scenes/game/relic.tscn")
var unit_selection: UnitSelection
var relic_instance: Node2D
var relic_position: Vector2i = GC.INITIAL_RELIC_POSITION  # Center of map

# Revival system
var is_revival_mode: bool = false
var revival_highlight_atlas: Vector2i = GC.REVIVAL_HIGHLIGHT_ATLAS  # Different tile for revival highlight
var attack_highlight_atlas: Vector2i = GC.ATTACK_HIGHLIGHT_ATLAS  # Different tile for attack highlight
var goal_highlight_atlas: Vector2i = GC.GOAL_HIGHLIGHT_ATLAS  # Different tile for goal highlight

var relic_timer: int = 0

# UI elements
@onready var turn_indicator: Label = $UILayer/MainUIContainer/TopBar/TurnIndicator
@onready var relic_status: Label = $UILayer/MainUIContainer/TopBar/RelicStatus
@onready var end_turn_button: Button = $UILayer/MainUIContainer/BottomBar/EndTurnButton
@onready var revive_button: Button = $UILayer/MainUIContainer/BottomBar/ReviveButton
@onready var reset_button: Button = $UILayer/MainUIContainer/BottomBar/ResetTurnButton
@onready var revive_count: Label = $UILayer/MainUIContainer/BottomBar/ReviveCount
@onready var victory_message: Label = $UILayer/MainUIContainer/VictoryMessage

# Game over menu
var GameOverMenuScene: PackedScene = null
var game_over_menu: PopupPanel = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:

    unit_selection = UnitSelectionScene.instantiate()
    unit_selection.visible = false
    add_child(unit_selection)

    # Try to load game over menu scene
    _load_game_over_menu()

    for location in GC.get_spawn_positions(GC.PLAYER_RED):
        spawn_unit_at_tile(UnitScene, location, GC.PLAYER_RED)
    for location in GC.get_spawn_positions(GC.PLAYER_BLUE):
        spawn_unit_at_tile(UnitScene, location, GC.PLAYER_BLUE)

    # Spawn relic at center of map
    spawn_relic_at_tile(relic_position)

    # Initialize UI
    _update_turn_indicator()
    _update_relic_status()
    _update_revive_ui()

    # Highlight goal tiles
    _highlight_goal_tiles()

    # Connect button signals
    end_turn_button.pressed.connect(_on_end_turn_button_pressed)
    revive_button.pressed.connect(_on_revive_button_pressed)
    reset_button.pressed.connect(_on_reset_button_pressed)

    # Initialize movements for starting player (Red)
    _reset_player_unit_movements()


func _is_walkable(coords: Vector2i) -> bool:
    if terrain_layer.get_cell_source_id(coords) == -1:
        return false
    if not obstacles.has(coords):
        return true
    return not obstacles[coords]


func spawn_unit_at_tile(spawning_scene: PackedScene, grid_pos: Vector2i, side=GC.PLAYER_RED) -> Unit:
    var unit = spawning_scene.instantiate()
    unit.conflict_side = side
    add_child(unit)
    unit.add_to_group("units")  # Add to units group for easy finding
    unit.grid_position = grid_pos
    obstacles[grid_pos] = true

    var local_pos = terrain_layer.map_to_local(grid_pos)
    var global_pos = terrain_layer.to_global(local_pos)
    unit.global_position = global_pos
    print("Spawning unit at", grid_pos)
    return unit


func spawn_relic_at_tile(grid_pos: Vector2i):
    relic_instance = RelicScene.instantiate()
    add_child(relic_instance)
    relic_position = grid_pos

    # Make relic tile an obstacle when on ground
    obstacles[grid_pos] = true

    var local_pos = terrain_layer.map_to_local(grid_pos)
    var global_pos = terrain_layer.to_global(local_pos)
    relic_instance.global_position = global_pos


func _pickup_relic(unit: Unit) -> void:
    # Unit picks up the relic with current global timer
    unit.become_relic_holder(relic_timer)
    GS.relic_holder = unit

    # Remove relic from obstacles (it's now carried by unit)
    obstacles[relic_position] = false

    # Hide the relic sprite
    if relic_instance:
        relic_instance.queue_free()
        relic_instance = null

    # Update relic status UI
    _update_relic_status()

    # Apply attack penalty (like attacking)
    unit.has_attacked_this_turn = true
    unit.movement_left = 0
    print("Relic picked up by unit at", unit.grid_position, "with global timer:", relic_timer)


func _steal_relic(new_holder: Unit, previous_holder: Unit) -> void:
    # Safety checks
    if new_holder == null:
        print("ERROR: new_holder is null in _steal_relic!")
        return

    if previous_holder == null:
        print("ERROR: previous_holder is null in _steal_relic!")
        return

    if new_holder == previous_holder:
        print("ERROR: new_holder == previous_holder in _steal_relic!")
        return

    # Previous holder drops the relic
    previous_holder.drop_relic()

    # New holder takes the relic with current global timer
    new_holder.become_relic_holder(relic_timer)
    GS.relic_holder = new_holder

    # Update relic status UI
    _update_relic_status()
    print("Relic stolen by unit at", new_holder.grid_position, "with global timer:", relic_timer)


func select_tile(coords: Vector2i) -> void:
    # Handle revival mode first
    if is_revival_mode:
        _handle_revival_click(coords)
        return

    # If we have a selected unit
    if GS.selected_unit:
        var unit_coords = GS.selected_unit.grid_position

        # First check if clicking on the relic for pickup
        if coords == relic_position and GS.relic_holder == null and _are_tiles_adjacent(unit_coords, coords):
            # Pick up the relic
            print("Picking up relic at", coords)
            _pickup_relic(GS.selected_unit)
            clear_selection()
            clear_walkable_highlight()
            return

        # Then check if clicking on an enemy unit for attack
        var enemy_unit_at_tile: Unit = null
        for unit: Unit in get_tree().get_nodes_in_group("units"):
            if unit.grid_position == coords and unit.conflict_side != GS.current_player:
                enemy_unit_at_tile = unit
                break

        if enemy_unit_at_tile and _are_tiles_adjacent(unit_coords, coords):
            # Attack the enemy unit
            print("Attacking enemy unit at", coords)
            GS.selected_unit.attack(enemy_unit_at_tile)

            # Save reference to attacker before clearing selection
            var attacker: Unit = GS.selected_unit

            clear_selection()
            clear_walkable_highlight()

            # Check if enemy unit died
            if enemy_unit_at_tile.is_dead():
                # Check if the dead unit was holding the relic
                if GS.relic_holder == enemy_unit_at_tile:
                    # Steal the relic - attacker becomes new relic holder
                    _steal_relic(attacker, enemy_unit_at_tile)

                _handle_unit_death(enemy_unit_at_tile)
        else:
            # Try to move the unit
            print("Unit from", unit_coords)
            print("walks to", coords)
            var reachable_data = get_reachable_tiles(unit_coords, GS.selected_unit.movement_left)
            var reachable_tiles: Array[Vector2i] = reachable_data["tiles"]
            if reachable_tiles.has(coords):
                var movement_cost: int = reachable_data["distances"][coords]
                move_unit(GS.selected_unit, coords, movement_cost)
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
        # No unit selected - check if clicking on a unit to select it
        for unit: Unit in get_tree().get_nodes_in_group("units"):
            if unit.grid_position == coords:
                # Only allow selecting units belonging to current player
                if unit.conflict_side == GS.current_player:
                    select_unit(unit)
                else:
                    print("Cannot select opponent's unit during your turn")
                return

        # Clicked on empty tile with no unit selected - clear any existing selection
        clear_selection()
        clear_walkable_highlight()


func clear_walkable_highlight() -> void:
    for coord in highlight_layer.get_used_cells():
        highlight_layer.erase_cell(coord)


func highlight_walkable_tiles(unit) -> void:
    var starting_coord = unit.grid_position
    clear_walkable_highlight()

    var reachable_data = get_reachable_tiles(starting_coord, unit.movement_left)
    var reachable_tiles: Array[Vector2i] = reachable_data["tiles"]
    for tile in reachable_tiles:
        highlight_layer.set_cell(tile, 0, Vector2i(0, 0))

    # Also highlight attackable enemy units
    _highlight_attackable_enemies(unit)


func select_unit(unit: Unit) -> void:
    unit_selection.global_position = unit.global_position
    unit_selection.visible = true
    GS.selected_unit = unit
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
    GS.selected_unit = null


func get_reachable_tiles(start: Vector2i, max_distance: int) -> Dictionary:
    # Returns a dictionary with "tiles" (array of reachable tiles) and "distances" (tile -> distance)
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

    return {"tiles": reachable, "distances": distances}


func move_unit(unit: Unit, target_cell, movement_cost: int = 1) -> void:
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

        # Check for goal scoring (relic holder reaching opponent's goal)
        _check_goal_scoring(unit, target_cell)
    else:
        print("Unit doesn't have enough movement left")


func _check_goal_scoring(unit: Unit, target_cell: Vector2i) -> void:
    # Check if unit is a relic holder
    if not unit.is_relic_holder:
        return

    # Check if relic holder reached opponent's goal
    if unit.conflict_side == GC.PLAYER_RED:
        if target_cell == GC.get_goal_position(GC.PLAYER_BLUE):
            _handle_victory(GC.PLAYER_RED)
    else:  # Blue player
        if target_cell == GC.get_goal_position(GC.PLAYER_RED):
            _handle_victory(GC.PLAYER_BLUE)


func _handle_victory(winning_player: int) -> void:
    # Handle victory condition - game ends immediately
    var player_name = "Red" if winning_player == GC.PLAYER_RED else "Blue"
    var player_color = Color.RED if winning_player == GC.PLAYER_RED else Color.BLUE

    print("VICTORY! Player ", player_name, " wins!")

    # Disable input to prevent further gameplay
    set_process_unhandled_input(false)

    # Disable UI buttons
    end_turn_button.disabled = true
    revive_button.disabled = true

    # Show victory message - use game over menu if available, otherwise fallback
    if game_over_menu and game_over_menu.has_method("show_victory"):
        game_over_menu.show_victory(player_name, player_color)
        print("Showing game over menu")
    else:
        _show_victory_message(player_name, player_color)
        print("Using fallback victory message")


func _show_victory_message(player_name: String, player_color: Color) -> void:
    # Create and show victory message
    if not victory_message:
        # Create victory message label dynamically
        victory_message = Label.new()
        victory_message.name = "VictoryMessage"
        victory_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        victory_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        victory_message.size = Vector2(800, 100)
        victory_message.position = Vector2(400, 300)  # Center of screen (assuming 800x600)
        $UILayer/MainUIContainer.add_child(victory_message)
        print("Created victory message label dynamically")

    victory_message.text = player_name + " Player Wins!"
    victory_message.add_theme_color_override("font_color", player_color)
    victory_message.add_theme_font_size_override("font_size", 48)
    victory_message.visible = true
    print("Victory message shown for", player_name, "player")


func _switch_player_turn() -> void:

    # Switch to the other player
    if GS.current_player == GC.PLAYER_RED:
        GS.current_player = GC.PLAYER_BLUE
        print("Now it's Blue player's turn")
    else:
        # Increment global relic timer once per round (after Blue player's turn)
        if GS.relic_holder:
            relic_timer += 1
            # Update relic holder's effects with new timer value
            GS.relic_holder.apply_relic_effects(relic_timer)
            print("Global relic timer incremented to:", relic_timer)
        GS.current_player = GC.PLAYER_RED
        print("Now it's Red player's turn")

    # Reset movement for all units of the new current player
    _reset_player_unit_movements()

    # Update the UI
    _update_turn_indicator()
    _update_relic_status()


func _reset_player_unit_movements() -> void:
    # Reset movement and attack status for all units belonging to current player
    for unit: Unit in get_tree().get_nodes_in_group("units"):
        if unit.conflict_side == GS.current_player:
            unit.reset_turn()


func _are_tiles_adjacent(tile1: Vector2i, tile2: Vector2i) -> bool:
    # Check if two tiles are adjacent (neighbors) on the hex grid
    var neighbors = terrain_layer.get_surrounding_cells(tile1)
    return neighbors.has(tile2)


func _highlight_attackable_enemies(attacking_unit: Unit) -> void:
    # Highlight enemy units that can be attacked by the selected unit AND relic if it can be picked up
    var attacker_coords = attacking_unit.grid_position

    # Get all adjacent tiles
    var adjacent_tiles = terrain_layer.get_surrounding_cells(attacker_coords)

    for tile in adjacent_tiles:
        # Check if tile contains an enemy unit
        for unit: Unit in get_tree().get_nodes_in_group("units"):
            if unit.grid_position == tile and unit.conflict_side != GS.current_player:
                # This is an attackable enemy unit
                highlight_layer.set_cell(tile, 0, attack_highlight_atlas)
                break

        # Also check if tile contains the relic (and relic is not held by anyone)
        if tile == relic_position and GS.relic_holder == null:
            # This is a pickupable relic
            highlight_layer.set_cell(tile, 0, attack_highlight_atlas)


func _highlight_revival_tiles() -> void:
    # Clear any existing highlights
    clear_walkable_highlight()

    # Get spawn tiles for current player
    var spawn_tiles: Array[Vector2i] = GC.get_spawn_positions(GS.current_player)

    # Highlight each spawn tile if it's not occupied
    for tile in spawn_tiles:
        if _is_walkable(tile):  # Check if tile is not occupied
            highlight_layer.set_cell(tile, 0, revival_highlight_atlas)


func _highlight_goal_tiles() -> void:
    # Highlight both goal tiles
    highlight_layer.set_cell(GC.get_goal_position(GC.PLAYER_RED), 0, goal_highlight_atlas)
    highlight_layer.set_cell(GC.get_goal_position(GC.PLAYER_BLUE), 0, goal_highlight_atlas)
    print("Goal tiles highlighted at", GC.get_goal_position(GC.PLAYER_RED), "and", GC.get_goal_position(GC.PLAYER_BLUE))


func _handle_revival_click(coords: Vector2i) -> void:
    # Check if clicked tile is a valid revival tile
    var spawn_tiles: Array[Vector2i] = GC.get_spawn_positions(GS.current_player)

    if spawn_tiles.has(coords) and _is_walkable(coords):
        # Spawn a unit at this tile
        _revive_unit_at_tile(coords)
    else:
        # Clicked outside revival tiles - do nothing (as per spec)
        print("Clicked outside revival tiles, ignoring")


func _revive_unit_at_tile(grid_pos: Vector2i) -> void:
    # Spawn a unit for current player
    var unit = UnitScene.instantiate()
    unit.conflict_side = GS.current_player
    add_child(unit)
    unit.add_to_group("units")
    unit.grid_position = grid_pos
    obstacles[grid_pos] = true

    # Position the unit
    var local_pos = terrain_layer.map_to_local(grid_pos)
    var global_pos = terrain_layer.to_global(local_pos)
    unit.global_position = global_pos

    # Apply stun effect (like relic holder on turn 1)
    unit.movement_left = 0  # Can't move this turn
    unit.has_attacked_this_turn = true  # Can't attack this turn
    # Note: attack_power is already 1 by default, which is correct for revived units

    print("Revived unit at", grid_pos, "for player", GS.current_player)

    # Decrement revive count
    if GS.current_player == GC.PLAYER_RED:
        GS.red_revive_count -= 1
    else:
        GS.blue_revive_count -= 1

    # Update UI
    _update_revive_ui()

    # Exit revival mode
    is_revival_mode = false
    clear_walkable_highlight()
    revive_button.text = "Revive Unit"

    print("Revival complete. Revives left:", GS.red_revive_count if GS.current_player == GC.PLAYER_RED else GS.blue_revive_count)


func _update_turn_indicator() -> void:
    # Update the turn indicator label based on current player
    if GS.current_player == GC.PLAYER_RED:
        turn_indicator.text = "Red Player's Turn"
        turn_indicator.add_theme_color_override("font_color", Color.RED)
    else:
        turn_indicator.text = "Blue Player's Turn"
        turn_indicator.add_theme_color_override("font_color", Color.BLUE)


func _update_relic_status() -> void:
    if GS.relic_holder:
        var player_name = "Red" if GS.relic_holder.conflict_side == GC.PLAYER_RED else "Blue"
        relic_status.text = "Relic: Held by " + player_name + " (Global Timer: " + str(relic_timer) + ")"
        relic_status.add_theme_color_override("font_color", Color.RED if GS.relic_holder.conflict_side == GC.PLAYER_RED else Color.BLUE)
    else:
        relic_status.text = "Relic: On ground at " + str(relic_position) + " (Timer: " + str(relic_timer) + ")"
        relic_status.add_theme_color_override("font_color", Color.WHITE)


func _handle_unit_death(unit: Unit) -> void:
    # Remove unit from the board
    print("Unit died at", unit.grid_position)

    # Free the obstacle
    obstacles[unit.grid_position] = false

    # Remove the unit node from the scene
    unit.queue_free()

    # Increment revive count for the player who lost the unit
    if unit.conflict_side == GC.PLAYER_RED:
        GS.red_revive_count += GC.REVIVE_TOKEN_REWARD  # Red player killed a blue unit
        print("Red player gets a revive token. Total:", GS.red_revive_count)
    else:
        GS.blue_revive_count += GC.REVIVE_TOKEN_REWARD  # Blue player killed a red unit
        print("Blue player gets a revive token. Total:", GS.blue_revive_count)

    # Update revive UI
    _update_revive_ui()


func _update_revive_ui() -> void:
    # Update revive UI based on current player
    if GS.current_player == GC.PLAYER_RED:
        revive_count.text = "Revives: " + str(GS.red_revive_count)
        revive_button.disabled = (GS.red_revive_count <= 0)
    else:
        revive_count.text = "Revives: " + str(GS.blue_revive_count)
        revive_button.disabled = (GS.blue_revive_count <= 0)


func _on_end_turn_button_pressed() -> void:
    # Cancel revival mode if active
    if is_revival_mode:
        is_revival_mode = false
        clear_walkable_highlight()
        revive_button.text = "Revive Unit"
        print("Revival mode cancelled due to turn end")

    # End current player's turn and switch to other player
    print("Ending turn for player", GS.current_player)
    _switch_player_turn()
    GS.save_game()
    _update_revive_ui()


func _on_reset_button_pressed() -> void:
    GS.load_game()


func _on_revive_button_pressed() -> void:
    # Toggle revival mode
    if is_revival_mode:
        # Cancel revival mode
        is_revival_mode = false
        clear_walkable_highlight()
        revive_button.text = "Revive Unit"
        print("Revival mode cancelled")
    else:
        # Enter revival mode if player has revives
        var available_revives = GS.red_revive_count if GS.current_player == GC.PLAYER_RED else GS.blue_revive_count
        if available_revives > 0:
            is_revival_mode = true
            revive_button.text = "Cancel revival"
            # Clear any unit selection when entering revival mode
            clear_selection()
            clear_walkable_highlight()
            _highlight_revival_tiles()
            print("Entered revival mode")
        else:
            print("No revives available")

func _load_game_over_menu() -> void:
    # Try to load the game over menu scene
    if ResourceLoader.exists("res://scenes/ui/game_over_menu.tscn"):
        GameOverMenuScene = load("res://scenes/ui/game_over_menu.tscn")
        game_over_menu = GameOverMenuScene.instantiate()
        add_child(game_over_menu)

        print("Game over menu loaded successfully")
    else:
        print("Game over menu scene not found. Using fallback victory message.")

func restart_game() -> void:
    # Restart the game by reloading the scene
    print("Restarting game...")
    get_tree().reload_current_scene()
