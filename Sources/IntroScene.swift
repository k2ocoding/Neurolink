import Foundation

class IntroScene: Scene {
    private let renderer: Renderer
    private let inputHandler: InputHandler
    private var animationProgress = 0.0
    private var nextSceneToTransition: Scene? = nil
    private var startTime: Date
    
    init(renderer: Renderer, inputHandler: InputHandler) {
        self.renderer = renderer
        self.inputHandler = inputHandler
        self.startTime = Date()
    }
    
    func handleInput(_ input: Character, gameState: inout GameState) {
        if input == " " || input == "\r" {
            // Skip intro and go to main menu
            nextSceneToTransition = MainMenuScene(renderer: renderer, inputHandler: inputHandler)
        }
    }
    
    func update(gameState: inout GameState) {
        // Update animation progress based on time
        let elapsed = Date().timeIntervalSince(startTime)
        animationProgress = min(1.0, elapsed / 3.0) // 3-second intro
        
        // Auto-transition after intro completes
        if animationProgress >= 1.0 && nextSceneToTransition == nil {
            nextSceneToTransition = MainMenuScene(renderer: renderer, inputHandler: inputHandler)
        }
    }
    
    func render(renderer: Renderer) {
        renderWithOpacity(renderer: renderer, opacity: 1.0)
    }
    
    func renderWithOpacity(renderer: Renderer, opacity: Double) {
        let baseColor = Renderer.Colors.brightCyan
        let dimmedColor = Renderer.Colors.cyan
        let selectedColor = Renderer.Colors.brightWhite
        
        // Calculate a pulsing effect
        let pulseAmount = sin(Date().timeIntervalSince1970 * 4) * 0.5 + 0.5
        
        // Apply opacity to colors through ANSI brightness levels
        let effectiveColor = opacity > 0.7 ? baseColor : dimmedColor
        
        // Title with animated reveal
        let titleText = "NEUROLINK"
        let visibleChars = min(titleText.count, Int(Double(titleText.count) * animationProgress * 1.5))
        let visibleTitle = String(titleText.prefix(visibleChars))
        
        renderer.drawTextCentered(y: 5, text: visibleTitle, color: effectiveColor)
        
        // Subtitle with fade-in effect
        if animationProgress > 0.3 {
            let subtitleOpacity = min(1.0, (animationProgress - 0.3) / 0.4)
            let subtitleColor = opacity * subtitleOpacity > 0.5 ? baseColor : dimmedColor
            renderer.drawTextCentered(y: 7, text: "SYSTEM INFILTRATION PROTOCOL", color: subtitleColor)
        }
        
        // Loading indicator
        if animationProgress < 0.9 {
            let loadingWidth = 30
            let progress = animationProgress / 0.9
            renderer.drawProgressBar(
                x: (renderer.terminalWidth - loadingWidth) / 2,
                y: 10,
                width: loadingWidth,
                progress: progress,
                color: effectiveColor
            )
            
            // Loading text
            let loadingText = "Initializing security protocols..."
            renderer.drawTextCentered(y: 12, text: loadingText, color: dimmedColor)
        } else {
            // Ready message
            renderer.drawTextCentered(y: 10, text: "SYSTEM READY", color: selectedColor)
            
            // Pulsing prompt
            if pulseAmount > 0.5 {
                renderer.drawTextCentered(y: 12, text: "Press ENTER to continue", color: dimmedColor)
            }
        }
        
        // Copyright/version
        let versionInfo = "v1.0.0"
        renderer.drawText(x: 2, y: renderer.terminalHeight - 2, text: versionInfo, color: dimmedColor)
    }
    
    func nextScene() -> Scene? {
        return nextSceneToTransition
    }
}