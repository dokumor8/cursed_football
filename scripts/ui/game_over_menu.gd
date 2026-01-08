# game_over_menu.gd
# Script for the game over/popup menu

extends PopupPanel

@onready var victory_label: Label = $VBoxContainer/VictoryLabel
@onready var restart_button: Button = $VBoxContainer/RestartButton
@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # Connect button signals
    restart_button.pressed.connect(_on_restart_button_pressed)
    main_menu_button.pressed.connect(_on_main_menu_button_pressed)

    # Make restart button focused by default for keyboard navigation
    restart_button.grab_focus()

# Set the victory message
func set_victory_message(player_name: String, player_color: Color) -> void:
    victory_label.text = player_name + " Player Wins!"
    victory_label.add_theme_color_override("font_color", player_color)

# Show the popup
func show_victory(player_name: String, player_color: Color) -> void:
    set_victory_message(player_name, player_color)
    popup_centered()

func _on_restart_button_pressed() -> void:
    print("Restarting game...")
    # Close the popup
    hide()

    # Get the current game scene and restart it
    var game_scene = get_tree().current_scene
    if game_scene and game_scene.has_method("restart_game"):
        game_scene.restart_game()
    else:
        # Fallback: reload the game scene
        get_tree().reload_current_scene()

func _on_main_menu_button_pressed() -> void:
    print("Returning to main menu...")
    # Close the popup
    hide()

    # Change to main menu scene
    get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
