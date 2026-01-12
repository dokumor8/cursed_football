# Multiplayer Implementation Guide

## Overview
The multiplayer system for Hex Relic Tactics uses a **peer-to-peer authoritative model** where one player acts as the host (server) and synchronizes game state with the other player (client).

## Architecture

### Key Components
1. **MultiplayerManager** (`scripts/network/multiplayer_manager.gd`)
   - Handles network connections (host/join)
   - Manages connection state
   - Provides RPC utilities

2. **GameState Network Extensions** (`scripts/game/game_state.gd`)
   - Added RPC functions for game actions
   - State synchronization via serialization
   - Request validation and processing

3. **Network-Aware Game Scene** (`scripts/game/game_scene.gd`)
   - Modified input handling for network play
   - Network status display
   - Authority checking for actions

4. **Lobby System** (`scripts/ui/lobby.gd`, `scenes/ui/lobby.tscn`)
   - Simple host/join interface
   - Connection status feedback
   - IP address input

## How It Works

### Connection Flow
1. Player selects "Multiplayer" from main menu
2. Chooses "Host Game" or "Join Game"
3. Joining player enters host's IP address
4. Connection established, players transition to game

### Gameplay Flow
1. **Host (Player 1)** acts as authoritative server
2. **Client (Player 2)** sends action requests to host
3. Host validates and processes actions
4. Host synchronizes updated game state to client
5. Both players see the same game state

### Action Processing
- **Local/Host**: Processes actions directly, then syncs state
- **Client**: Sends RPC request to host, waits for state sync
- **Validation**: Host validates all actions before processing

## Testing Multiplayer

### Local Testing (Same Machine)
1. Open two instances of Godot Editor
2. Instance 1: Click "Multiplayer" → "Host Game"
3. Instance 2: Click "Multiplayer" → "Join Game" → Enter "127.0.0.1"
4. Both should connect and transition to game

### Network Testing (Different Machines)
1. Host needs to port forward 9999 (or use different port)
2. Joining player enters host's public IP address
3. Both connect and play

### Testing Commands
```bash
# Run the multiplayer test script
# (Open Godot and run the test_multiplayer.gd script)
```

## Configuration

### Port Settings
- Default port: 9999
- Can be changed in `MultiplayerManager.DEFAULT_PORT`

### Player Assignment
- Host/Server: Player 1 (Red)
- Client: Player 2 (Blue)
- Turn order remains Red → Blue → Red → Blue

### Network Status Display
Game scene shows network status in top-left corner:
- **Green**: Connected/Hosting
- **Yellow**: Connecting
- **Red**: Disconnected
- **White**: Unknown status

## Troubleshooting

### Common Issues

1. **"Connection failed"**
   - Check firewall settings (port 9999)
   - Verify IP address is correct
   - Ensure host is running and waiting for connections

2. **"Not your turn" messages when it should be**
   - Network delay in state synchronization
   - Check network_status_label for connection issues

3. **Actions not processing**
   - Verify you're connected (green status)
   - Check Godot console for RPC errors
   - Ensure host is running and responsive

### Debug Commands
Add to game_scene.gd for debugging:
```gdscript
print("Multiplayer status:", multiplayer_manager.get_connection_status())
print("Is authority:", multiplayer.is_server())
print("Current player:", GS.current_player)
```

## Future Enhancements

### Planned Features
1. **Dedicated Server Mode**
   - Run server on VPS for reliability
   - Better NAT traversal

2. **Matchmaking System**
   - Server maintains game list
   - Automatic player pairing

3. **Reconnection Handling**
   - Save game state on server
   - Allow reconnection after disconnect

4. **Spectator Mode**
   - Watch ongoing games
   - Replay system

### Technical Improvements
1. **Delta State Updates**
   - Send only changed data, not full state
   - Reduce network bandwidth

2. **Input Prediction**
   - Client-side prediction for smoother gameplay
   - Server reconciliation

3. **Cheat Prevention**
   - Action validation with cryptographic signatures
   - Server-side game logic

## Files Modified/Added

### New Files
- `scripts/network/multiplayer_manager.gd`
- `scripts/ui/lobby.gd`
- `scenes/ui/lobby.tscn`
- `scripts/network/test_multiplayer.gd`
- `MULTIPLAYER.md` (this file)

### Modified Files
- `scripts/game/game_state.gd` (added RPC functions)
- `scripts/game/game_scene.gd` (network input handling)
- `scripts/ui/main_menu.gd` (added multiplayer button)
- `scenes/ui/main_menu.tscn` (added multiplayer button)

## Development Notes

### Design Decisions
1. **P2P over Dedicated Server**: Chosen for simplicity and no server costs
2. **Host Authority**: Prevents cheating in friendly games
3. **Full State Sync**: Simpler than delta updates, acceptable for turn-based game
4. **No Client Prediction**: Not needed for turn-based gameplay

### Performance Considerations
- Game state JSON is ~1-2KB per sync
- Sync occurs after each action (move, attack, end turn)
- Network bandwidth usage is minimal

### Security Notes
- No encryption (plaintext JSON over network)
- No authentication (trusted players only)
- No cheat protection (friendly games assumption)

For production use, consider adding:
- SSL/TLS encryption
- Player authentication
- Action validation with hashing