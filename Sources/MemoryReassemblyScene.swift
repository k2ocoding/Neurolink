import Foundation

class MemoryReassemblyScene: Scene {
    private let renderer: Renderer
    private let inputHandler: InputHandler
    private var nextSceneToTransition: Scene? = nil
    
    // Game state
    private var memoryFragments: [String] = []
    private var correctOrder: [Int] = []
    private var currentOrder: [Int] = []
    private var selectedIndex: Int = 0
    private var startTime = Date()
    private var timeLeft: TimeInterval = 90
    private var incorrectAttempts = 0
    private var maxIncorrectAttempts = 3
    private var won = false
    private var lost = false
    private var animationPhase = 0
    private var difficulty = 1 // 1-3 scale
    
    init(renderer: Renderer, inputHandler: InputHandler, difficulty: Int = 1) {
        self.renderer = renderer
        self.inputHandler = inputHandler
        self.difficulty = min(3, max(1, difficulty))
        self.timeLeft = 120.0 - Double(difficulty) * 20.0
        self.maxIncorrectAttempts = 5 - difficulty
        self.startTime = Date()
        setupPuzzle()
    }
    
    private func setupPuzzle() {
        // Generate memory fragments based on difficulty
        let fragmentCount = 5 + difficulty * 2
        
        // Create sample fragment content - in a real game, these would be more varied
        let patterns = [
            "0x48A7F1",
            "0xB349EC",
            "0x2DE5C8",
            "0x92F76B",
            "0x5C31D0",
            "0xA18F29", 
            "0x6B72E4",
            "0xF39D1C",
            "0x7E25B8",
            "0x3AF65D",
            "0xD1C84B",
        ]
        
        // Create fragments with sequential data that will make sense when assembled correctly
        memoryFragments = []
        for i in 0..<fragmentCount {
            let basePattern = patterns[i % patterns.count]
            
            // Add position markers that make the correct sequence discoverable
            let prefix = "[\(i+1)/\(fragmentCount)]"
            let content = basePattern + String(format: "%02X", i)
            
            // Create a fragment with some recognizable pattern for ordering
            memoryFragments.append("\(prefix) \(content)")
        }
        
        // Set the correct order (initially sequential)
        correctOrder = Array(0..<fragmentCount)
        
        // Shuffle for player to solve (ensuring it's not already correct)
        repeat {
            currentOrder = correctOrder.shuffled()
        } while currentOrder == correctOrder
        
        selectedIndex = 0
    }
    
    private func checkSolution() -> Bool {
        return currentOrder == correctOrder
    }
    
    private func submitSolution() {
        if checkSolution() {
            won = true
        } else {
            incorrectAttempts += 1
            if incorrectAttempts >= maxIncorrectAttempts {
                lost = true
            }
        }
    }
    
    private func swapFragments(index1: Int, index2: Int) {
        guard index1 >= 0 && index1 < currentOrder.count,
              index2 >= 0 && index2 < currentOrder.count else {
            return
        }
        
        let temp = currentOrder[index1]
        currentOrder[index1] = currentOrder[index2]
        currentOrder[index2] = temp
    }
    
    func handleInput(_ input: Character, gameState: inout GameState) {
        if won || lost {
            if input == " " || input == "\r" {
                // Progress to next scene
                nextSceneToTransition = KeycrackerScene(renderer: renderer, inputHandler: inputHandler)
            } else if input == "r" || input == "R" {
                // Restart puzzle
                setupPuzzle()
                startTime = Date()
                won = false
                lost = false
                incorrectAttempts = 0
            }
            return
        }
        
        switch input {
        case "w", "W": // Up
            selectedIndex = max(0, selectedIndex - 1)
        case "s", "S": // Down
            selectedIndex = min(currentOrder.count - 1, selectedIndex + 1)
        case "a", "A": // Left - move fragment up in order
            if selectedIndex > 0 {
                swapFragments(index1: selectedIndex, index2: selectedIndex - 1)
                selectedIndex -= 1
            }
        case "d", "D": // Right - move fragment down in order
            if selectedIndex < currentOrder.count - 1 {
                swapFragments(index1: selectedIndex, index2: selectedIndex + 1)
                selectedIndex += 1
            }
        case "1", "2", "3", "4", "5", "6", "7", "8", "9":
            // Quick select by number if within range
            let index = Int(String(input))! - 1
            if index >= 0 && index < currentOrder.count {
                selectedIndex = index
            }
        case " ", "\r": // Submit solution
            submitSolution()
        case "r", "R": // Reset puzzle
            setupPuzzle()
            startTime = Date()
            won = false
            lost = false
            incorrectAttempts = 0
        case "q", "Q": // Quit puzzle
            nextSceneToTransition = MainMenuScene(renderer: renderer, inputHandler: inputHandler)
        default:
            break
        }
    }
    
