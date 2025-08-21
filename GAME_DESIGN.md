# Dark Room - Game Design Document

## Overview
Dark Room is an audio-centric escape room game where players navigate completely dark environments using only sound, touch, and spatial awareness. Players must escape increasingly complex rooms while avoiding deadly NPCs and solving puzzles through audio cues and item collection.

## Core Concept
- **Genre**: Audio-based puzzle/survival horror
- **Platform**: Cross-platform (iOS, Android, Desktop, Web)
- **Target Audience**: Players seeking unique sensory gaming experiences, accessibility-focused gamers
- **Core Loop**: Explore → Discover → Collect → Escape

## Visual Design Philosophy
The game embraces complete visual deprivation as a core mechanic:
- **Primary Screen**: Completely black during gameplay
- **UI Elements**: Minimal HUD showing only health, inventory, and navigation controls
- **Menu/Progress Screens**: Traditional visual interfaces between levels

## Gameplay Mechanics

### Movement System
- **Desktop**: WASD or arrow keys for directional movement
- **Mobile/Tablet**: Virtual joystick or directional buttons
- **Movement Style**: Continuous movement with optimized collision detection
- **Speed Control**: Multiple movement speeds affecting noise generation
- **Implementation Note**: Collision shortcuts acceptable since layout is invisible to player

### Audio System (Core Gameplay)
- **3D Directional Audio**: Full spatial audio with headphone support
- **Distance-based Volume**: Objects get louder as player approaches
- **Audio Range Design**: Environmental sounds heard only when relatively close, with exceptions for specific long-range objects
- **Sound Categories**:
  - **Environmental**: Object sounds, ambient room tone (close-range detection)
  - **Long-range Objects**: Special objects audible across entire room
  - Large mechanical devices (generators, ventilation systems)
  - Water features (dripping, flowing water)
  - Musical/tonal objects (wind chimes, music boxes)
  - Emergency systems (alarms, beeping devices)
  - Radio broadcasts (music, static, voices)
  - **Interactive**: Pickup sounds, door mechanisms, key insertion
  - **NPC Audio**: Breathing, footsteps, vocalizations
  - **Feedback**: Collision sounds, inventory notifications
  - **Narration**: Character voice describing found items

### Collision & Physics
- **Wall Detection**: Audio/haptic feedback when hitting boundaries
- **Material-Specific Sounds**: Different collision sounds for various surfaces
- **Obstacle Navigation**: Objects block movement but provide audio landmarks

### Inventory System
- **Pickup Mechanism**: Touch/interact with objects to collect
- **Item Discovery**: Voice narration + text description of found items
- **Inventory Display**: Listed in HUD, accessible during gameplay
- **Item Usage**: Context-sensitive use of collected items

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
- **Thief**: Steals random inventory items on contact, causes minor damage
  - *Audio Signature*: Quick scurrying sounds, metallic jingling
- **Stunner**: Temporarily stuns and relocates player to random location, minor damage
  - *Audio Signature*: Electric buzzing, crackling sounds

### NPC Mechanics
- **AI States**: Patrolling, Investigating, Hunting, Attacking
- **Detection Methods**: 
  - Player movement noise
  - Collision sounds
  - Time-based proximity detection
- **Audio Signatures**: Each NPC type has unique sound profile
- **Behavior Variance**: Randomized elements prevent pattern memorization

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
  - Hearing effects have distinct recovery patterns per NPC type
  - Health regenerates slowly over time
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
- **Object Density**: Increasing number of interactive elements
- **Audio Landmarks**: Strategic placement of sound-generating objects
- **Environmental Storytelling**: Room contents suggest narrative context

## User Interface Design

### In-Game HUD (Always Visible)
- **Health Indicator**: Visual health bar or numerical display
- **Inventory List**: Text-based item listing
- **Navigation Controls**: Virtual controls for mobile platforms
- **Objective Hint**: Subtle text reminder of current goal

### Menu Systems
- **Level Select**: Traditional visual interface showing progress
- **Statistics Screen**: Post-level completion stats
- **Settings**: Audio settings, control customization, accessibility options

### Accessibility Features
- **Text-to-Speech**: All UI text readable by screen readers
- **Haptic Feedback**: Controller/mobile vibration for collision and events
- **Audio Settings**: Volume balancing, frequency adjustments
- **Control Remapping**: Customizable input schemes

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

### Level Completion Stats
- **Time to Complete**: Speed-running potential
- **Damage Taken**: Health management skill
- **Items Found**: Exploration thoroughness
- **Detection Events**: Stealth performance
- **Efficiency Rating**: Overall performance score

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

## Open Design Questions

1. **Inventory Limits**: Should carrying capacity be limited?
2. **Save System**: Level-based vs. checkpoint saves?
3. **Multiplayer**: Potential for cooperative gameplay?
4. **Hearing Loss Duration**: How long should Disruptor effects last?
5. **Health Regeneration**: Should health regenerate automatically or require items?
6. **Long-Range Objects**: Which specific objects should be audible across entire room?

## Success Metrics
- **Player Retention**: Level completion rates
- **Accessibility Impact**: Adoption by visually impaired players
- **Audio Quality**: Player feedback on 3D audio effectiveness
- **Difficulty Balance**: Level completion times and frustration indicators

---

*This document is a living design specification and should be updated as development progresses and player feedback is incorporated.*