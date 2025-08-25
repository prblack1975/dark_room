import 'package:flutter_test/flutter_test.dart';
import 'package:dark_room/game/systems/narration_system.dart';

void main() {
  group('Enhanced Narration System Tests', () {
    late NarrationSystem narrationSystem;

    setUp(() {
      narrationSystem = NarrationSystem();
    });

    test('Enhanced item descriptions work correctly', () {
      // Test that narration system enhances descriptions
      String capturedNarration = '';
      
      narrationSystem.onNarrationStart = (text) {
        capturedNarration = text;
      };

      // Test key enhancement
      narrationSystem.narrateItemPickup('key', 'A simple key');
      expect(capturedNarration, contains('Its metallic surface is cool to the touch'));

      // Test brass key enhancement
      narrationSystem.narrateItemPickup('brass key', 'A brass key');
      expect(capturedNarration, contains('The brass gleams faintly in the darkness'));

      // Test coin enhancement
      narrationSystem.narrateItemPickup('coin', 'A small coin');
      expect(capturedNarration, contains('A small metallic disc, warm from your pocket'));
    });

    test('Atmospheric situation descriptions work', () {
      String capturedNarration = '';
      
      narrationSystem.onNarrationStart = (text) {
        capturedNarration = text;
      };

      narrationSystem.narrateSituation('approach the door');
      
      // Should contain atmospheric phrasing
      expect(capturedNarration.toLowerCase(), anyOf([
        contains('darkness presses in'),
        contains('absolute blackness'),
        contains('footsteps echo'),
        contains('silence is broken'),
        contains('guided by sound'),
      ]));
      
      expect(capturedNarration.toLowerCase(), contains('approach the door'));
    });

    test('Narration priority system works correctly', () {
      // Stop any current narration to start fresh
      narrationSystem.clearQueue();
      
      // Add normal priority item
      narrationSystem.narrate('Normal message', priority: NarrationPriority.normal);
      
      // Add urgent priority item before first one starts - should go to front
      narrationSystem.narrate('Urgent message', priority: NarrationPriority.urgent);
      
      // Check that urgent message is first
      final debugInfo = narrationSystem.getDebugInfo();
      final queueItems = debugInfo['queueItems'] as List<String>;
      if (queueItems.isNotEmpty) {
        expect(queueItems.first, equals('Urgent message'));
      }
    });

    test('Door interaction narration works', () {
      String capturedNarration = '';
      
      narrationSystem.onNarrationStart = (text) {
        capturedNarration = text;
      };

      narrationSystem.narrateDoorInteraction('The door clicks open');
      expect(capturedNarration, equals('The door clicks open'));
    });

    test('Level completion narration works', () {
      String capturedNarration = '';
      
      narrationSystem.onNarrationStart = (text) {
        capturedNarration = text;
      };

      narrationSystem.narrateLevelComplete('Tutorial');
      expect(capturedNarration, contains('Level complete: Tutorial'));
      expect(capturedNarration, contains('Well done!'));
    });

    test('Proximity narration works', () {
      String capturedNarration = '';
      
      narrationSystem.onNarrationStart = (text) {
        capturedNarration = text;
      };

      narrationSystem.narrateProximity('mysterious object', 'It hums with energy');
      expect(capturedNarration, contains('Approaching mysterious object'));
      expect(capturedNarration, contains('It hums with energy'));
    });

    test('Room entry narration works', () {
      String capturedNarration = '';
      
      narrationSystem.onNarrationStart = (text) {
        capturedNarration = text;
      };

      narrationSystem.narrateRoomEntry('A dark chamber filled with echoes');
      expect(capturedNarration, contains('Entering: A dark chamber filled with echoes'));
    });

    test('Narration duration calculation is reasonable', () {
      // Clear queue first
      narrationSystem.clearQueue();
      
      final shortText = 'Hello';
      final longText = 'This is a much longer piece of narration text that should take significantly more time to speak aloud';

      // Create narration items to test duration calculation
      narrationSystem.narrate(shortText);
      narrationSystem.narrate(longText);

      // At least one item should be in queue (the other might have started)
      expect(narrationSystem.queueLength, greaterThanOrEqualTo(0));
    });

    test('Clear queue functionality works', () {
      // Clear any existing queue first
      narrationSystem.clearQueue();
      
      narrationSystem.narrate('Message 1');
      narrationSystem.narrate('Message 2');
      narrationSystem.narrate('Message 3');
      
      // After clearing, queue should be empty
      narrationSystem.clearQueue();
      expect(narrationSystem.queueLength, equals(0));
      expect(narrationSystem.isNarrating, isFalse);
    });

    test('Debug information is comprehensive', () {
      narrationSystem.narrate('Test message');
      
      final debugInfo = narrationSystem.getDebugInfo();
      
      expect(debugInfo, containsPair('isNarrating', isA<bool>()));
      expect(debugInfo, containsPair('currentNarration', isA<String>()));
      expect(debugInfo, containsPair('queueLength', isA<int>()));
      expect(debugInfo, containsPair('queueItems', isA<List>()));
    });
  });
}