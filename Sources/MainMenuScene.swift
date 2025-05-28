import Foundation

class MainMenuScene: Scene {
    private let renderer: Renderer
    private let inputHandler: InputHandler
    private var selectedOption = 0
    private var options = ["Start Mission", "Tutorial", "Settings", "Exit"]
    private var nextSceneToTransition: Scene? = nil
    
    init(renderer: Renderer, inputHandler: InputHandler) {
        self.renderer = renderer
        self.inputHandler = inputHandler
    }
    
    func handleInput(_ input: Character, gameState: inout GameState) {
        switch input {
        case "w", "W": // Up 
            selectedOption = (selectedOption - 1 + options.count) % options.count
        case "s", "S": // Down
            selectedOption = (selectedOption + 1) % options.count
        case "\r", " ": // Enter or Space
            selectCurrentOption(gameState: &gameState)
        case "q", "Q":
            if selectedOption == options.count - 1 { // Exit option
                gameState.isRunning = false
            }
        default:
            break
        }
    }
    
    private func selectCurrentOption(gameState: inout GameState) {
        switch options[selectedOption] {
        case "Start Mission":
            nextSceneToTransition = MissionBriefingScene(renderer: renderer, inputHandler: inputHandler)
        case "Tutorial":
            nextSceneToTransition = TutorialScene(renderer: renderer, inputHandler: inputHandler)
        case "Settings":
            nextSceneToTransition = SettingsScene(renderer: renderer, inputHandler: inputHandler)
        case "Exit":
            gameState.isRunning = false
        default:
            break
        }
    }
    
    func update(gameState: inout GameState) {
        // No update logic needed for menu
    }
    
    func render(renderer: Renderer) {
        renderWithOpacity(renderer: renderer, opacity: 1.0)
    }
    
    func renderWithOpacity(renderer: Renderer, opacity: Double) {
        let baseColor = Renderer.Colors.brightCyan
        let dimmedColor = Renderer.Colors.cyan
        let selectedColor = Renderer.Colors.brightWhite
        
        // Title
        renderer.drawTextCentered(y: 3, text: "NEUROLINK", color: baseColor)
        renderer.drawTextCentered(y: 4, text: "MAIN INTERFACE", color: dimmedColor)
        
        // Menu box
        let boxWidth = 40
        let boxHeight = options.count + 4
        let boxX = (renderer.terminalWidth - boxWidth) / 2
        let boxY = 6
        renderer.drawBox(x: boxX, y: boxY, width: boxWidth, height: boxHeight, title: "SYSTEM MENU", color: baseColor)
        
        // Menu options
        for (index, option) in options.enumerated() {
            let color = index == selectedOption ? selectedColor : dimmedColor
            let prefix = index == selectedOption ? "▶ " : "  "
            let text = prefix + option
            renderer.drawText(x: boxX + 4, y: boxY + 2 + index, text: text, color: color)
        }
        
        // Instructions
        renderer.drawTextCentered(y: boxY + boxHeight + 2, text: "↑/↓: Navigate   ENTER: Select", color: dimmedColor)
        
        // System status
        renderer.drawBox(x: 2, y: renderer.terminalHeight - 6, width: 30, height: 4, title: "SYSTEM STATUS", color: dimmedColor)
        renderer.drawText(x: 4, y: renderer.terminalHeight - 4, text: "Security Level: Normal", color: dimmedColor)
        renderer.drawText(x: 4, y: renderer.terminalHeight - 3, text: "Connection: Secure", color: dimmedColor)
    }
    
    func nextScene() -> Scene? {
        return nextSceneToTransition
    }
}

class TutorialScene: Scene {
    private let renderer: Renderer
    private let inputHandler: InputHandler
    private var tutorialStep = 0
    private var nextSceneToTransition: Scene? = nil
    
    init(renderer: Renderer, inputHandler: InputHandler) {
        self.renderer = renderer
        self.inputHandler = inputHandler
    }
    
    func handleInput(_ input: Character, gameState: inout GameState) {
        if input == " " || input == "\r" {
            tutorialStep += 1
            
            // Exit tutorial after last step
            if tutorialStep >= 5 {
                nextSceneToTransition = MainMenuScene(renderer: renderer, inputHandler: inputHandler)
            }
        } else if input == "q" || input == "Q" {
            nextSceneToTransition = MainMenuScene(renderer: renderer, inputHandler: inputHandler)
        }
    }
    
