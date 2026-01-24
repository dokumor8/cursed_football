class_name MultiplayerManager
extends Node

# Signals for connection events
signal connection_succeeded
signal connection_failed
signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal game_state_received(state_json: String)

# Network configuration
const DEFAULT_PORT: int = 9999
const MAX_PLAYERS: int = 2

# Network peer
var peer: ENetMultiplayerPeer = null
var is_host: bool = false
var is_server: bool = false  # True if running as dedicated server
var connection_status: String = "disconnected"

# Game state synchronization
var pending_actions: Array = []

# Player assignment (for dedicated server)
var assigned_player_id: int = 0  # Local player's assigned ID (0 for server, 1/2 for players)
var peer_to_player_id: Dictionary = {}  # Server only: peer_id -> player_id
var next_player_id: int = 1  # Server only: next player ID to assign

func _ready() -> void:
    # Connect multiplayer signals
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

# Host a game (P2P mode)
func host_game(port: int = DEFAULT_PORT) -> void:
    print("Hosting game on port ", port)
    
    peer = ENetMultiplayerPeer.new()
    var result = peer.create_server(port, MAX_PLAYERS)
    
    if result == OK:
        multiplayer.multiplayer_peer = peer
        is_host = true
        is_server = false
        connection_status = "hosting"
        print("Game hosted successfully - waiting for players")
        # Don't emit connection_succeeded yet - wait for player to connect
    else:
        print("Failed to host game: ", result)
        connection_failed.emit()

# Join a game (P2P mode)
func join_game(ip: String, port: int = DEFAULT_PORT) -> void:
    print("Joining game at ", ip, ":", port)
    
    peer = ENetMultiplayerPeer.new()
    var result = peer.create_client(ip, port)
    
    if result == OK:
        multiplayer.multiplayer_peer = peer
        is_host = false
        is_server = false
        connection_status = "connecting"
        print("Connecting to game...")
    else:
        print("Failed to create client: ", result)
        connection_failed.emit()

# Start as dedicated server (for VPS)
func start_dedicated_server(port: int = DEFAULT_PORT) -> void:
    print("Starting dedicated server on port ", port)
    
    peer = ENetMultiplayerPeer.new()
    var result = peer.create_server(port, MAX_PLAYERS)
    
    if result == OK:
        multiplayer.multiplayer_peer = peer
        is_host = false
        is_server = true
        connection_status = "server"
        print("Dedicated server started")
        connection_succeeded.emit()
    else:
        print("Failed to start server: ", result)
        connection_failed.emit()

# Connect to dedicated server
func connect_to_server(ip: String, port: int = DEFAULT_PORT) -> void:
    print("Connecting to server at ", ip, ":", port)
    
    peer = ENetMultiplayerPeer.new()
    var result = peer.create_client(ip, port)
    
    if result == OK:
        multiplayer.multiplayer_peer = peer
        is_host = false
        is_server = false
        connection_status = "connecting"
        print("Connecting to server...")
    else:
        print("Failed to connect to server: ", result)
        connection_failed.emit()

# Disconnect from game
func disconnect_from_game() -> void:
    if multiplayer.multiplayer_peer:
        multiplayer.multiplayer_peer.close()
        multiplayer.multiplayer_peer = null

    is_host = false
    is_server = false
    connection_status = "disconnected"
    assigned_player_id = 0  # Reset assigned player ID
    print("Disconnected from game")

# Get local player ID (1 for host/server, 2 for client)
func get_local_player_id() -> int:
    # If we're a dedicated server, we're not a player
    if is_server:
        return 0

    # If we have an assigned player ID (from dedicated server), use it
    if assigned_player_id > 0:
        return assigned_player_id

    # Legacy P2P mode
    if is_host:
        return 1
    else:
        return 2

# Check if it's local player's turn
func is_local_player_turn(current_player: int) -> bool:
    var local_id = get_local_player_id()
    return current_player == local_id

# Assign player ID to client (server -> client)
@rpc("authority", "call_local", "reliable")
func assign_player_id_rpc(player_id: int) -> void:
    print("Received assigned player ID: ", player_id)
    assigned_player_id = player_id

# Send game state to all players
@rpc("authority", "call_local", "reliable")
func sync_game_state(state_json: String) -> void:
    print("Received game state sync")
    game_state_received.emit(state_json)

# Request action from server/host
@rpc("any_peer", "call_local", "reliable")
func request_action(action_type: String, action_data: Dictionary) -> void:
    if multiplayer.is_server():
        print("Processing action request: ", action_type)
        # Validate and process action
        var success = _process_action(action_type, action_data)
        if success:
            # Get updated game state and sync
            var game_state = _get_current_game_state()
            if game_state:
                sync_game_state.rpc(game_state)

# Signal handlers
func _on_peer_connected(peer_id: int) -> void:
    print("Player connected: ", peer_id)
    player_connected.emit(peer_id)

    # Assign player ID if we're the server
    if is_server and next_player_id <= MAX_PLAYERS:
        var player_id = next_player_id
        peer_to_player_id[peer_id] = player_id
        next_player_id += 1
        print("Assigned player ID ", player_id, " to peer ", peer_id)
        # Notify the client of their assigned player ID
        assign_player_id_rpc.rpc_id(peer_id, player_id)

    # Note: We don't send game state here anymore
    # Game state will be sent by the game scene after it loads

func _on_peer_disconnected(peer_id: int) -> void:
    print("Player disconnected: ", peer_id)
    player_disconnected.emit(peer_id)

    # Clean up player assignment if we're the server
    if is_server and peer_to_player_id.has(peer_id):
        var player_id = peer_to_player_id[peer_id]
        peer_to_player_id.erase(peer_id)
        print("Removed player ID ", player_id, " for disconnected peer ", peer_id)
        # Could potentially reassign this player ID later if needed

func _on_connected_to_server() -> void:
    print("Connected to server successfully")
    connection_status = "connected"
    connection_succeeded.emit()

func _on_connection_failed() -> void:
    print("Connection failed")
    connection_status = "disconnected"
    connection_failed.emit()

func _on_server_disconnected() -> void:
    print("Server disconnected")
    connection_status = "disconnected"
    # Could emit a specific signal here

# Helper functions
func _process_action(action_type: String, action_data: Dictionary) -> bool:
    # This should be implemented by the game logic
    # For now, just return true for testing
    print("Processing action: ", action_type, " with data: ", action_data)
    return true

func _get_current_game_state() -> String:
    # Get game state from game_state.gd
    var game_state_node = get_node_or_null("/root/GS")
    if game_state_node and game_state_node.has_method("serialize"):
        return game_state_node.serialize()
    return ""

# Utility functions
func get_connection_status() -> String:
    return connection_status

func has_active_connection() -> bool:
    return connection_status in ["hosting", "connected", "server"]

func is_authority() -> bool:
    return multiplayer.is_server()

# Get player ID for a peer (server only)
func get_player_id_for_peer(peer_id: int) -> int:
    if not is_server:
        return 0
    return peer_to_player_id.get(peer_id, 0)

# Get peer ID for a player (server only)
func get_peer_id_for_player(player_id: int) -> int:
    if not is_server:
        return 0
    for peer_id in peer_to_player_id:
        if peer_to_player_id[peer_id] == player_id:
            return peer_id
    return 0

# Reset player assignments (server only)
func reset_player_assignments() -> void:
    if is_server:
        peer_to_player_id.clear()
        next_player_id = 1
        print("Reset player assignments")
