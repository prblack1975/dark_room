import 'package:flame/components.dart';
import 'level.dart';
import '../components/wall.dart';
import '../components/game_object.dart';

class OfficeComplexLevel extends Level {
  OfficeComplexLevel() : super(
    name: 'Office Complex: Corporate Tower Floor',
    description: 'Navigate a sprawling office complex with varied equipment sounds and interconnected workspaces',
    spawn: Vector2(100, 200),
  );
  
  @override
  Future<void> buildLevel() async {
    final floorSize = Vector2(1800, 1400);
    
    // Create office floor boundaries
    createRoomBoundaries(floorSize);
    
    // === MULTI-DEPARTMENT OFFICE COMPLEX ===
    
    // Reception and lobby area
    _createReceptionArea();
    
    // Open office workspace with cubicles
    _createOpenOfficeArea();
    
    // IT department and server room
    _createITDepartment();
    
    // Executive offices
    _createExecutiveOffices();
    
    // Conference and meeting rooms
    _createConferenceRooms();
    
    // Copy/print center and supplies
    _createCopyCenter();
    
    // Break room and kitchen area
    _createBreakRoom();
    
    // Create interconnecting hallways
    _createOfficeHallways();
    
    // Place office items throughout complex
    _placeOfficeItems();
  }
  
