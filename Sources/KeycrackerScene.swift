import Foundation

class KeycrackerScene: Scene {
    private let renderer: Renderer
    private let inputHandler: InputHandler
    private var nextSceneToTransition: Scene? = nil
    
    // Game state
    private var keyPatterns: [String] = []
    private var targetPatterns: [String] = []
    private var foundPatterns: [Bool] = []
    private var cycling = true
    private var cyclePosition = 0
    private var cycleSpeed: Double
    private var lastCycleTime = Date()
    private var cursorPosition = 0
    private var startTime = Date()
    private var timeLeft: TimeInterval
    private var incorrectAttempts = 0
    private var maxIncorrectAttempts = 5
    private var won = false
    private var lost = false
    private var difficulty = 1 // 1-3 scale
    private var interference = false
    // Track corrupted patterns for restoration
    private var patternRestorations: [(index: Int, pattern: String, time: Date)] = []
    
    init(renderer: Renderer, inputHandler: InputHandler, difficulty: Int = 1) {
        self.renderer = renderer
        self.inputHandler = inputHandler
        self.difficulty = min(3, max(1, difficulty))
        self.timeLeft = 120.0 - Double(difficulty) * 15.0
        self.cycleSpeed = 0.5 - (Double(difficulty) * 0.1)  // Cycle speed in seconds
        self.maxIncorrectAttempts = 6 - difficulty
        self.interference = difficulty >= 2
        self.startTime = Date()
        setupPuzzle()
    }
    
    private func setupPuzzle() {
        // Generate a sequence of random key patterns
        let patternLength = 15 + (difficulty * 5)
        let numTargets = 3 + difficulty
        
        // Generate the main key sequence
        keyPatterns = []
        let characters = "ABCDEF0123456789"
        
        for _ in 0..<patternLength {
            var pattern = ""
            for _ in 0..<8 {
                let randomIndex = Int.random(in: 0..<characters.count)
                let randomChar = characters[characters.index(characters.startIndex, offsetBy: randomIndex)]
                pattern.append(randomChar)
            }
            keyPatterns.append(pattern)
        }
        
        // Generate target patterns that appear in the sequence
        targetPatterns = []
        foundPatterns = []
        
        // Choose random positions in the key pattern to be targets
        var targetPositions = Array(0..<keyPatterns.count)
        targetPositions.shuffle()
        targetPositions = Array(targetPositions.prefix(numTargets))
        
        for position in targetPositions {
            targetPatterns.append(keyPatterns[position])
            foundPatterns.append(false)
        }
        
        cursorPosition = 0
    }
    
    private func checkSelection(index: Int) -> Bool {
        // Get the currently visible pattern
        let visiblePattern = keyPatterns[(cyclePosition + index) % keyPatterns.count]
        
        // Check if this pattern is one of our targets
        if let targetIndex = targetPatterns.firstIndex(of: visiblePattern) {
            if !foundPatterns[targetIndex] {
                foundPatterns[targetIndex] = true
                
                // Check if all patterns found
                if foundPatterns.allSatisfy({ $0 }) {
                    won = true
                }
                
                return true
            }
        }
        
        // Wrong selection
        incorrectAttempts += 1
        if incorrectAttempts >= maxIncorrectAttempts {
            lost = true
        }
        
        return false
    }
    
    func handleInput(_ input: Character, gameState: inout GameState) {
        if won || lost {
            if input == " " || input == "\r" {
                // Progress to next scene
                nextSceneToTransition = MainMenuScene(renderer: renderer, inputHandler: inputHandler)
            } else if input == "r" || input == "R" {
                // Restart puzzle
                setupPuzzle()
                startTime = Date()
                won = false
                lost = false
                incorrectAttempts = 0
                cycling = true
            }
            return
        }
        
        switch input {
        case " ", "\r": // Submit current selection
            _ = checkSelection(index: cursorPosition)
        case "a", "A": // Move cursor left
            cursorPosition = max(0, cursorPosition - 1)
        case "d", "D": // Move cursor right
            cursorPosition = min(4, cursorPosition + 1)
        case "p", "P": // Pause/resume cycling
            cycling = !cycling
        case "1", "2", "3", "4", "5": // Quick select position
            if let pos = Int(String(input)) {
                cursorPosition = pos - 1
                _ = checkSelection(index: cursorPosition)
            }
        case "r", "R": // Reset puzzle
            setupPuzzle()
            startTime = Date()
            won = false
            lost = false
            incorrectAttempts = 0
            cycling = true
        case "q", "Q": // Quit puzzle
            nextSceneToTransition = MainMenuScene(renderer: renderer, inputHandler: inputHandler)
        default:
            break
        }
    }
    
