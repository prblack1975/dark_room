import 'package:flame/components.dart';
import 'level.dart';
import '../components/wall.dart';
import '../components/game_object.dart';

class BasementLevel extends Level {
  BasementLevel() : super(
    name: 'Basement: Industrial Underground',
    description: 'Navigate a maze-like basement complex with water systems and industrial machinery',
    spawn: Vector2(80, 100),
  );
  
  @override
  Future<void> buildLevel() async {
    final complexSize = Vector2(1600, 1200);
    
    // Create basement boundaries
    createRoomBoundaries(complexSize);
    
    // === MAZE-LIKE BASEMENT COMPLEX ===
    
    // Create interconnected areas with dead ends and multiple paths
    _createMazeWallSystem();
    
    // Water treatment area
    _createWaterTreatmentArea();
    
    // Electrical/generator room
    _createGeneratorRoom();
    
    // Storage areas with dead ends
    _createStorageAreas();
    
    // Maintenance tunnels
    _createMaintenanceTunnels();
    
    // Boiler room (final area)
    _createBoilerRoom();
    
    // Place navigation-challenging items throughout
    _placeHiddenItems();
  }
  
  void _createMazeWallSystem() {
    // === MAIN MAZE STRUCTURE ===
    
    // Primary corridor spine (horizontal)
    add(Wall(position: Vector2(200, 250), size: Vector2(800, 25)));
    add(Wall(position: Vector2(200, 400), size: Vector2(800, 25)));
    
    // Vertical connectors with gaps
    add(Wall(position: Vector2(300, 100), size: Vector2(25, 150)));
    add(Wall(position: Vector2(300, 275), size: Vector2(25, 125)));
    
    add(Wall(position: Vector2(500, 50), size: Vector2(25, 200)));
    add(Wall(position: Vector2(500, 275), size: Vector2(25, 125)));
    add(Wall(position: Vector2(500, 425), size: Vector2(25, 200)));
    
    add(Wall(position: Vector2(700, 100), size: Vector2(25, 150)));
    add(Wall(position: Vector2(700, 275), size: Vector2(25, 125)));
    add(Wall(position: Vector2(700, 425), size: Vector2(25, 150)));
    
    add(Wall(position: Vector2(900, 50), size: Vector2(25, 200)));
    add(Wall(position: Vector2(900, 275), size: Vector2(25, 125)));
    add(Wall(position: Vector2(900, 425), size: Vector2(25, 300)));
    
    // Dead-end creators
    add(Wall(position: Vector2(150, 150), size: Vector2(100, 25)));
    add(Wall(position: Vector2(350, 500), size: Vector2(100, 25)));
    add(Wall(position: Vector2(750, 600), size: Vector2(100, 25)));
    
    // L-shaped maze sections
    add(Wall(position: Vector2(1100, 200), size: Vector2(150, 25)));
    add(Wall(position: Vector2(1225, 200), size: Vector2(25, 150)));
    
    add(Wall(position: Vector2(1100, 500), size: Vector2(100, 25)));
    add(Wall(position: Vector2(1175, 400), size: Vector2(25, 125)));
  }
  
