import 'package:flame/components.dart';
import 'level.dart';
import '../components/wall.dart';
import '../components/game_object.dart';

class TutorialLevel extends Level {
  TutorialLevel() : super(
    name: 'Tutorial: First Steps',
    description: 'Learn the basics of movement and audio navigation in the darkness',
    spawn: Vector2(100, 300),
  );
  
  @override
  Future<void> buildLevel() async {
    final roomSize = Vector2(1200, 800);
    
    // Create room boundaries for larger exploration space
    createRoomBoundaries(roomSize);
    
    // === TUTORIAL PROGRESSION: AUDIO LANDMARKS ===
    
    // Small objects (100 unit radius) - First audio landmark
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'ticking_clock',
      description: 'An old grandfather clock ticks steadily.',
      atmosphericDescription: 'The methodical tick-tock of this ancient timepiece cuts through the silence like a heartbeat. Each tick seems to count down to something important, its mechanical precision a comfort in this dark place.',
      position: Vector2(300, 200),
      size: Vector2(25, 25),
      soundRadius: 100, // Small object range
      soundFile: 'click.mp3',
    ));
    
    // Medium objects (200 unit radius) - Second audio landmark
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'computer_hum',
      description: 'An old computer hums with electronic life.',
      atmosphericDescription: 'This forgotten machine whirs quietly to itself, its cooling fans spinning endlessly. The electronic hum speaks of data processing in the dark, circuits still faithfully executing their ancient programs.',
      position: Vector2(600, 150),
      size: Vector2(40, 40),
      soundRadius: 200, // Medium object range
      soundFile: 'wall_hit.mp3', // Placeholder for computer hum
    ));
    
    // Large objects (400+ unit radius) - Major audio landmark
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'ventilation_system',
      description: 'A massive ventilation system rumbles overhead.',
      atmosphericDescription: 'This industrial giant breathes life into the building, its powerful motors pushing air through hidden ducts. The deep rumble vibrates through the floor and walls, a constant reminder of the building\'s living infrastructure.',
      position: Vector2(900, 400),
      size: Vector2(60, 60),
      soundRadius: 400, // Large object range
      soundFile: 'wall-hit-1-100717.mp3', // Placeholder for ventilation
    ));
    
    // === TUTORIAL ITEMS FOR PICKUP PRACTICE ===
    
    // Practice item near clock (small radius pickup)
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'small_coin',
      description: 'A tarnished copper coin.',
      atmosphericDescription: 'This small coin feels warm in your palm, as if it has been waiting here just for you. Its surface is worn smooth, but you can still make out faint markings that speak of its age and the countless hands that have held it.',
      position: Vector2(320, 180),
      size: Vector2(15, 15),
      pickupRadius: 30,
    ));
    
    // Main key near computer (medium radius pickup)
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'rusty_key',
      description: 'A rusty metal key. It feels cold to the touch.',
      atmosphericDescription: 'This ancient key bears the weight of countless secrets. Its iron surface is pitted with age, and its teeth are worn from use. You can almost feel the history it carries, the doors it has opened, and the mysteries it has unlocked.',
      position: Vector2(580, 180),
      size: Vector2(20, 20),
      pickupRadius: 35,
    ));
    
    // Bonus item near ventilation (larger radius pickup)
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'access_card',
      description: 'A plastic access card with a magnetic stripe.',
      atmosphericDescription: 'This keycard still bears the faded photo of its original owner. The magnetic stripe gleams dully in your fingers, holding digital secrets that might unlock more than just doors.',
      position: Vector2(880, 380),
      size: Vector2(25, 15),
      pickupRadius: 40,
    ));
    
    // === EXIT DOOR ===
    addObject(GameObject(
      type: GameObjectType.door,
      name: 'tutorial_exit',
      description: 'A heavy wooden door marked "EXIT". It\'s locked.',
      atmosphericDescription: 'This imposing door stands as your final barrier to freedom. Its dark wood is scarred by time, and the lock mechanism clicks ominously when touched. Beyond it lies your escape from this tutorial chamber.',
      position: Vector2(1100, 350),
      size: Vector2(40, 60),
      requiredKey: 'rusty_key',
    ));
    
    // === WALL OBSTACLES FOR OCCLUSION TESTING ===
    
    // Central dividing wall with gaps
    add(Wall(
      position: Vector2(500, 100),
      size: Vector2(20, 200),
    ));
    add(Wall(
      position: Vector2(500, 350),
      size: Vector2(20, 200),
    ));
    
    // L-shaped wall near ventilation for occlusion testing
    add(Wall(
      position: Vector2(750, 300),
      size: Vector2(150, 20),
    ));
    add(Wall(
      position: Vector2(750, 300),
      size: Vector2(20, 100),
    ));
    
    // Small barrier near clock
    add(Wall(
      position: Vector2(250, 250),
      size: Vector2(100, 20),
    ));
    
    // Corridor-forming walls
    add(Wall(
      position: Vector2(400, 500),
      size: Vector2(400, 20),
    ));
    add(Wall(
      position: Vector2(400, 600),
      size: Vector2(400, 20),
    ));
    
    // === ATMOSPHERIC DETAILS ===
    
    // Water drip sound in corner for ambience
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'corner_drip',
      description: 'Water drips steadily from a pipe.',
      atmosphericDescription: 'Hidden in the darkness, a broken pipe weeps endlessly. Each drop echoes off the cold floor, counting the passage of time in this forgotten place.',
      position: Vector2(150, 700),
      size: Vector2(20, 20),
      soundRadius: 80,
      soundFile: 'pickup.mp3', // Placeholder for dripping
    ));
  }
}