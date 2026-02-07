extends Node

var relic_holder: Unit = null
var relic_timer = 0
var relic_taken = false
var red_revive_count = 0
var blue_revive_count = 0

var current_player: int = GC.PLAYER_RED # Red player starts (bottom)
var selected_unit: Unit = null


func serialize() -> String:
    var units: Array = []
    var relic_holder_index = -1
    var loop_index = 0
    for unit: Unit in get_tree().get_nodes_in_group("units"):
        print("serializing unit at", unit.grid_position)
        var unit_data = unit.serialize()
        print("Current unit data:", unit_data)
        if relic_holder == unit:
            relic_holder_index = loop_index
        units.append(unit_data)
        loop_index += 1
    print("Unit data:", units)
    var game_state = {
        "units": units,
        "relic_holder": relic_holder_index,
        "red_revive_count": red_revive_count,
        "blue_revive_count": blue_revive_count,
        "relic_taken": relic_taken,
        "relic_timer": relic_timer,
        "current_player": current_player
    }
    var json_string = JSON.stringify(game_state)
    print("Serialized")
    return json_string


func deserealize(json_string: String) -> Dictionary:
    var json = JSON.new()
    var error = json.parse(json_string)
    if error == OK:
        var data_received = json.data
        if typeof(data_received) == TYPE_DICTIONARY:
            print("JSON data parsed")
            return data_received
        else:
            print("Unexpected data")
            return {}
    else:
        print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
        return {}


func load_state(game_data: Dictionary) -> void:
    print("DEBUG: load_state called")
    if get_tree().current_scene:
        print("DEBUG: Current scene name: ", get_tree().current_scene.name)
    else:
        print("DEBUG: No current scene")
    
    var unit_scene = preload("res://scenes/game/unit.tscn")
    
    var game_scenes = get_tree().get_nodes_in_group("main_scene")
    print("DEBUG: Found ", game_scenes.size(), " nodes in 'main_scene' group")
    for i in range(game_scenes.size()):
        print("DEBUG:   Node ", i, ": ", game_scenes[i].name, " (", game_scenes[i].get_class(), ")")
    
    if game_scenes.size() == 0:
        print("ERROR: No game scene found in load_state!")
        return
    var game_scene = game_scenes[0]
    print("DEBUG: Using game scene: ", game_scene.name)
    
    game_scene.obstacles = {}

    red_revive_count = game_data["red_revive_count"]
    blue_revive_count = game_data["blue_revive_count"]
    relic_taken = game_data["relic_taken"]
    # Always destroy any existing relic sprites
    var relic_group = get_tree().get_nodes_in_group("relic")
    for item in relic_group:
        item.queue_free()
    # Only spawn a new relic if it's not taken (on ground)
    if not relic_taken:
        game_scene.spawn_relic_at_tile(GC.INITIAL_RELIC_POSITION)
    else:
        game_scene.obstacles[GC.INITIAL_RELIC_POSITION] = false
    relic_timer = game_data["relic_timer"]
    current_player = game_data["current_player"]

    for unit: Unit in get_tree().get_nodes_in_group("units"):
        unit.queue_free()
        unit = null

    var units: Array = game_data["units"]
    var relic_holder_index = game_data["relic_holder"]
    var loop_index = 0
    for unit_data: Dictionary in units:
        var grid_pos_x = unit_data["grid_pos_x"]
        var grid_pos_y = unit_data["grid_pos_y"]
        var grid_pos = Vector2i(grid_pos_x, grid_pos_y)
        var conflict_side = unit_data["conflict_side"]
        var unit = game_scene.spawn_unit_at_tile(unit_scene, grid_pos, conflict_side)
        unit.current_hp = unit_data["current_hp"]
        unit.is_relic_holder = unit_data["is_relic_holder"]
        unit.has_attacked_this_turn = unit_data["has_attacked_this_turn"]
        unit.attack_power = unit_data["attack_power"]
        unit.speed = unit_data["speed"]
        unit.movement_left = unit_data["movement_left"]
        unit._update_hp_label()
        unit._update_relic_sprite()
        if loop_index == relic_holder_index:
            relic_holder = unit
        loop_index += 1
    print("State loaded")


func save_game():
    var save_file = FileAccess.open("user://temp.save", FileAccess.WRITE)
    var json_string = serialize()
   
    save_file.store_line(json_string)
    print("State data saved to temp file")


