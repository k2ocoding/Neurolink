import Foundation

class LogicPuzzleScene: Scene {
    private let renderer: Renderer
    private let inputHandler: InputHandler
    private var nextSceneToTransition: Scene? = nil
    private var grid: [[Int]] = []
    private var cursorX = 0
    private var cursorY = 0
    private var selectedCell: (Int, Int)? = nil
    private var connectedPaths: [(Int, Int, Int, Int)] = []
    private var solved = false
    private var startTime = Date()
    private var elapsedTime: TimeInterval = 0
    private var nodeValues: [Int: Int] = [:]
    private var nodeOperations: [Int: String] = [:]
    private var targetValue = 0
    
    init(renderer: Renderer, inputHandler: InputHandler) {
        self.renderer = renderer
        self.inputHandler = inputHandler
        self.startTime = Date()
        setupPuzzle()
    }
    
    private func setupPuzzle() {
        // Create a 5x5 grid
        grid = Array(repeating: Array(repeating: 0, count: 5), count: 5)
        
        // Place nodes (1-6)
        let nodePositions = [
            (1, 1), (3, 1),
            (0, 2), (4, 2),
            (1, 3), (3, 3)
        ]
        
        for (i, pos) in nodePositions.enumerated() {
            grid[pos.1][pos.0] = i + 1
        }
        
        // Set node values and operations
        nodeValues = [
            1: 5,
            2: 3,
            3: 8,
            4: 2,
            5: 7,
            6: 4
        ]
        
        // Operations: +, -, *, /
        nodeOperations = [
            1: "+",
            2: "*",
            3: "-",
            4: "/",
            5: "+",
            6: "*"
        ]
        
        // Set target value
        targetValue = 10
    }
    
    private func isValidMove(fromX: Int, fromY: Int, toX: Int, toY: Int) -> Bool {
        // Check if we're connecting from a node
        guard grid[fromY][fromX] > 0 else { return false }
        
        // Check if destination is empty or another node
        if grid[toY][toX] > 0 {
            // Can only connect to another node if directly adjacent
            return abs(fromX - toX) + abs(fromY - toY) == 1
        }
        
        // Check if moving orthogonally
        return (fromX == toX || fromY == toY) && abs(fromX - toX) + abs(fromY - toY) == 1
    }
    
    private func connectCells(fromX: Int, fromY: Int, toX: Int, toY: Int) {
        // Add to connected paths
        connectedPaths.append((fromX, fromY, toX, toY))
        
        // Check if puzzle is solved
        checkSolution()
    }
    
    private func checkSolution() {
        // Build graph from connected paths
        var adjacencyList = [Int: [Int]](minimumCapacity: 6)
        
        for path in connectedPaths {
            let fromCell = grid[path.1][path.0]
            let toCell = grid[path.3][path.2]
            
            // Skip if not connecting two nodes
            guard fromCell > 0 && toCell > 0 else { continue }
            
            // Add to adjacency list
            if adjacencyList[fromCell] == nil {
                adjacencyList[fromCell] = []
            }
            if adjacencyList[toCell] == nil {
                adjacencyList[toCell] = []
            }
            
            // Add bidirectional connection
            if !adjacencyList[fromCell]!.contains(toCell) {
                adjacencyList[fromCell]!.append(toCell)
            }
            if !adjacencyList[toCell]!.contains(fromCell) {
                adjacencyList[toCell]!.append(fromCell)
            }
        }
        
        // Check if we have a connected path that equals the target value
        for startNode in 1...6 {
            var visited = Set<Int>()
            if evaluatePath(from: startNode, visited: &visited, adjacencyList: adjacencyList, currentValue: nodeValues[startNode]!) {
                solved = true
                return
            }
        }
    }
    
