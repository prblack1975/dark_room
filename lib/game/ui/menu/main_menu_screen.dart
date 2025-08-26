import 'package:flutter/material.dart';
import '../../systems/level_progress_manager.dart';
import 'level_selection_card.dart';

class MainMenuScreen extends StatefulWidget {
  final Function(String levelId) onLevelSelected;

  const MainMenuScreen({
    super.key,
    required this.onLevelSelected,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final LevelProgressManager _progressManager = LevelProgressManager();
  Map<String, dynamic> _levelData = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLevelData();
  }

  Future<void> _loadLevelData() async {
    try {
      final data = await _progressManager.getAllLevelData();
      setState(() {
        _levelData = data;
        _loading = false;
      });
      print('📋 MENU: Loaded level data for ${data.keys.length} levels');
    } catch (e) {
      print('❌ MENU: Error loading level data: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _resetProgress() async {
    final confirmed = await _showResetConfirmationDialog();
    if (confirmed) {
      await _progressManager.resetProgress();
      await _loadLevelData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress has been reset'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<bool> _showResetConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Reset Progress',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to reset all level progress? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _onLevelCardTapped(String levelId, Map<String, dynamic> levelInfo) {
    if (levelInfo['unlocked'] as bool) {
      print('🎯 MENU: Selected level: $levelId');
      widget.onLevelSelected(levelId);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Complete "${_getPreviousLevelName(levelId)}" to unlock this level'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getPreviousLevelName(String levelId) {
    final levelIds = _progressManager.levelIds;
    final index = levelIds.indexOf(levelId);
    if (index > 0) {
      final previousId = levelIds[index - 1];
      return _progressManager.getLevelName(previousId);
    }
    return 'previous level';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Dark Room',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            color: Colors.grey[800],
            onSelected: (value) {
              switch (value) {
                case 'reset':
                  _resetProgress();
                  break;
                case 'debug':
                  _progressManager.printDebugInfo();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Reset Progress', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'debug',
                child: Row(
                  children: [
                    Icon(Icons.bug_report, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text('Debug Info', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white54,
              ),
            )
          : _buildLevelSelection(),
    );
  }

  Widget _buildLevelSelection() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Your Challenge',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Navigate through audio-only environments and escape increasingly complex rooms.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ..._progressManager.levelIds.map((levelId) {
              final levelInfo = _levelData[levelId] as Map<String, dynamic>?;
              if (levelInfo == null) return const SizedBox.shrink();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: LevelSelectionCard(
                  levelId: levelId,
                  levelInfo: levelInfo,
                  onTap: () => _onLevelCardTapped(levelId, levelInfo),
                ),
              );
            }),
            const SizedBox(height: 32),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.headphones,
                      color: Colors.white70,
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Best experienced with headphones',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}