import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../utils/platform_utils.dart';
import '../utils/game_logger.dart';

class AssetAudioPlayer {
  static AssetAudioPlayer? _testInstance;
  static final AssetAudioPlayer _instance = AssetAudioPlayer._internal();
  
  factory AssetAudioPlayer() => _testInstance ?? _instance;
  AssetAudioPlayer._internal() {
    gameLogger.initialize();
    _logger = gameLogger.audio;
  }
  
  /// Set a test instance (used during testing to inject mocks)
  static void setTestInstance(AssetAudioPlayer? testInstance) {
    _testInstance = testInstance;
  }
  
  /// Check if running in test mode
  bool get isTestMode => _testInstance != null;

  final Map<String, AudioPlayer> _players = {};
  final List<AudioPlayer> _collisionPlayers = []; // Multiple collision sound players
  final Map<String, AudioPlayer> _continuousPlayers = {}; // Continuous looping sounds
  final Map<String, List<AudioPlayer>> _continuousPlayerPool = {}; // Pre-initialized pool for continuous sounds
  int _currentCollisionPlayer = 0;
  bool _isInitialized = false;
  
  // Logger instance for this class
  late final GameCategoryLogger _logger;
  
  // Track which continuous sounds are commonly used for pre-initialization
  static const List<String> _commonContinuousSounds = [
    'click.mp3',
    'wall_hit.mp3',
    'pickup.mp3',
    'wall-hit-1-100717.mp3',
    'wall-hit-cartoon.mp3',
    'key-get-39925.mp3',
  ];

  Future<void> _initializePlayer(String soundName, String assetPath) async {
    if (_players.containsKey(soundName)) return;
    
    // In test mode, just register the sound without loading
    if (isTestMode) {
      _logger.test('Registered audio $soundName (test mode)');
      return;
    }
    
    try {
      final player = AudioPlayer();
      // Preload the asset
      await player.setSource(AssetSource(assetPath));
      _players[soundName] = player;
      _logger.success('Loaded audio: $soundName from $assetPath');
    } catch (e) {
      _logger.error('Failed to load $soundName from $assetPath: $e');
      // Do not create backup player - this was causing clicking sounds
      // _players[soundName] = AudioPlayer();
    }
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    _logger.process('Initializing asset audio system...');
    
    // Initialize all sound players with asset paths
    await _initializePlayer('wall_hit', 'audio/interaction/wall-hit-cartoon.mp3');
    await _initializePlayer('pickup', 'audio/interaction/pickup.mp3');
    await _initializePlayer('door', 'audio/interaction/door.mp3');
    await _initializePlayer('success', 'audio/interaction/success.mp3');
    await _initializePlayer('click', 'audio/interaction/click.mp3');
    
    // Health-related sounds
    await _initializePlayer('damage', 'audio/interaction/wall-hit-cartoon.mp3'); // Reuse existing sound for damage
    await _initializePlayer('healing', 'audio/interaction/pickup.mp3'); // Reuse existing sound for healing
    await _initializePlayer('critical_health', 'audio/interaction/wall-hit-1-100717.mp3'); // Reuse for critical health warning
    await _initializePlayer('death', 'audio/interaction/wall-hit-1-100717.mp3'); // Reuse for death sound
    
    // Initialize multiple collision sound players for overlapping sounds
    for (int i = 0; i < 5; i++) {
      try {
        final player = AudioPlayer();
        await player.setSource(AssetSource('audio/interaction/wall-hit-cartoon.mp3'));
        _collisionPlayers.add(player);
        _logger.success('Loaded collision player ${i + 1}');
      } catch (e) {
        _logger.error('Failed to load collision player ${i + 1}: $e');
      }
    }
    
    // Pre-initialize continuous sound player pool for better Fire OS compatibility
    await _initializeContinuousPlayerPool();
    
    _isInitialized = true;
    _logger.success('Asset audio system ready!');
  }
  
  /// Pre-initialize continuous sound player pool for better Fire OS compatibility
  Future<void> _initializeContinuousPlayerPool() async {
    _logger.pool('Initializing continuous sound player pool...');
    
    if (isTestMode) {
      _logger.test('Skipping continuous player pool initialization in test mode');
      return;
    }
    
    final poolSize = PlatformUtils.maxConcurrentAudioPlayers.clamp(2, 4);
    _logger.pool('Creating pool of $poolSize players per sound for ${PlatformUtils.platformName}');
    
    for (final soundFile in _commonContinuousSounds) {
      final playerPool = <AudioPlayer>[];
      
      for (int i = 0; i < poolSize; i++) {
        try {
          _logger.pool('Creating player ${i + 1} for $soundFile');
          final player = AudioPlayer();
          
          // Pre-configure for continuous playback
          await player.setReleaseMode(ReleaseMode.loop);
          await player.setSource(AssetSource('audio/interaction/$soundFile'));
          await player.setVolume(0.0); // Start silent
          
          playerPool.add(player);
          _logger.pool('Successfully created player ${i + 1} for $soundFile');
          
          // Add delay between player creation on Fire OS
          if (PlatformUtils.isFireOS) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          
        } catch (e) {
          _logger.pool('Failed to create player ${i + 1} for $soundFile: $e');
          
          if (PlatformUtils.isFireOS) {
            _logger.fireOS('Player pool creation failed - this may limit audio functionality');
          }
        }
      }
      
      if (playerPool.isNotEmpty) {
        _continuousPlayerPool[soundFile] = playerPool;
        _logger.pool('Initialized ${playerPool.length} players for $soundFile');
      } else {
        _logger.pool('No players successfully created for $soundFile');
      }
    }
    
    final totalPlayers = _continuousPlayerPool.values.fold(0, (sum, pool) => sum + pool.length);
    _logger.pool('Continuous player pool ready with $totalPlayers total players');
  }

