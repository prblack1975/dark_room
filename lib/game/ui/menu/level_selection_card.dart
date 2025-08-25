import 'package:flutter/material.dart';

class LevelSelectionCard extends StatelessWidget {
  final String levelId;
  final Map<String, dynamic> levelInfo;
  final VoidCallback onTap;

  const LevelSelectionCard({
    super.key,
    required this.levelId,
    required this.levelInfo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = levelInfo['completed'] as bool;
    final bool isUnlocked = levelInfo['unlocked'] as bool;
    final String name = levelInfo['name'] as String;
    final String description = levelInfo['description'] as String;
    final String difficulty = levelInfo['difficulty'] as String;
    final Map<String, dynamic> stats = levelInfo['stats'] as Map<String, dynamic>;

    return Card(
      elevation: 4,
      color: _getCardColor(isCompleted, isUnlocked),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getBorderColor(isCompleted, isUnlocked),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: _getTextColor(isUnlocked),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusIcon(isCompleted, isUnlocked),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildDifficultyChip(difficulty, isUnlocked),
                  if (isCompleted) ...[
                    const SizedBox(width: 8),
                    _buildCompletionTime(stats),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  color: _getTextColor(isUnlocked).withOpacity(0.8),
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
              if (!isUnlocked) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: const Text(
                    'LOCKED - Complete previous level to unlock',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (isCompleted && stats['healthRemaining'] != null) ...[
                const SizedBox(height: 8),
                _buildHealthBar(stats['healthRemaining'] as double),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getCardColor(bool isCompleted, bool isUnlocked) {
    if (!isUnlocked) return Colors.grey[850]!;
    if (isCompleted) return Colors.green.withOpacity(0.1);
    return Colors.grey[800]!;
  }

  Color _getBorderColor(bool isCompleted, bool isUnlocked) {
    if (!isUnlocked) return Colors.grey[600]!;
    if (isCompleted) return Colors.green;
    return Colors.blue.withOpacity(0.5);
  }

  Color _getTextColor(bool isUnlocked) {
    return isUnlocked ? Colors.white : Colors.grey[500]!;
  }

  Widget _buildStatusIcon(bool isCompleted, bool isUnlocked) {
    if (isCompleted) {
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 24,
      );
    } else if (isUnlocked) {
      return const Icon(
        Icons.play_circle_outline,
        color: Colors.blue,
        size: 24,
      );
    } else {
      return const Icon(
        Icons.lock,
        color: Colors.orange,
        size: 24,
      );
    }
  }

  Widget _buildDifficultyChip(String difficulty, bool isUnlocked) {
    Color chipColor;
    switch (difficulty.toUpperCase()) {
      case 'BEGINNER':
        chipColor = Colors.green;
        break;
      case 'EASY':
        chipColor = Colors.lightGreen;
        break;
      case 'INTERMEDIATE':
        chipColor = Colors.orange;
        break;
      case 'ADVANCED':
        chipColor = Colors.red;
        break;
      case 'MASTER':
        chipColor = Colors.purple;
        break;
      default:
        chipColor = Colors.grey;
    }

    if (!isUnlocked) {
      chipColor = chipColor.withOpacity(0.3);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCompletionTime(Map<String, dynamic> stats) {
    final int? timeSeconds = stats['completionTime'] as int?;
    if (timeSeconds == null) return const SizedBox.shrink();

    final duration = Duration(seconds: timeSeconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, color: Colors.blue, size: 14),
          const SizedBox(width: 4),
          Text(
            '${minutes}m ${seconds}s',
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBar(double healthRemaining) {
    final healthPercent = healthRemaining / 100.0;
    Color healthColor;
    
    if (healthPercent > 0.7) {
      healthColor = Colors.green;
    } else if (healthPercent > 0.3) {
      healthColor = Colors.orange;
    } else {
      healthColor = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite, color: Colors.red, size: 14),
            const SizedBox(width: 4),
            Text(
              'Health: ${healthRemaining.toStringAsFixed(0)}%',
              style: TextStyle(
                color: healthColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: healthPercent,
            child: Container(
              decoration: BoxDecoration(
                color: healthColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}