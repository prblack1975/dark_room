import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'wall.dart';
import 'player.dart';
import 'game_object.dart';

class DebugOverlay extends PositionComponent {
  static const double opacity = 0.7;
  
  @override
  int get priority => 1000; // Render on top of everything
  
  @override
  void render(Canvas canvas) {
    if (parent == null || !parent!.isMounted) return;
    
    // Draw grid
    _drawGrid(canvas);
    
    // Draw all game components with debug visualization
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
    
    // Draw coordinate info
    _drawCoordinateInfo(canvas);
  }
  
  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    const gridSize = 50.0;
    final gameSize = parent!.findGame()!.size;
    
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
  
  void _drawWall(Canvas canvas, Wall wall) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 2.0
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
      ..color = Colors.white.withValues(alpha: opacity * 1.5)
      ..style = PaintingStyle.fill;
    
    // Draw player as a circle
    canvas.drawCircle(
      Offset(player.position.x, player.position.y),
      player.size.x / 2,
      paint,
    );
    
    // Draw direction indicator
    final directionPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: opacity)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final angle = player.velocity.angleToSigned(Vector2(1, 0));
    if (player.velocity.length > 0) {
      final endPoint = Offset(
        player.position.x + player.velocity.normalized().x * 20,
        player.position.y + player.velocity.normalized().y * 20,
      );
      
      canvas.drawLine(
        Offset(player.position.x, player.position.y),
        endPoint,
        directionPaint,
      );
    }
  }
  
  void _drawGameObject(Canvas canvas, GameObject object) {
    Paint paint;
    
    switch (object.type) {
      case GameObjectType.item:
        paint = Paint()
          ..color = Colors.green.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;
        break;
      case GameObjectType.healthArtifact:
        paint = Paint()
          ..color = Colors.red.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;
        break;
      case GameObjectType.door:
        paint = Paint()
          ..color = Colors.blue.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;
        break;
      case GameObjectType.interactable:
        paint = Paint()
          ..color = Colors.yellow.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;
        break;
      case GameObjectType.soundSource:
        paint = Paint()
          ..color = Colors.purple.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        
        // Draw static circles for sound sources (remove pulsing to fix blinking)
        const pulseRadius = 25.0;
        
        canvas.drawCircle(
          Offset(object.position.x + object.size.x / 2, 
                 object.position.y + object.size.y / 2),
          pulseRadius,
          paint,
        );
        break;
    }
    
    canvas.drawRect(
      Rect.fromLTWH(
        object.position.x,
        object.position.y,
        object.size.x,
        object.size.y,
      ),
      paint,
    );
    
    // Draw label
    final textPainter = TextPainter(
      text: TextSpan(
        text: object.type.name,
        style: TextStyle(
          color: Colors.white.withValues(alpha: opacity),
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(object.position.x, object.position.y - 15),
    );
  }
  
  void _drawCoordinateInfo(Canvas canvas) {
    final game = parent!.findGame();
    if (game == null) return;
    
    // Find player
    Player? player;
    for (final component in parent!.children) {
      if (component is Player) {
        player = component;
        break;
      }
    }
    
    if (player == null) return;
    
    final info = 'Player: (${player.position.x.toStringAsFixed(0)}, '
                 '${player.position.y.toStringAsFixed(0)})';
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: info,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 10));
  }
}

