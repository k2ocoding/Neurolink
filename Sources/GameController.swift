import Foundation

class GameController {
    private let renderer = Renderer()
    private let inputHandler = InputHandler()
    private var currentScene: Scene?
    private var gameState = GameState()
    
    func start() {
        // Clear terminal and set up environment
        renderer.clearScreen()
        renderer.hideCursor()
        
        // Set up terminal handling
        setupTerminalHandling()
        
        // Show intro
        let intro = IntroScene(renderer: renderer, inputHandler: inputHandler)
        transitionTo(scene: intro)
        
        // Main game loop
        while gameState.isRunning {
            guard let scene = currentScene else {
                gameState.isRunning = false
                break
            }
            
            let frameStartTime = Date()
            
            // Process input
            let input = inputHandler.getInput(timeout: 0.01)
            if let input = input {
                scene.handleInput(input, gameState: &gameState)
            }
            
            // Update scene
            scene.update(gameState: &gameState)
            
            // Render scene
            renderer.beginFrame()
            scene.render(renderer: renderer)
            renderer.endFrame()
            
            // Handle scene transitions
            if let nextScene = scene.nextScene() {
                transitionTo(scene: nextScene)
            }
            
            // Calculate frame time and sleep if needed
            let frameDuration = Date().timeIntervalSince(frameStartTime)
            if frameDuration < 0.016 { // ~60fps
                Thread.sleep(forTimeInterval: 0.016 - frameDuration)
            }
        }
        
        // Clean up
        renderer.showCursor()
        renderer.resetTerminal()
        print("\nNeurolink session terminated.")
    }
    
    private func transitionTo(scene: Scene) {
        // Perform transition animation
        renderer.transition(duration: 0.3) { progress in
            if let currentScene = self.currentScene {
                currentScene.renderWithOpacity(renderer: self.renderer, opacity: 1.0 - progress)
            }
            scene.renderWithOpacity(renderer: self.renderer, opacity: progress)
        }
        
        self.currentScene = scene
    }
    
    private func setupTerminalHandling() {
        // Set up signal handling for clean exit
        signal(SIGINT) { _ in
            // Reset terminal state
            let renderer = Renderer()
            renderer.showCursor()
            renderer.resetTerminal()
            print("\nNeurolink session terminated.")
            exit(0)
        }
    }
}
