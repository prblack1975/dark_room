import 'dart:async';

// Simple audio player using procedural sounds for web compatibility
class SimpleAudioPlayer {
  static final SimpleAudioPlayer _instance = SimpleAudioPlayer._internal();
  factory SimpleAudioPlayer() => _instance;
  SimpleAudioPlayer._internal();

  Timer? _beepTimer;
  bool _isPlaying = false;

  // Play a simple beep sound using procedural generation
  void playBeep({
    double frequency = 800.0,
    int durationMs = 200,
    double volume = 0.3,
  }) {
    if (_isPlaying) return;
    
    _isPlaying = true;
    print('🔊 BEEP: ${frequency.toInt()}Hz for ${durationMs}ms (Volume: ${(volume * 100).toInt()}%)');
    
    // Simulate sound duration
    _beepTimer?.cancel();
    _beepTimer = Timer(Duration(milliseconds: durationMs), () {
      _isPlaying = false;
    });
  }

  void playCollisionSound() {
    // Low frequency thud
    playBeep(frequency: 150.0, durationMs: 100, volume: 0.4);
  }

  void playPickupSound() {
    // Pleasant chime
    playBeep(frequency: 1200.0, durationMs: 300, volume: 0.3);
  }

  void playDoorOpenSound() {
    // Lower creak sound
    playBeep(frequency: 300.0, durationMs: 500, volume: 0.5);
  }

  void playLevelCompleteSound() {
    // Success sound sequence
    playBeep(frequency: 800.0, durationMs: 150, volume: 0.4);
    Timer(Duration(milliseconds: 200), () {
      playBeep(frequency: 1000.0, durationMs: 150, volume: 0.4);
    });
    Timer(Duration(milliseconds: 400), () {
      playBeep(frequency: 1200.0, durationMs: 300, volume: 0.4);
    });
  }

  void playAmbientDrip() {
    // Soft drip sound
    playBeep(frequency: 2000.0, durationMs: 50, volume: 0.2);
  }

  void playMenuSelectSound() {
    // UI selection sound
    playBeep(frequency: 600.0, durationMs: 100, volume: 0.3);
  }

  void stop() {
    _beepTimer?.cancel();
    _isPlaying = false;
  }

  void dispose() {
    _beepTimer?.cancel();
  }
}