import 'package:flame/components.dart';
import 'level.dart';
import '../components/game_object.dart';
import '../components/wall.dart';
import 'tutorial_level.dart';
import 'escape_room_level.dart';
import 'laboratory_level.dart';
import 'basement_level.dart';
import 'office_complex_level.dart';

class MenuLevel extends Level {
  MenuLevel() : super(
    name: 'Dark Room: Level Selection Hub',
    description: 'Choose your escape challenge - progress through increasingly complex audio navigation puzzles',
    spawn: Vector2(400, 600),
  );
  
  @override
  Future<void> buildLevel() async {
    final hubSize = Vector2(1400, 800);
    
    // Create selection hub boundaries
    createRoomBoundaries(hubSize);
    
    // === LEVEL PROGRESSION LAYOUT ===
    
    // Tutorial (Level 1) - Always available
    _createLevelPortal(
      name: 'tutorial_portal',
      title: '1. TUTORIAL: First Steps',
      description: 'Learn audio navigation basics with simple challenges',
      difficulty: 'BEGINNER',
      position: Vector2(200, 400),
      isAvailable: true,
    );
    
    // Simple Escape (Level 2) - Available after tutorial
    _createLevelPortal(
      name: 'escape_portal',
      title: '2. SIMPLE ESCAPE: The Antechamber',
      description: 'Single room escape with strategic audio landmarks',
      difficulty: 'EASY',
      position: Vector2(450, 400),
      isAvailable: true, // For demo purposes - normally would check progression
    );
    
    // Laboratory (Level 3) - Intermediate complexity
    _createLevelPortal(
      name: 'laboratory_portal',
      title: '3. LABORATORY: Chemical Analysis Wing',
      description: 'Multi-room facility with scientific equipment sounds',
      difficulty: 'INTERMEDIATE',
      position: Vector2(700, 400),
      isAvailable: true, // For demo purposes
    );
    
    // Basement (Level 4) - Advanced maze navigation
    _createLevelPortal(
      name: 'basement_portal',
      title: '4. BASEMENT: Industrial Underground',
      description: 'Complex maze with water systems and dead ends',
      difficulty: 'ADVANCED',
      position: Vector2(950, 400),
      isAvailable: true, // For demo purposes
    );
    
    // Office Complex (Level 5) - Master level
    _createLevelPortal(
      name: 'office_portal',
      title: '5. OFFICE COMPLEX: Corporate Tower',
      description: 'Sprawling multi-department facility - ultimate challenge',
      difficulty: 'MASTER',
      position: Vector2(1200, 400),
      isAvailable: true, // For demo purposes
    );
    
    // === HUB ATMOSPHERE AND GUIDANCE ===
    
    // Central hub ambience (large range for orientation)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'hub_ambience',
      description: 'Ethereal echoes guide you through the selection hub.',
      atmosphericDescription: 'This mystical space exists between realities, where the echoes of countless escape attempts linger in the air. The sound seems to emanate from everywhere and nowhere, helping you orient yourself among the challenge portals.',
      position: Vector2(700, 200),
      size: Vector2(40, 40),
      soundRadius: 500,
      soundFile: 'pickup.mp3', // Soft ambient placeholder
    ));
    
    // Audio landmark for tutorial (extended range to reach player start position)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'beginner_chime',
      description: 'Gentle chimes mark the beginner challenge.',
      atmosphericDescription: 'These welcoming chimes ring softly, encouraging new players to begin their journey. The sound is warm and inviting, promising a safe learning environment.',
      position: Vector2(200, 350),
      size: Vector2(20, 20),
      soundRadius: 350, // Increased to reach player at [400, 600]
      soundFile: 'click.mp3',
    ));
    
    // Audio landmark for intermediate challenges (extended range to reach player)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'challenge_tone',
      description: 'Steady electronic tones mark intermediate challenges.',
      atmosphericDescription: 'These purposeful tones suggest increasing complexity and challenge. They pulse with determination, calling to those ready for more sophisticated audio navigation.',
      position: Vector2(700, 350),
      size: Vector2(30, 30),
      soundRadius: 400, // Increased to reach player at [400, 600]
      soundFile: 'wall_hit.mp3',
    ));
    
    // Audio landmark for advanced challenges (extended range to reach player)  
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'mastery_resonance',
      description: 'Deep resonant tones mark the most challenging levels.',
      atmosphericDescription: 'These commanding tones speak of mastery and ultimate challenge. The sound carries weight and authority, calling only to those who have proven themselves worthy.',
      position: Vector2(1100, 350),
      size: Vector2(40, 40),
      soundRadius: 800, // Increased to reach player at [400, 600]
      soundFile: 'wall-hit-1-100717.mp3',
    ));
    
    // === NAVIGATION HELPERS ===
    
    // Information sound source (close to player start position)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'info_beacon',
      description: 'An information beacon provides guidance.',
      atmosphericDescription: 'This helpful beacon offers audio cues about level progression. Listen carefully to understand how the challenges increase in complexity from left to right.',
      position: Vector2(700, 600),
      size: Vector2(25, 25),
      soundRadius: 350, // Increased to ensure audibility at start position  
      soundFile: 'key-get-39925.mp3',
    ));
    
    // === WALLS FOR SPATIAL DEFINITION ===
    
    // Create subtle barriers to help define portal areas
    add(Wall(position: Vector2(350, 300), size: Vector2(25, 200)));
    add(Wall(position: Vector2(600, 300), size: Vector2(25, 200)));
    add(Wall(position: Vector2(850, 300), size: Vector2(25, 200)));
    add(Wall(position: Vector2(1100, 300), size: Vector2(25, 200)));
    
    // Central platform definition
    add(Wall(position: Vector2(600, 150), size: Vector2(200, 25)));
    add(Wall(position: Vector2(600, 250), size: Vector2(200, 25)));
  }
  
  void _createLevelPortal({
    required String name,
    required String title,
    required String description,
    required String difficulty,
    required Vector2 position,
    required bool isAvailable,
  }) {
    final fullDescription = isAvailable 
      ? '$title\\n$description\\nDifficulty: $difficulty\\nSTATUS: AVAILABLE - Navigate close and move forward to enter'
      : '$title\\n$description\\nDifficulty: $difficulty\\nSTATUS: LOCKED - Complete previous levels to unlock';
    
    addObject(GameObject(
      type: GameObjectType.interactable,  // Level selectors should be interactables (yellow in debug)
      name: name,
      description: fullDescription,
      atmosphericDescription: isAvailable 
        ? 'This portal pulses with active energy, ready to transport you to a new challenge. You can feel the unique atmosphere of the level beyond seeping through the dimensional barrier.'
        : 'This portal remains sealed, its energy dormant. Complete the previous challenges to prove your mastery and unlock this next test.',
      position: position,
      size: Vector2(80, 80),
    ));
  }
  
  @override
  void handleObjectInteraction(GameObject object, player) {
    // Handle level selector portals (interactables)
    if (object.type == GameObjectType.interactable) {
      switch (object.name) {
        case 'tutorial_portal':
          print('🟡 DEBUG: Loading Tutorial Level');
          narrationSystem.narrateLevelTransition('Entering Tutorial: First Steps. Learn the fundamentals of audio navigation.');
          gameRef.loadLevel(TutorialLevel());
          break;
          
        case 'escape_portal':
          print('🟡 DEBUG: Loading Simple Escape Level');
          narrationSystem.narrateLevelTransition('Entering Simple Escape: The Antechamber. Navigate using strategic audio landmarks.');
          gameRef.loadLevel(EscapeRoomLevel());
          break;
          
        case 'laboratory_portal':
          print('🟡 DEBUG: Loading Laboratory Level');
          narrationSystem.narrateLevelTransition('Entering Laboratory: Chemical Analysis Wing. Navigate complex multi-room facility.');
          gameRef.loadLevel(LaboratoryLevel());
          break;
          
        case 'basement_portal':
          print('🟡 DEBUG: Loading Basement Level');
          narrationSystem.narrateLevelTransition('Entering Basement: Industrial Underground. Master maze navigation with industrial sounds.');
          gameRef.loadLevel(BasementLevel());
          break;
          
        case 'office_portal':
          print('🟡 DEBUG: Loading Office Complex Level');
          narrationSystem.narrateLevelTransition('Entering Office Complex: Corporate Tower. Ultimate challenge with varied equipment sounds.');
          gameRef.loadLevel(OfficeComplexLevel());
          break;
          
        default:
          // Handle other interactables
          super.handleObjectInteraction(object, player);
      }
    } else {
      // Let the parent class handle doors and other types normally
      super.handleObjectInteraction(object, player);
    }
  }
}