    func update(gameState: inout GameState) {
        // No additional update logic needed
    }
    
    func render(renderer: Renderer) {
        renderWithOpacity(renderer: renderer, opacity: 1.0)
    }
    
    func renderWithOpacity(renderer: Renderer, opacity: Double) {
        let baseColor = Renderer.Colors.brightCyan
        let dimmedColor = Renderer.Colors.cyan
        let highlightColor = Renderer.Colors.brightYellow
        
        // Title
        renderer.drawTextCentered(y: 2, text: "TUTORIAL", color: baseColor)
        
        // Tutorial content box
        let boxWidth = 60
        let boxHeight = 15
        let boxX = (renderer.terminalWidth - boxWidth) / 2
        let boxY = 4
        renderer.drawBox(x: boxX, y: boxY, width: boxWidth, height: boxHeight, color: baseColor)
        
        // Tutorial content based on step
        let tutorial: [String: [String]] = [
            "0": [
                "WELCOME TO NEUROLINK",
                "",
                "This tutorial will guide you through the basic",
                "mechanics of the Neurolink infiltration system.",
                "",
                "You'll learn how to navigate security systems,",
                "solve various types of puzzles, and manage your",
                "resources during missions."
            ],
            "1": [
                "INTERFACE NAVIGATION",
                "",
                "The Neurolink interface uses keyboard commands:",
                "",
                "↑/↓/←/→ or WASD: Navigate menus and puzzles",
                "ENTER or SPACE: Confirm selections",
                "ESC or Q: Return to previous screen",
                "TAB: Access inventory during missions"
            ],
            "2": [
                "PUZZLE SYSTEMS",
                "",
                "You'll encounter various security challenges:",
                "",
                "◉ Logic Networks: Connect nodes in correct sequence",
                "◉ Code Breaking: Decrypt patterns and sequences",
                "◉ System Override: Time-based input challenges",
                "◉ Privilege Escalation: Multi-stage security bypass"
            ],
            "3": [
                "SECURITY LEVELS",
                "",
                "Security systems have different alert levels:",
                "",
                "GREEN  ᐅ Low security: Multiple attempt access",
                "YELLOW ᐅ Medium: Limited attempts, time restrictions",
                "RED    ᐅ High: Single attempt, may trigger lockdown",
                "",
                "Your alert level increases with failed attempts",
                "and decreases over time with successful operations."
            ],
            "4": [
                "PROGRESSION",
                "",
                "As you complete challenges, you'll gain:",
                "",
                "✦ New skills for approaching future puzzles",
                "✦ Access to deeper security systems",
                "✦ Tools and utilities for your inventory",
                "✦ Information about the facility and its systems",
                "",
                "Good luck, operator."
            ]
        ]
        
        let content = tutorial[String(tutorialStep)] ?? ["Tutorial content not found"]
        
        // Render tutorial content
        for (index, line) in content.enumerated() {
            let color = index == 0 ? highlightColor : dimmedColor
            renderer.drawText(x: boxX + 3, y: boxY + 2 + index, text: line, color: color)
        }
        
        // Navigation hint
        renderer.drawTextCentered(y: boxY + boxHeight + 2, text: "Press ENTER to continue, Q to exit", color: dimmedColor)
        
        // Progress indicators
        let totalSteps = 5
        for i in 0..<totalSteps {
            let indicator = i < tutorialStep ? "●" : (i == tutorialStep ? "○" : "·")
            let indicatorColor = i < tutorialStep ? baseColor : (i == tutorialStep ? highlightColor : dimmedColor)
            renderer.drawText(
                x: (renderer.terminalWidth - totalSteps * 2) / 2 + i * 2, 
                y: boxY + boxHeight + 4, 
                text: indicator, 
                color: indicatorColor
            )
        }
    }
    
    func nextScene() -> Scene? {
        return nextSceneToTransition
    }
}

class SettingsScene: Scene {
    private let renderer: Renderer
    private let inputHandler: InputHandler
    private var selectedOption = 0
    private var options = ["Audio: ON", "Animations: ON", "Difficulty: Normal", "Controls", "Back to Main Menu"]
    private var nextSceneToTransition: Scene? = nil
    
    init(renderer: Renderer, inputHandler: InputHandler) {
        self.renderer = renderer
        self.inputHandler = inputHandler
    }
    