  void _createReceptionArea() {
    // Reception boundaries (entrance area)
    add(Wall(position: Vector2(50, 100), size: Vector2(400, 25)));
    add(Wall(position: Vector2(50, 100), size: Vector2(25, 200)));
    add(Wall(position: Vector2(425, 100), size: Vector2(25, 200)));
    add(Wall(position: Vector2(50, 275), size: Vector2(200, 25)));
    add(Wall(position: Vector2(275, 275), size: Vector2(200, 25)));
    
    // === RECEPTION EQUIPMENT ===
    
    // HVAC system (large equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'office_hvac',
      description: 'Central HVAC system maintains comfortable office climate.',
      atmosphericDescription: 'This climate control system works tirelessly to maintain perfect office conditions. Large air handlers push conditioned air through the entire floor while return ducts create subtle air currents.',
      position: Vector2(200, 150),
      size: Vector2(80, 60),
      soundRadius: 450,
      soundFile: 'wall-hit-1-100717.mp3',
    ));
    
    // Reception desk phone system (small equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'phone_system',
      description: 'A multi-line phone system occasionally rings.',
      atmosphericDescription: 'This business phone system manages calls for the entire office. Even after hours, it occasionally rings with automated calls, voicemails, and system diagnostics.',
      position: Vector2(150, 200),
      size: Vector2(20, 20),
      soundRadius: 95,
      soundFile: 'click.mp3',
    ));
    
    // Security system panel (small equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'security_panel',
      description: 'A security monitoring panel beeps softly.',
      atmosphericDescription: 'This access control system monitors entry points throughout the building. Status LEDs blink while the system occasionally chirps to confirm its vigilant watch over the facility.',
      position: Vector2(350, 130),
      size: Vector2(25, 15),
      soundRadius: 80,
      soundFile: 'click.mp3',
    ));
  }
  
  void _createOpenOfficeArea() {
    // Open office boundaries (central area)
    add(Wall(position: Vector2(500, 50), size: Vector2(600, 25)));
    add(Wall(position: Vector2(500, 50), size: Vector2(25, 400)));
    add(Wall(position: Vector2(1075, 50), size: Vector2(25, 400)));
    add(Wall(position: Vector2(500, 425), size: Vector2(600, 25)));
    
    // Cubicle dividers (partial walls)
    add(Wall(position: Vector2(650, 100), size: Vector2(100, 15)));
    add(Wall(position: Vector2(650, 200), size: Vector2(100, 15)));
    add(Wall(position: Vector2(650, 300), size: Vector2(100, 15)));
    
    add(Wall(position: Vector2(850, 100), size: Vector2(100, 15)));
    add(Wall(position: Vector2(850, 200), size: Vector2(100, 15)));
    add(Wall(position: Vector2(850, 300), size: Vector2(100, 15)));
    
    // === OPEN OFFICE EQUIPMENT ===
    
    // Workstation cluster 1 (medium equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'workstation_cluster_a',
      description: 'A group of desktop computers work quietly.',
      atmosphericDescription: 'This cluster of workstations hums with productivity. Multiple CPU fans whir while hard drives access data and monitors display screensavers that no one will see until morning.',
      position: Vector2(600, 150),
      size: Vector2(50, 40),
      soundRadius: 180,
      soundFile: 'wall_hit.mp3',
    ));
    
    // Workstation cluster 2 (medium equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'workstation_cluster_b',
      description: 'Another set of computers processes overnight tasks.',
      atmosphericDescription: 'These dedicated machines run automated processes through the night. Cooling fans cycle as processors handle batch jobs and system updates that keep the business running.',
      position: Vector2(800, 250),
      size: Vector2(50, 40),
      soundRadius: 190,
      soundFile: 'wall_hit.mp3',
    ));
    
    // Desk fan (small equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'personal_desk_fan',
      description: 'Someone left a small desk fan running.',
      atmosphericDescription: 'This forgotten desk fan continues its gentle circulation. Its plastic blades cut through the office air with a soft whoosh, a personal touch in an otherwise corporate environment.',
      position: Vector2(950, 180),
      size: Vector2(20, 20),
      soundRadius: 85,
      soundFile: 'wall-hit-cartoon.mp3',
    ));
    
    // Office printer (medium equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'department_printer',
      description: 'A networked printer occasionally springs to life.',
      atmosphericDescription: 'This workhorse printer serves the entire department. Even in the quiet hours, it occasionally warms up for scheduled maintenance or processes delayed print jobs from the network queue.',
      position: Vector2(550, 350),
      size: Vector2(40, 30),
      soundRadius: 150,
      soundFile: 'wall-hit-cartoon.mp3',
    ));
  }
  
  void _createITDepartment() {
    // IT department boundaries (upper right)
    add(Wall(position: Vector2(1150, 50), size: Vector2(350, 25)));
    add(Wall(position: Vector2(1150, 50), size: Vector2(25, 300)));
    add(Wall(position: Vector2(1475, 50), size: Vector2(25, 300)));
    add(Wall(position: Vector2(1150, 325), size: Vector2(350, 25)));
    
    // Server rack area walls
    add(Wall(position: Vector2(1300, 100), size: Vector2(25, 150)));
    add(Wall(position: Vector2(1300, 100), size: Vector2(100, 25)));
    
    // === IT EQUIPMENT ===
    
    // Server rack cluster (large equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'server_farm',
      description: 'A bank of servers maintains company data and services.',
      atmosphericDescription: 'This digital nerve center houses the company\'s entire IT infrastructure. Dozens of servers whir in perfect harmony while network switches blink with constant data traffic. The cooling system works overtime to prevent overheating.',
      position: Vector2(1350, 150),
      size: Vector2(80, 100),
      soundRadius: 420,
      soundFile: 'wall-hit-1-100717.mp3',
    ));
    
    // Network equipment (medium equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'network_equipment',
      description: 'Network switches and routers manage data traffic.',
      atmosphericDescription: 'These network devices route digital traffic throughout the building. Status lights blink rapidly while cooling fans maintain optimal operating temperatures for critical network infrastructure.',
      position: Vector2(1200, 200),
      size: Vector2(60, 40),
      soundRadius: 200,
      soundFile: 'wall_hit.mp3',
    ));
    
    // UPS backup power (medium equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'ups_system',
      description: 'Uninterruptible power supplies protect critical systems.',
      atmosphericDescription: 'These backup power systems stand ready to protect the IT infrastructure from power failures. Internal fans maintain battery temperature while charging circuits occasionally click as they manage power flow.',
      position: Vector2(1250, 280),
      size: Vector2(50, 30),
      soundRadius: 170,
      soundFile: 'click.mp3',
    ));
  }
  
  void _createExecutiveOffices() {
    // Executive office 1
    add(Wall(position: Vector2(300, 500), size: Vector2(200, 25)));
    add(Wall(position: Vector2(300, 500), size: Vector2(25, 150)));
    add(Wall(position: Vector2(475, 500), size: Vector2(25, 150)));
    add(Wall(position: Vector2(300, 625), size: Vector2(200, 25)));
    
    // Executive office 2
    add(Wall(position: Vector2(550, 500), size: Vector2(200, 25)));
    add(Wall(position: Vector2(550, 500), size: Vector2(25, 150)));
    add(Wall(position: Vector2(725, 500), size: Vector2(25, 150)));
    add(Wall(position: Vector2(550, 625), size: Vector2(200, 25)));
    
    // === EXECUTIVE OFFICE EQUIPMENT ===
    
    // Executive workstation (medium equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'executive_computer',
      description: 'A high-end executive workstation processes financial data.',
      atmosphericDescription: 'This powerful machine handles complex financial modeling and executive decision support. Multiple monitors display market data while the system processes real-time analytics.',
      position: Vector2(400, 550),
      size: Vector2(40, 30),
      soundRadius: 160,
      soundFile: 'wall_hit.mp3',
    ));
    
    // Executive coffee machine (small equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'espresso_machine',
      description: 'A premium espresso machine occasionally cycles its heating element.',
      atmosphericDescription: 'This high-end coffee machine maintains perfect brewing temperature around the clock. Steam occasionally hisses from its internal boiler while heating elements click on and off.',
      position: Vector2(650, 580),
      size: Vector2(25, 20),
      soundRadius: 90,
      soundFile: 'wall-hit-cartoon.mp3',
    ));
  }
  
  void _createConferenceRooms() {
    // Large conference room
    add(Wall(position: Vector2(800, 500), size: Vector2(300, 25)));
    add(Wall(position: Vector2(800, 500), size: Vector2(25, 200)));
    add(Wall(position: Vector2(1075, 500), size: Vector2(25, 200)));
    add(Wall(position: Vector2(800, 675), size: Vector2(300, 25)));
    
    // Small meeting room
    add(Wall(position: Vector2(1150, 400), size: Vector2(150, 25)));
    add(Wall(position: Vector2(1150, 400), size: Vector2(25, 100)));
    add(Wall(position: Vector2(1275, 400), size: Vector2(25, 100)));
    add(Wall(position: Vector2(1150, 475), size: Vector2(150, 25)));
    
    // === CONFERENCE ROOM EQUIPMENT ===
    
    // Presentation projector (medium equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'conference_projector',
      description: 'A ceiling-mounted projector maintains standby readiness.',
      atmosphericDescription: 'This presentation system stays ready for important meetings. Its cooling fan runs continuously while the lamp maintains optimal temperature for instant-on capability.',
      position: Vector2(950, 600),
      size: Vector2(40, 30),
      soundRadius: 140,
      soundFile: 'wall-hit-cartoon.mp3',
    ));
    
    // Conference phone system (small equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'conference_phone',
      description: 'A conference phone system occasionally dials automated checks.',
      atmosphericDescription: 'This advanced telephony system enables global business communications. It periodically tests its connection while standby indicators blink to show system readiness.',
      position: Vector2(1200, 440),
      size: Vector2(20, 15),
      soundRadius: 75,
      soundFile: 'click.mp3',
    ));
  }
  
  void _createCopyCenter() {
    // Copy center boundaries
    add(Wall(position: Vector2(50, 800), size: Vector2(300, 25)));
    add(Wall(position: Vector2(50, 800), size: Vector2(25, 200)));
    add(Wall(position: Vector2(325, 800), size: Vector2(25, 200)));
    add(Wall(position: Vector2(50, 975), size: Vector2(300, 25)));
    
    // === COPY CENTER EQUIPMENT ===
    
    // Industrial printer/copier (large equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'industrial_copier',
      description: 'A high-volume copier processes overnight print jobs.',
      atmosphericDescription: 'This production machine handles massive print volumes for the entire company. Multiple paper trays, scanning mechanisms, and finishing equipment create a symphony of precision mechanical sounds.',
      position: Vector2(200, 900),
      size: Vector2(100, 80),
      soundRadius: 380,
      soundFile: 'wall-hit-1-100717.mp3',
    ));
    
    // Paper shredder (medium equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'document_shredder',
      description: 'An industrial document shredder occasionally self-cleans.',
      atmosphericDescription: 'This security device destroys sensitive documents to protect corporate information. Its powerful motor occasionally runs maintenance cycles while safety sensors check for proper operation.',
      position: Vector2(120, 850),
      size: Vector2(40, 30),
      soundRadius: 160,
      soundFile: 'wall-hit-cartoon.mp3',
    ));
  }
  
  void _createBreakRoom() {
    // Break room boundaries
    add(Wall(position: Vector2(400, 800), size: Vector2(250, 25)));
    add(Wall(position: Vector2(400, 800), size: Vector2(25, 150)));
    add(Wall(position: Vector2(625, 800), size: Vector2(25, 150)));
    add(Wall(position: Vector2(400, 925), size: Vector2(250, 25)));
    
    // === BREAK ROOM EQUIPMENT ===
    
    // Refrigerator (medium equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'break_room_refrigerator',
      description: 'A commercial refrigerator maintains food storage temperature.',
      atmosphericDescription: 'This large appliance keeps employee lunches fresh. The compressor cycles on and off while internal fans circulate cold air. Ice makers occasionally drop cubes into collection bins.',
      position: Vector2(450, 850),
      size: Vector2(50, 40),
      soundRadius: 180,
      soundFile: 'wall-hit-cartoon.mp3',
    ));
    
    // Microwave (small equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'microwave_oven',
      description: 'A microwave oven occasionally runs self-cleaning cycles.',
      atmosphericDescription: 'This convenience appliance serves the break room community. Its magnetron occasionally powers up for self-diagnostic cycles while the turntable motor tests its rotation mechanism.',
      position: Vector2(580, 880),
      size: Vector2(25, 20),
      soundRadius: 85,
      soundFile: 'click.mp3',
    ));
    
    // Coffee machine (small equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'coffee_maker',
      description: 'An automatic coffee maker maintains brewing readiness.',
      atmosphericDescription: 'This essential office appliance stays ready to fuel productivity. Water heating elements click on and off while the internal clock prepares for the next automated brewing cycle.',
      position: Vector2(520, 820),
      size: Vector2(20, 15),
      soundRadius: 70,
      soundFile: 'click.mp3',
    ));
  }
  
  void _createOfficeHallways() {
    // === MAIN HALLWAY SYSTEM ===
    
    // Central hallway
    add(Wall(position: Vector2(450, 300), size: Vector2(600, 25)));
    add(Wall(position: Vector2(450, 375), size: Vector2(600, 25)));
    
    // North-south connector
    add(Wall(position: Vector2(250, 300), size: Vector2(25, 200)));
    add(Wall(position: Vector2(375, 300), size: Vector2(25, 200)));
    
    // Secondary hallways
    add(Wall(position: Vector2(700, 700), size: Vector2(400, 25)));
    add(Wall(position: Vector2(700, 775), size: Vector2(400, 25)));
    
    // === HALLWAY ATMOSPHERE ===
    
    // Fluorescent lighting (small equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'hallway_lighting',
      description: 'Fluorescent lights buzz with electrical current.',
      atmosphericDescription: 'These institutional fixtures provide corridor illumination throughout the night. Ballasts buzz softly while the lights occasionally flicker as they age beyond their intended lifespan.',
      position: Vector2(750, 340),
      size: Vector2(15, 15),
      soundRadius: 70,
      soundFile: 'click.mp3',
    ));
    
    // Water fountain (small equipment)
    addObject(GameObject(
      type: GameObjectType.soundSource,
      name: 'water_fountain',
      description: 'A water fountain occasionally cycles its cooling system.',
      atmosphericDescription: 'This convenience fixture provides cold drinking water for employees. Its refrigeration unit occasionally hums to life while water circulation pumps maintain freshness.',
      position: Vector2(900, 740),
      size: Vector2(20, 25),
      soundRadius: 80,
      soundFile: 'pickup.mp3',
    ));
  }
  
  void _placeOfficeItems() {
    // === STRATEGICALLY PLACED OFFICE ITEMS ===
    
    // Reception security badge
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'security_badge',
      description: 'A high-clearance security badge.',
      atmosphericDescription: 'This executive access badge bears the highest security clearance markings. The photo shows "Dr. Sarah Chen - Chief Technology Officer" and the RFID chip still glows with ready status.',
      position: Vector2(180, 220),
      size: Vector2(20, 15),
      pickupRadius: 35,
    ));
    
    // USB drive in IT department
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'encrypted_usb',
      description: 'An encrypted USB drive labeled "BACKUP KEYS".',
      atmosphericDescription: 'This military-grade storage device contains critical security keys. The encryption indicator still blinks green, and a small label reads "Emergency Access Protocols - CTO Authorization Required".',
      position: Vector2(1220, 180),
      size: Vector2(15, 10),
      pickupRadius: 30,
    ));
    
    // Executive keycard in office
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'executive_keycard',
      description: 'An executive keycard for high-security areas.',
      atmosphericDescription: 'This premium access card bears holographic security features and "EXECUTIVE LEVEL" markings. The magnetic stripe appears to be quantum-encrypted for maximum security.',
      position: Vector2(420, 580),
      size: Vector2(25, 15),
      pickupRadius: 40,
    ));
    
    // Meeting notes in conference room
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'meeting_notes',
      description: 'Confidential meeting notes about security protocols.',
      atmosphericDescription: 'These handwritten notes discuss "emergency evacuation procedures" and mention "master override codes stored in executive safe". The letterhead shows this came from the board of directors.',
      position: Vector2(950, 620),
      size: Vector2(20, 15),
      pickupRadius: 35,
    ));
    
    // Maintenance tablet in copy center
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'maintenance_tablet',
      description: 'A tablet containing building maintenance schedules.',
      atmosphericDescription: 'This ruggedized tablet contains the complete building maintenance database. The screen shows recent entries about "emergency exit system updates" and "master key rotation schedule".',
      position: Vector2(150, 920),
      size: Vector2(25, 20),
      pickupRadius: 35,
    ));
    
    // Employee handbook in break room
    addObject(GameObject(
      type: GameObjectType.item,
      name: 'employee_handbook',
      description: 'An employee handbook with emergency procedures.',
      atmosphericDescription: 'This comprehensive guide contains all company policies. A bookmarked section on "Emergency Evacuation" details the location of emergency exits and required access credentials.',
      position: Vector2(480, 870),
      size: Vector2(20, 25),
      pickupRadius: 35,
    ));
    
    // === HEALTH ARTIFACTS IN OFFICE COMPLEX ===
    
    // Corporate wellness supplies in reception
    addObject(GameObject(
      type: GameObjectType.healthArtifact,
      name: 'wellness_station_supplies',
      description: 'Corporate wellness station supplies.',
      atmosphericDescription: 'This premium wellness station was part of the company\'s employee health initiative. It contains high-quality vitamins, stress relief supplements, and energy boosters designed to keep executives performing at peak efficiency.',
      position: Vector2(120, 280),
      size: Vector2(25, 20),
      pickupRadius: 40,
      healingAmount: 30.0,
    ));
    
    // Executive first aid kit
    addObject(GameObject(
      type: GameObjectType.healthArtifact,
      name: 'executive_first_aid',
      description: 'An executive-grade first aid kit.',
      atmosphericDescription: 'This luxury first aid kit was kept in the executive office for VIP medical emergencies. It contains premium medical supplies, including prescription medications and advanced treatment options available only to top-level personnel.',
      position: Vector2(500, 550),
      size: Vector2(30, 25),
      pickupRadius: 40,
      healingAmount: 50.0,
    ));
    
    // Emergency medical cabinet in break room
    addObject(GameObject(
      type: GameObjectType.healthArtifact,
      name: 'emergency_medical_cabinet',
      description: 'An emergency medical supply cabinet.',
      atmosphericDescription: 'This wall-mounted medical cabinet was installed as part of workplace safety regulations. It contains everything needed for common office injuries plus additional supplies for more serious emergencies.',
      position: Vector2(550, 900),
      size: Vector2(25, 30),
      pickupRadius: 40,
      healingAmount: 40.0,
    ));
    
    // === THE FINAL EXIT ===
    
    // Executive emergency exit
    addObject(GameObject(
      type: GameObjectType.door,
      name: 'executive_emergency_exit',
      description: 'A secure emergency exit requiring executive authorization.',
      atmosphericDescription: 'This high-security exit leads directly to the executive parking garage. Multiple authentication systems guard it, but you can hear the hum of ventilation beyond - fresh air and freedom await.',
      position: Vector2(1600, 600),
      size: Vector2(50, 100),
      requiredKey: 'executive_keycard',
    ));
  }
}