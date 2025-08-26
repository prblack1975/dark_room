import 'package:flame/components.dart';
import 'level.dart';
import '../components/wall.dart';
import '../components/game_object.dart';

class LaboratoryLevel extends Level {
  LaboratoryLevel() : super(
    name: 'Laboratory: Chemical Analysis Wing',
    description: 'Navigate a multi-room laboratory facility with active scientific equipment',
    spawn: Vector2(100, 150),
  );
  
  @override
  Future<void> buildLevel() async {
    final facilitySize = Vector2(1400, 900);
    
    // Create facility boundaries
    createRoomBoundaries(facilitySize);
    
    // === MULTI-ROOM LABORATORY COMPLEX ===
    
    // Main lab room (largest area)
    _createMainLabRoom();
    
    // Chemical storage room
    _createChemicalStorageRoom();
    
    // Analysis room
    _createAnalysisRoom();
    
    // Equipment maintenance corridor
    _createMaintenanceCorridor();
    
    // Emergency exit room
    _createExitRoom();
    
    // Connect rooms with hallways and access points
    _createHallwayConnections();
  }
  
  void _createMainLabRoom() {
    // Main lab boundaries (central area)
    add(Wall(position: Vector2(200, 50), size: Vector2(20, 300)));
    add(Wall(position: Vector2(200, 50), size: Vector2(400, 20)));
    add(Wall(position: Vector2(600, 50), size: Vector2(20, 200)));
    add(Wall(position: Vector2(400, 250), size: Vector2(220, 20)));
    add(Wall(position: Vector2(200, 350), size: Vector2(200, 20)));
    
    // === LARGE SCIENTIFIC EQUIPMENT (400+ radius) ===
    
    // Industrial centrifuge
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'industrial_centrifuge',
      description: 'A massive centrifuge spins samples at incredible speed.',
      atmosphericDescription: 'This industrial titan whirs with tremendous force, separating compounds at thousands of RPM. The vibration travels through the floor and into your bones. Whatever it\'s processing has been spinning for hours.',
      position: Vector2(450, 150),
      size: Vector2(80, 80),
      soundRadius: 450,
      soundFile: 'wall-hit-1-100717.mp3',
    ));
    
    // === MEDIUM EQUIPMENT (200 radius) ===
    
    // Fume hood extraction system
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'fume_hood_system',
      description: 'A powerful fume hood pulls dangerous vapors away.',
      atmosphericDescription: 'This safety system works tirelessly to protect the lab from toxic fumes. The powerful extraction fan creates a steady airflow that you can feel pulling at your clothes and hair.',
      position: Vector2(300, 100),
      size: Vector2(60, 40),
      soundRadius: 220,
      soundFile: 'wall_hit.mp3',
    ));
    
    // === SMALL EQUIPMENT (100 radius) ===
    
    // Analytical balance
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'precision_balance',
      description: 'An ultra-precise analytical balance hums quietly.',
      atmosphericDescription: 'This delicate instrument measures to the microgram. Its temperature control system maintains perfect conditions with tiny clicking sounds as it adjusts for environmental changes.',
      position: Vector2(250, 150),
      size: Vector2(25, 25),
      soundRadius: 95,
      soundFile: 'click.mp3',
    ));
    
    // === ITEMS IN MAIN LAB ===
    
    // Lab notebook with clues
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'research_journal',
      description: 'A leather-bound research journal.',
      atmosphericDescription: 'This journal contains detailed notes about "Project Synthesis" and mentions a security key hidden in the chemical storage room. The handwriting becomes increasingly urgent in later entries.',
      position: Vector2(280, 120),
      size: Vector2(20, 15),
      pickupRadius: 35,
    ));
    
    // Sample vial
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'sample_vial',
      description: 'A sealed vial containing an unknown liquid.',
      atmosphericDescription: 'This glass vial contains a shimmering liquid that seems to move on its own. The label reads "COMPOUND-X" in faded letters. It feels warm to the touch.',
      position: Vector2(480, 200),
      size: Vector2(15, 15),
      pickupRadius: 30,
    ));
    
    // === HEALTH ARTIFACTS IN MAIN LAB ===
    
    // Emergency medical kit
    addObject(GameObject(
      type: GameObjectType.healthArtifact,
      name: 'emergency_medical_kit',
      description: 'A comprehensive emergency medical kit.',
      atmosphericDescription: 'This well-stocked medical kit contains bandages, antiseptic, and emergency medications. The supplies are perfectly preserved and ready for immediate use. Your injuries seem less severe just touching its contents.',
      position: Vector2(350, 180),
      size: Vector2(25, 20),
      pickupRadius: 40,
      healingAmount: 40.0,
    ));
  }
  
  void _createChemicalStorageRoom() {
    // Storage room boundaries (upper right)
    add(Wall(position: Vector2(700, 50), size: Vector2(300, 20)));
    add(Wall(position: Vector2(700, 50), size: Vector2(20, 250)));
    add(Wall(position: Vector2(980, 50), size: Vector2(20, 250)));
    add(Wall(position: Vector2(720, 300), size: Vector2(280, 20)));
    
    // === CHEMICAL STORAGE EQUIPMENT ===
    
    // Refrigeration unit (medium sound)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'chemical_refrigerator',
      description: 'A specialized refrigeration unit for chemical storage.',
      atmosphericDescription: 'This cold storage unit maintains precise temperatures for volatile compounds. The compressor cycles on and off with mechanical precision, and you can hear the gentle hum of circulation fans.',
      position: Vector2(850, 150),
      size: Vector2(50, 60),
      soundRadius: 180,
      soundFile: 'wall-hit-cartoon.mp3',
    ));
    
    // Ventilation system (small sound)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'storage_ventilation',
      description: 'Safety ventilation maintains air quality.',
      atmosphericDescription: 'This specialized ventilation system ensures no dangerous fumes accumulate. The gentle whoosh of filtered air creates a subtle current that hints at the room\'s safety systems.',
      position: Vector2(750, 100),
      size: Vector2(30, 30),
      soundRadius: 110,
      soundFile: 'pickup.mp3',
    ));
    
    // === KEY ITEM IN STORAGE ===
    
    // Security access card (main key)
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'lab_access_card',
      description: 'A high-security access card for restricted areas.',
      atmosphericDescription: 'This heavy access card bears the highest security clearance markings. The holographic seal shimmers with embedded security features, and the magnetic stripe appears to be quantum-encrypted.',
      position: Vector2(920, 180),
      size: Vector2(25, 15),
      pickupRadius: 40,
    ));
  }
  
  void _createAnalysisRoom() {
    // Analysis room boundaries (lower right)
    add(Wall(position: Vector2(700, 400), size: Vector2(300, 20)));
    add(Wall(position: Vector2(700, 400), size: Vector2(20, 200)));
    add(Wall(position: Vector2(980, 400), size: Vector2(20, 200)));
    add(Wall(position: Vector2(700, 580), size: Vector2(300, 20)));
    
    // === ANALYSIS EQUIPMENT ===
    
    // Spectrometer (large equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'mass_spectrometer',
      description: 'A sophisticated mass spectrometer analyzes molecular structures.',
      atmosphericDescription: 'This analytical giant peers into the very structure of matter itself. High-voltage circuits hum with barely contained energy while vacuum pumps maintain impossible emptiness within its chambers.',
      position: Vector2(800, 500),
      size: Vector2(70, 60),
      soundRadius: 380,
      soundFile: 'wall-hit-1-100717.mp3',
    ));
    
    // Computer workstation (medium equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'analysis_computer',
      description: 'A powerful computer processes spectral data.',
      atmosphericDescription: 'This workstation crunches massive datasets from the analysis equipment. Multiple cooling fans work overtime while hard drives spin continuously, processing terabytes of molecular fingerprints.',
      position: Vector2(750, 450),
      size: Vector2(40, 30),
      soundRadius: 170,
      soundFile: 'wall_hit.mp3',
    ));
    
    // === ANALYSIS ROOM ITEMS ===
    
    // Backup data drive
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'backup_drive',
      description: 'An encrypted backup drive labeled "Emergency Protocols".',
      atmosphericDescription: 'This military-grade storage device contains critical backup data. The encryption indicator still blinks green, suggesting the data remains intact and accessible.',
      position: Vector2(770, 470),
      size: Vector2(20, 10),
      pickupRadius: 35,
    ));
    
    // === HEALTH ARTIFACTS IN ANALYSIS ROOM ===
    
    // Adrenaline injector
    addObject(GameObject(
      type: GameObjectType.healthArtifact,
      name: 'adrenaline_injector',
      description: 'An emergency adrenaline auto-injector.',
      atmosphericDescription: 'This medical-grade auto-injector contains pure epinephrine for emergency use. The device is still sealed and functional, ready to provide an immediate surge of life-saving energy when activated.',
      position: Vector2(850, 520),
      size: Vector2(15, 20),
      pickupRadius: 35,
      healingAmount: 60.0,
    ));
  }
  
  void _createMaintenanceCorridor() {
    // Maintenance corridor (left side)
    add(Wall(position: Vector2(50, 400), size: Vector2(150, 20)));
    add(Wall(position: Vector2(50, 400), size: Vector2(20, 300)));
    add(Wall(position: Vector2(180, 400), size: Vector2(20, 300)));
    add(Wall(position: Vector2(50, 680), size: Vector2(150, 20)));
    
    // === MAINTENANCE EQUIPMENT ===
    
    // HVAC system (large)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'facility_hvac',
      description: 'The main HVAC system controls the entire facility climate.',
      atmosphericDescription: 'This mechanical heart of the building breathes for everyone inside. Massive blowers push conditioned air through kilometers of ductwork while compressors cycle with industrial determination.',
      position: Vector2(100, 550),
      size: Vector2(80, 80),
      soundRadius: 420,
      soundFile: 'wall-hit-1-100717.mp3',
    ));
    
    // Water pump (medium)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'coolant_pump',
      description: 'A coolant pump circulates fluid through the equipment.',
      atmosphericDescription: 'This pump maintains the lifeblood of the laboratory - the coolant system that keeps sensitive equipment at optimal temperatures. Water flows through sealed pipes with steady, rhythmic pulses.',
      position: Vector2(130, 450),
      size: Vector2(40, 40),
      soundRadius: 190,
      soundFile: 'pickup.mp3',
    ));
    
    // === MAINTENANCE ITEMS ===
    
    // Emergency tool kit
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'emergency_toolkit',
      description: 'A comprehensive emergency repair kit.',
      atmosphericDescription: 'This well-maintained toolkit contains everything needed for emergency repairs. Among the tools, you notice what appears to be a universal override key.',
      position: Vector2(110, 480),
      size: Vector2(25, 20),
      pickupRadius: 35,
    ));
  }
  
  void _createExitRoom() {
    // Exit room boundaries (far right)
    add(Wall(position: Vector2(1100, 200), size: Vector2(200, 20)));
    add(Wall(position: Vector2(1100, 200), size: Vector2(20, 400)));
    add(Wall(position: Vector2(1280, 200), size: Vector2(20, 400)));
    add(Wall(position: Vector2(1100, 580), size: Vector2(200, 20)));
    
    // === EXIT ROOM ATMOSPHERE ===
    
    // Emergency lighting system (small)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'emergency_lighting',
      description: 'Emergency lighting circuits buzz quietly.',
      atmosphericDescription: 'These backup systems stand ready for crisis. The electronic circuits emit a barely audible buzz, and you can hear the slight crackle of ready energy waiting to illuminate escape routes.',
      position: Vector2(1150, 300),
      size: Vector2(20, 20),
      soundRadius: 85,
      soundFile: 'click.mp3',
    ));
    
    // === THE EXIT ===
    
    // High-security exit door
    addObject(GameObject(
      type: GameObjectType.door,
      name: 'laboratory_exit',
      description: 'A blast-resistant emergency exit with multiple locks.',
      atmosphericDescription: 'This fortress-like door represents your escape from the laboratory complex. Multiple security systems guard it, but you can feel fresh air seeping around its edges - freedom is close.',
      position: Vector2(1200, 380),
      size: Vector2(50, 100),
      requiredKey: 'lab_access_card',
    ));
  }
  
  void _createHallwayConnections() {
    // === HALLWAY SYSTEM BETWEEN ROOMS ===
    
    // Main corridor walls
    add(Wall(position: Vector2(400, 320), size: Vector2(300, 20)));
    add(Wall(position: Vector2(400, 380), size: Vector2(300, 20)));
    
    // Connecting passages
    add(Wall(position: Vector2(620, 70), size: Vector2(80, 20)));
    add(Wall(position: Vector2(620, 320), size: Vector2(80, 20)));
    
    // Laboratory entrance corridor
    add(Wall(position: Vector2(1020, 220), size: Vector2(80, 20)));
    add(Wall(position: Vector2(1020, 360), size: Vector2(80, 20)));
    
    // === HALLWAY ATMOSPHERE ===
    
    // Fluorescent light ballast (small sound in hallway)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'hallway_lighting',
      description: 'Fluorescent lights flicker and buzz overhead.',
      atmosphericDescription: 'These institutional lights struggle to maintain their glow. The ballasts buzz and click as they fight against age and neglect, occasionally flickering as if trying to communicate.',
      position: Vector2(550, 350),
      size: Vector2(15, 15),
      soundRadius: 75,
      soundFile: 'click.mp3',
    ));
  }
}