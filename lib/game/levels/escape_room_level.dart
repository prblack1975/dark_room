import 'package:flame/components.dart';
import 'level.dart';
import '../components/wall.dart';
import '../components/game_object.dart';

class EscapeRoomLevel extends Level {
  EscapeRoomLevel() : super(
    name: 'Simple Escape: The Antechamber',
    description: 'A single room escape challenge with multiple audio landmarks and strategic navigation',
    spawn: Vector2(100, 500),
  );
  
  @override
  Future<void> buildLevel() async {
    final roomSize = Vector2(1000, 700);
    
    // Create room boundaries
    createRoomBoundaries(roomSize);
    
    // === STRATEGIC AUDIO LANDMARK PLACEMENT ===
    
    // Large landmark: Main ventilation system (400+ radius)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'main_ventilation',
      description: 'A powerful ventilation system dominates one corner.',
      atmosphericDescription: 'This industrial beast churns the air with mechanical determination. Its deep, rhythmic breathing fills the room, creating currents you can feel on your skin. The massive ducts above groan under the pressure.',
      position: Vector2(800, 100),
      size: Vector2(70, 70),
      soundRadius: 420,
      soundFile: 'wall-hit-1-100717.mp3',
    ));
    
    // Medium landmark: Computer cluster (200 radius)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'server_cluster',
      description: 'A bank of old computers hums steadily.',
      atmosphericDescription: 'These forgotten servers continue their endless digital vigil. Cooling fans whir in electronic harmony while hard drives click and process data that may never be retrieved. LED lights blink in patterns only they understand.',
      position: Vector2(450, 300),
      size: Vector2(50, 50),
      soundRadius: 200,
      soundFile: 'wall_hit.mp3',
    ));
    
    // Small landmark: Desk clock (100 radius)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'antique_clock',
      description: 'An ornate desk clock ticks with precision.',
      atmosphericDescription: 'This timepiece has witnessed decades pass in this room. Its brass face gleams despite the darkness, and each tick resonates with mechanical perfection. Time moves forward, whether you\'re ready or not.',
      position: Vector2(200, 150),
      size: Vector2(25, 25),
      soundRadius: 100,
      soundFile: 'click.mp3',
    ));
    
    // Medium landmark: Fan unit (180 radius)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'ceiling_fan',
      description: 'A large ceiling fan whirs overhead.',
      atmosphericDescription: 'This industrial fan pushes stale air in lazy circles above your head. Its metal blades cut through the atmosphere with a steady whoosh, creating tiny wind currents that hint at its location.',
      position: Vector2(650, 500),
      size: Vector2(40, 40),
      soundRadius: 180,
      soundFile: 'wall-hit-cartoon.mp3',
    ));
    
    // Small landmark: Water source (90 radius)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'water_cooler',
      description: 'A water cooler gurgles quietly.',
      atmosphericDescription: 'This forgotten appliance still holds its vigil, occasionally releasing air bubbles that pop and gurgle through the water reservoir. The sound is almost organic in this mechanical space.',
      position: Vector2(150, 600),
      size: Vector2(30, 30),
      soundRadius: 90,
      soundFile: 'pickup.mp3',
    ));
    
    // === STRATEGIC ITEM PLACEMENT ===
    
    // First clue item near clock (teaches audio navigation)
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'maintenance_log',
      description: 'A waterlogged maintenance logbook.',
      atmosphericDescription: 'This soggy logbook contains years of repair records. The ink has run in places, but you can still make out entries about "ventilation system key" and "emergency override procedures."',
      position: Vector2(180, 130),
      size: Vector2(20, 15),
      pickupRadius: 35,
    ));
    
    // Key item near servers (medium difficulty navigation)
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'brass_keycard',
      description: 'A brass keycard with magnetic stripe.',
      atmosphericDescription: 'This heavy keycard bears the embossed seal of "FACILITY ACCESS - LEVEL 2". The brass construction suggests importance, and the magnetic stripe still gleams despite years of disuse.',
      position: Vector2(480, 280),
      size: Vector2(25, 15),
      pickupRadius: 40,
    ));
    
    // Secondary item near ventilation (challenges wall navigation)
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'backup_key',
      description: 'A small backup key taped under a vent.',
      atmosphericDescription: 'Someone hid this emergency key with care, taping it securely where only someone who knew to look would find it. It\'s small but perfectly crafted, suggesting it opens something important.',
      position: Vector2(820, 130),
      size: Vector2(15, 10),
      pickupRadius: 30,
    ));
    
    // === EXIT DOOR ===
    addObject(GameObject(
      type: GameObjectType.door,
      name: 'security_exit',
      description: 'A reinforced security door with an electronic lock.',
      atmosphericDescription: 'This imposing barrier stands between you and freedom. Multiple locking mechanisms are visible in the darkness, and the electronic keypad glows faintly. You can hear wind whistling through the keyhole - the outside world awaits.',
      position: Vector2(50, 300),
      size: Vector2(40, 80),
      requiredKey: 'brass_keycard',
    ));
    
    // === NAVIGATION CHALLENGE WALLS ===
    
    // Central obstacle with gaps for navigation
    add(Wall(
      position: Vector2(350, 150),
      size: Vector2(20, 180),
    ));
    add(Wall(
      position: Vector2(350, 380),
      size: Vector2(20, 180),
    ));
    
    // L-shaped maze near server cluster
    add(Wall(
      position: Vector2(500, 200),
      size: Vector2(120, 20),
    ));
    add(Wall(
      position: Vector2(600, 200),
      size: Vector2(20, 100),
    ));
    
    // Corner barriers to create navigation challenges
    add(Wall(
      position: Vector2(150, 250),
      size: Vector2(150, 20),
    ));
    
    add(Wall(
      position: Vector2(700, 400),
      size: Vector2(20, 120),
    ));
    
    // Partial room divider
    add(Wall(
      position: Vector2(250, 450),
      size: Vector2(200, 20),
    ));
    
    // === ATMOSPHERIC DETAILS ===
    
    // Red herring interactable
    addObject(GameObject(
      type: GameObjectType.interactable,
      name: 'locked_cabinet',
      description: 'A metal filing cabinet. All drawers are locked tight.',
      atmosphericDescription: 'This bureaucratic monument contains nothing but old paperwork and broken dreams. Despite your hopes, its lock mechanism is rusted beyond repair.',
      position: Vector2(300, 550),
      size: Vector2(40, 40),
    ));
  }
}