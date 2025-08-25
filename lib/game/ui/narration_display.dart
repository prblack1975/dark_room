import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../systems/narration_system.dart';
import 'settings_config.dart';

/// Text display component for current narration
/// 
/// Features:
/// - Shows current narration text
/// - Auto-fades when narration ends
/// - Configurable visibility and styling
/// - Positioned at bottom of screen
/// - Follows minimal HUD aesthetic
class NarrationDisplay extends Component {
  late NarrationSystem _narrationSystem;
  late SettingsConfig _settings;
  late TextPaint _textPaint;
  
  String _currentText = '';
  double _textOpacity = 0.0;
  bool _isShowing = false;
  
  // Animation properties
  double _fadeSpeed = 2.0; // Opacity units per second
  double _maxDisplayTime = 8.0; // Maximum time to show text in seconds
  double _displayTimer = 0.0;
  
  // Position and layout
  late Vector2 _position;
  final double _maxWidth = 600.0;
  final double _padding = 20.0;
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    _settings = SettingsConfig();
    _position = Vector2(_padding, 500); // Fixed position for now
    _initializeTextPaint();
    print('🗣️ NARRATION DISPLAY: Initialized');
  }
  
  void _initializeTextPaint() {
    final textColor = Color.fromARGB(
      (255 * _textOpacity * _settings.hudOpacity).round(),
      160, 160, 160, // Lighter grey for readability
    );
    
    _textPaint = TextPaint(
      style: TextStyle(
        color: textColor,
        fontSize: _settings.narrationFontSize,
        fontFamily: 'sans-serif',
        fontWeight: FontWeight.w400,
      ),
    );
  }
  
  /// Set the narration system to monitor
  void setNarrationSystem(NarrationSystem narrationSystem) {
    _narrationSystem = narrationSystem;
    
    // Set up callbacks for narration events
    _narrationSystem.onNarrationStart = _onNarrationStart;
    _narrationSystem.onNarrationEnd = _onNarrationEnd;
    
    print('🗣️ NARRATION DISPLAY: Connected to narration system');
  }
  
  void _onNarrationStart(String text) {
    if (!_settings.narrationTextVisible || !_settings.narrationEnabled) return;
    
    _currentText = text;
    _isShowing = true;
    _displayTimer = 0.0;
    _textOpacity = 1.0;
    _initializeTextPaint();
    
    print('🗣️ NARRATION DISPLAY: Showing text: "$text"');
  }
  
  void _onNarrationEnd() {
    _isShowing = false;
    // Text will fade out gradually
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (_isShowing) {
      _displayTimer += dt;
      
      // Start fading if we've exceeded max display time
      if (_displayTimer > _maxDisplayTime) {
        _isShowing = false;
      }
    }
    
    // Handle opacity animation
    if (_isShowing) {
      // Fade in
      _textOpacity = (_textOpacity + _fadeSpeed * dt).clamp(0.0, 1.0);
    } else {
      // Fade out
      _textOpacity = (_textOpacity - _fadeSpeed * dt).clamp(0.0, 1.0);
      
      // Clear text when fully faded
      if (_textOpacity <= 0.0) {
        _currentText = '';
      }
    }
    
    // Update text paint with new opacity
    if (_textOpacity > 0.0) {
      _initializeTextPaint();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Don't render if disabled or no text
    if (!_settings.narrationTextVisible || _currentText.isEmpty || _textOpacity <= 0.0) {
      return;
    }
    
    // Render text with word wrapping
    _renderWrappedText(canvas, _currentText, _position);
  }
  
  void _renderWrappedText(Canvas canvas, String text, Vector2 position) {
    final words = text.split(' ');
    final lines = <String>[];
    String currentLine = '';
    
    // Simple word wrapping
    for (final word in words) {
      final testLine = currentLine.isEmpty ? word : '$currentLine $word';
      final testWidth = _measureTextWidth(testLine);
      
      if (testWidth <= _maxWidth) {
        currentLine = testLine;
      } else {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine);
          currentLine = word;
        } else {
          // Word is too long, add it anyway
          lines.add(word);
        }
      }
    }
    
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    
    // Render each line
    for (int i = 0; i < lines.length; i++) {
      final linePosition = Vector2(
        position.x,
        position.y - (lines.length - 1 - i) * (_settings.narrationFontSize + 4),
      );
      
      _textPaint.render(canvas, lines[i], linePosition);
    }
  }
  
  double _measureTextWidth(String text) {
    // Approximate text width calculation
    // This is a simplified version - in production you'd use proper text measurement
    return text.length * (_settings.narrationFontSize * 0.6);
  }
  
  /// Update position based on game size
  void updatePosition({Vector2? gameSize}) {
    if (gameSize != null) {
      _position = Vector2(_padding, gameSize.y - 100);
    } else {
      // Default position for bottom of screen
      _position = Vector2(_padding, 500);
    }
  }
  
  /// Force show specific text (for debugging)
  void showText(String text, {double duration = 5.0}) {
    _currentText = text;
    _isShowing = true;
    _displayTimer = 0.0;
    _textOpacity = 1.0;
    _maxDisplayTime = duration;
    _initializeTextPaint();
  }
  
  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'visible': _settings.narrationTextVisible,
      'currentText': _currentText,
      'isShowing': _isShowing,
      'textOpacity': _textOpacity,
      'displayTimer': _displayTimer,
      'position': {'x': _position.x, 'y': _position.y},
      'hasNarrationSystem': _narrationSystem != null,
    };
  }
}