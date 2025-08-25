import 'package:shared_preferences/shared_preferences.dart';

class LevelProgressManager {
  static final LevelProgressManager _instance = LevelProgressManager._internal();
  factory LevelProgressManager() => _instance;
  LevelProgressManager._internal();

  static const String _completedLevelsKey = 'completed_levels';
  static const String _levelStatsPrefix = 'level_stats_';
  
  final List<String> _levelIds = [
    'tutorial',
    'escape_room', 
    'laboratory',
    'basement',
    'office_complex'
  ];

  final Map<String, String> _levelNames = {
    'tutorial': 'Tutorial: First Steps',
    'escape_room': 'Simple Escape: The Antechamber',
    'laboratory': 'Laboratory: Chemical Analysis Wing', 
    'basement': 'Basement: Industrial Underground',
    'office_complex': 'Office Complex: Corporate Tower'
  };

  final Map<String, String> _levelDescriptions = {
    'tutorial': 'Learn audio navigation basics with simple challenges',
    'escape_room': 'Single room escape with strategic audio landmarks',
    'laboratory': 'Multi-room facility with scientific equipment sounds',
    'basement': 'Complex maze with water systems and dead ends',
    'office_complex': 'Sprawling multi-department facility - ultimate challenge'
  };

  final Map<String, String> _levelDifficulties = {
    'tutorial': 'BEGINNER',
    'escape_room': 'EASY',
    'laboratory': 'INTERMEDIATE',
    'basement': 'ADVANCED',
    'office_complex': 'MASTER'
  };

  List<String> get levelIds => List.unmodifiable(_levelIds);
  
  String getLevelName(String levelId) => _levelNames[levelId] ?? 'Unknown Level';
  String getLevelDescription(String levelId) => _levelDescriptions[levelId] ?? '';
  String getLevelDifficulty(String levelId) => _levelDifficulties[levelId] ?? 'UNKNOWN';

  Future<void> markLevelCompleted(String levelId, {
    Duration? completionTime,
    int? attempts,
    double? healthRemaining
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    List<String> completedLevels = prefs.getStringList(_completedLevelsKey) ?? [];
    
    if (!completedLevels.contains(levelId)) {
      completedLevels.add(levelId);
      await prefs.setStringList(_completedLevelsKey, completedLevels);
      print('🏆 PROGRESS: Level "$levelId" marked as completed');
    }
    
    if (completionTime != null || attempts != null || healthRemaining != null) {
      await _saveLevelStats(levelId, completionTime, attempts, healthRemaining);
    }
  }

  Future<bool> isLevelCompleted(String levelId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> completedLevels = prefs.getStringList(_completedLevelsKey) ?? [];
    return completedLevels.contains(levelId);
  }

  Future<bool> isLevelUnlocked(String levelId) async {
    if (levelId == 'tutorial') {
      return true;
    }
    
    int levelIndex = _levelIds.indexOf(levelId);
    if (levelIndex <= 0) return false;
    
    String previousLevelId = _levelIds[levelIndex - 1];
    return await isLevelCompleted(previousLevelId);
  }

  Future<List<String>> getCompletedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_completedLevelsKey) ?? [];
  }

  Future<Map<String, dynamic>> getLevelStats(String levelId) async {
    final prefs = await SharedPreferences.getInstance();
    final statsKey = '$_levelStatsPrefix$levelId';
    final statsJson = prefs.getString(statsKey);
    
    if (statsJson != null) {
      return {
        'completed': true,
        'completionTime': prefs.getInt('${statsKey}_time') ?? 0,
        'attempts': prefs.getInt('${statsKey}_attempts') ?? 1,
        'healthRemaining': prefs.getDouble('${statsKey}_health') ?? 100.0,
        'firstCompletedAt': prefs.getString('${statsKey}_first_completion') ?? DateTime.now().toIso8601String()
      };
    }
    
    return {
      'completed': false,
      'completionTime': null,
      'attempts': null,
      'healthRemaining': null,
      'firstCompletedAt': null
    };
  }

  Future<void> _saveLevelStats(String levelId, Duration? completionTime, int? attempts, double? healthRemaining) async {
    final prefs = await SharedPreferences.getInstance();
    final statsKey = '$_levelStatsPrefix$levelId';
    
    final existingStats = await getLevelStats(levelId);
    final isFirstCompletion = !existingStats['completed'];
    
    if (completionTime != null) {
      await prefs.setInt('${statsKey}_time', completionTime.inSeconds);
    }
    
    if (attempts != null) {
      await prefs.setInt('${statsKey}_attempts', attempts);
    }
    
    if (healthRemaining != null) {
      await prefs.setDouble('${statsKey}_health', healthRemaining);
    }
    
    if (isFirstCompletion) {
      await prefs.setString('${statsKey}_first_completion', DateTime.now().toIso8601String());
    }
    
    print('📊 PROGRESS: Saved stats for level "$levelId" - Time: ${completionTime?.inSeconds}s, Attempts: $attempts, Health: $healthRemaining%');
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedLevelsKey);
    
    for (String levelId in _levelIds) {
      final statsKey = '$_levelStatsPrefix$levelId';
      await prefs.remove('${statsKey}_time');
      await prefs.remove('${statsKey}_attempts');
      await prefs.remove('${statsKey}_health');
      await prefs.remove('${statsKey}_first_completion');
    }
    
    print('🔄 PROGRESS: All progress data has been reset');
  }

  Future<Map<String, dynamic>> getAllLevelData() async {
    Map<String, dynamic> allData = {};
    
    for (String levelId in _levelIds) {
      allData[levelId] = {
        'id': levelId,
        'name': getLevelName(levelId),
        'description': getLevelDescription(levelId),
        'difficulty': getLevelDifficulty(levelId),
        'completed': await isLevelCompleted(levelId),
        'unlocked': await isLevelUnlocked(levelId),
        'stats': await getLevelStats(levelId)
      };
    }
    
    return allData;
  }

  void printDebugInfo() async {
    print('🐛 PROGRESS DEBUG: Current progress state:');
    final completedLevels = await getCompletedLevels();
    print('   Completed levels: $completedLevels');
    
    for (String levelId in _levelIds) {
      final unlocked = await isLevelUnlocked(levelId);
      final completed = await isLevelCompleted(levelId);
      print('   $levelId: unlocked=$unlocked, completed=$completed');
    }
  }
}