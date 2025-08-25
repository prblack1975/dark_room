import 'package:flame/components.dart';
import 'dart:math' as math;
import '../components/wall.dart';

/// Represents a line segment between two points
class LineSegment {
  final Vector2 start;
  final Vector2 end;
  
  LineSegment(this.start, this.end);
  
  @override
  String toString() => 'LineSegment($start -> $end)';
}

/// Represents an intersection point with additional data
class WallIntersection {
  final Vector2 point;
  final double distance;
  final Wall wall;
  
  WallIntersection(this.point, this.distance, this.wall);
  
  @override
  String toString() => 'WallIntersection($point, distance: ${distance.toStringAsFixed(2)})';
}

/// Utility class for calculating line-wall intersections for audio occlusion
class LineIntersection {
  
  /// Calculate all wall intersections between player and sound source positions
  /// Returns list of intersections sorted by distance from player
  /// Optimized version with early exit for performance
  static List<WallIntersection> calculateWallIntersections(
    Vector2 playerPos, 
    Vector2 soundPos, 
    List<Wall> walls
  ) {
    final intersections = <WallIntersection>[];
    final lineOfSight = LineSegment(playerPos, soundPos);
    final maxDistance = playerPos.distanceTo(soundPos);
    
    // Early exit if line of sight is very short
    if (maxDistance < 10.0) {
      return intersections;
    }
    
    for (final wall in walls) {
      // Quick bounding box check before expensive intersection calculation
      if (!_lineIntersectsBoundingBox(lineOfSight, wall)) {
        continue;
      }
      
      final wallIntersections = getLineWallIntersections(lineOfSight, wall);
      intersections.addAll(wallIntersections);
      
      // Optional: early exit if we have too many intersections (performance vs accuracy trade-off)
      if (intersections.length > 10) {
        break;
      }
    }
    
    // Sort by distance from player
    intersections.sort((a, b) => a.distance.compareTo(b.distance));
    
    return intersections;
  }
  
  /// Quick bounding box intersection test before expensive line-wall intersection
  static bool _lineIntersectsBoundingBox(LineSegment line, Wall wall) {
    final minX = math.min(line.start.x, line.end.x);
    final maxX = math.max(line.start.x, line.end.x);
    final minY = math.min(line.start.y, line.end.y);
    final maxY = math.max(line.start.y, line.end.y);
    
    final wallMinX = wall.position.x;
    final wallMaxX = wall.position.x + wall.size.x;
    final wallMinY = wall.position.y;
    final wallMaxY = wall.position.y + wall.size.y;
    
    // Check if bounding boxes overlap
    return !(maxX < wallMinX || minX > wallMaxX || maxY < wallMinY || minY > wallMaxY);
  }
  
  /// Get intersection points between a line segment and a rectangular wall
  static List<WallIntersection> getLineWallIntersections(LineSegment line, Wall wall) {
    final intersections = <WallIntersection>[];
    
    // Get wall boundaries as line segments
    final wallSegments = getWallBoundarySegments(wall);
    
    for (final wallSegment in wallSegments) {
      final intersection = lineSegmentIntersection(line, wallSegment);
      if (intersection != null) {
        final distance = line.start.distanceTo(intersection);
        intersections.add(WallIntersection(intersection, distance, wall));
      }
    }
    
    return intersections;
  }
  
  /// Get the four boundary segments of a rectangular wall
  static List<LineSegment> getWallBoundarySegments(Wall wall) {
    final pos = wall.position;
    final size = wall.size;
    
    return [
      // Top edge
      LineSegment(pos, Vector2(pos.x + size.x, pos.y)),
      // Right edge  
      LineSegment(Vector2(pos.x + size.x, pos.y), pos + size),
      // Bottom edge
      LineSegment(pos + size, Vector2(pos.x, pos.y + size.y)),
      // Left edge
      LineSegment(Vector2(pos.x, pos.y + size.y), pos),
    ];
  }
  
  /// Calculate intersection point between two line segments
  /// Returns null if no intersection exists
  static Vector2? lineSegmentIntersection(LineSegment line1, LineSegment line2) {
    final x1 = line1.start.x;
    final y1 = line1.start.y;
    final x2 = line1.end.x;
    final y2 = line1.end.y;
    
    final x3 = line2.start.x;
    final y3 = line2.start.y;
    final x4 = line2.end.x;
    final y4 = line2.end.y;
    
    final denominator = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
    
    // Lines are parallel
    if (denominator.abs() < 1e-10) {
      return null;
    }
    
    final t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denominator;
    final u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / denominator;
    
    // Check if intersection is within both line segments
    if (t >= 0 && t <= 1 && u >= 0 && u <= 1) {
      final intersectionX = x1 + t * (x2 - x1);
      final intersectionY = y1 + t * (y2 - y1);
      return Vector2(intersectionX, intersectionY);
    }
    
    return null;
  }
  
  /// Calculate occlusion strength based on number of wall intersections
  /// Returns value between 0.0 (no occlusion) and 1.0 (maximum occlusion)
  static double calculateOcclusionStrength(List<WallIntersection> intersections) {
    if (intersections.isEmpty) {
      return 0.0; // No walls in the way
    }
    
    // Count unique walls intersected (avoid double-counting corner intersections)
    final uniqueWalls = <Wall>{};
    for (final intersection in intersections) {
      uniqueWalls.add(intersection.wall);
    }
    
    final wallCount = uniqueWalls.length;
    
    // Each wall reduces volume exponentially
    // 1 wall = ~50% reduction, 2 walls = ~75% reduction, 3+ walls = ~87%+ reduction
    final occlusionStrength = 1.0 - math.pow(0.5, wallCount.toDouble());
    
    return occlusionStrength.clamp(0.0, 0.9); // Cap at 90% to avoid complete silence
  }
  
  /// Calculate muffling effect strength for low-pass filtering simulation
  /// Returns value between 0.0 (no muffling) and 1.0 (maximum muffling)
  static double calculateMufflingStrength(List<WallIntersection> intersections) {
    if (intersections.isEmpty) {
      return 0.0; // No muffling needed
    }
    
    // Muffling is stronger than just volume reduction
    final wallCount = intersections.length;
    final mufflingStrength = math.min(wallCount * 0.3, 0.8);
    
    return mufflingStrength.clamp(0.0, 0.8);
  }
}