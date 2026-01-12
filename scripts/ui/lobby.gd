extends Control

@onready var host_button: Button = $VBoxContainer/HostButton
@onready var join_button: Button = $VBoxContainer/JoinButton
@onready var ip_address: LineEdit = $VBoxContainer/IPAddress
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var back_button: Button = $VBoxContainer/BackButton

var multiplayer_manager: MultiplayerManager = null

func _ready() -> void:
    # Initialize multiplayer manager
    _initialize_multiplayer_manager()
    
    # Connect signals
    host_button.pressed.connect(_on_host_button_pressed)
    join_button.pressed.connect(_on_join_button_pressed)
    back_button.pressed.connect(_on_back_button_pressed)
    
    # Set default IP (localhost for testing)
    ip_address.text = "127.0.0.1"
    
    # Update status
    _update_status("Ready to connect")

func _initialize_multiplayer_manager() -> void:
    # Check if multiplayer manager already exists
    multiplayer_manager = get_node_or_null("/root/MultiplayerManager")
    if not multiplayer_manager:
        # Create new multiplayer manager
        multiplayer_manager = preload("res://scripts/network/multiplayer_manager.gd").new()
        multiplayer_manager.name = "MultiplayerManager"
        get_tree().root.add_child(multiplayer_manager)
    
    # Connect multiplayer manager signals
    multiplayer_manager.connection_succeeded.connect(_on_connection_succeeded)
    multiplayer_manager.connection_failed.connect(_on_connection_failed)
    multiplayer_manager.player_connected.connect(_on_player_connected)
    multiplayer_manager.player_disconnected.connect(_on_player_disconnected)

func _on_host_button_pressed() -> void:
    _update_status("Hosting game...")
    host_button.disabled = true
    join_button.disabled = true
    back_button.disabled = true
    
    multiplayer_manager.host_game()

func _on_join_button_pressed() -> void:
    var ip = ip_address.text.strip_edges()
    if ip.is_empty():
        _update_status("Please enter an IP address", Color.RED)
        return
    
    _update_status("Connecting to " + ip + "...")
    host_button.disabled = true
    join_button.disabled = true
    
    multiplayer_manager.join_game(ip)

func _on_back_button_pressed() -> void:
    # Disconnect if connected
    if multiplayer_manager and multiplayer_manager.is_connected_m():
        multiplayer_manager.disconnect_from_game()
    
    # Go back to main menu
    get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_connection_succeeded() -> void:
    if multiplayer_manager.is_host:
        # Host: Wait for client to connect
        _update_status("Waiting for player to join...", Color.YELLOW)
        # Don't transition yet - wait for player_connected signal
    else:
        # Client: Connected to host
        _update_status("Connected to host!", Color.GREEN)
        
        # Wait a moment then transition to game
        await get_tree().create_timer(1.0).timeout
        
        # Transition to game scene
        get_tree().change_scene_to_file("res://scenes/game/game_scene.tscn")

func _on_connection_failed() -> void:
    _update_status("Connection failed", Color.RED)
    host_button.disabled = false
    join_button.disabled = false

func _on_player_connected(peer_id: int) -> void:
    _update_status("Player " + str(peer_id) + " connected", Color.YELLOW)
    
    # If we're the host and a player connected, transition to game
    if multiplayer_manager.is_host:
        _update_status("Player connected! Starting game...", Color.GREEN)
        
        # Wait a moment then transition to game
        await get_tree().create_timer(1.0).timeout
        
        # Transition to game scene
        get_tree().change_scene_to_file("res://scenes/game/game_scene.tscn")

func _on_player_disconnected(peer_id: int) -> void:
    _update_status("Player " + str(peer_id) + " disconnected", Color.ORANGE)

func _update_status(message: String, color: Color = Color.WHITE) -> void:
    status_label.text = message
    status_label.add_theme_color_override("font_color", color)
    print("Lobby: " + message)

# Clean up on exit
func _exit_tree() -> void:
    if multiplayer_manager:
        multiplayer_manager.connection_succeeded.disconnect(_on_connection_succeeded)
        multiplayer_manager.connection_failed.disconnect(_on_connection_failed)
        multiplayer_manager.player_connected.disconnect(_on_player_connected)
        multiplayer_manager.player_disconnected.disconnect(_on_player_disconnected)