    func update(gameState: inout GameState) {
        if !won && !lost {
            timeLeft = max(0, 120.0 - Double(difficulty) * 20.0 - Date().timeIntervalSince(startTime))
            
            // Check time-based failure
            if timeLeft <= 0 {
                lost = true
            }
        }
        
        // Handle pulsing animation
        animationPhase = (animationPhase + 1) % 30
        
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
            renderer.drawTextCentered(y: 2, text: "MEMORY RECONSTRUCTION COMPLETE", color: successColor)
        } else if lost {
            renderer.drawTextCentered(y: 2, text: "MEMORY RECONSTRUCTION FAILED", color: dangerColor)
        } else {
            renderer.drawTextCentered(y: 2, text: "MEMORY FRAGMENT REASSEMBLY", color: baseColor)
        }
        
        // Instructions
        let instructionY = 3
        if won || lost {
            renderer.drawTextCentered(y: instructionY, text: "Press ENTER to continue, R to restart", color: dimmedColor)
        } else {
            renderer.drawTextCentered(y: instructionY, text: "Rearrange memory fragments into correct sequence", color: dimmedColor)
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
        
        // Calculate fragment list position
        let listX = 10
        let listY = 6
        let listWidth = renderer.terminalWidth - 20
        
        // Draw frame around fragments
        let frameColor = won ? successColor : lost ? dangerColor : baseColor
        renderer.drawBox(x: listX - 2, y: listY - 1, 
                       width: listWidth + 4, height: currentOrder.count + 3, color: frameColor)
        
        // Draw current fragment arrangement
        for i in 0..<currentOrder.count {
            let fragmentIndex = currentOrder[i]
            let fragment = memoryFragments[fragmentIndex]
            
            // Determine color based on selection status
            var color = dimmedColor
            if i == selectedIndex {
                // Pulse animation for selected item
                let pulse = sin(Double(animationPhase) * 0.4) * 0.5 + 0.5
                color = pulse > 0.7 ? selectedColor : highlightColor
            } else if won {
                color = successColor
            }
            
            // Draw fragment
            renderer.drawText(x: listX, y: listY + i, text: "\(i+1). \(fragment)", color: color)
        }
        
        // Controls help
        let controlsY = listY + currentOrder.count + 3
        renderer.drawTextCentered(y: controlsY, text: "↑/↓: Select   ←/→: Reorder   1-9: Quick Select   ENTER: Submit   R: Reset   Q: Quit", color: dimmedColor)
        
        // Status message
        if won {
            renderer.drawTextCentered(y: controlsY + 2, text: "Memory successfully reconstructed!", color: successColor)
            renderer.drawTextCentered(y: controlsY + 3, text: "Data extraction complete: ACCESS_GRANTED", color: successColor)
        } else if lost {
            if timeLeft <= 0 {
                renderer.drawTextCentered(y: controlsY + 2, text: "Time expired - reconstruction failed!", color: dangerColor)
            } else {
                renderer.drawTextCentered(y: controlsY + 2, text: "Too many incorrect attempts - data corrupted!", color: dangerColor)
            }
        } else {
            // Show hint about which parts to look for in the pattern
            renderer.drawTextCentered(y: controlsY + 2, text: "Hint: Read the sequence identifiers carefully", color: baseColor)
        }
    }
    
    func nextScene() -> Scene? {
        return nextSceneToTransition
    }
}