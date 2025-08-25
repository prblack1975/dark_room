import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:dark_room/game/utils/line_intersection.dart';
import 'package:dark_room/game/components/wall.dart';
import 'package:dark_room/game/audio/audio_manager.dart';

void main() {
  group('Wall Occlusion System Tests', () {
    test('line intersection calculation works correctly', () {
      // Create a simple line segment
      final line1 = LineSegment(Vector2(0, 0), Vector2(10, 10));
      final line2 = LineSegment(Vector2(0, 10), Vector2(10, 0));
      
      // These lines should intersect at (5, 5)
      final intersection = LineIntersection.lineSegmentIntersection(line1, line2);
      
      expect(intersection, isNotNull);
      expect(intersection!.x, closeTo(5.0, 0.1));
      expect(intersection.y, closeTo(5.0, 0.1));
    });
    
    test('parallel lines do not intersect', () {
      final line1 = LineSegment(Vector2(0, 0), Vector2(10, 0));
      final line2 = LineSegment(Vector2(0, 5), Vector2(10, 5));
      
      final intersection = LineIntersection.lineSegmentIntersection(line1, line2);
      expect(intersection, isNull);
    });
    
    test('wall boundary segments are calculated correctly', () {
      final wall = Wall(
        position: Vector2(10, 10),
        size: Vector2(20, 30),
      );
      
      final segments = LineIntersection.getWallBoundarySegments(wall);
      expect(segments.length, equals(4));
      
      // Check top edge
      expect(segments[0].start, equals(Vector2(10, 10)));
      expect(segments[0].end, equals(Vector2(30, 10)));
      
      // Check right edge
      expect(segments[1].start, equals(Vector2(30, 10)));
      expect(segments[1].end, equals(Vector2(30, 40)));
      
      // Check bottom edge
      expect(segments[2].start, equals(Vector2(30, 40)));
      expect(segments[2].end, equals(Vector2(10, 40)));
      
      // Check left edge
      expect(segments[3].start, equals(Vector2(10, 40)));
      expect(segments[3].end, equals(Vector2(10, 10)));
    });
    
    test('wall intersections are detected correctly', () {
      // Create a wall that blocks the line of sight
      final wall = Wall(
        position: Vector2(40, 40),
        size: Vector2(20, 20),
      );
      
      final playerPos = Vector2(30, 50);
      final soundPos = Vector2(70, 50);
      
      final intersections = LineIntersection.calculateWallIntersections(
        playerPos,
        soundPos,
        [wall],
      );
      
      // Should have at least one intersection (entry and exit points)
      expect(intersections.length, greaterThan(0));
      
      // All intersections should be between player and sound
      for (final intersection in intersections) {
        expect(intersection.distance, greaterThan(0));
        expect(intersection.distance, lessThan(playerPos.distanceTo(soundPos)));
      }
    });
    
    test('occlusion strength increases with wall count', () {
      // No walls
      final noOcclusion = LineIntersection.calculateOcclusionStrength([]);
      expect(noOcclusion, equals(0.0));
      
      // Create mock intersections (we just need the wall reference)
      final wall1 = Wall(position: Vector2.zero(), size: Vector2(10, 10));
      final wall2 = Wall(position: Vector2(20, 0), size: Vector2(10, 10));
      
      final oneWallIntersections = [
        WallIntersection(Vector2(5, 5), 10.0, wall1),
      ];
      
      final twoWallIntersections = [
        WallIntersection(Vector2(5, 5), 10.0, wall1),
        WallIntersection(Vector2(25, 5), 20.0, wall2),
      ];
      
      final oneWallOcclusion = LineIntersection.calculateOcclusionStrength(oneWallIntersections);
      final twoWallOcclusion = LineIntersection.calculateOcclusionStrength(twoWallIntersections);
      
      expect(oneWallOcclusion, greaterThan(0.0));
      expect(twoWallOcclusion, greaterThan(oneWallOcclusion));
      expect(twoWallOcclusion, lessThanOrEqualTo(0.9)); // Capped at 90%
    });
    
    test('audio spatial data includes occlusion information', () {
      final baseAudio = AudioSpatialData(
        volume: 0.8,
        balance: 0.1,
        distance: 50.0,
      );
      
      final occludedAudio = baseAudio.withOcclusion(
        occlusionStrength: 0.5,
        mufflingStrength: 0.3,
        wallCount: 2,
      );
      
      // Volume should be reduced
      expect(occludedAudio.volume, lessThan(baseAudio.volume));
      expect(occludedAudio.volume, closeTo(0.4, 0.01)); // 0.8 * (1.0 - 0.5)
      
      // Other properties should be preserved or updated
      expect(occludedAudio.balance, equals(baseAudio.balance));
      expect(occludedAudio.distance, equals(baseAudio.distance));
      expect(occludedAudio.occlusionStrength, equals(0.5));
      expect(occludedAudio.mufflingStrength, equals(0.3));
      expect(occludedAudio.wallCount, equals(2));
    });
    
    test('line of sight is clear when no walls block it', () {
      final playerPos = Vector2(10, 10);
      final soundPos = Vector2(90, 90);
      
      // Create walls that don't block the line of sight
      final walls = [
        Wall(position: Vector2(0, 50), size: Vector2(20, 20)),
        Wall(position: Vector2(70, 0), size: Vector2(20, 20)),
      ];
      
      final intersections = LineIntersection.calculateWallIntersections(
        playerPos,
        soundPos,
        walls,
      );
      
      expect(intersections.length, equals(0));
      
      final occlusionStrength = LineIntersection.calculateOcclusionStrength(intersections);
      expect(occlusionStrength, equals(0.0));
    });
    
    test('complex wall configuration creates multiple intersections', () {
      final playerPos = Vector2(0, 50);
      final soundPos = Vector2(100, 50);
      
      // Create multiple walls in the path
      final walls = [
        Wall(position: Vector2(20, 40), size: Vector2(10, 20)), // Wall 1
        Wall(position: Vector2(50, 30), size: Vector2(10, 40)), // Wall 2  
        Wall(position: Vector2(80, 45), size: Vector2(10, 10)), // Wall 3
      ];
      
      final intersections = LineIntersection.calculateWallIntersections(
        playerPos,
        soundPos,
        walls,
      );
      
      // Should have multiple intersections
      expect(intersections.length, greaterThan(2));
      
      // Intersections should be sorted by distance
      for (int i = 1; i < intersections.length; i++) {
        expect(intersections[i].distance, greaterThanOrEqualTo(intersections[i-1].distance));
      }
      
      final occlusionStrength = LineIntersection.calculateOcclusionStrength(intersections);
      expect(occlusionStrength, greaterThan(0.5)); // Significant occlusion with multiple walls
    });
  });
}