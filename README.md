# Neurolink

A modern text-based puzzle game using Swift's terminal capabilities. This game simulates a cybersecurity infiltration system with various puzzles and challenges.

## Features

- Modern Visual Interface using Unicode symbols and color coding
- Multi-Format Puzzle System including logic networks, memory challenges, and cryptographic puzzles
- Security Bypass Mechanics with simulated hacking challenges
- Format-Shifting Gameplay with different types of challenges
- Progression System where skills gained apply to future obstacles

## How to Run

1. Clone this repository
2. Build the project with Swift:
   ```
   swift build
   ```
3. Run the game:
   ```
   swift run
   ```

## Controls

- Arrow keys or WASD: Navigate menus and puzzles
- ENTER or SPACE: Confirm selections
- ESC or Q: Return to previous screen/menu
- TAB: Access inventory during missions (when implemented)

## Game Flow

1. Main menu allows selecting game mode
2. Tutorial introduces game mechanics
3. Mission briefing provides context
4. Gameplay involves solving various puzzles to progress
5. Different security zones present escalating challenges

## Technical Details

- Built with Swift for terminal environments
- Uses ANSI color codes for visual enhancements
- Custom rendering system for smooth animations
- Terminal-native input handling
- Modular scene system for game flow management