    func handleInput(_ input: Character, gameState: inout GameState) {
        switch input {
        case "w", "W": // Up
            selectedOption = (selectedOption - 1 + options.count) % options.count
        case "s", "S": // Down
            selectedOption = (selectedOption + 1) % options.count
        case "\r", " ": // Enter or Space
            selectCurrentOption()
        case "q", "Q": // Q or Escape
            nextSceneToTransition = MainMenuScene(renderer: renderer, inputHandler: inputHandler)
        default:
            break
        }
    }
    
    private func selectCurrentOption() {
        switch selectedOption {
        case 0: // Audio toggle
            options[0] = options[0].contains("ON") ? "Audio: OFF" : "Audio: ON"
        case 1: // Animations toggle
            options[1] = options[1].contains("ON") ? "Animations: OFF" : "Animations: ON"
        case 2: // Difficulty cycle
            if options[2].contains("Easy") {
                options[2] = "Difficulty: Normal"
            } else if options[2].contains("Normal") {
                options[2] = "Difficulty: Hard"
            } else {
                options[2] = "Difficulty: Easy"
            }
        case 3: // Controls
            // Would show controls screen in full implementation
            break
        case 4: // Back to main menu
            nextSceneToTransition = MainMenuScene(renderer: renderer, inputHandler: inputHandler)
        default:
            break
        }
    }
    
    func update(gameState: inout GameState) {
        // No update logic needed for settings
    }
    
    func render(renderer: Renderer) {
        renderWithOpacity(renderer: renderer, opacity: 1.0)
    }
    
    func renderWithOpacity(renderer: Renderer, opacity: Double) {
        let baseColor = Renderer.Colors.brightCyan
        let dimmedColor = Renderer.Colors.cyan
        let selectedColor = Renderer.Colors.brightWhite
        
        // Title
        renderer.drawTextCentered(y: 3, text: "SETTINGS", color: baseColor)
        
        // Settings box
        let boxWidth = 40
        let boxHeight = options.count + 4
        let boxX = (renderer.terminalWidth - boxWidth) / 2
        let boxY = 6
        renderer.drawBox(x: boxX, y: boxY, width: boxWidth, height: boxHeight, title: "CONFIGURATION", color: baseColor)
        
        // Settings options
        for (index, option) in options.enumerated() {
            let color = index == selectedOption ? selectedColor : dimmedColor
            let prefix = index == selectedOption ? "▶ " : "  "
            let text = prefix + option
            renderer.drawText(x: boxX + 4, y: boxY + 2 + index, text: text, color: color)
        }
        
        // Instructions
        renderer.drawTextCentered(y: boxY + boxHeight + 2, text: "↑/↓: Navigate   ENTER: Select   Q: Back", color: dimmedColor)
    }
    
    func nextScene() -> Scene? {
        return nextSceneToTransition
    }
}

class MissionBriefingScene: Scene {
    private let renderer: Renderer
    private let inputHandler: InputHandler
    private var briefingPage = 0
    private var nextSceneToTransition: Scene? = nil
    private var startTime: Date
    private var textRevealProgress = 0.0
    
    init(renderer: Renderer, inputHandler: InputHandler) {
        self.renderer = renderer
        self.inputHandler = inputHandler
        self.startTime = Date()
    }
    
    func handleInput(_ input: Character, gameState: inout GameState) {
        // Skip text animation if still revealing
        if textRevealProgress < 1.0 {
            textRevealProgress = 1.0
            return
        }
        
        if input == " " || input == "\r" {
            briefingPage += 1
            
            // After last page, go to first puzzle
            if briefingPage >= 3 {
                nextSceneToTransition = LogicPuzzleScene(renderer: renderer, inputHandler: inputHandler)
            } else {
                // Reset text reveal for next page
                textRevealProgress = 0.0
                startTime = Date()
            }
        } else if input == "q" || input == "Q" {
            nextSceneToTransition = MainMenuScene(renderer: renderer, inputHandler: inputHandler)
        }
    }
    
    func update(gameState: inout GameState) {
        // Update text reveal animation
        let elapsed = Date().timeIntervalSince(startTime)
        textRevealProgress = min(1.0, elapsed / 2.0) // 2-second reveal
    }
    
    func render(renderer: Renderer) {
        renderWithOpacity(renderer: renderer, opacity: 1.0)
    }
    
