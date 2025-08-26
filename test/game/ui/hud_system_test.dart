import 'package:flutter_test/flutter_test.dart';
import 'package:dark_room/game/ui/settings_config.dart';

void main() {
  group('Settings Configuration Tests', () {
    late SettingsConfig settings;

    setUp(() {
      settings = SettingsConfig();
    });

    test('Settings configuration works correctly', () {
      // Test initial values
      expect(settings.inventoryDisplayVisible, isTrue);
      expect(settings.minimalHUDMode, isTrue);
      expect(settings.hudOpacity, equals(0.3));

      // Test toggles
      settings.toggleInventoryDisplay();
      expect(settings.inventoryDisplayVisible, isFalse);

      settings.toggleMinimalHUDMode();
      expect(settings.minimalHUDMode, isFalse);
      expect(settings.hudOpacity, equals(0.7));
    });

    test('Settings reset to defaults correctly', () {
      // Change some settings
      settings.setInventoryDisplayVisible(false);
      settings.setMinimalHUDMode(false);
      settings.setHudOpacity(0.8);

      // Reset to defaults
      settings.resetToDefaults();

      expect(settings.inventoryDisplayVisible, isTrue);
      expect(settings.minimalHUDMode, isTrue);
      expect(settings.hudOpacity, equals(0.3));
    });

    test('Settings provide comprehensive debug info', () {
      final debugInfo = settings.getDebugInfo();
      
      expect(debugInfo, containsPair('ui', isA<Map<String, dynamic>>()));
      expect(debugInfo, containsPair('audio', isA<Map<String, dynamic>>()));
      
      final uiSettings = debugInfo['ui'] as Map<String, dynamic>;
      expect(uiSettings, containsPair('inventoryVisible', isA<bool>()));
      expect(uiSettings, containsPair('minimalHUDMode', isA<bool>()));
      expect(uiSettings, containsPair('hudOpacity', isA<double>()));
    });
  });
}