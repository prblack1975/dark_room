import 'package:flutter/material.dart';
import '../utils/platform_utils.dart';
import '../dark_room_game.dart';

/// Touch controls overlay for mobile and tablet devices
class TouchControls extends StatefulWidget {
  final DarkRoomGame game;
  
  const TouchControls({
    super.key,
    required this.game,
  });

  @override
  State<TouchControls> createState() => _TouchControlsState();
}

class _TouchControlsState extends State<TouchControls> {
  bool _showControls = true;
  
  @override
  Widget build(BuildContext context) {
    // Only show on mobile/tablet devices
    if (!PlatformUtils.shouldShowTouchControls) {
      return const SizedBox.shrink();
    }
    
    return Stack(
      children: [
        // Debug Mode Toggle Button (top-right)
        Positioned(
          top: 50,
          right: 16,
          child: SafeArea(
            child: Column(
              children: [
                _buildDebugToggleButton(),
                const SizedBox(height: 8),
                _buildControlsToggleButton(),
              ],
            ),
          ),
        ),
        
        // Movement Controls (bottom-left)
        if (_showControls)
          Positioned(
            bottom: 50,
            left: 16,
            child: SafeArea(
              child: _buildMovementControls(),
            ),
          ),
      ],
    );
  }
  
  Widget _buildDebugToggleButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.game.debugMode ? Colors.green : Colors.white38,
          width: 2,
        ),
      ),
      child: IconButton(
        icon: Icon(
          Icons.map,
          color: widget.game.debugMode ? Colors.green : Colors.white70,
          size: 24,
        ),
        onPressed: () {
          setState(() {
            widget.game.toggleDebugMode();
          });
        },
        tooltip: 'Toggle Map View',
      ),
    );
  }
  
  Widget _buildControlsToggleButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white38,
          width: 2,
        ),
      ),
      child: IconButton(
        icon: Icon(
          _showControls ? Icons.gamepad : Icons.gamepad_outlined,
          color: Colors.white70,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        tooltip: 'Toggle Controls',
      ),
    );
  }
  
  Widget _buildMovementControls() {
    // Scale controls based on screen size
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600; // iPad Mini and larger
    final controlSize = isTablet ? 64.0 : 48.0;
    final spacing = isTablet ? 12.0 : 8.0;
    final padding = isTablet ? 12.0 : 8.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white38),
      ),
      child: Column(
        children: [
          // Up button
          _buildDirectionButton(
            icon: Icons.keyboard_arrow_up,
            direction: 'up',
            size: controlSize,
          ),
          
          Row(
            children: [
              // Left button
              _buildDirectionButton(
                icon: Icons.keyboard_arrow_left,
                direction: 'left',
                size: controlSize,
              ),
              
              SizedBox(width: spacing),
              
              // Right button
              _buildDirectionButton(
                icon: Icons.keyboard_arrow_right,
                direction: 'right',
                size: controlSize,
              ),
            ],
          ),
          
          // Down button
          _buildDirectionButton(
            icon: Icons.keyboard_arrow_down,
            direction: 'down',
            size: controlSize,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDirectionButton({
    required IconData icon,
    required String direction,
    required double size,
  }) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white38),
      ),
      child: GestureDetector(
        onTapDown: (_) => _handleMovementStart(direction),
        onTapUp: (_) => _handleMovementStop(),
        onTapCancel: () => _handleMovementStop(),
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
  
  void _handleMovementStart(String direction) {
    widget.game.handleTouchMovement(direction);
    print('🎮 TOUCH: Movement $direction started');
  }
  
  void _handleMovementStop() {
    widget.game.stopTouchMovement();
    print('🎮 TOUCH: Movement stopped');
  }
}