    func renderWithOpacity(renderer: Renderer, opacity: Double) {
        let baseColor = Renderer.Colors.brightCyan
        let dimmedColor = Renderer.Colors.cyan
        let highlightColor = Renderer.Colors.brightYellow
        let warningColor = Renderer.Colors.brightRed
        
        // Title
        renderer.drawTextCentered(y: 2, text: "MISSION BRIEFING", color: baseColor)
        
        // Briefing content box
        let boxWidth = 60
        let boxHeight = 15
        let boxX = (renderer.terminalWidth - boxWidth) / 2
        let boxY = 4
        renderer.drawBox(x: boxX, y: boxY, width: boxWidth, height: boxHeight, color: baseColor)
        
        // Briefing content based on page
        let briefing: [String: [String]] = [
            "0": [
                "OPERATION: SILENT GUARDIAN",
                "",
                "TARGET: Quantum Dynamics Research Facility",
                "OBJECTIVE: Access central database, retrieve Project Nexus files",
                "SECURITY LEVEL: High - Adaptive Systems",
                "",
                "Your mission is to infiltrate the research facility's",
                "network infrastructure and locate classified data",
                "related to Project Nexus. Intelligence suggests the",
                "facility employs multi-layered security protocols",
                "and adaptive countermeasures."
            ],
            "1": [
                "FACILITY LAYOUT",
                "",
                "◉ ENTRANCE ZONE - Basic authentication systems",
                "◉ ADMIN SECTOR - Employee credential verification",
                "◉ R&D DEPARTMENT - Research data archives",
                "◉ SERVER COMPLEX - Central database, highest security",
                "",
                "Each zone utilizes different security approaches.",
                "Expect escalating difficulty as you progress deeper.",
                "Minimize detection to prevent system lockdown."
            ],
            "2": [
                "MISSION PARAMETERS",
                "",
                "✦ TIME FRAME: 30 minutes until security reset",
                "✦ ALERT THRESHOLD: 75% triggers facility lockdown",
                "✦ EXTRACTION: Data must be transmitted to secure uplink",
                "",
                "You've been equipped with basic infiltration tools.",
                "Additional capabilities must be acquired on-site.",
                "",
                "WARNING: Security AI adapts to intrusion patterns.",
                "Vary your approach to avoid pattern recognition.",
                "",
                "Good luck, operator. Commence infiltration."
            ]
        ]
        
        let content = briefing[String(briefingPage)] ?? ["Briefing content not found"]
        
        // Calculate visible text based on reveal progress
        var totalChars = 0
        for line in content {
            totalChars += line.count
        }
        
        let visibleChars = Int(Double(totalChars) * textRevealProgress)
        var remainingChars = visibleChars
        
        // Render briefing content with typewriter effect
        for (index, line) in content.enumerated() {
            let color = index == 0 ? highlightColor : (
                line.contains("WARNING") ? warningColor : dimmedColor
            )
            
            if remainingChars >= line.count {
                // Show full line
                renderer.drawText(x: boxX + 3, y: boxY + 2 + index, text: line, color: color)
                remainingChars -= line.count
            } else if remainingChars > 0 {
                // Show partial line
                let partialLine = String(line.prefix(remainingChars))
                renderer.drawText(x: boxX + 3, y: boxY + 2 + index, text: partialLine, color: color)
                remainingChars = 0
            }
        }
        
        // Navigation hint
        if textRevealProgress >= 1.0 {
            renderer.drawTextCentered(
                y: boxY + boxHeight + 2, 
                text: "Press ENTER to continue, Q to exit", 
                color: dimmedColor
            )
        } else {
            renderer.drawTextCentered(
                y: boxY + boxHeight + 2, 
                text: "Press any key to skip animation", 
                color: dimmedColor
            )
        }
        
        // Progress indicators
        let totalPages = 3
        for i in 0..<totalPages {
            let indicator = i < briefingPage ? "●" : (i == briefingPage ? "○" : "·")
            let indicatorColor = i < briefingPage ? baseColor : (i == briefingPage ? highlightColor : dimmedColor)
            renderer.drawText(
                x: (renderer.terminalWidth - totalPages * 2) / 2 + i * 2, 
                y: boxY + boxHeight + 4, 
                text: indicator, 
                color: indicatorColor
            )
        }
    }
    
    func nextScene() -> Scene? {
        return nextSceneToTransition
    }
}