func load_game():
    if not FileAccess.file_exists("user://temp.save"):
        return

    # Load the file line by line and process that dictionary to restore
    # the object it represents.
    var save_file = FileAccess.open("user://temp.save", FileAccess.READ)
    var json_string = save_file.get_line()
    var game_data = deserealize(json_string)
    load_state(game_data)


func load_game_from_server(state_json):
    var game_data = deserealize(state_json)
    load_state(game_data)


# Network signal handlers
func _on_game_state_received(state_json: String) -> void:
    print("Game scene received state sync from host")
    load_game_from_server(state_json)


# Network RPC functions
@rpc("authority", "call_local", "reliable")
func sync_game_state_rpc(state_json: String) -> void:
    print("=== RPC: sync_game_state_rpc called ===")
    print("RPC: Received game state sync from host")
    print("RPC: State JSON length: ", state_json.length())
    var game_data = deserealize(state_json)
    if game_data.is_empty():
        print("RPC: Failed to parse game state JSON")
        return
    print("RPC: Game data keys: ", game_data.keys())
    print("RPC: Loading game state with ", game_data.get("units", []).size(), " units")
    load_state(game_data)
    print("=== RPC: sync_game_state_rpc complete ===")

@rpc("any_peer", "call_local", "reliable")
func request_move_rpc(unit_index: int, target_x: int, target_y: int) -> void:
    var sender_id = multiplayer.get_remote_sender_id()
    print("RPC: Received move request from peer ", sender_id, " for unit ", unit_index, " to (", target_x, ", ", target_y, ")")
    print("RPC: Is server? ", multiplayer.is_server())
    if multiplayer.is_server():
        print("Processing move request for unit ", unit_index, " to (", target_x, ", ", target_y, ")")
        _process_move_request(sender_id, unit_index, Vector2i(target_x, target_y))
    else:
        print("RPC: Not server, ignoring move request")

@rpc("any_peer", "call_local", "reliable")
func request_attack_rpc(attacker_position: Vector2i, target_position: Vector2i) -> void:
    var sender_id = multiplayer.get_remote_sender_id()
    print("=== RPC: request_attack_rpc called ===")
    print("RPC: Received attack request from peer ", sender_id)
    print("RPC: attacker_index=", attacker_position, " target_index=", target_position)
    print("RPC: Processing attack request")
    _process_attack_request(sender_id, attacker_position, target_position)
    print("=== RPC: request_attack_rpc complete ===")

@rpc("any_peer", "call_local", "reliable")
func request_end_turn_rpc() -> void:
    var sender_id = multiplayer.get_remote_sender_id()
    print("RPC: Received end turn request from peer ", sender_id)
    print("RPC: Is server? ", multiplayer.is_server())
    if multiplayer.is_server():
        print("Processing end turn request")
        _process_end_turn_request(sender_id)

@rpc("any_peer", "call_local", "reliable")
func request_revive_rpc(player: int) -> void:
    var sender_id = multiplayer.get_remote_sender_id()
    print("RPC: Received revive request from peer ", sender_id, " for player ", player)
    print("RPC: Is server? ", multiplayer.is_server())
    if multiplayer.is_server():
        print("Processing revive request for player ", player)
        _process_revive_request(sender_id, player)

@rpc("any_peer", "call_local", "reliable")
func request_pick_up_rpc(unit_index: int) -> void:
    var sender_id = multiplayer.get_remote_sender_id()
    print("RPC: Received pick up request from peer ", sender_id, " for unit ", unit_index)
    print("RPC: Is server? ", multiplayer.is_server())
    if multiplayer.is_server():
        print("Processing pick up request for unit ", unit_index)
        _process_pick_up_request(sender_id, unit_index)
    else:
        print("RPC: Not server, ignoring move request")



