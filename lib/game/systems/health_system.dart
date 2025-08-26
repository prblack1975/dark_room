import 'package:flame/components.dart';
import '../audio/asset_audio_player.dart';
import '../utils/game_logger.dart';
import 'narration_system.dart';

/// Manages player health for the Dark Room game
/// 
/// Features:
/// - Health tracking (0-100 scale)
/// - Damage and healing mechanics
/// - Audio feedback for health changes
/// - Integration with narration system
/// - Preparation for future NPC damage types
/// - No automatic regeneration (healing only through artifacts)
class HealthSystem extends Component {
  static const double maxHealth = 100.0;
  static const double criticalHealthThreshold = 25.0;
  static const double lowHealthThreshold = 50.0;
  
  double _currentHealth = maxHealth;
  double _lastCriticalWarningTime = 0.0;
  static const double criticalWarningCooldown = 10.0; // 10 seconds between warnings
  
  late AssetAudioPlayer _audioPlayer;
  late final GameCategoryLogger _logger;
  
  // Reference to narration system
  NarrationSystem? _narrationSystem;
  
  // Health change callbacks for UI updates
  Function(double)? onHealthChanged;
  Function()? onHealthCritical;
  Function()? onPlayerDeath;
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    gameLogger.initialize();
    _logger = gameLogger.health;
    _audioPlayer = AssetAudioPlayer();
    _logger.info('❤️ HEALTH: System initialized with ${_currentHealth.toInt()}/100 health');
  }
  
  /// Set reference to narration system
  void setNarrationSystem(NarrationSystem narrationSystem) {
    _narrationSystem = narrationSystem;
  }
  
  /// Get current health value
  double get currentHealth => _currentHealth;
  
  /// Get current health as percentage (0.0 to 1.0)
  double get healthPercentage => _currentHealth / maxHealth;
  
  /// Check if health is at critical level
  bool get isCritical => _currentHealth <= criticalHealthThreshold;
  
  /// Check if health is low
  bool get isLow => _currentHealth <= lowHealthThreshold;
  
  /// Check if player is alive
  bool get isAlive => _currentHealth > 0;
  
  /// Take damage (for future NPC implementation)
  void takeDamage(double amount, {String? damageType, String? source}) {
    if (!isAlive || amount <= 0) return;
    
    final previousHealth = _currentHealth;
    _currentHealth = (_currentHealth - amount).clamp(0.0, maxHealth);
    
    _logger.info('❤️ HEALTH: Took ${amount.toInt()} damage${source != null ? ' from $source' : ''} (${_currentHealth.toInt()}/100)');
    
    // Audio feedback for damage
    _playDamageSound(amount);
    
    // Narration for damage
    _narrateDamage(amount, damageType, source);
    
    // Check for critical health
    if (isCritical && previousHealth > criticalHealthThreshold) {
      _triggerCriticalHealthWarning();
    }
    
    // Check for death
    if (!isAlive) {
      _triggerPlayerDeath();
    }
    
    // Notify UI
    onHealthChanged?.call(_currentHealth);
    if (isCritical) {
      onHealthCritical?.call();
    }
  }
  
  /// Restore health (from health artifacts)
  void restoreHealth(double amount, {String? source}) {
    if (!isAlive || amount <= 0) return;
    
    final previousHealth = _currentHealth;
    _currentHealth = (_currentHealth + amount).clamp(0.0, maxHealth);
    
    final actualHealing = _currentHealth - previousHealth;
    
    _logger.info('❤️ HEALTH: Restored ${actualHealing.toInt()} health${source != null ? ' from $source' : ''} (${_currentHealth.toInt()}/100)');
    
    // Audio feedback for healing
    _playHealingSound(actualHealing);
    
    // Narration for healing
    _narrateHealing(actualHealing, source);
    
    // Notify UI
    onHealthChanged?.call(_currentHealth);
  }
  
  /// Set health to specific value (for debugging)
  void setHealth(double health) {
    final previousHealth = _currentHealth;
    _currentHealth = health.clamp(0.0, maxHealth);
    
    _logger.info('❤️ HEALTH: Set to ${_currentHealth.toInt()}/100 (debug)');
    
    // Check state changes
    if (isCritical && previousHealth > criticalHealthThreshold) {
      _triggerCriticalHealthWarning();
    }
    
    if (!isAlive && previousHealth > 0) {
      _triggerPlayerDeath();
    }
    
    // Notify UI
    onHealthChanged?.call(_currentHealth);
    if (isCritical) {
      onHealthCritical?.call();
    }
  }
  
  /// Reset health to maximum (for new levels)
  void resetHealth() {
    _currentHealth = maxHealth;
    _lastCriticalWarningTime = 0.0;
    _logger.info('❤️ HEALTH: Reset to full health for new level');
    onHealthChanged?.call(_currentHealth);
  }
  
  /// Play damage sound based on amount
  void _playDamageSound(double amount) {
    if (amount >= 30) {
      // Major damage
      _audioPlayer.playDamageSound(volume: 0.7);
    } else if (amount >= 15) {
      // Moderate damage
      _audioPlayer.playDamageSound(volume: 0.5);
    } else {
      // Minor damage
      _audioPlayer.playDamageSound(volume: 0.3);
    }
  }
  
  /// Play healing sound based on amount
  void _playHealingSound(double amount) {
    if (amount >= 50) {
      // Major healing
      _audioPlayer.playHealingSound(volume: 0.8);
    } else if (amount >= 25) {
      // Moderate healing
      _audioPlayer.playHealingSound(volume: 0.6);
    } else {
      // Minor healing
      _audioPlayer.playHealingSound(volume: 0.4);
    }
  }
  
  /// Narrate damage taken
  void _narrateDamage(double amount, String? damageType, String? source) {
    if (_narrationSystem == null) return;
    
    String narrationText;
    if (isCritical) {
      narrationText = 'Critical damage sustained! Your health is dangerously low.';
    } else if (amount >= 30) {
      narrationText = 'Severe damage taken. You feel significantly weakened.';
    } else if (amount >= 15) {
      narrationText = 'Moderate damage sustained. You wince from the impact.';
    } else {
      narrationText = 'Minor damage taken. You feel a slight sting.';
    }
    
    // Add source context if available
    if (source != null) {
      narrationText += ' The damage came from $source.';
    }
    
    _narrationSystem!.narrate(narrationText, priority: isCritical ? NarrationPriority.urgent : NarrationPriority.important);
  }
  
  /// Narrate health restoration
  void _narrateHealing(double amount, String? source) {
    if (_narrationSystem == null) return;
    
    String narrationText;
    if (amount >= 50) {
      narrationText = 'Major healing! You feel significantly restored and energized.';
    } else if (amount >= 25) {
      narrationText = 'Moderate healing applied. Your strength is returning.';
    } else {
      narrationText = 'Minor healing received. You feel slightly better.';
    }
    
    // Add source context if available
    if (source != null) {
      narrationText += ' The healing came from $source.';
    }
    
    _narrationSystem!.narrate(narrationText, priority: NarrationPriority.important);
  }
  
  /// Trigger critical health warning
  void _triggerCriticalHealthWarning() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    // Rate limit critical warnings
    if (currentTime - _lastCriticalWarningTime < criticalWarningCooldown) {
      return;
    }
    
    _lastCriticalWarningTime = currentTime;
    
    // Play critical health sound
    _audioPlayer.playCriticalHealthSound();
    
    // Critical health narration
    if (_narrationSystem != null) {
      _narrationSystem!.narrate(
        'Warning: Critical health level! Find medical supplies immediately or risk collapse.',
        priority: NarrationPriority.urgent,
      );
    }
    
    _logger.warning('HEALTH: Critical health warning triggered');
  }
  
  /// Trigger player death
  void _triggerPlayerDeath() {
    // Play death sound
    _audioPlayer.playDeathSound();
    
    // Death narration
    if (_narrationSystem != null) {
      _narrationSystem!.narrate(
        'Your health has reached zero. The darkness claims you. Game over.',
        priority: NarrationPriority.urgent,
      );
    }
    
    // Notify game of death
    onPlayerDeath?.call();
    
    _logger.info('💀 HEALTH: Player death triggered');
  }
  
  /// Handle health artifact pickup
  void processHealthArtifact(String artifactName, double healingAmount, String description) {
    _logger.healthPickup('Processing health artifact "$artifactName" (+${healingAmount.toInt()} health)');
    
    // Play pickup sound
    _audioPlayer.playPickupSound();
    
    // Restore health
    restoreHealth(healingAmount, source: artifactName);
    
    // Enhanced narration for health artifacts
    if (_narrationSystem != null) {
      _narrationSystem!.narrateItemPickup(artifactName, description);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Check for periodic critical health warnings
    if (isCritical && isAlive) {
      final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      if (currentTime - _lastCriticalWarningTime >= criticalWarningCooldown) {
        _triggerCriticalHealthWarning();
      }
    }
  }
  
  /// Get health status description for narration
  String getHealthStatus() {
    if (!isAlive) {
      return 'unconscious';
    } else if (isCritical) {
      return 'critically injured';
    } else if (isLow) {
      return 'wounded';
    } else if (_currentHealth >= 75) {
      return 'healthy';
    } else {
      return 'slightly injured';
    }
  }
  
  /// Get detailed health information for narration
  String getDetailedHealthStatus() {
    final status = getHealthStatus();
    final percentage = (healthPercentage * 100).toInt();
    return 'You are currently $status with $percentage percent of your health remaining.';
  }
  
  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'currentHealth': _currentHealth,
      'healthPercentage': healthPercentage,
      'maxHealth': maxHealth,
      'isAlive': isAlive,
      'isCritical': isCritical,
      'isLow': isLow,
      'status': getHealthStatus(),
      'hasNarrationSystem': _narrationSystem != null,
      'lastCriticalWarning': _lastCriticalWarningTime,
    };
  }
}