    private func evaluatePath(from node: Int, visited: inout Set<Int>, adjacencyList: [Int: [Int]], currentValue: Int) -> Bool {
        // Mark current node as visited
        visited.insert(node)
        
        // Check if we reached the target value
        if currentValue == targetValue && visited.count > 1 {
            return true
        }
        
        // Try all adjacent nodes
        for neighbor in adjacencyList[node] ?? [] {
            if !visited.contains(neighbor) {
                // Calculate new value based on the operation
                let nextValue: Int
                switch nodeOperations[neighbor]! {
                case "+": nextValue = currentValue + nodeValues[neighbor]!
                case "-": nextValue = currentValue - nodeValues[neighbor]!
                case "*": nextValue = currentValue * nodeValues[neighbor]!
                case "/": 
                    if nodeValues[neighbor]! != 0 && currentValue % nodeValues[neighbor]! == 0 {
                        nextValue = currentValue / nodeValues[neighbor]!
                    } else {
                        continue // Skip invalid division
                    }
                default: nextValue = currentValue
                }
                
                if evaluatePath(from: neighbor, visited: &visited, adjacencyList: adjacencyList, currentValue: nextValue) {
                    return true
                }
            }
        }
        
        // Backtrack
        visited.remove(node)
        return false
    }
    
    func handleInput(_ input: Character, gameState: inout GameState) {
        if solved {
            if input == " " || input == "\r" {
                nextSceneToTransition = MemoryPuzzleScene(renderer: renderer, inputHandler: inputHandler)
            }
            return
        }
        
        switch input {
        case "w", "W": // Up 
            cursorY = max(0, cursorY - 1)
        case "s", "S": // Down
            cursorY = min(grid.count - 1, cursorY + 1)
        case "a", "A": // Left
            cursorX = max(0, cursorX - 1)
        case "d", "D": // Right
            cursorX = min(grid[0].count - 1, cursorX + 1)
        case " ", "\r": // Space or Enter - select/connect
            if let selected = selectedCell {
                if isValidMove(fromX: selected.0, fromY: selected.1, toX: cursorX, toY: cursorY) {
                    connectCells(fromX: selected.0, fromY: selected.1, toX: cursorX, toY: cursorY)
                }
                selectedCell = nil // Deselect after attempt
            } else if grid[cursorY][cursorX] > 0 {
                // Select this cell
                selectedCell = (cursorX, cursorY)
            }
        case "r", "R": // Reset puzzle
            connectedPaths = []
            selectedCell = nil
            solved = false
        case "q", "Q": // Quit puzzle
            nextSceneToTransition = MainMenuScene(renderer: renderer, inputHandler: inputHandler)
        default:
            break
        }
    }
    