    func update(gameState: inout GameState) {
        if !won && !lost {
            // Update time remaining
            timeLeft = max(0, 120.0 - Double(difficulty) * 15.0 - Date().timeIntervalSince(startTime))
            
            // Check time-based failure
            if timeLeft <= 0 {
                lost = true
            }
            
            // Restore any corrupted patterns that have reached their restoration time
            let now = Date()
            var restoredIndices: [Int] = []
            
            for (i, restoration) in patternRestorations.enumerated() {
                if now.timeIntervalSince(restoration.time) >= 0 {
                    keyPatterns[restoration.index] = restoration.pattern
                    restoredIndices.append(i)
                }
            }
            
            // Remove restored patterns from the tracking array (in reverse to avoid index issues)
            for i in restoredIndices.sorted(by: >) {
                patternRestorations.remove(at: i)
            }
            
            // Update cycling patterns
            if cycling && Date().timeIntervalSince(lastCycleTime) >= cycleSpeed {
                cyclePosition = (cyclePosition + 1) % keyPatterns.count
                lastCycleTime = Date()
                
                // Add interference at higher difficulties
                if interference && Int.random(in: 0...10) < difficulty {
                    // Temporary pattern corruption (will revert on next cycle)
                    let randomIndex = Int.random(in: 0..<keyPatterns.count)
                    let originalPattern = keyPatterns[randomIndex]
                    
                    // Corrupt a few characters
                    var corruptedPattern = originalPattern
                    let corruptPositions = min(3, difficulty + 1)
                    for _ in 0..<corruptPositions {
                        let pos = Int.random(in: 0..<originalPattern.count)
                        let charPos = originalPattern.index(originalPattern.startIndex, offsetBy: pos)
                        corruptedPattern.remove(at: charPos)
                        corruptedPattern.insert("X", at: charPos)
                    }
                    
                    // Store corrupted pattern
                    keyPatterns[randomIndex] = corruptedPattern
                    
                    // Store the pattern for restoration later, avoiding DispatchQueue race conditions
                    patternRestorations.append((
                        index: randomIndex,
                        pattern: originalPattern,
                        time: Date().addingTimeInterval(cycleSpeed)
                    ))
                }
            }
        }
        
        // Update game state if won
        if won {
            gameState.skills[.cryptography] = (gameState.skills[.cryptography] ?? 0) + 1
            gameState.puzzlesSolved += 1
        }
    }
    
    func render(renderer: Renderer) {
        renderWithOpacity(renderer: renderer, opacity: 1.0)
    }
    
