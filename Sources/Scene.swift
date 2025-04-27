import Foundation

protocol Scene {
    func handleInput(_ input: Character, gameState: inout GameState)
    func update(gameState: inout GameState)
    func render(renderer: Renderer)
    func renderWithOpacity(renderer: Renderer, opacity: Double)
    func nextScene() -> Scene?
}

class GameState {
    var isRunning = true
    var securityLevel = 0
    var skills = [Skill: Int]()
    var inventory = [Item]()
    var completedChallenges = Set<String>()
    var currentLocation = "Entrance"
    var alertLevel = 0.0
    
    // Game progress tracking
    var discoveredLocations = Set<String>()
    var unlockedPaths = Set<String>()
    
    // Game metrics
    var timeElapsed: TimeInterval = 0
    var puzzlesSolved = 0
    var failedAttempts = 0
}

enum Skill {
    case hacking
    case cryptography
    case socialEngineering
    case systemsKnowledge
    case timing
}

struct Item {
    let id: String
    let name: String
    let description: String
    var uses: Int? // nil means unlimited uses
}