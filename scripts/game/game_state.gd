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
    var selected_unit_index = -1
    var loop_index = 0
    for unit: Unit in get_tree().get_nodes_in_group("units"):
        print("serializing unit at", unit.grid_position)
        var unit_data = unit.serialize()
        print("Current unit data:", unit_data)
        if relic_holder == unit:
            relic_holder_index = loop_index
        if selected_unit == unit:
            selected_unit_index = loop_index
        units.append(unit_data)
        loop_index += 1
    print("Unit data:", units)
    var game_state = {
        "units": units,
        "relic_holder": relic_holder_index,
        # "selected_unit": selected_unit_index,
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
    var unit_scene = preload("res://scenes/game/unit.tscn")
    
    var game_scene = get_tree().get_nodes_in_group("main_scene")[0]
    
    red_revive_count = game_data["red_revive_count"]
    blue_revive_count = game_data["blue_revive_count"]
    relic_taken = game_data["relic_taken"]
    if not relic_taken:
        var relic_group = get_tree().get_nodes_in_group("relic")
        for item in relic_group:
            item.queue_free()
        game_scene.spawn_relic_at_tile(GC.INITIAL_RELIC_POSITION)
    relic_timer = game_data["relic_timer"]
    current_player = game_data["current_player"]

    for unit: Unit in get_tree().get_nodes_in_group("units"):
        unit.queue_free()

    var units: Array = game_data["units"]

    var relic_holder_index = game_data["relic_holder"]
    var loop_index = 0
    for unit_data: Dictionary in units:
        var grid_pos_x = unit_data["grid_pos_x"]
        var grid_pos_y = unit_data["grid_pos_y"]
        var grid_pos = Vector2i(grid_pos_x, grid_pos_y)
        var conflict_side = unit_data["conflict_side"]
        print("Loading unit from data")
        var unit = game_scene.spawn_unit_at_tile(unit_scene, grid_pos, conflict_side)
        unit.current_hp = unit_data["current_hp"]
        unit.is_relic_holder = unit_data["is_relic_holder"]
        unit.has_attacked_this_turn = unit_data["has_attacked_this_turn"]
        unit.attack_power = unit_data["attack_power"]
        unit.speed = unit_data["speed"]
        unit.movement_left = unit_data["movement_left"]
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

    # while save_file.get_position() < save_file.get_length():
    #     # var json_string = save_file.get_line()

    #     # Creates the helper class to interact with JSON.
    #     var json = JSON.new()

    #     # Get the data from the JSON object.
    #     var node_data = json.data

    #     # Firstly, we need to create the object and add it to the tree and set its position.
    #     var new_object = load(node_data["filename"]).instantiate()
    #     get_node(node_data["parent"]).add_child(new_object)
    #     new_object.position = Vector2(node_data["pos_x"], node_data["pos_y"])

    #     # Now we set the remaining variables.
    #     for i in node_data.keys():
    #         if i == "filename" or i == "parent" or i == "pos_x" or i == "pos_y":
    #             continue
    #         new_object.set(i, node_data[i])