    func renderWithOpacity(renderer: Renderer, opacity: Double) {
        let baseColor = Renderer.Colors.brightCyan
        let dimmedColor = Renderer.Colors.cyan
        let highlightColor = Renderer.Colors.brightYellow
        let successColor = Renderer.Colors.brightGreen
        let dangerColor = Renderer.Colors.brightRed
        let selectedColor = Renderer.Colors.brightMagenta
        
        // Title and instructions
        if won {
            renderer.drawTextCentered(y: 2, text: "ENCRYPTION KEY CRACKED", color: successColor)
        } else if lost {
            renderer.drawTextCentered(y: 2, text: "ENCRYPTION LOCKOUT TRIGGERED", color: dangerColor)
        } else {
            renderer.drawTextCentered(y: 2, text: "ENCRYPTION KEYCRACKER", color: baseColor)
        }
        
        // Instructions
        let instructionY = 3
        if won || lost {
            renderer.drawTextCentered(y: instructionY, text: "Press ENTER to continue, R to restart", color: dimmedColor)
        } else {
            renderer.drawTextCentered(y: instructionY, text: "Identify target patterns in the cycling code sequence", color: dimmedColor)
        }
        
        // Draw time remaining
        let minutes = Int(timeLeft) / 60
        let seconds = Int(timeLeft) % 60
        let timeString = String(format: "Time: %02d:%02d", minutes, seconds)
        renderer.drawText(x: 2, y: 2, text: timeString, color: dimmedColor)
        
        // Draw attempts remaining
        let attemptsString = "Attempts: \(maxIncorrectAttempts - incorrectAttempts)/\(maxIncorrectAttempts)"
        renderer.drawText(x: renderer.terminalWidth - attemptsString.count - 2, y: 2, text: attemptsString, 
                        color: incorrectAttempts >= maxIncorrectAttempts - 1 ? dangerColor : dimmedColor)
        
        // Draw target patterns to find
        renderer.drawTextCentered(y: 5, text: "TARGET PATTERNS", color: baseColor)
        
        let targetsX = (renderer.terminalWidth - 12) / 2
        for i in 0..<targetPatterns.count {
            let pattern = targetPatterns[i]
            let patternColor = foundPatterns[i] ? successColor : dimmedColor
            renderer.drawText(x: targetsX, y: 7 + i, text: "\(i+1). \(pattern)", color: patternColor)
        }
        
        // Calculate cycling display position
        let displayY = 12
        let displayX = (renderer.terminalWidth - 50) / 2
        
        // Draw frame around cycling display
        let frameColor = won ? successColor : lost ? dangerColor : baseColor
        renderer.drawBox(x: displayX - 2, y: displayY - 1, width: 54, height: 5, color: frameColor)
        
        // Draw cycling display status
        let statusText = cycling ? "CYCLING" : "PAUSED"
        let statusColor = cycling ? highlightColor : dimmedColor
        renderer.drawText(x: displayX, y: displayY - 1, text: " \(statusText) ", color: statusColor)
        
        // Draw the cycling pattern display
        for i in 0..<5 {
            let patternIndex = (cyclePosition + i) % keyPatterns.count
            let pattern = keyPatterns[patternIndex]
            
            // Determine pattern color
            var patternColor = dimmedColor
            if i == cursorPosition {
                patternColor = selectedColor
            } else if targetPatterns.contains(pattern) {
                // Only highlight unfound target patterns
                if let targetIndex = targetPatterns.firstIndex(of: pattern),
                   !foundPatterns[targetIndex] {
                    patternColor = highlightColor
                }
            }
            
            // Draw box around each pattern
            renderer.drawBox(x: displayX + i * 10, y: displayY, width: 10, height: 3, color: patternColor)
            
            // Draw pattern inside box
            renderer.drawText(x: displayX + i * 10 + 1, y: displayY + 1, text: pattern, color: patternColor)
            
            // Draw selection number below
            renderer.drawText(x: displayX + i * 10 + 4, y: displayY + 3, text: "\(i+1)", color: patternColor)
        }
        
        // Draw cursor indicator
        renderer.drawText(x: displayX + cursorPosition * 10 + 4, y: displayY + 4, text: "^", color: selectedColor)
        
        // Controls help
        let controlsY = displayY + 6
        renderer.drawTextCentered(y: controlsY, text: "←/→: Move   1-5: Select   SPACE: Confirm   P: Pause   R: Reset   Q: Quit", color: dimmedColor)
        
        // Status message
        if won {
            renderer.drawTextCentered(y: controlsY + 2, text: "Encryption key successfully cracked!", color: successColor)
            renderer.drawTextCentered(y: controlsY + 3, text: "Secured data accessed: MISSION COMPLETE", color: successColor)
        } else if lost {
            if timeLeft <= 0 {
                renderer.drawTextCentered(y: controlsY + 2, text: "Time expired - system locked out!", color: dangerColor)
            } else {
                renderer.drawTextCentered(y: controlsY + 2, text: "Too many incorrect attempts - security triggered!", color: dangerColor)
            }
        } else {
            // Show progress
            let found = foundPatterns.filter { $0 }.count
            let total = foundPatterns.count
            renderer.drawTextCentered(y: controlsY + 2, text: "Patterns cracked: \(found)/\(total)", color: baseColor)
        }
        
        // Show difficulty effects
        if interference && difficulty >= 2 && !won && !lost {
            renderer.drawTextCentered(y: controlsY + 3, text: "WARNING: Signal interference detected", color: dangerColor)
        }
    }
    
    func nextScene() -> Scene? {
        return nextSceneToTransition
    }
}