    func update(gameState: inout GameState) {
        // Update elapsed time
        if !solved {
            elapsedTime = Date().timeIntervalSince(startTime)
        }
        
        // If puzzle is solved, update game state
        if solved {
            gameState.skills[.systemsKnowledge] = (gameState.skills[.systemsKnowledge] ?? 0) + 1
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
        let selectedColor = Renderer.Colors.brightMagenta
        
        // Title and instructions
        if solved {
            renderer.drawTextCentered(y: 2, text: "LOGIC NETWORK ESTABLISHED", color: successColor)
        } else {
            renderer.drawTextCentered(y: 2, text: "LOGIC NETWORK CHALLENGE", color: baseColor)
        }
        
        // Instructions
        let instructionY = 3
        if solved {
            renderer.drawTextCentered(y: instructionY, text: "Press ENTER to continue", color: dimmedColor)
        } else {
            renderer.drawTextCentered(y: instructionY, text: "Connect nodes to reach the target value: \(targetValue)", color: dimmedColor)
        }
        
        // Draw time elapsed
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let timeString = String(format: "Time: %02d:%02d", minutes, seconds)
        renderer.drawText(x: 2, y: 2, text: timeString, color: dimmedColor)
        
        // Calculate grid position
        let cellWidth = 4
        let cellHeight = 2
        let gridWidth = grid[0].count * cellWidth + 1
        let gridHeight = grid.count * cellHeight + 1
        let gridX = (renderer.terminalWidth - gridWidth) / 2
        let gridY = 5
        
        // Draw grid background
        renderer.drawBox(x: gridX - 2, y: gridY - 1, width: gridWidth + 4, height: gridHeight + 2, color: solved ? successColor : baseColor)
        
        // Draw grid cells
        for y in 0..<grid.count {
            for x in 0..<grid[y].count {
                let cellX = gridX + x * cellWidth
                let cellY = gridY + y * cellHeight
                
                // Determine cell color
                var cellColor = dimmedColor
                if (x, y) == (cursorX, cursorY) {
                    cellColor = highlightColor
                } else if let selected = selectedCell, selected == (x, y) {
                    cellColor = selectedColor
                } else if grid[y][x] > 0 {
                    cellColor = baseColor
                }
                
                // Draw cell content
                if grid[y][x] > 0 {
                    let nodeId = grid[y][x]
                    let nodeValue = nodeValues[nodeId] ?? 0
                    let nodeOp = nodeOperations[nodeId] ?? ""
                    let cellText = String(format: "%d%@", nodeValue, nodeOp)
                    renderer.drawText(x: cellX + 1, y: cellY + 0, text: cellText, color: cellColor)
                } else {
                    renderer.drawText(x: cellX + 1, y: cellY + 0, text: "  ", color: cellColor)
                }
            }
        }
        
        // Draw connections
        for (fromX, fromY, toX, toY) in connectedPaths {
            let fromCellX = gridX + fromX * cellWidth + cellWidth/2
            let fromCellY = gridY + fromY * cellHeight + cellHeight/2
            let toCellX = gridX + toX * cellWidth + cellWidth/2
            let toCellY = gridY + toY * cellHeight + cellHeight/2
            
            // Draw line between cells (simplified with characters)
            if fromX == toX {
                // Vertical connection
                let y = min(fromCellY, toCellY)
                renderer.drawText(x: fromCellX, y: y, text: "│", color: dimmedColor)
            } else if fromY == toY {
                // Horizontal connection
                let x = min(fromCellX, toCellX)
                renderer.drawText(x: x, y: fromCellY, text: "─", color: dimmedColor)
            }
        }
        
        // Controls help
        let controlsY = gridY + gridHeight + 2
        renderer.drawTextCentered(y: controlsY, text: "↑/↓/←/→: Move   SPACE: Select/Connect   R: Reset   Q: Quit", color: dimmedColor)
        
        // If solved, show success message
        if solved {
            renderer.drawTextCentered(y: controlsY + 2, text: "Network connection established successfully!", color: successColor)
            renderer.drawTextCentered(y: controlsY + 3, text: "System access granted: ADMIN SECTOR", color: successColor)
        }
    }
    
    func nextScene() -> Scene? {
        return nextSceneToTransition
    }
}

class MemoryPuzzleScene: Scene {
    private let renderer: Renderer
    private let inputHandler: InputHandler
    private var nextSceneToTransition: Scene? = nil
    
    init(renderer: Renderer, inputHandler: InputHandler) {
        self.renderer = renderer
        self.inputHandler = inputHandler
    }
    
    func handleInput(_ input: Character, gameState: inout GameState) {
        // Basic implementation for the example
        if input == "q" || input == "Q" {
            nextSceneToTransition = MainMenuScene(renderer: renderer, inputHandler: inputHandler)
        }
    }
    
    func update(gameState: inout GameState) {
        // Basic implementation for the example
    }
    
    func render(renderer: Renderer) {
        renderWithOpacity(renderer: renderer, opacity: 1.0)
    }
    
    func renderWithOpacity(renderer: Renderer, opacity: Double) {
        let baseColor = Renderer.Colors.brightCyan
        renderer.drawTextCentered(y: 10, text: "Memory Puzzle - This would be the next challenge", color: baseColor)
        renderer.drawTextCentered(y: 12, text: "Press Q to return to the main menu", color: baseColor)
    }
    
    func nextScene() -> Scene? {
        return nextSceneToTransition
    }
}