# Process network requests
func _process_move_request(sender_id: int, unit_index: int, target_position: Vector2i) -> void:
    print("DEBUG: _process_move_request called with unit_index=", unit_index, " target=", target_position)
    var units = get_tree().get_nodes_in_group("units")
    print("DEBUG: Found ", units.size(), " units in group")
    
    if unit_index >= 0 and unit_index < units.size():
        var unit = units[unit_index]
        print("DEBUG: Unit found: side=", unit.conflict_side, " pos=", unit.grid_position, " movement_left=", unit.movement_left)
        
        # Check if sender is authorized to control this unit
        var multiplayer_manager = get_node_or_null("/root/MultiplayerManager")
        if multiplayer_manager:
            var sender_player_id = multiplayer_manager.get_player_id_for_peer(sender_id)
            if sender_player_id != unit.conflict_side:
                print("DEBUG: Sender not authorized. Sender player ID=", sender_player_id, " unit side=", unit.conflict_side)
                return
            # Also check if it's this player's turn
            if unit.conflict_side != current_player:
                print("DEBUG: Not this player's turn. Unit side=", unit.conflict_side, " current_player=", current_player)
                return
        else:
            # Fallback: check if it's this unit's player's turn (for P2P mode)
            if unit.conflict_side != current_player:
                print("DEBUG: Not this player's turn. Unit side=", unit.conflict_side, " current_player=", current_player)
                return
            
        # Check if unit can move (simplified validation)
        if unit.movement_left <= 0:
            print("DEBUG: Unit has no movement left")
            return
            
        # Move the unit (simplified - actual validation should check reachable tiles)
        var game_scene = get_tree().get_nodes_in_group("main_scene")
        print("DEBUG: Found ", game_scene.size(), " main_scene nodes")
        if game_scene.size() > 0 and game_scene[0].has_method("move_unit"):
            var scene = game_scene[0]
            # Check if tile is reachable
            var reachable_data = scene.get_reachable_tiles(unit.grid_position, unit.movement_left)
            var reachable_tiles: Array[Vector2i] = reachable_data["tiles"]
            
            print("DEBUG: Checking if target ", target_position, " is in reachable tiles")
            if reachable_tiles.has(target_position):
                var movement_cost: int = reachable_data["distances"][target_position]
                print("DEBUG: Moving unit, movement_cost=", movement_cost)
                scene.move_unit(unit, target_position, movement_cost)
                
                # Sync updated state
                _sync_game_state()
            else:
                print("DEBUG: Tile not reachable for movement")
        else:
            print("DEBUG: No game scene found or missing move_unit method")
    else:
        print("DEBUG: Invalid unit index: ", unit_index)

func _process_attack_request(sender_id: int, attacker_position: Vector2i, target_position: Vector2i) -> void:
    print("DEBUG: _process_attack_request called with attacker=", attacker_position, " target=", target_position)
    var units = get_tree().get_nodes_in_group("units")
    print("DEBUG: Found ", units.size(), " units in group")
    var attacker: Unit
    var target: Unit
    for unit: Unit in units:
        if attacker_position == unit.grid_position:
            attacker = unit
        if target_position == unit.grid_position:
            target = unit
    
    print("DEBUG: Attacker: side=", attacker.conflict_side, " pos=", attacker.grid_position, " has_attacked=", attacker.has_attacked_this_turn)
    print("DEBUG: Target: side=", target.conflict_side, " pos=", target.grid_position)
    
    # Check if sender is authorized to control this attacker
    var multiplayer_manager = get_node_or_null("/root/MultiplayerManager")
    if multiplayer_manager:
        var sender_player_id = multiplayer_manager.get_player_id_for_peer(sender_id)
        if sender_player_id != attacker.conflict_side:
            print("DEBUG: Sender not authorized. Sender player ID=", sender_player_id, " attacker side=", attacker.conflict_side)
            return
        # Also check if it's this player's turn
        if attacker.conflict_side != current_player:
            print("DEBUG: Not this player's turn. Attacker side=", attacker.conflict_side, " current_player=", current_player)
            return
    else:
        # Fallback: check if it's attacker's player's turn (for P2P mode)
        if attacker.conflict_side != current_player:
            print("DEBUG: Not this player's turn. Attacker side=", attacker.conflict_side, " current_player=", current_player)
            return
        
    # Check if attacker can attack
    if attacker.has_attacked_this_turn:
        print("DEBUG: Attacker has already attacked this turn")
        return
        
    # Check if target is adjacent (simplified)
    var distance = abs(attacker.grid_position.x - target.grid_position.x) + \
                    abs(attacker.grid_position.y - target.grid_position.y)
    print("DEBUG: Distance between units: ", distance)
    if distance > 1:
        print("DEBUG: Target not adjacent")
        return
        
    # Perform attack
    var game_scene = get_tree().get_nodes_in_group("main_scene")
    print("DEBUG: Found ", game_scene.size(), " main_scene nodes")
    if game_scene.size() > 0 and game_scene[0].has_method("attack_unit"):
        game_scene[0].attack_unit(attacker, target)
        
        # Sync updated state
        _sync_game_state()
    else:
        print("DEBUG: No game scene found or missing attack_unit method")

