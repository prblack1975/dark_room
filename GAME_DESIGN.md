# Dark Room - Game Design Document

## Overview
Dark Room is an audio-centric escape room game where players navigate completely dark environments using only sound, touch, and spatial awareness. Players must escape increasingly complex rooms while avoiding deadly NPCs and solving puzzles through audio cues and item collection.

## Core Concept
- **Genre**: Audio-based puzzle/survival horror
- **Platform**: Cross-platform (iOS, Android, Desktop, Web)
- **Target Audience**: Players seeking unique sensory gaming experiences, accessibility-focused gamers
- **Core Loop**: Explore → Discover → Collect → Escape
- **Game Structure**: Level-based progression with self-contained challenges

## Visual Design Philosophy
The game embraces complete visual deprivation as a core mechanic:
- **Primary Screen**: Completely black during gameplay
- **UI Elements**: Minimal HUD showing only health, inventory, and navigation controls. These should be in a dark grey, almost not visible. Health and inventory are configurable.
- **Menu/Progress Screens**: Traditional visual interfaces between levels
- **Debug Mode**: Optional visual overlay for development and accessibility

### Debug Mode Configuration
A toggleable debug visualization mode for development, testing, and accessibility:
- **Toggle Method**: Settings menu option or keyboard shortcut (F3 or D key)
- **Visual Style**: Minimalist wireframe representation
- **Display Elements**:
  - **Player**: Simple white square or circle
  - **Walls**: White lines showing room boundaries
  - **Objects**: Colored boxes (green = items, yellow = interactables, blue = doors)
  - **NPCs**: Red squares/triangles with direction indicators
  - **Sound Sources**: Pulsing circles showing audio range
  - **Grid**: Optional grid overlay for position reference
- **Resolution**: Deliberately low-fi, retro-style graphics (think 1980s vector displays)
- **Transparency**: Semi-transparent overlay allowing darkness to remain visible
- **Performance**: Minimal rendering overhead to maintain audio focus

## Gameplay Mechanics

### Movement System
- **Desktop**: WASD or arrow keys for directional movement
- **Mobile/Tablet**: Virtual joystick or directional buttons
- **Movement Style**: Continuous movement with optimized collision detection
- **Speed Control**: Multiple movement speeds affecting noise generation
- **Implementation Note**: Collision shortcuts acceptable since layout is invisible to player

### Audio System (Core Gameplay)
- **3D Directional Audio**: Full spatial audio with headphone support
- **Always-Playing Sound Sources**: Sound sources continuously play their audio loops at their location
- **Proximity-Based Volume**: All sounds get louder as player approaches, quieter as they move away
- **Wall and Room Attenuation**: Walls and separate rooms reduce sound volume and add muffling effects
- **Variable Sound Ranges**: Not all sounds extend throughout the entire room - each has its own effective radius
- **Sound Categories**:
  - **Environmental Sound Sources**: Continuously playing location-based sounds
    - Small objects (close-range: ~100 units) - music boxes, clocks, small appliances
    - Medium objects (medium-range: ~200 units) - fans, computers, larger machinery
    - Large objects (long-range: ~400+ units) - generators, ventilation systems, water features
    - Radio/broadcast sources - music, static, voices (medium to long-range depending on power)
  - **Interactive Audio**: Triggered by player actions
    - Pickup sounds, door mechanisms, key insertion
    - Collision sounds with walls and objects
  - **NPC Audio**: Dynamic positional audio from moving entities
    - Breathing, footsteps, vocalizations that follow NPC positions
  - **UI Feedback**: Inventory notifications, health status changes
  - **Narration**: Character voice describing found items and situations

### Collision & Physics
- **Wall Detection**: Audio/haptic feedback when hitting boundaries. When about to hit the wall, sound gets extra echo-y
- **Material-Specific Sounds**: Different collision sounds for various surfaces
- **Obstacle Navigation**: Objects block movement but provide audio landmarks

### Inventory System
- **No Carry Limits**: Players can pick up all available items in a level without capacity restrictions
- **Level Item Design**: Each level contains only a few carefully placed items (typically 1-3 items per level)
- **Pickup Mechanism**: Touch/interact with objects to collect
- **Item Discovery**: Voice narration + text description of found items
- **Inventory Display**: Listed in HUD, accessible during gameplay
- **Item Usage**: Context-sensitive use of collected items
- **Level-Specific Items**: Items do not carry between levels - each level is self-contained

