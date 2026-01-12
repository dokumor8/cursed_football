# test_multiplayer.gd
# Simple test script to verify multiplayer functionality

extends Node

func _ready() -> void:
    print("=== Multiplayer Test ===")
    print("1. Testing MultiplayerManager creation...")
    
    var mm = preload("res://scripts/network/multiplayer_manager.gd").new()
    mm.name = "TestMultiplayerManager"
    add_child(mm)
    
    print("2. Testing host game function...")
    mm.host_game(9998)  # Use different port to avoid conflict
    
    print("3. Testing connection status...")
    print("   Connection status:", mm.get_connection_status())
    print("   Is connected:", mm.is_connected_m())
    print("   Is authority:", mm.is_authority())
    
    print("4. Testing local player ID...")
    print("   Local player ID:", mm.get_local_player_id())
    
    print("5. Testing disconnect...")
    mm.disconnect_from_game()
    print("   Connection status after disconnect:", mm.get_connection_status())
    
    print("=== Test Complete ===")
    
    # Clean up
    mm.queue_free()