func _process_end_turn_request(sender_id: int) -> void:
    print("DEBUG: _process_end_turn_request called from sender ", sender_id)

    # Check if sender is authorized to end turn
    var multiplayer_manager = get_node_or_null("/root/MultiplayerManager")
    if multiplayer_manager:
        var sender_player_id = multiplayer_manager.get_player_id_for_peer(sender_id)
        if sender_player_id != current_player:
            print("DEBUG: Sender not authorized to end turn. Sender player ID=", sender_player_id, " current_player=", current_player)
            return
    else:
        # P2P mode: basic validation
        print("DEBUG: P2P mode, accepting end turn request")

    # Switch player
    current_player = GC.PLAYER_BLUE if current_player == GC.PLAYER_RED else GC.PLAYER_RED

    # Reset unit states for new player
    for unit in get_tree().get_nodes_in_group("units"):
        if unit.conflict_side == current_player:
            unit.movement_left = unit.speed
            unit.has_attacked_this_turn = false

    # Sync updated state
    _sync_game_state()

func _process_revive_request(sender_id: int, player: int) -> void:
    print("DEBUG: _process_revive_request called from sender ", sender_id, " for player ", player)

    # Check if sender is authorized to revive for this player
    var multiplayer_manager = get_node_or_null("/root/MultiplayerManager")
    if multiplayer_manager:
        var sender_player_id = multiplayer_manager.get_player_id_for_peer(sender_id)
        if sender_player_id != player:
            print("DEBUG: Sender not authorized to revive for player. Sender player ID=", sender_player_id, " requested player=", player)
            return
    else:
        # P2P mode: basic validation
        print("DEBUG: P2P mode, accepting revive request")

    # Simplified revive logic
    var game_scenes = get_tree().get_nodes_in_group("main_scene")
    if game_scenes.size() == 0:
        print("ERROR: No game scene found in _process_revive_request!")
        return
    var game_scene = game_scenes[0]
    if game_scene.has_method("revive_unit"):
        game_scene.revive_unit(player)

        # Sync updated state
        _sync_game_state()


func _process_pick_up_request(sender_id: int, unit_index: int):
    print("DEBUG: _process_pick_up_request called with unit_index=", unit_index)
    var units = get_tree().get_nodes_in_group("units")
    print("DEBUG: Found ", units.size(), " units in group")
    
    if unit_index >= 0 and unit_index < units.size():
        var unit: Unit = units[unit_index]
        print("DEBUG: Unit found: side=", unit.conflict_side, " pos=", unit.grid_position, " movement_left=", unit.movement_left)
        
        # Check if sender is authorized to control this unit
        var sender_player_id = MM.get_player_id_for_peer(sender_id)
        if sender_player_id != unit.conflict_side:
            print("DEBUG: Sender not authorized. Sender player ID=", sender_player_id, " unit side=", unit.conflict_side)
            return
        # Also check if it's this player's turn
        if unit.conflict_side != current_player:
            print("DEBUG: Not this player's turn. Unit side=", unit.conflict_side, " current_player=", current_player)
            return
                        
        # Pick up the relic
        var game_scene = get_tree().get_nodes_in_group("main_scene")
        print("DEBUG: Found ", game_scene.size(), " main_scene nodes")
        if game_scene.size() > 0 and game_scene[0].has_method("_pickup_relic"):
            var scene = game_scene[0]
            # Check if tiles are adjacent
            if scene._are_tiles_adjacent(unit.grid_position, GC.INITIAL_RELIC_POSITION):
                scene._pickup_relic(unit)            
                # Sync updated state
                _sync_game_state()
            else:
                print("DEBUG: Tile not reachable for movement")
        else:
            print("DEBUG: No game scene found or missing move_unit method")
    else:
        print("DEBUG: Invalid unit index: ", unit_index)


# Sync game state to all clients
func _sync_game_state() -> void:
    print("=== GS._sync_game_state() called ===")
    print("GS: Is server? ", multiplayer.is_server())
    if multiplayer.is_server():
        var state_json = serialize()
        print("GS: Serialized state, length: ", state_json.length())
        print("GS: Calling sync_game_state_rpc.rpc()")
        sync_game_state_rpc.rpc(state_json)
        print("GS: RPC call sent")
    else:
        print("GS: Not server, not syncing")
    print("=== GS._sync_game_state() complete ===")


@rpc("any_peer", "call_local", "reliable")
func request_game_sync() -> void:
    _sync_game_state()
