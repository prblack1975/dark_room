import 'package:flame/components.dart';
import 'dart:async' as async;
import '../utils/game_logger.dart';

/// Manages text-to-speech narration for the Dark Room game
/// 
/// Features:
/// - Queued narration to prevent overlapping speech
/// - Text display for accessibility
/// - Voice narration timing management
/// - Priority system for important messages
class NarrationSystem extends Component {
  GameCategoryLogger? _logger;
  final List<NarrationItem> _narrationQueue = [];
  bool _isNarrating = false;
  String _currentNarration = '';
  async.Timer? _narrationTimer;
  
  // Callbacks for UI integration
  Function(String)? onNarrationStart;
  Function()? onNarrationEnd;
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    gameLogger.initialize();
    _logger = gameLogger.system;
    _logger?.info('🗣️ NARRATION: System initialized');
  }
  
  /// Add narration to the queue
  void narrate(String text, {NarrationPriority priority = NarrationPriority.normal}) {
    final item = NarrationItem(text: text, priority: priority);
    
    if (priority == NarrationPriority.urgent) {
      // Insert at beginning for urgent messages
      _narrationQueue.insert(0, item);
    } else {
      _narrationQueue.add(item);
    }
    
    _processQueue();
  }
  
  /// Add item pickup narration with enhanced format
  void narrateItemPickup(String itemName, String description) {
    final enhancedDescription = _enhanceItemDescription(itemName, description);
    final narrationText = 'Picked up $itemName. $enhancedDescription';
    narrate(narrationText, priority: NarrationPriority.normal);
  }
  
  /// Add atmospheric situational narration
  void narrateSituation(String situation, {NarrationPriority priority = NarrationPriority.normal}) {
    final enhancedText = _enhanceSituationalDescription(situation);
    narrate(enhancedText, priority: priority);
  }
  
  /// Add room entry narration
  void narrateRoomEntry(String roomDescription) {
    narrate('Entering: $roomDescription', priority: NarrationPriority.important);
  }
  
  /// Add proximity-based narration (for approaching objects)
  void narrateProximity(String objectName, String proximityDescription) {
    final text = 'Approaching $objectName. $proximityDescription';
    narrate(text, priority: NarrationPriority.normal);
  }
  
  /// Add door interaction narration
  void narrateDoorInteraction(String message) {
    narrate(message, priority: NarrationPriority.important);
  }
  
  /// Add level completion narration
  void narrateLevelComplete(String levelName) {
    final narrationText = 'Level complete: $levelName. Well done!';
    narrate(narrationText, priority: NarrationPriority.urgent);
  }
  
  /// Add level transition narration
  void narrateLevelTransition(String message) {
    narrate(message, priority: NarrationPriority.important);
  }
  
  /// Add system message narration
  void narrateSystemMessage(String message) {
    narrate(message, priority: NarrationPriority.normal);
  }
  
  /// Process the narration queue
  void _processQueue() {
    if (_isNarrating || _narrationQueue.isEmpty) return;
    
    final nextItem = _narrationQueue.removeAt(0);
    _startNarration(nextItem);
  }
  
  /// Start narrating a specific item
  void _startNarration(NarrationItem item) {
    _isNarrating = true;
    _currentNarration = item.text;
    
    // Notify UI components
    onNarrationStart?.call(item.text);
    
    // Calculate narration duration based on text length
    final duration = _calculateNarrationDuration(item.text);
    
    _logger?.debug('🗣️ NARRATION: "${item.text}" (${duration.inMilliseconds}ms)');
    
    // Set timer to end narration
    _narrationTimer = async.Timer(duration, _endNarration);
    
    // Future Enhancement: Integrate with actual TTS system when available
    // For now, we simulate TTS with timing
  }
  
  /// End current narration and process next in queue
  void _endNarration() {
    _isNarrating = false;
    _currentNarration = '';
    _narrationTimer?.cancel();
    _narrationTimer = null;
    
    // Notify UI components
    onNarrationEnd?.call();
    
    // Process next item in queue
    _processQueue();
  }
  
  /// Calculate narration duration based on text length and speech rate
  Duration _calculateNarrationDuration(String text) {
    // Assume average speech rate of 150 words per minute
    const wordsPerMinute = 150;
    const wordsPerSecond = wordsPerMinute / 60;
    
    final wordCount = text.split(RegExp(r'\s+')).length;
    final baseDuration = (wordCount / wordsPerSecond) * 1000; // Convert to milliseconds
    
    // Add buffer time for natural pauses
    final bufferTime = 500; // 500ms buffer
    
    return Duration(milliseconds: (baseDuration + bufferTime).round());
  }
  
  /// Stop current narration
  void stopNarration() {
    if (_isNarrating) {
      _endNarration();
    }
  }
  
  /// Clear all queued narration
  void clearQueue() {
    _narrationQueue.clear();
    stopNarration();
    _logger?.debug('🗣️ NARRATION: Queue cleared');
  }
  
  /// Get current narration status
  bool get isNarrating => _isNarrating;
  
  /// Get current narration text
  String get currentNarration => _currentNarration;
  
  /// Get number of items in queue
  int get queueLength => _narrationQueue.length;
  
  /// Enhance item descriptions with atmospheric detail
  String _enhanceItemDescription(String itemName, String baseDescription) {
    final enhancements = {
      'key': 'Its metallic surface is cool to the touch, and you can feel intricate grooves along its edges.',
      'small key': 'This delicate key feels ancient, its bronze surface worn smooth by countless hands.',
      'brass key': 'The brass gleams faintly in the darkness, heavy with purpose and possibility.',
      'iron key': 'Cold iron, unforgiving and solid. This key has opened many doors in its time.',
      'card': 'The smooth plastic surface slides between your fingers, its purpose unclear but important.',
      'note': 'Paper crinkles softly as you unfold it. The words may hold crucial information.',
      'coin': 'A small metallic disc, warm from your pocket. Perhaps it serves a purpose here.',
      'crystal': 'The crystalline structure catches what little light there is, refracting it mysteriously.',
    };
    
    // Check for exact matches first
    if (enhancements.containsKey(itemName.toLowerCase())) {
      return enhancements[itemName.toLowerCase()]!;
    }
    
    // Check for partial matches, prioritizing longer matches
    final sortedKeys = enhancements.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (final key in sortedKeys) {
      if (itemName.toLowerCase().contains(key)) {
        return enhancements[key]!;
      }
    }
    
    // Return enhanced base description or create atmospheric fallback
    if (baseDescription.isNotEmpty) {
      return '$baseDescription The darkness around you seems to acknowledge your discovery.';
    } else {
      return 'You sense this item will be important in your escape from this dark place.';
    }
  }
  
  /// Enhance situational descriptions with atmospheric detail
  String _enhanceSituationalDescription(String situation) {
    final atmosphericPhrases = [
      'The darkness presses in around you as you',
      'In the absolute blackness, you',
      'Your footsteps echo as you',
      'The silence is broken only as you',
      'Guided by sound alone, you',
    ];
    
    final randomPhrase = atmosphericPhrases[DateTime.now().millisecond % atmosphericPhrases.length];
    return '$randomPhrase ${situation.toLowerCase()}.';
  }

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'isNarrating': _isNarrating,
      'currentNarration': _currentNarration,
      'queueLength': _narrationQueue.length,
      'queueItems': _narrationQueue.map((item) => item.text).toList(),
    };
  }
  
  @override
  void onRemove() {
    _narrationTimer?.cancel();
    super.onRemove();
  }
}

/// Represents a narration item with priority
class NarrationItem {
  final String text;
  final NarrationPriority priority;
  final DateTime timestamp;
  
  NarrationItem({
    required this.text,
    this.priority = NarrationPriority.normal,
  }) : timestamp = DateTime.now();
}

/// Priority levels for narration
enum NarrationPriority {
  normal,    // Regular game narration
  important, // Door interactions, significant events
  urgent,    // Level completion, critical messages
}