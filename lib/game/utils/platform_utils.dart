import 'dart:io';
import 'package:flutter/foundation.dart';
import 'game_logger.dart';

/// Utility class for platform detection and mobile-specific adaptations
class PlatformUtils {
  
  // Logger instance for this class
  static final GameCategoryLogger _logger = (() {
    gameLogger.initialize();
    return gameLogger.platform;
  })();
  
  /// Returns true if running on a mobile or tablet device
  static bool get isMobileOrTablet {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }
  
  /// Returns true if running on Android
  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }
  
  /// Returns true if running on iOS
  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }
  
  /// Manual override for Fire OS detection (for testing)
  static bool? _fireOSOverride;
  
  /// Set manual Fire OS detection override for testing
  static void setFireOSOverride(bool? override) {
    _fireOSOverride = override;
    _logger.fireOS('Manual override set to $override');
  }
  
  /// Enable Fire OS testing mode (for debugging on non-Fire devices)
  static void enableFireOSTestingMode() {
    setFireOSOverride(true);
    _logger.fireOS('Testing mode enabled - all Fire OS specific code will activate');
    _logger.fireOS('This forces Fire tablet compatibility mode');
  }
  
  /// Disable Fire OS testing mode
  static void disableFireOSTestingMode() {
    setFireOSOverride(null);
    _logger.fireOS('Testing mode disabled - using automatic detection');
  }
  
  /// Returns true if running on Amazon Fire OS (detected via multiple methods)
  static bool get isFireOS {
    if (kIsWeb || !Platform.isAndroid) return false;
    
    // Check manual override first (for testing)
    if (_fireOSOverride != null) {
      _logger.fireOS('Using manual override: $_fireOSOverride');
      return _fireOSOverride!;
    }
    
    // Method 1: Check environment variables (might work on some devices)
    try {
      final environment = Platform.environment;
      final deviceModel = environment['ro.product.model']?.toLowerCase() ?? '';
      final deviceManufacturer = environment['ro.product.manufacturer']?.toLowerCase() ?? '';
      
      if (deviceModel.contains('fire') || 
          deviceModel.contains('kindle') ||
          deviceManufacturer.contains('amazon') ||
          deviceModel.contains('kf')) {
        _logger.fireOS('Detected via environment variables');
        return true;
      }
    } catch (e) {
      _logger.fireOS('Environment detection failed: $e');
    }
    
    // Method 2: Check for Fire OS specific characteristics
    try {
      // Fire tablets often have specific package managers or system apps
      final environment = Platform.environment;
      final user = environment['USER']?.toLowerCase() ?? '';
      final path = environment['PATH']?.toLowerCase() ?? '';
      
      // Fire OS might have amazon-specific paths or users
      if (path.contains('amazon') || user.contains('amazon')) {
        _logger.fireOS('Detected via system characteristics');
        return true;
      }
    } catch (e) {
      _logger.fireOS('System characteristics check failed: $e');
    }
    
    // Method 3: Fallback - assume Fire OS if we're on Android and have audio issues
    // This is a heuristic and will be refined based on actual testing
    _logger.fireOS('No definitive detection - assuming standard Android');
    return false;
  }
  
  /// Check if we should force Fire OS mode based on runtime detection
  static bool get shouldUseFireOSMode {
    return isFireOS || _shouldForceFireOSMode();
  }
  
  /// Internal method to detect if we should force Fire OS mode based on runtime issues
  static bool _shouldForceFireOSMode() {
    // This will be used later to detect audio issues at runtime
    // and automatically switch to Fire OS mode even on non-Fire devices
    // that have similar audio limitations
    return false; // For now, only use explicit Fire OS detection
  }
  
  /// Returns true if running on desktop (Windows, macOS, Linux)
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
  
  /// Returns true if touch controls should be shown
  static bool get shouldShowTouchControls => isMobileOrTablet;
  
  /// Returns true if keyboard controls are preferred
  static bool get preferKeyboardControls => isDesktop || kIsWeb;
  
  /// Returns true if platform has known audio limitations
  static bool get hasAudioLimitations => shouldUseFireOSMode;
  
  /// Returns true if platform needs audio fallback mechanisms
  static bool get needsAudioFallback => shouldUseFireOSMode;
  
  /// Get recommended concurrent audio player limit for platform
  static int get maxConcurrentAudioPlayers {
    if (shouldUseFireOSMode) return 3; // Conservative limit for Fire tablets
    if (isMobileOrTablet) return 5; // Standard mobile limit
    return 10; // Desktop can handle more
  }
  
  /// Get platform name for debugging
  static String get platformName {
    if (kIsWeb) return 'Web';
    if (shouldUseFireOSMode) return 'Fire OS Mode';
    if (isFireOS) return 'Fire OS (detected)';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
  
  /// Get detailed platform info for audio debugging
  static String get detailedPlatformInfo {
    final buffer = StringBuffer();
    buffer.write('Platform: $platformName');
    
    if (!kIsWeb && Platform.isAndroid) {
      buffer.write('\nFire OS Detected: $isFireOS');
      buffer.write('\nFire OS Mode: $shouldUseFireOSMode');
      buffer.write('\nManual Override: $_fireOSOverride');
      buffer.write('\nAudio Limitations: $hasAudioLimitations');
      buffer.write('\nMax Audio Players: $maxConcurrentAudioPlayers');
    }
    
    return buffer.toString();
  }
}