import 'dart:html' as html;
import 'dart:async';
import 'dart:math' as math;

// Real web audio implementation using Web Audio API
class WebAudioPlayer {
  static final WebAudioPlayer _instance = WebAudioPlayer._internal();
  factory WebAudioPlayer() => _instance;
  WebAudioPlayer._internal();

  html.AudioContext? _audioContext;
  Timer? _currentSoundTimer;

  html.AudioContext get audioContext {
    _audioContext ??= html.AudioContext();
    return _audioContext!;
  }

  // Generate and play a beep tone
  Future<void> playBeep({
    double frequency = 800.0,
    int durationMs = 200,
    double volume = 0.3,
  }) async {
    try {
      // Stop any current sound
      _currentSoundTimer?.cancel();
      
      final context = audioContext;
      
      // Create oscillator for tone generation
      final oscillator = context.createOscillator();
      final gainNode = context.createGain();
      
      // Connect oscillator -> gain -> destination
      oscillator.connectNode(gainNode);
      gainNode.connectNode(context.destination!);
      
      // Set frequency and type
      oscillator.frequency!.value = frequency;
      oscillator.type = 'sine'; // Smooth sine wave
      
      // Set volume with fade in/out to avoid clicking
      final now = context.currentTime!;
      gainNode.gain!.setValueAtTime(0, now);
      gainNode.gain!.linearRampToValueAtTime(volume, now + 0.01); // Fade in
      gainNode.gain!.linearRampToValueAtTime(volume, now + (durationMs / 1000) - 0.01);
      gainNode.gain!.linearRampToValueAtTime(0, now + (durationMs / 1000)); // Fade out
      
      // Start and stop the oscillator
      oscillator.start(now);
      oscillator.stop(now + (durationMs / 1000));
      
      print('🔊 Playing ${frequency.toInt()}Hz for ${durationMs}ms at ${(volume * 100).toInt()}% volume');
      
    } catch (e) {
      print('Audio error: $e');
      // Fallback to console logging
      print('🔊 BEEP: ${frequency.toInt()}Hz for ${durationMs}ms (Volume: ${(volume * 100).toInt()}%)');
    }
  }

  void playCollisionSound() {
    // Low frequency thud
    playBeep(frequency: 200.0, durationMs: 150, volume: 0.4);
  }

  void playPickupSound() {
    // Pleasant ascending chime
    playBeep(frequency: 800.0, durationMs: 100, volume: 0.3);
    Timer(Duration(milliseconds: 120), () {
      playBeep(frequency: 1200.0, durationMs: 200, volume: 0.25);
    });
  }

  void playDoorOpenSound() {
    // Creaking door sequence
    playBeep(frequency: 300.0, durationMs: 200, volume: 0.4);
    Timer(Duration(milliseconds: 250), () {
      playBeep(frequency: 250.0, durationMs: 300, volume: 0.3);
    });
  }

  void playLevelCompleteSound() {
    // Success chord progression
    playBeep(frequency: 523.0, durationMs: 200, volume: 0.3); // C
    Timer(Duration(milliseconds: 250), () {
      playBeep(frequency: 659.0, durationMs: 200, volume: 0.3); // E
    });
    Timer(Duration(milliseconds: 500), () {
      playBeep(frequency: 784.0, durationMs: 400, volume: 0.4); // G
    });
  }

  void playMenuSelectSound() {
    // UI click sound
    playBeep(frequency: 1000.0, durationMs: 80, volume: 0.2);
  }

  void playAmbientDrip() {
    // Soft water drip
    playBeep(frequency: 2500.0, durationMs: 30, volume: 0.15);
  }

  void stop() {
    _currentSoundTimer?.cancel();
  }

  void dispose() {
    _currentSoundTimer?.cancel();
    _audioContext?.close();
  }
}