### Level Objectives
1. **Basic Escape**: Find and reach the exit door
2. **Key Collection**: Locate specific items to unlock exit
3. **Multi-step Puzzles**: Combine items or perform sequence of actions
4. **Survival Challenges**: Escape while avoiding NPCs

## NPC System (Advanced Levels)

### NPC Types & Behaviors
- **Hunter**: Actively seeks player, moderate speed, instant kill on contact
  - *Audio Signature*: Heavy, rhythmic breathing
- **Stalker**: Slow but relentless, responds to player noise, damage over time, can be escaped
  - *Audio Signature*: Soft footsteps, occasional low growling
- **Berserker**: Fast and aggressive, limited detection range, instant kill on contact
  - *Audio Signature*: Loud grunting, rapid heavy footsteps when charging
- **Phantom**: Unpredictable movement patterns, appears/disappears, damage over time
  - *Audio Signature*: Whispers, fading in/out audio presence
- **Silencer**: Causes complete hearing loss for period, then gradual return, damage over time
  - *Audio Signature*: High-pitched whining sound
- **Deafener**: Causes muffled/reduced audio that slowly clears, damage over time
  - *Audio Signature*: Low rumbling, mechanical grinding
- **Monaural**: Causes complete hearing loss in one ear (stereo), slowly returns, damage over time
  - *Audio Signature*: Sharp clicking sounds, alternating left/right
- **Thief**: Steals random inventory items on contact, causes minor damage. Runs away and hides items.
  - *Audio Signature*: Quick scurrying sounds, metallic jingling
- **Stunner**: Temporarily stuns and relocates player to random location, minor damage
  - *Audio Signature*: Electric buzzing, crackling sounds
- **Silencer**: Just makes all sound go quiet the closer to the NPC. No damage to player
    - *Audio Signature*: No audio

### NPC Mechanics
- **AI States**: Patrolling, Investigating, Hunting, Attacking
- **Detection Methods**: 
  - Player movement noise
  - Collision sounds
  - Time-based proximity detection
  - Some NPCs can see, possibly limited sight range
- **Audio Signatures**: Each NPC type has unique sound profile
- **Behavior Variance**: Randomized elements prevent pattern memorization
- **Effect Duration**: Status effects from NPCs last approximately 10 seconds before recovery begins

### Player-NPC Interaction
- **Stealth System**: Player movement speed affects noise generation
- **Detection Consequences**: Varied based on NPC type:
  - **Instant Kill**: Hunter, Berserker (immediate game over)
  - **Damage Over Time**: Stalker, Phantom, all hearing-loss NPCs (escapable encounters)
  - **Status Effects**: 
    - Silencer (complete hearing loss → gradual return)
    - Deafener (muffled audio → slow clearing)
    - Monaural (one ear silence → gradual return)
    - Thief (random item loss)
    - Stunner (relocation + brief stun)
- **Evasion Options**: Hiding spots, misdirection, temporary concealment
- **Recovery Mechanics**: 
  - Hearing effects have distinct recovery patterns per NPC type (approximately 10 seconds duration)
  - Health does not regenerate over time - only special artifacts can restore health instantly
  - Lost items from Thief are gone permanently (unless found again)

## Level Design Framework

### Difficulty Progression
1. **Tutorial Levels**: Basic movement and audio orientation
2. **Simple Escape**: Single room, no NPCs, clear objective
3. **Item Collection**: Multiple objects required for escape
4. **Maze Navigation**: Complex room layouts with dead ends
5. **NPC Introduction**: Single enemy with predictable behavior
6. **Advanced Survival**: Multiple NPCs, complex objectives

### Room Generation
- **Layout Complexity**: From simple rectangular rooms to complex mazes
- **Minimal Item Design**: Each level contains only essential items (1-3 items typically)
- **Strategic Item Placement**: Items positioned to guide exploration and puzzle-solving
- **Audio Landmarks**: Strategic placement of sound-generating objects
- **Environmental Storytelling**: Room contents suggest narrative context
- **Health Artifacts**: Rare healing items placed strategically for difficulty balance

