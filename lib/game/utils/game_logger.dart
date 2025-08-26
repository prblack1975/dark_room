import 'package:logger/logger.dart';

/// Custom logging framework for the Dark Room game
/// 
/// Preserves existing emoji-based categorization while providing
/// proper log levels, filtering, and configuration.
class GameLogger {
  static GameLogger? _testInstance;
  static final GameLogger _instance = GameLogger._internal();
  
  factory GameLogger() => _testInstance ?? _instance;
  GameLogger._internal();
  
  /// Set a test instance (used during testing to override logging behavior)
  static void setTestInstance(GameLogger? testInstance) {
    _testInstance = testInstance;
  }
  
  /// Check if running in test mode
  bool get isTestMode => _testInstance != null;
  
  Logger? _logger;
  
  /// Initialize the logger with appropriate configuration
  void initialize({Level? level}) {
    if (_logger != null) return; // Already initialized
    
    _logger = Logger(
      level: level ?? (isTestMode ? Level.off : Level.debug),
      printer: _GameLogPrinter(),
      output: isTestMode ? _TestLogOutput() : null,
    );
  }
  
  /// Reset the logger (used for testing)
  void reset() {
    _logger = null;
  }
  
  /// Get a category-specific logger
  GameCategoryLogger category(String categoryName) {
    return GameCategoryLogger(_logger, categoryName);
  }
  
  /// Get logger for specific domains
  GameCategoryLogger get audio => category('AUDIO');
  GameCategoryLogger get player => category('PLAYER');
  GameCategoryLogger get navigation => category('NAVIGATOR');
  GameCategoryLogger get platform => category('PLATFORM');
  GameCategoryLogger get inventory => category('INVENTORY');
  GameCategoryLogger get health => category('HEALTH');
  GameCategoryLogger get ui => category('UI');
  GameCategoryLogger get system => category('SYSTEM');
  GameCategoryLogger get test => category('TEST');
}

/// Category-specific logger that preserves emoji patterns
class GameCategoryLogger {
  final Logger? _logger;
  final String _category;
  
  GameCategoryLogger(this._logger, this._category);
  
  /// Test mode logging (🧪 TEST)
  void test(String message) {
    _logger?.d('🧪 TEST: $message');
  }
  
  /// Success logging (✅)
  void success(String message) {
    _logger?.i('✅ $message');
  }
  
  /// Error logging (❌)
  void error(String message) {
    _logger?.e('❌ $message');
  }
  
  /// Process/initialization logging (🔄)
  void process(String message) {
    _logger?.i('🔄 $message');
  }
  
  /// Audio pool logging (🔊 POOL)
  void pool(String message) {
    _logger?.i('🔊 POOL: $message');
  }
  
  /// Fire OS specific logging (🔥 FIRE OS)
  void fireOS(String message) {
    _logger?.i('🔥 FIRE OS: $message');
  }
  
  /// Navigation logging (🎯 NAVIGATOR, 🔙 NAVIGATOR)
  void nav(String message) {
    _logger?.d('🎯 $_category: $message');
  }
  
  void navReturn(String message) {
    _logger?.d('🔙 $_category: $message');
  }
  
  /// Debug logging (🟥 DEBUG, 🔍 DEBUG, 🎯 DEBUG)
  void debug(String message, {String? emoji}) {
    final prefix = emoji ?? '🔍';
    _logger?.d('$prefix DEBUG: $message');
  }
  
  void debugCollision(String message) {
    _logger?.d('🟥 DEBUG: $message');
  }
  
  void debugTarget(String message) {
    _logger?.d('🎯 DEBUG: $message');
  }
  
  /// Warning logging (⚠️ WARNING, ⚠️ DEBUG)
  void warning(String message) {
    _logger?.w('⚠️ WARNING: $message');
  }
  
  void debugWarning(String message) {
    _logger?.w('⚠️ DEBUG: $message');
  }
  
  /// Pickup/game event logging (🎯 PICKUP, ❤️ PICKUP)
  void pickup(String message) {
    _logger?.i('🎯 PICKUP: $message');
  }
  
  void healthPickup(String message) {
    _logger?.i('❤️ PICKUP: $message');
  }
  
  /// General info logging
  void info(String message) {
    _logger?.i(message);
  }
  
  /// General debug logging
  void log(String message) {
    _logger?.d(message);
  }
}

/// Custom printer that maintains our existing format
class _GameLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    // Simply return the message as-is, preserving emoji formatting
    return [event.message];
  }
}

/// Test mode log output that captures logs without printing
class _TestLogOutput extends LogOutput {
  static final List<String> _capturedLogs = [];
  
  @override
  void output(OutputEvent event) {
    // In test mode, capture logs instead of printing
    for (final line in event.lines) {
      _capturedLogs.add(line);
    }
  }
  
  /// Get captured logs (for testing purposes)
  // Preserved for future testing use
  // ignore: unused_element
  static List<String> _getCapturedLogs() => List.from(_capturedLogs);
  
  /// Clear captured logs (for testing purposes)
  // Preserved for future testing use
  // ignore: unused_element
  static void _clearCapturedLogs() => _capturedLogs.clear();
}

/// Global logger instance for easy access
final gameLogger = GameLogger();