  void _createWaterTreatmentArea() {
    // Water treatment boundaries (left side)
    add(Wall(position: Vector2(50, 600), size: Vector2(300, 25)));
    add(Wall(position: Vector2(50, 600), size: Vector2(25, 350)));
    add(Wall(position: Vector2(325, 600), size: Vector2(25, 350)));
    add(Wall(position: Vector2(50, 925), size: Vector2(300, 25)));
    
    // === WATER TREATMENT EQUIPMENT ===
    
    // Main water pump (large equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'main_water_pump',
      description: 'A massive water pump moves thousands of gallons per hour.',
      atmosphericDescription: 'This industrial titan is the heart of the building\'s water system. Its powerful motor thrums with hydraulic force while massive impellers push water through underground pipes. The vibration travels through the concrete floor.',
      position: Vector2(150, 750),
      size: Vector2(90, 90),
      soundRadius: 480,
      soundFile: 'wall-hit-1-100717.mp3',
    ));
    
    // Filtration system (medium equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'water_filtration',
      description: 'Water filters through a complex purification system.',
      atmosphericDescription: 'This sophisticated system cleans and purifies every drop. You can hear water cascading through multiple filter stages while pumps maintain precise pressure throughout the process.',
      position: Vector2(250, 650),
      size: Vector2(50, 60),
      soundRadius: 210,
      soundFile: 'pickup.mp3',
    ));
    
    // Pressure gauge monitoring (small equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'pressure_monitor',
      description: 'Automated pressure monitoring systems click and beep.',
      atmosphericDescription: 'These safety systems vigilantly monitor water pressure throughout the building. Electronic sensors click softly as they take readings, occasionally beeping to confirm system status.',
      position: Vector2(100, 850),
      size: Vector2(25, 25),
      soundRadius: 90,
      soundFile: 'click.mp3',
    ));
  }
  
  void _createGeneratorRoom() {
    // Generator room boundaries (upper right)
    add(Wall(position: Vector2(1200, 50), size: Vector2(300, 25)));
    add(Wall(position: Vector2(1200, 50), size: Vector2(25, 200)));
    add(Wall(position: Vector2(1475, 50), size: Vector2(25, 200)));
    add(Wall(position: Vector2(1200, 225), size: Vector2(300, 25)));
    
    // === ELECTRICAL GENERATION EQUIPMENT ===
    
    // Backup generator (massive equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'backup_generator',
      description: 'An industrial backup generator idles on standby.',
      atmosphericDescription: 'This mechanical giant stands ready to power the entire facility during outages. Its diesel engine idles with controlled power, occasionally revving as it tests its systems. The exhaust fan draws away fumes with industrial force.',
      position: Vector2(1350, 125),
      size: Vector2(100, 80),
      soundRadius: 500,
      soundFile: 'wall-hit-1-100717.mp3',
    ));
    
    // Electrical panel (medium equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'main_electrical_panel',
      description: 'The main electrical distribution panel hums with power.',
      atmosphericDescription: 'This nerve center distributes electricity throughout the facility. Transformers hum with high voltage while circuit breakers occasionally click as they manage electrical loads.',
      position: Vector2(1250, 100),
      size: Vector2(40, 60),
      soundRadius: 180,
      soundFile: 'wall_hit.mp3',
    ));
  }
  
  void _createStorageAreas() {
    // Storage area 1 (creates dead end)
    add(Wall(position: Vector2(1050, 400), size: Vector2(25, 150)));
    add(Wall(position: Vector2(1050, 525), size: Vector2(150, 25)));
    add(Wall(position: Vector2(1175, 400), size: Vector2(25, 150)));
    
    // Storage area 2 (another dead end)
    add(Wall(position: Vector2(400, 700), size: Vector2(200, 25)));
    add(Wall(position: Vector2(400, 700), size: Vector2(25, 100)));
    add(Wall(position: Vector2(575, 700), size: Vector2(25, 100)));
    add(Wall(position: Vector2(400, 775), size: Vector2(200, 25)));
    
    // === STORAGE AREA SOUNDS ===
    
    // Ventilation in storage (small equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'storage_ventilation',
      description: 'Storage area ventilation prevents humidity buildup.',
      atmosphericDescription: 'These moisture control systems work continuously to protect stored equipment. Small fans circulate air while dehumidifiers click on and off as needed.',
      position: Vector2(1125, 450),
      size: Vector2(30, 30),
      soundRadius: 100,
      soundFile: 'wall-hit-cartoon.mp3',
    ));
    
    // Dripping in abandoned storage
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'storage_leak',
      description: 'Water drips from a pipe in the abandoned storage area.',
      atmosphericDescription: 'A forgotten leak has created a steady drip in this neglected corner. Each drop echoes off concrete walls, marking time in this forgotten space.',
      position: Vector2(500, 740),
      size: Vector2(20, 20),
      soundRadius: 75,
      soundFile: 'pickup.mp3',
    ));
  }
  
  void _createMaintenanceTunnels() {
    // Tunnel system (bottom area)
    add(Wall(position: Vector2(600, 800), size: Vector2(600, 25)));
    add(Wall(position: Vector2(600, 900), size: Vector2(600, 25)));
    
    // Tunnel branches
    add(Wall(position: Vector2(800, 825), size: Vector2(25, 75)));
    add(Wall(position: Vector2(1000, 825), size: Vector2(25, 75)));
    
    // === TUNNEL EQUIPMENT ===
    
    // Air handling unit (medium equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'tunnel_air_handler',
      description: 'An air handling unit moves stale air through the tunnels.',
      atmosphericDescription: 'This system ensures breathable air in the underground spaces. Large fans push air through ductwork while filters trap dust and particles from the basement environment.',
      position: Vector2(900, 850),
      size: Vector2(60, 40),
      soundRadius: 200,
      soundFile: 'wall_hit.mp3',
    ));
    
    // Pipe junction (small equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'pipe_junction',
      description: 'A complex pipe junction carries various utilities.',
      atmosphericDescription: 'Multiple utility lines converge here - water, steam, and compressed air all flow through this junction. Each pipe carries its own sound signature as fluids move through the basement infrastructure.',
      position: Vector2(700, 850),
      size: Vector2(25, 25),
      soundRadius: 85,
      soundFile: 'pickup.mp3',
    ));
  }
  
  void _createBoilerRoom() {
    // Boiler room boundaries (bottom right - final area)
    add(Wall(position: Vector2(1300, 800), size: Vector2(200, 25)));
    add(Wall(position: Vector2(1300, 800), size: Vector2(25, 300)));
    add(Wall(position: Vector2(1475, 800), size: Vector2(25, 300)));
    add(Wall(position: Vector2(1300, 1075), size: Vector2(200, 25)));
    
    // === BOILER ROOM EQUIPMENT ===
    
    // Industrial boiler (massive equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'industrial_boiler',
      description: 'A massive steam boiler provides building heat.',
      atmosphericDescription: 'This industrial furnace is the thermal heart of the building. Gas burners roar with controlled flame while water transforms into pressurized steam. The entire system pulses with thermal energy.',
      position: Vector2(1380, 950),
      size: Vector2(80, 100),
      soundRadius: 520,
      soundFile: 'wall-hit-1-100717.mp3',
    ));
    
    // Steam release valve (medium equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'steam_release',
      description: 'Automatic steam release valves maintain safe pressure.',
      atmosphericDescription: 'These safety systems periodically release excess steam pressure. The sharp hiss of escaping steam echoes through the boiler room as the system maintains safe operating conditions.',
      position: Vector2(1330, 900),
      size: Vector2(30, 30),
      soundRadius: 160,
      soundFile: 'wall-hit-cartoon.mp3',
    ));
    
    // === THE FINAL EXIT ===
    
    // Emergency basement exit
    addObject(GameObject(
      type: GameObjectType.door,
      name: 'basement_emergency_exit',
      description: 'An emergency exit leading to the surface.',
      atmosphericDescription: 'This heavy steel door leads up to ground level. You can feel cold air seeping down from above, carrying the promise of fresh air and freedom from this underground maze.',
      position: Vector2(1420, 1000),
      size: Vector2(40, 80),
      requiredKey: 'facility_master_key',
    ));
  }
  
  void _placeHiddenItems() {
    // === STRATEGICALLY HIDDEN ITEMS ===
    
    // Maintenance ID near water treatment
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'maintenance_id',
      description: 'A water-stained maintenance worker ID badge.',
      atmosphericDescription: 'This plastic ID badge belongs to "J. Martinez - Senior Technician". The photo is faded but the magnetic stripe still works. A handwritten note on the back mentions "backup key in the old storage room".',
      position: Vector2(120, 800),
      size: Vector2(20, 15),
      pickupRadius: 35,
    ));
    
    // Emergency flashlight in dead-end storage
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'emergency_flashlight',
      description: 'A heavy-duty emergency flashlight.',
      atmosphericDescription: 'This industrial flashlight still has power after years of neglect. Its beam could cut through absolute darkness. Someone left it here for emergencies that may never have come.',
      position: Vector2(1130, 470),
      size: Vector2(25, 10),
      pickupRadius: 30,
    ));
    
    // Valve wheel (red herring) in another dead end
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'valve_wheel',
      description: 'A heavy valve wheel for emergency shutoffs.',
      atmosphericDescription: 'This cast iron wheel controlled some long-forgotten system. Its weight suggests importance, but whatever it once operated has been disconnected for years.',
      position: Vector2(480, 750),
      size: Vector2(30, 30),
      pickupRadius: 40,
    ));
    
    // Facility master key (hidden in generator room)
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'facility_master_key',
      description: 'A master key for all facility emergency systems.',
      atmosphericDescription: 'This specialized key bears the facility\'s official seal and "EMERGENCY USE ONLY" markings. Its unique cut pattern suggests it opens critical security systems throughout the building.',
      position: Vector2(1280, 150),
      size: Vector2(20, 10),
      pickupRadius: 35,
    ));
    
    // Tool kit in maintenance tunnel
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'tunnel_toolkit',
      description: 'A professional maintenance toolkit.',
      atmosphericDescription: 'This well-organized toolkit contains specialized equipment for underground utility work. Each tool has its place, suggesting this belonged to someone who took pride in their craft.',
      position: Vector2(850, 870),
      size: Vector2(25, 20),
      pickupRadius: 35,
    ));
    
    // System manual near boiler
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'boiler_manual',
      description: 'A comprehensive boiler operation manual.',
      atmosphericDescription: 'This thick manual contains everything needed to operate the facility\'s heating system. Handwritten notes in the margins suggest years of practical experience by multiple operators.',
      position: Vector2(1350, 880),
      size: Vector2(20, 25),
      pickupRadius: 35,
    ));
    
    // === HEALTH ARTIFACTS IN BASEMENT ===
    
    // Emergency medical station in water treatment
    addObject(GameObject(
      type: GameObjectType.healthArtifact,
      name: 'emergency_medical_station',
      description: 'An industrial emergency medical station.',
      atmosphericDescription: 'This wall-mounted medical station contains supplies for treating workplace injuries. The sterile bandages, antiseptic solutions, and pain relievers are still sealed and effective. Industrial accidents require immediate treatment.',
      position: Vector2(280, 750),
      size: Vector2(30, 25),
      pickupRadius: 40,
      healingAmount: 35.0,
    ));
    
    // Pain relief tablets in storage area
    addObject(GameObject(
      type: GameObjectType.healthArtifact,
      name: 'pain_relief_tablets',
      description: 'A bottle of industrial-strength pain relief tablets.',
      atmosphericDescription: 'These prescription-strength tablets were kept for workers dealing with chronic pain from heavy labor. The sealed bottle contains enough medication to dull even severe pain.',
      position: Vector2(1100, 400),
      size: Vector2(15, 15),
      pickupRadius: 35,
      healingAmount: 25.0,
    ));
    
    // First aid supplies in generator room
    addObject(GameObject(
      type: GameObjectType.healthArtifact,
      name: 'first_aid_supplies',
      description: 'Professional first aid supplies for electrical workers.',
      atmosphericDescription: 'This specialized first aid kit is designed for electrical and mechanical injuries. It contains burn gel, electrical shock recovery aids, and trauma supplies. The contents could treat serious industrial accidents.',
      position: Vector2(1420, 180),
      size: Vector2(25, 20),
      pickupRadius: 40,
      healingAmount: 45.0,
    ));
  }
}