  // Continuous sound methods
  Future<void> startContinuousSound(String soundName, String assetPath) async {
    _logger.pool('Starting continuous sound $soundName on ${PlatformUtils.platformName}');
    _logger.pool('Asset path: $assetPath');
    
    try {
      await _initialize();
      _logger.pool('Audio system initialized');
      
      // Don't recreate if already playing
      if (_continuousPlayers.containsKey(soundName)) {
        _logger.pool('$soundName already playing, skipping');
        return;
      }
      
      // Extract filename from asset path for pool lookup
      final filename = assetPath.split('/').last;
      _logger.pool('Looking for pre-initialized player for $filename');
      
      // Try to use pre-initialized player pool first
      if (_continuousPlayerPool.containsKey(filename) && _continuousPlayerPool[filename]!.isNotEmpty) {
        _logger.pool('Using pre-initialized player for $filename');
        final playerPool = _continuousPlayerPool[filename]!;
        
        // Find an available player (not already in use)
        AudioPlayer? availablePlayer;
        for (final player in playerPool) {
          if (!_continuousPlayers.values.contains(player)) {
            availablePlayer = player;
            break;
          }
        }
        
        if (availablePlayer != null) {
          // Start the pre-initialized player
          await availablePlayer.resume();
          _continuousPlayers[soundName] = availablePlayer;
          _logger.pool('Successfully started pre-initialized player for $soundName');
          
          _logger.pool('Pre-initialized player started successfully');
          return;
        } else {
          _logger.warning('No available pre-initialized players for $filename, falling back to dynamic creation');
        }
      }
      
      // Fallback to dynamic player creation if pool is not available
      _logger.pool('Creating new AudioPlayer for $soundName (fallback)');
      final player = AudioPlayer();
      
      _logger.pool('Setting source to $assetPath');
      await player.setSource(AssetSource(assetPath));
      
      _logger.pool('Setting release mode to loop');
      await player.setReleaseMode(ReleaseMode.loop);
      
      _logger.pool('Setting initial volume to 0.0');
      await player.setVolume(0.0); // Start silent
      
      _logger.pool('Starting playback');
      await player.resume(); // Start playing
      
      _continuousPlayers[soundName] = player;
      _logger.success('Successfully started continuous audio playback for $soundName (fallback)');
      
      _logger.pool('Dynamic player started successfully');
      
    } catch (e) {
      _logger.error('Failed to start continuous sound $soundName: $e');
      _logger.error('Error type: ${e.runtimeType}');
      
      // Add Fire OS specific error handling
      if (PlatformUtils.isFireOS) {
        _logger.fireOS('Detected continuous audio failure on Fire tablet');
        _logger.fireOS('This is a known issue with Fire OS audio limitations');
        _logger.fireOS('Attempting fallback strategy...');
        
        try {
          // Try alternative approach for Fire OS
          await _startContinuousSoundFireOSFallback(soundName, assetPath);
        } catch (fallbackError) {
          _logger.fireOS('Fallback also failed: $fallbackError');
        }
      }
    }
  }
  
  /// Fire OS specific fallback for continuous sounds
  Future<void> _startContinuousSoundFireOSFallback(String soundName, String assetPath) async {
    _logger.fireOS('Attempting fallback continuous sound for $soundName');
    
    try {
      // Create a more conservative player setup for Fire OS
      final player = AudioPlayer();
      
      // Set player mode first
      await player.setReleaseMode(ReleaseMode.loop);
      
      // Use more conservative approach
      await player.setVolume(0.0);
      await player.setSource(AssetSource(assetPath));
      
      // Store in a separate fallback container
      if (!_continuousPlayers.containsKey(soundName)) {
        _continuousPlayers[soundName] = player;
      }
      
      // Start playing with delay for Fire OS
      await Future.delayed(const Duration(milliseconds: 100));
      await player.resume();
      
      _logger.fireOS('Fallback continuous sound started for $soundName');
    } catch (e) {
      _logger.fireOS('Fallback failed for $soundName: $e');
      rethrow;
    }
  }

