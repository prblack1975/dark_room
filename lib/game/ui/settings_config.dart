import '../utils/game_logger.dart';

/// Configuration system for Dark Room game UI and settings
/// 
/// Features:
/// - UI visibility controls
/// - Dark theme compliance
/// - Persistent settings (future implementation)
/// - Audio/visual balance configuration
class SettingsConfig {
  late final GameCategoryLogger _logger;
  static final SettingsConfig _instance = SettingsConfig._internal();
  factory SettingsConfig() => _instance;
  SettingsConfig._internal() {
    gameLogger.initialize();
    _logger = gameLogger.ui;
  }

  // UI Visibility Settings
  bool _inventoryDisplayVisible = true;
  bool _healthDisplayVisible = true; // Health system now implemented
  bool _debugInfoVisible = false;
  bool _narrationTextVisible = true;
  bool _minimalHUDMode = true; // When true, UI elements are barely visible

  // UI Styling Settings
  double _hudOpacity = 0.3; // Very low opacity for "barely visible" design
  double _inventoryFontSize = 12.0;
  double _narrationFontSize = 14.0;

  // Audio Settings
  bool _narrationEnabled = true;
  double _narrationVolume = 0.8;
  double _environmentalAudioVolume = 1.0;

  // Getters for UI visibility
  bool get inventoryDisplayVisible => _inventoryDisplayVisible;
  bool get healthDisplayVisible => _healthDisplayVisible;
  bool get debugInfoVisible => _debugInfoVisible;
  bool get narrationTextVisible => _narrationTextVisible;
  bool get minimalHUDMode => _minimalHUDMode;

  // Getters for UI styling
  double get hudOpacity => _hudOpacity;
  double get inventoryFontSize => _inventoryFontSize;
  double get narrationFontSize => _narrationFontSize;

  // Getters for audio settings
  bool get narrationEnabled => _narrationEnabled;
  double get narrationVolume => _narrationVolume;
  double get environmentalAudioVolume => _environmentalAudioVolume;

  // Setters for UI visibility
  void setInventoryDisplayVisible(bool visible) {
    _inventoryDisplayVisible = visible;
    _logger.info('⚙️ SETTINGS: Inventory display ${visible ? 'enabled' : 'disabled'}');
  }

  void setHealthDisplayVisible(bool visible) {
    _healthDisplayVisible = visible;
    _logger.info('⚙️ SETTINGS: Health display ${visible ? 'enabled' : 'disabled'}');
  }

  void setDebugInfoVisible(bool visible) {
    _debugInfoVisible = visible;
    _logger.info('⚙️ SETTINGS: Debug info ${visible ? 'enabled' : 'disabled'}');
  }

  void setNarrationTextVisible(bool visible) {
    _narrationTextVisible = visible;
    _logger.info('⚙️ SETTINGS: Narration text ${visible ? 'enabled' : 'disabled'}');
  }

  void setMinimalHUDMode(bool minimal) {
    _minimalHUDMode = minimal;
    _hudOpacity = minimal ? 0.3 : 0.7;
    _logger.info('⚙️ SETTINGS: Minimal HUD mode ${minimal ? 'enabled' : 'disabled'}');
  }

  // Setters for UI styling
  void setHudOpacity(double opacity) {
    _hudOpacity = opacity.clamp(0.1, 1.0);
    _logger.info('⚙️ SETTINGS: HUD opacity set to $_hudOpacity');
  }

  void setInventoryFontSize(double size) {
    _inventoryFontSize = size.clamp(8.0, 20.0);
    _logger.info('⚙️ SETTINGS: Inventory font size set to $_inventoryFontSize');
  }

  void setNarrationFontSize(double size) {
    _narrationFontSize = size.clamp(10.0, 24.0);
    _logger.info('⚙️ SETTINGS: Narration font size set to $_narrationFontSize');
  }

  // Setters for audio settings
  void setNarrationEnabled(bool enabled) {
    _narrationEnabled = enabled;
    _logger.info('⚙️ SETTINGS: Narration ${enabled ? 'enabled' : 'disabled'}');
  }

  void setNarrationVolume(double volume) {
    _narrationVolume = volume.clamp(0.0, 1.0);
    _logger.info('⚙️ SETTINGS: Narration volume set to $_narrationVolume');
  }

  void setEnvironmentalAudioVolume(double volume) {
    _environmentalAudioVolume = volume.clamp(0.0, 1.0);
    _logger.info('⚙️ SETTINGS: Environmental audio volume set to $_environmentalAudioVolume');
  }

  // Toggle methods for easy keyboard shortcuts
  void toggleInventoryDisplay() {
    setInventoryDisplayVisible(!_inventoryDisplayVisible);
  }

  void toggleHealthDisplay() {
    setHealthDisplayVisible(!_healthDisplayVisible);
  }

  void toggleDebugInfo() {
    setDebugInfoVisible(!_debugInfoVisible);
  }

  void toggleNarrationText() {
    setNarrationTextVisible(!_narrationTextVisible);
  }

  void toggleMinimalHUDMode() {
    setMinimalHUDMode(!_minimalHUDMode);
  }

  void toggleNarration() {
    setNarrationEnabled(!_narrationEnabled);
  }

  // Debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'ui': {
        'inventoryVisible': _inventoryDisplayVisible,
        'healthVisible': _healthDisplayVisible,
        'debugInfoVisible': _debugInfoVisible,
        'narrationTextVisible': _narrationTextVisible,
        'minimalHUDMode': _minimalHUDMode,
        'hudOpacity': _hudOpacity,
        'inventoryFontSize': _inventoryFontSize,
        'narrationFontSize': _narrationFontSize,
      },
      'audio': {
        'narrationEnabled': _narrationEnabled,
        'narrationVolume': _narrationVolume,
        'environmentalAudioVolume': _environmentalAudioVolume,
      },
    };
  }

  // Reset to defaults
  void resetToDefaults() {
    _inventoryDisplayVisible = true;
    _healthDisplayVisible = true;
    _debugInfoVisible = false;
    _narrationTextVisible = true;
    _minimalHUDMode = true;
    _hudOpacity = 0.3;
    _inventoryFontSize = 12.0;
    _narrationFontSize = 14.0;
    _narrationEnabled = true;
    _narrationVolume = 0.8;
    _environmentalAudioVolume = 1.0;
    _logger.info('⚙️ SETTINGS: Reset to defaults');
  }

  // Future: Save/load settings to persistent storage
  // Future Enhancement: Implement persistent storage
  // void saveSettings() async { /* Persistent storage implementation pending */ }
  // void loadSettings() async { /* Persistent storage implementation pending */ }
}