# main_menu.gd
# Script for the main menu scene

extends Control

@onready var start_button: Button = $MarginContainer/MarginContainer/Panel/VBoxContainer/StartButton
@onready var multiplayer_button: Button = $MarginContainer/MarginContainer/Panel/VBoxContainer/MultiplayerButton
@onready var options_button: Button = $MarginContainer/MarginContainer/Panel/VBoxContainer/OptionsButton

func _ready() -> void:
    # Check if we're running as a dedicated server
    if OS.has_feature("dedicated_server"):
        print("Dedicated server mode detected, starting server...")
        MM.start_dedicated_server()
        # Load game scene (server will run without UI)
        get_tree().change_scene_to_file("res://scenes/game/game_scene.tscn")
        return

    # Connect button signals
    start_button.pressed.connect(_on_start_button_pressed)
    multiplayer_button.pressed.connect(_on_multiplayer_button_pressed)
    options_button.pressed.connect(_on_options_button_pressed)

    # Make sure buttons are focused for keyboard navigation
    start_button.grab_focus()

func _on_start_button_pressed() -> void:
    print("Starting local game...")
    # Change scene to the game scene for local play
    get_tree().change_scene_to_file("res://scenes/game/game_scene.tscn")

func _on_multiplayer_button_pressed() -> void:
    print("Starting multiplayer...")
    # Change scene to the lobby scene
    get_tree().change_scene_to_file("res://scenes/ui/lobby.tscn")

func _on_options_button_pressed() -> void:
    print("Options button pressed (placeholder)")
    # TODO: Implement options menu
    # For now, just show a message
    var options_label = Label.new()
    options_label.text = "Options menu coming soon!"
    options_label.position = Vector2(100, 100)
    add_child(options_label)

    # Remove the label after 2 seconds
    await get_tree().create_timer(2.0).timeout
    options_label.queue_free()
