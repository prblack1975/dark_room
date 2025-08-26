import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/line_intersection.dart';
import 'wall.dart';
import 'player.dart';
import 'game_object.dart';
import '../utils/game_logger.dart';

/// Debug visualization component for wall occlusion calculations
class WallOcclusionDebug extends Component with HasGameReference {
  late final GameCategoryLogger _logger;
  bool isVisible = false;
  late Player? _player;
  List<Wall> _walls = [];
  List<GameObject> _soundSources = [];
  
  final Paint _lineOfSightPaint = Paint()
    ..color = Colors.green.withValues(alpha: 0.6)
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;
    
  final Paint _occludedLinePaint = Paint()
    ..color = Colors.red.withValues(alpha: 0.6)
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;
    
  final Paint _intersectionPaint = Paint()
    ..color = Colors.orange
    ..style = PaintingStyle.fill;
    
  final Paint _wallPaint = Paint()
    ..color = Colors.blue.withValues(alpha: 0.3)
    ..style = PaintingStyle.fill;
    
  final Paint _soundSourcePaint = Paint()
    ..color = Colors.purple.withValues(alpha: 0.5)
    ..style = PaintingStyle.fill;

  @override
  void onLoad() async {
    super.onLoad();
    gameLogger.initialize();
    _logger = gameLogger.system;
  }

  @override
  bool get debugMode => true;

  @override
  void update(double dt) {
    super.update(dt);
    
    if (!isVisible) return;
    
    // Update cached references
    _updateCachedComponents();
  }
  
  void _updateCachedComponents() {
    // Find player
    _player = findGame()?.children
        .expand((component) => component.children)
        .whereType<Player>()
        .firstOrNull;
    
    // Find walls
    _walls = findGame()?.children
        .expand((component) => component.children)
        .whereType<Wall>()
        .toList() ?? [];
        
    // Find sound sources
    _soundSources = findGame()?.children
        .expand((component) => component.children)
        .whereType<GameObject>()
        .where((obj) => obj.type == GameObjectType.soundSource)
        .toList() ?? [];
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    if (!isVisible || _player == null) return;
    
    // Draw walls with semi-transparent overlay
    _drawWalls(canvas);
    
    // Draw sound sources
    _drawSoundSources(canvas);
    
    // Draw lines of sight and occlusion data
    _drawOcclusionLines(canvas);
    
    // Draw debug text overlay
    _drawDebugText(canvas);
  }
  
  void _drawWalls(Canvas canvas) {
    for (final wall in _walls) {
      final rect = Rect.fromLTWH(
        wall.position.x,
        wall.position.y,
        wall.size.x,
        wall.size.y,
      );
      canvas.drawRect(rect, _wallPaint);
      
      // Draw wall outline
      final outlinePaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawRect(rect, outlinePaint);
    }
  }
  
  void _drawSoundSources(Canvas canvas) {
    for (final soundSource in _soundSources) {
      final center = soundSource.position + soundSource.size / 2;
      
      // Draw sound source circle
      canvas.drawCircle(
        Offset(center.x, center.y),
        math.max(soundSource.size.x, soundSource.size.y) / 2,
        _soundSourcePaint,
      );
      
      // Draw sound radius
      final radiusPaint = Paint()
        ..color = Colors.purple.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(
        Offset(center.x, center.y),
        soundSource.soundRadius,
        radiusPaint,
      );
    }
  }
  
  void _drawOcclusionLines(Canvas canvas) {
    if (_player == null) return;
    
    final playerPos = _player!.position;
    
    for (final soundSource in _soundSources) {
      final soundPos = soundSource.position + soundSource.size / 2;
      
      // Calculate intersections
      final intersections = LineIntersection.calculateWallIntersections(
        playerPos,
        soundPos,
        _walls,
      );
      
      // Draw line of sight
      final paint = intersections.isEmpty ? _lineOfSightPaint : _occludedLinePaint;
      canvas.drawLine(
        Offset(playerPos.x, playerPos.y),
        Offset(soundPos.x, soundPos.y),
        paint,
      );
      
      // Draw intersection points
      for (final intersection in intersections) {
        canvas.drawCircle(
          Offset(intersection.point.x, intersection.point.y),
          4.0,
          _intersectionPaint,
        );
        
        // Draw small text showing wall count at intersection
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${intersections.indexOf(intersection) + 1}',
            style: const TextStyle(
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
            intersection.point.x - textPainter.width / 2,
            intersection.point.y - textPainter.height / 2,
          ),
        );
      }
    }
  }
  
  void _drawDebugText(Canvas canvas) {
    if (_player == null) return;
    
    final playerPos = _player!.position;
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      backgroundColor: Colors.black54,
    );
    
    double yOffset = 10.0;
    
    // Draw header
    _drawText(canvas, 'WALL OCCLUSION DEBUG', 10.0, yOffset, textStyle);
    yOffset += 20.0;
    
    // Draw stats for each sound source
    for (final soundSource in _soundSources) {
      final soundPos = soundSource.position + soundSource.size / 2;
      final distance = playerPos.distanceTo(soundPos);
      
      // Calculate occlusion data
      final intersections = LineIntersection.calculateWallIntersections(
        playerPos,
        soundPos,
        _walls,
      );
      
      final occlusionStrength = LineIntersection.calculateOcclusionStrength(intersections);
      final mufflingStrength = LineIntersection.calculateMufflingStrength(intersections);
      final wallCount = intersections.map((i) => i.wall).toSet().length;
      
      // Base volume calculation
      final baseVolume = distance <= soundSource.soundRadius ? 
          ((soundSource.soundRadius - distance) / soundSource.soundRadius).clamp(0.0, 1.0) : 0.0;
      final finalVolume = baseVolume * (1.0 - occlusionStrength);
      
      final info = '${soundSource.soundFile ?? 'unknown'}: '
                  'Dist=${distance.toStringAsFixed(1)} '
                  'Vol=${finalVolume.toStringAsFixed(2)} '
                  'Walls=$wallCount '
                  'Occ=${(occlusionStrength * 100).toStringAsFixed(0)}% '
                  'Muff=${(mufflingStrength * 100).toStringAsFixed(0)}%';
      
      _drawText(canvas, info, 10.0, yOffset, textStyle);
      yOffset += 15.0;
    }
    
    // Draw controls
    yOffset += 10.0;
    _drawText(canvas, 'Press O to toggle occlusion debug', 10.0, yOffset, textStyle);
  }
  
  void _drawText(Canvas canvas, String text, double x, double y, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }
  
  /// Toggle debug visualization
  void toggle() {
    isVisible = !isVisible;
    _logger.debug('🔧 DEBUG: Wall occlusion debug ${isVisible ? 'ENABLED' : 'DISABLED'}');
  }
}