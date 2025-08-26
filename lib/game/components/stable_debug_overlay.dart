import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'wall.dart';
import 'player.dart';
import 'game_object.dart';

class StableDebugOverlay extends Component {
  static const double opacity = 0.8;
  
  @override
  int get priority => 1000; // Render on top of everything
  
  @override
  void render(Canvas canvas) {
    if (parent == null) return;
    
    final gameSize = findGame()?.size ?? Vector2(800, 600);
    
    // Fill background with semi-transparent black
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameSize.x, gameSize.y),
      Paint()..color = Colors.black.withOpacity(0.3),
    );
    
    // Draw grid
    _drawGrid(canvas, gameSize);
    
    // Draw all components
    _drawComponents(canvas);
    
    // Draw instructions
    _drawInstructions(canvas);
  }
  
  void _drawGrid(Canvas canvas, Vector2 gameSize) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // Scale grid size based on screen size for better tablet visibility
    final gridSize = gameSize.x > 800 ? 75.0 : 50.0;
    
    // Vertical lines
    for (double x = 0; x <= gameSize.x; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, gameSize.y),
        paint,
      );
    }
    
    // Horizontal lines
    for (double y = 0; y <= gameSize.y; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(gameSize.x, y),
        paint,
      );
    }
  }
  
  void _drawComponents(Canvas canvas) {
    final components = parent!.children;
    
    for (final component in components) {
      if (component is Wall) {
        _drawWall(canvas, component);
      } else if (component is Player) {
        _drawPlayer(canvas, component);
      } else if (component is GameObject) {
        _drawGameObject(canvas, component);
      }
    }
  }
  
  void _drawWall(Canvas canvas, Wall wall) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawRect(
      Rect.fromLTWH(
        wall.position.x,
        wall.position.y,
        wall.size.x,
        wall.size.y,
      ),
      paint,
    );
  }
  
  void _drawPlayer(Canvas canvas, Player player) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    // Draw player as a circle
    canvas.drawCircle(
      Offset(player.position.x, player.position.y),
      player.size.x / 2,
      paint,
    );
    
    // Add "P" label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'P',
        style: TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(player.position.x - 6, player.position.y - 8),
    );
  }
  
  void _drawGameObject(Canvas canvas, GameObject object) {
    Color color;
    String label;
    
    switch (object.type) {
      case GameObjectType.item:
        color = Colors.green;
        label = 'KEY';
        break;
      case GameObjectType.healthArtifact:
        color = Colors.red;
        label = 'HEALTH';
        break;
      case GameObjectType.door:
        color = Colors.blue;
        label = 'DOOR';
        break;
      case GameObjectType.interactable:
        color = Colors.yellow;
        label = 'LEVEL';
        break;
      case GameObjectType.soundSource:
        color = Colors.purple;
        label = 'SOUND';
        break;
    }
    
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    // Draw filled rectangle
    canvas.drawRect(
      Rect.fromLTWH(
        object.position.x,
        object.position.y,
        object.size.x,
        object.size.y,
      ),
      paint,
    );
    
    // Draw border
    canvas.drawRect(
      Rect.fromLTWH(
        object.position.x,
        object.position.y,
        object.size.x,
        object.size.y,
      ),
      Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    
    // Draw label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        object.position.x + (object.size.x - textPainter.width) / 2,
        object.position.y - 15,
      ),
    );
  }
  
  void _drawInstructions(Canvas canvas) {
    final instructions = [
      'DEBUG MODE - Map/Touch controls visible',
      'Use touch controls or WASD/Arrows to move',
      'Tap map icon to toggle debug view',
      'F5: Toggle Fire tablet audio mode',
      'Walk near objects to interact',
      '',
      'WHITE LINES: Walls',
      'GREEN BOXES: Keys/Items', 
      'BLUE BOXES: Doors',
      'YELLOW BOXES: Level Select',
      'WHITE CIRCLE (P): You (Player)',
    ];
    
    final gameSize = findGame()?.size ?? Vector2(800, 600);
    final fontSize = gameSize.x > 800 ? 14.0 : 12.0;
    final lineHeight = gameSize.x > 800 ? 18.0 : 16.0;
    
    for (int i = 0; i < instructions.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: instructions[i],
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: fontSize,
            fontWeight: FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(canvas, Offset(10, 10 + (i * lineHeight)));
    }
  }
}