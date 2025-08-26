import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../systems/health_system.dart';
import 'settings_config.dart';

/// Health display component for Dark Room game
/// 
/// Features:
/// - Minimal, barely visible health bar
/// - Configurable display mode (bar/numeric/off)
/// - Color-coded health status
/// - Audio-first design with optional visual aid
/// - Dark aesthetic compliance
class HealthDisplay extends Component {
  late Paint _healthBarBackground;
  late Paint _healthBarFill;
  late Paint _criticalHealthPaint;
  late TextPaint _healthTextPaint;
  late TextPaint _criticalTextPaint;
  
  // Health display state
  double _currentHealth = 100.0;
  final double _maxHealth = 100.0;
  bool _isCritical = false;
  
  // Reference to systems
  HealthSystem? _healthSystem;
  late SettingsConfig _settings;
  
  // Display configuration
  Vector2 _displayPosition = Vector2(20, 20);
  Vector2 _barSize = Vector2(150, 8);
  
  // Animation for critical health warning
  double _criticalFlashTimer = 0.0;
  bool _showCriticalFlash = false;
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    _settings = SettingsConfig();
    _initializePaints();
    
    print('❤️ HEALTH DISPLAY: Initialized with minimal visibility design');
  }
  
  void _initializePaints() {
    // Health bar background (very subtle)
    _healthBarBackground = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    
    // Health bar fill (changes color based on health)
    _healthBarFill = Paint()
      ..style = PaintingStyle.fill;
    
    // Critical health warning paint
    _criticalHealthPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Health text paint (minimal)
    _healthTextPaint = TextPaint(
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.7),
        fontSize: 11,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w300,
      ),
    );
    
    // Critical health text paint
    _criticalTextPaint = TextPaint(
      style: TextStyle(
        color: Colors.red.withValues(alpha: 0.9),
        fontSize: 11,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  /// Set reference to health system
  void setHealthSystem(HealthSystem healthSystem) {
    _healthSystem = healthSystem;
    
    // Set up health change callback
    _healthSystem!.onHealthChanged = (double newHealth) {
      _updateHealthDisplay(newHealth);
    };
    
    // Set up critical health callback
    _healthSystem!.onHealthCritical = () {
      _triggerCriticalFlash();
    };
    
    // Initialize with current health
    _updateHealthDisplay(_healthSystem!.currentHealth);
    
    print('❤️ HEALTH DISPLAY: Connected to health system');
  }
  
  /// Update health display values
  void _updateHealthDisplay(double newHealth) {
    _currentHealth = newHealth;
    _isCritical = _currentHealth <= HealthSystem.criticalHealthThreshold;
    
    // Update health bar color based on health level
    _updateHealthBarColor();
  }
  
  /// Update health bar color based on current health
  void _updateHealthBarColor() {
    final healthPercentage = _currentHealth / _maxHealth;
    
    Color healthColor;
    if (healthPercentage > 0.75) {
      // High health - green
      healthColor = Colors.green.withValues(alpha: 0.7);
    } else if (healthPercentage > 0.5) {
      // Medium health - yellow
      healthColor = Colors.yellow.withValues(alpha: 0.7);
    } else if (healthPercentage > 0.25) {
      // Low health - orange
      healthColor = Colors.orange.withValues(alpha: 0.7);
    } else {
      // Critical health - red
      healthColor = Colors.red.withValues(alpha: 0.8);
    }
    
    _healthBarFill.color = healthColor;
  }
  
  /// Trigger critical health flash animation
  void _triggerCriticalFlash() {
    _criticalFlashTimer = 2.0; // Flash for 2 seconds
    _showCriticalFlash = true;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update critical health flash animation
    if (_criticalFlashTimer > 0) {
      _criticalFlashTimer -= dt;
      _showCriticalFlash = (_criticalFlashTimer % 0.5) > 0.25; // Flash every 0.5 seconds
      
      if (_criticalFlashTimer <= 0) {
        _showCriticalFlash = false;
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Only render if health display is enabled and visible
    if (!_settings.healthDisplayVisible || _settings.minimalHUDMode) {
      return;
    }
    
    // Render based on display mode
    _renderHealthBar(canvas);
    _renderHealthText(canvas);
    
    // Render critical health warning if active
    if (_isCritical && _showCriticalFlash) {
      _renderCriticalWarning(canvas);
    }
  }
  
  /// Render health bar
  void _renderHealthBar(Canvas canvas) {
    final opacity = _settings.hudOpacity;
    
    // Background bar
    final backgroundRect = Rect.fromLTWH(
      _displayPosition.x,
      _displayPosition.y,
      _barSize.x,
      _barSize.y,
    );
    
    _healthBarBackground.color = _healthBarBackground.color.withValues(alpha: opacity * 0.6);
    canvas.drawRect(backgroundRect, _healthBarBackground);
    
    // Health fill bar
    final healthPercentage = _currentHealth / _maxHealth;
    final fillWidth = _barSize.x * healthPercentage;
    
    if (fillWidth > 0) {
      final fillRect = Rect.fromLTWH(
        _displayPosition.x,
        _displayPosition.y,
        fillWidth,
        _barSize.y,
      );
      
      _healthBarFill.color = _healthBarFill.color.withValues(alpha: opacity);
      canvas.drawRect(fillRect, _healthBarFill);
    }
    
    // Border (very subtle)
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawRect(backgroundRect, borderPaint);
  }
  
  /// Render health text
  void _renderHealthText(Canvas canvas) {
    final healthValue = _currentHealth.toInt();
    final maxHealthValue = _maxHealth.toInt();
    final healthText = '$healthValue/$maxHealthValue';
    
    final textPosition = Vector2(
      _displayPosition.x + _barSize.x + 10,
      _displayPosition.y - 2,
    );
    
    if (_isCritical) {
      _criticalTextPaint.render(canvas, healthText, textPosition);
    } else {
      _healthTextPaint.render(canvas, healthText, textPosition);
    }
  }
  
  /// Render critical health warning
  void _renderCriticalWarning(Canvas canvas) {
    // Critical health border around the health bar
    final warningRect = Rect.fromLTWH(
      _displayPosition.x - 2,
      _displayPosition.y - 2,
      _barSize.x + 4,
      _barSize.y + 4,
    );
    
    canvas.drawRect(warningRect, _criticalHealthPaint);
    
    // Critical health text warning
    const warningText = 'CRITICAL!';
    final warningPosition = Vector2(
      _displayPosition.x,
      _displayPosition.y - 20,
    );
    
    _criticalTextPaint.render(canvas, warningText, warningPosition);
  }
  
  /// Update display position (for responsive layout)
  void updatePosition({required Vector2 gameSize}) {
    // Position in top-left corner with padding
    _displayPosition = Vector2(20, 20);
    
    // Adjust for screen size if needed
    if (gameSize.x < 400) {
      _barSize = Vector2(100, 6); // Smaller bar for small screens
    } else {
      _barSize = Vector2(150, 8); // Standard bar size
    }
  }
  
  /// Refresh display (for settings changes)
  void refresh() {
    _updateHealthBarColor();
    print('❤️ HEALTH DISPLAY: Refreshed display settings');
  }
  
  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'currentHealth': _currentHealth,
      'maxHealth': _maxHealth,
      'healthPercentage': _currentHealth / _maxHealth,
      'isCritical': _isCritical,
      'displayVisible': _settings.healthDisplayVisible,
      'minimalMode': _settings.minimalHUDMode,
      'hudOpacity': _settings.hudOpacity,
      'hasHealthSystem': _healthSystem != null,
      'criticalFlashActive': _showCriticalFlash,
      'criticalFlashTimer': _criticalFlashTimer,
    };
  }
  
  /// Force show health display for testing
  void showTestDisplay() {
    _currentHealth = 25.0; // Critical health for testing
    _isCritical = true;
    _triggerCriticalFlash();
    print('❤️ HEALTH DISPLAY: Showing test critical health display');
  }
  
  /// Simulate health change for testing
  void simulateHealthChange(double newHealth) {
    _updateHealthDisplay(newHealth);
    
    if (newHealth <= HealthSystem.criticalHealthThreshold) {
      _triggerCriticalFlash();
    }
    
    print('❤️ HEALTH DISPLAY: Simulated health change to ${newHealth.toInt()}');
  }
}