## User Interface Design

### In-Game HUD (Visible based on configuration)
- **Health Indicator**: Visual health bar or numerical display
- **Inventory List**: Text-based item listing
- **Navigation Controls**: Virtual controls for mobile platforms
- **Objective Hint**: Subtle text reminder of current goal

### Menu Systems
- **Level Select**: Traditional visual interface showing progress
- **Statistics Screen**: Post-level completion stats
- **Settings**: Audio settings, control customization, accessibility options
  - **Debug Mode Toggle**: Enable/disable visual map overlay
  - **Debug Display Options**: Configure which elements to show (grid, sound ranges, etc.)

## Technical Architecture

### Audio Engine Requirements
- **3D Spatial Audio**: Real-time positional audio processing
- **Dynamic Range**: Support for subtle audio cues and dramatic events
- **Platform Optimization**: Efficient audio processing across all targets
- **Headphone Detection**: Enhanced 3D audio when headphones connected

### Performance Considerations
- **Audio Streaming**: Efficient loading of audio assets
- **Memory Management**: Optimized for mobile devices
- **Platform-Specific Features**: Haptic feedback on supporting devices

## Progression & Retention

### Save System
- **Level-Based Saves**: Only level completion and related statistics are saved
- **No Persistent Inventory**: Items do not carry between levels
- **Session Continuity**: Players can resume mid-level if interrupted
- **Statistics Tracking**: Comprehensive performance data saved per level

### Level Completion Stats
- **Time to Complete**: Speed-running potential
- **Damage Taken**: Health management skill
- **Items Found**: Exploration thoroughness
- **Detection Events**: Stealth performance
- **Efficiency Rating**: Overall performance score
- **Health Artifacts Used**: Tracking of healing item usage

### Progression Rewards
- **Level Unlocks**: Sequential level access
- **Achievement System**: Specific challenge completions
- **Leaderboards**: Community competition elements
- **Difficulty Modifiers**: Unlockable challenge modes

## Development Phases

### Phase 1: Core Mechanics
- Basic movement and collision
- 3D audio system implementation
- Simple room navigation
- Basic UI framework

### Phase 2: Content Creation
- Level design tools
- Audio asset pipeline
- Tutorial levels
- Basic escape scenarios

### Phase 3: NPC Implementation
- AI system architecture
- NPC behavior programming
- Audio implementation for enemies
- Balance testing

### Phase 4: Polish & Release
- Cross-platform optimization
- Accessibility testing
- User experience refinement
- Performance optimization

## Future Development Considerations

### Multiplayer Vision
- **Cooperative Mode**: Planned future implementation allowing 2-4 players to collaborate
- **Shared Audio Space**: Multiple players navigating the same dark environment
- **Communication Challenges**: Limited voice chat or proximity-based communication
- **Collaborative Puzzles**: Multi-player specific objectives requiring coordination
- **Architecture Preparation**: Current single-player design considers future multiplayer expansion

### Sound Design Implementation Notes
- **Always-On Audio**: Sound sources never stop playing - they continuously loop their audio at their fixed positions
- **Distance Attenuation**: Volume decreases with distance using realistic 3D audio curves
- **Wall Occlusion**: Walls between player and sound source reduce volume and add low-pass filtering (muffled effect)
- **Room Separation**: Sounds from adjacent rooms are significantly quieter and more muffled
- **Sound Radius Categories**:
  - **Close-range (50-100 units)**: Small personal items, desk objects, small electronics
  - **Medium-range (150-250 units)**: Appliances, moderate machinery, musical instruments  
  - **Long-range (300-500+ units)**: Industrial equipment, HVAC systems, major water features
- **No Manual Activation**: Players never manually turn sounds on/off - all interaction is automatic based on proximity

## Success Metrics
- **Player Retention**: Level completion rates
- **Accessibility Impact**: Adoption by visually impaired players
- **Audio Quality**: Player feedback on 3D audio effectiveness
- **Difficulty Balance**: Level completion times and frustration indicators

---

*This document is a living design specification and should be updated as development progresses and player feedback is incorporated.*