  Future<void> setContinuousSoundVolume(String soundName, double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    
    try {
      final player = _continuousPlayers[soundName];
      if (player != null) {
        await player.setVolume(clampedVolume);
        
        // Only log volume changes that are significant (avoid spam)
        if (clampedVolume > 0.05) {
          _logger.pool('Set $soundName volume to ${(clampedVolume * 100).toInt()}%');
        }
        
        // Log volume setting on Fire OS
        if (PlatformUtils.isFireOS && clampedVolume > 0.1) {
          _logger.fireOS('$soundName volume set to ${(clampedVolume * 100).toInt()}%');
        }
      } else {
        _logger.warning('No player found for $soundName when setting volume');
        
        if (PlatformUtils.isFireOS) {
          _logger.fireOS('Missing player for $soundName - this indicates initialization failure');
        }
      }
    } catch (e) {
      _logger.error('Failed to set volume for $soundName: $e');
      
      if (PlatformUtils.isFireOS) {
        _logger.fireOS('Volume setting failed - known Fire tablet limitation');
        _logger.fireOS('Attempting volume retry with delay...');
        
        try {
          await Future.delayed(const Duration(milliseconds: 50));
          final player = _continuousPlayers[soundName];
          if (player != null) {
            await player.setVolume(clampedVolume);
            _logger.fireOS('Volume retry succeeded for $soundName');
          }
        } catch (retryError) {
          _logger.fireOS('Volume retry failed: $retryError');
        }
      }
    }
  }

  void stopContinuousSound(String soundName) {
    try {
      final player = _continuousPlayers[soundName];
      if (player != null) {
        player.stop();
        player.dispose();
        _continuousPlayers.remove(soundName);
        _logger.debug('Stopped continuous sound $soundName');
      }
    } catch (e) {
      _logger.error('Failed to stop continuous sound $soundName: $e');
    }
  }

  Future<void> _playSound(String soundName, {double volume = 0.5}) async {
    // In test mode, just log the sound play attempt without actual audio
    if (isTestMode) {
      _logger.test('Would play $soundName at ${(volume * 100).toInt()}% volume');
      return;
    }
    
    try {
      await _initialize();
      
      final player = _players[soundName];
      if (player != null) {
        await player.setVolume(volume);
        await player.seek(Duration.zero);
        await player.resume();
        _logger.info('Playing: $soundName at ${(volume * 100).toInt()}% volume');
      } else {
        _logger.error('Sound not found: $soundName (skipping playback)');
        return; // Exit early, don't try to play anything
      }
    } catch (e) {
      _logger.error('Audio playback error for $soundName: $e');
      return; // Exit early on any error
    }
  }

  void playCollisionSound() {
    _logger.debug('Wall hit', emoji: '🔊');
    _playCollisionSoundOverlap();
  }
  
  Future<void> _playCollisionSoundOverlap() async {
    try {
      await _initialize();
      
      if (_collisionPlayers.isEmpty) {
        // Fallback to regular method if collision players failed to load
        _playSound('wall_hit', volume: 0.4);
        return;
      }
      
      // Use next available collision player for overlapping sounds
      final player = _collisionPlayers[_currentCollisionPlayer];
      _currentCollisionPlayer = (_currentCollisionPlayer + 1) % _collisionPlayers.length;
      
      await player.setVolume(0.4);
      await player.seek(Duration.zero);
      await player.resume();
      _logger.debug('Playing collision sound on player $_currentCollisionPlayer', emoji: '🔊');
    } catch (e) {
      _logger.error('Collision sound error: $e');
    }
  }

  void playPickupSound() {
    _logger.pickup('Item collected');
    _playSound('pickup', volume: 0.3);
  }

  void playDoorOpenSound() {
    _logger.info('Door: Opening');
    _playSound('door', volume: 0.5);
  }

  void playLevelCompleteSound() {
    _logger.success('Level complete');
    _playSound('success', volume: 0.6);
  }

  void playMenuSelectSound() {
    _logger.info('UI: Menu select (DISABLED - audio loading issue)');
    // _playSound('click', volume: 0.3); // Temporarily disabled due to audio loading issues
  }

  void playDamageSound({double volume = 0.5}) {
    _logger.info('Health: Damage taken');
    _playSound('damage', volume: volume);
  }

  void playHealingSound({double volume = 0.6}) {
    _logger.info('Health: Health restored');
    _playSound('healing', volume: volume);
  }

  void playCriticalHealthSound() {
    _logger.info('Health: Critical health warning');
    _playSound('critical_health', volume: 0.8);
  }

  void playDeathSound() {
    _logger.info('Health: Player death');
    _playSound('death', volume: 0.9);
  }

  void stop() {
    for (final player in _players.values) {
      player.stop();
    }
    for (final player in _collisionPlayers) {
      player.stop();
    }
    for (final player in _continuousPlayers.values) {
      player.stop();
    }
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
    
    for (final player in _collisionPlayers) {
      player.dispose();
    }
    _collisionPlayers.clear();
    
    for (final player in _continuousPlayers.values) {
      player.dispose();
    }
    _continuousPlayers.clear();
  }
}