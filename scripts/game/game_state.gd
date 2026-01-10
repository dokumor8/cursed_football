extends Node


var relic_holder: Unit = null
var relic_timer = 0
var relic_taken = false
var red_revive_count = 0
var blue_revive_count = 0

var current_player: int = GC.PLAYER_RED # Red player starts (bottom)
var selected_unit: Unit = null


func serialize() -> String:
    var units: Array[Unit] = []
    var relic_holder_index = -1
    var selected_unit_index = -1
    var loop_index = 0
    for unit: Unit in get_tree().get_nodes_in_group("units"):
        var unit_data = unit.serialize()
        if relic_holder == unit:
            relic_holder_index = loop_index
        if selected_unit == unit:
            selected_unit_index = loop_index
        units.append(unit_data)
        loop_index += 1

    var game_state = {
        "units": units,
        "relic_holder": relic_holder_index,
        "selected_unit": selected_unit_index,
        "red_revive_count": red_revive_count,
        "blue_revive_count": blue_revive_count,
        "relic_taken": relic_taken,
        "relic_timer": relic_timer,
        "current_player": current_player
    }
    var json_string = JSON.stringify(game_state)
    return json_string
