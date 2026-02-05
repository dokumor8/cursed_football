extends Control

# UI Nodes
@onready var connect_button: Button = $VBoxContainer/ConnectButton
@onready var ip_address: LineEdit = $VBoxContainer/IPAddress
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var ready_button: Button = $VBoxContainer/ReadyButton

# Player slot labels
@onready var red_status_label: Label = $VBoxContainer/PlayerSlotsContainer/PlayerRedSlot/RedStatus
@onready var red_ready_label: Label = $VBoxContainer/PlayerSlotsContainer/PlayerRedSlot/RedReady
@onready var blue_status_label: Label = $VBoxContainer/PlayerSlotsContainer/PlayerBlueSlot/BlueStatus
@onready var blue_ready_label: Label = $VBoxContainer/PlayerSlotsContainer/PlayerBlueSlot/BlueReady

# Lobby state
var player_ready: bool = false
var local_player_id: int = 0  # 0 = not assigned, 1 = red, 2 = blue

func _ready() -> void:
    # Initialize multiplayer manager
    _initialize_multiplayer_manager()

    # Connect signals
    connect_button.pressed.connect(_on_connect_button_pressed)
    ready_button.pressed.connect(_on_ready_button_pressed)
    back_button.pressed.connect(_on_back_button_pressed)

    # Set default IP (localhost for testing)
    ip_address.text = "127.0.0.1"

    # Update status
    _update_status("Ready to connect")

    # Initialize player slots
    _update_player_slots()

func _initialize_multiplayer_manager() -> void:
    # Check if multiplayer manager already exists
    if not MM.initialized:
        MM.start_manager()
    # Connect multiplayer manager signals
    MM.connection_succeeded.connect(_on_connection_succeeded)
    MM.connection_failed.connect(_on_connection_failed)
    MM.player_connected.connect(_on_player_connected)
    MM.player_disconnected.connect(_on_player_disconnected)
    # Connect custom signals for lobby
    if MM.has_signal("player_id_assigned"):
        MM.player_id_assigned.connect(_on_player_id_assigned)
    if MM.has_signal("player_ready_changed"):
        MM.player_ready_changed.connect(_on_player_ready_changed)
    if MM.has_signal("lobby_state_updated"):
        MM.lobby_state_updated.connect(_on_lobby_state_updated)
    if MM.has_signal("game_starting"):
        MM.game_starting.connect(_on_game_starting)

func _on_connect_button_pressed() -> void:
    var ip = ip_address.text.strip_edges()
    if ip.is_empty():
        _update_status("Please enter an IP address", Color.RED)
        return

    _update_status("Connecting to " + ip + "...")
    connect_button.disabled = true
    ready_button.disabled = true

    MM.connect_to_server(ip)

func _on_ready_button_pressed() -> void:
    if local_player_id == 0:
        _update_status("Player ID not assigned yet", Color.RED)
        return

    player_ready = not player_ready
    ready_button.text = "Not Ready" if player_ready else "Ready"  # Toggle text
    # Send ready state to server
    MM.set_player_ready.rpc_id(1, player_ready)  # Send to server (peer_id 1)

    # Update local UI immediately
    _update_player_ready_display(local_player_id, player_ready)

func _on_back_button_pressed() -> void:
    # Disconnect if connected
    if MM.initialized and MM.has_active_connection():
        MM.disconnect_from_game()

    # Go back to main menu
    get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_connection_succeeded() -> void:
    _update_status("Connected to server!", Color.GREEN)
    connect_button.disabled = true
    # Ready button will be enabled when player ID is assigned

func _on_connection_failed() -> void:
    _update_status("Connection failed", Color.RED)
    connect_button.disabled = false
    ready_button.disabled = true

func _on_player_connected(peer_id: int) -> void:
    _update_status("Player " + str(peer_id) + " connected", Color.YELLOW)
    # Server will assign player ID and update lobby state
    # For clients, wait for lobby state update from server

func _on_player_disconnected(peer_id: int) -> void:
    _update_status("Player " + str(peer_id) + " disconnected", Color.ORANGE)
    # Server will update lobby state

# Called when server assigns player ID to us
func _on_player_id_assigned(player_id: int) -> void:
    local_player_id = player_id
    _update_status("Assigned as " + ("Red" if player_id == 1 else "Blue") + " player", Color.GREEN)
    ready_button.disabled = false
    _update_player_slots()

# Called when a player's ready state changes (via signal from MM)
func _on_player_ready_changed(player_id: int, is_ready: bool) -> void:
    _update_player_ready_display(player_id, is_ready)

    # If we're the player whose ready state changed, update our button
    if player_id == local_player_id:
        player_ready = is_ready
        ready_button.text = "Not Ready" if is_ready else "Ready"

# Called when server broadcasts full lobby state
func _on_lobby_state_updated(lobby_state: Dictionary) -> void:
    # lobby_state format: { "players": { 1: {"connected": bool, "ready": bool}, 2: ... } }
    var players = lobby_state.get("players", {})
    for player_id in players:
        var player_data = players[player_id]
        _update_player_slot(player_id, player_data.get("connected", false), player_data.get("ready", false))

# Called when server starts the game
func _on_game_starting() -> void:
    _update_status("Starting game...", Color.GREEN)
    # Wait a moment then transition
    await get_tree().create_timer(1.0).timeout
    get_tree().change_scene_to_file("res://scenes/game/game_scene.tscn")

# UI update helpers
func _update_status(message: String, color: Color = Color.WHITE) -> void:
    status_label.text = message
    status_label.add_theme_color_override("font_color", color)
    print("Lobby: " + message)

func _update_player_slots() -> void:
    # Default state: both not connected, not ready
    red_status_label.text = "Not Connected"
    red_ready_label.text = "Not Ready"
    blue_status_label.text = "Not Connected"
    blue_ready_label.text = "Not Ready"

    # If we know our player ID, update status to Connected
    if local_player_id == 1:
        red_status_label.text = "Connected (You)"
    elif local_player_id == 2:
        blue_status_label.text = "Connected (You)"

func _update_player_slot(player_id: int, connected: bool, is_ready: bool) -> void:
    var status_text = "Connected" + (" (You)" if player_id == local_player_id else "")
    var ready_text = "Ready" if is_ready else "Not Ready"

    match player_id:
        1:
            red_status_label.text = status_text if connected else "Not Connected"
            red_ready_label.text = ready_text
        2:
            blue_status_label.text = status_text if connected else "Not Connected"
            blue_ready_label.text = ready_text

func _update_player_ready_display(player_id: int, is_ready: bool) -> void:
    var ready_text = "Ready" if is_ready else "Not Ready"
    match player_id:
        1: red_ready_label.text = ready_text
        2: blue_ready_label.text = ready_text

# Clean up on exit
func _exit_tree() -> void:
    if MM:
        MM.connection_succeeded.disconnect(_on_connection_succeeded)
        MM.connection_failed.disconnect(_on_connection_failed)
        MM.player_connected.disconnect(_on_player_connected)
        MM.player_disconnected.disconnect(_on_player_disconnected)
        if MM.has_signal("player_id_assigned"):
            MM.player_id_assigned.disconnect(_on_player_id_assigned)
        if MM.has_signal("player_ready_changed"):
            MM.player_ready_changed.disconnect(_on_player_ready_changed)
        if MM.has_signal("lobby_state_updated"):
            MM.lobby_state_updated.disconnect(_on_lobby_state_updated)
        if MM.has_signal("game_starting"):
            MM.game_starting.disconnect(_on_game_starting)
