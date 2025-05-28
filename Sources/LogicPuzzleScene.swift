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
    
    // Track the current connected path for sequential connection validation
    private var currentPathNodes: [Int] = [] // Nodes in the current connected path
    
    // State handling
    private var showFailure = false
    private var failureMessage = ""
    private var failureTime: Date? = nil
    private let failureDisplayDuration: TimeInterval = 3.0 // Show failure message for 3 seconds
    private var showVictory = false
    private var victoryTime: Date? = nil
    
    init(renderer: Renderer, inputHandler: InputHandler) {
        self.renderer = renderer
        self.inputHandler = inputHandler
        self.startTime = Date()
        setupPuzzle()
    }
    
    private func setupPuzzle() {
        // Create a 5x5 grid
        grid = Array(repeating: Array(repeating: 0, count: 5), count: 5)
        
        // Place nodes (1-6) in a more complex, non-linear pattern
        // This zigzag layout forces players to think about connection paths
        // and prevents simple straight-line solutions
        let nodePositions = [
            (1, 1),  // Node 1: Top-left area
            (3, 0),  // Node 2: Top-right area
            (0, 3),  // Node 3: Bottom-left area  
            (2, 2),  // Node 4: Center area
            (4, 2),  // Node 5: Right-center area
            (3, 4)   // Node 6: Bottom-right area
        ]
        
        // This creates a scattered zigzag layout like:
        //  0 1 2 3 4
        // 0       2   
        // 1   1       
        // 2       4 5
        // 3 3         
        // 4       6   
        //
        // Multiple possible paths:
        // 1-4-2, 1-4-5, 3-4-5, 3-4-2, 5-4-6, etc.
        
        for (i, pos) in nodePositions.enumerated() {
            grid[pos.1][pos.0] = i + 1
        }
        
        // Set node values and operations for our zigzag layout
        // Values are chosen to create multiple possible solutions
        // while still requiring careful planning
        nodeValues = [
            1: 3,  // Node 1: Value 3, Operation +
            2: 5,  // Node 2: Value 5, Operation *
            3: 4,  // Node 3: Value 4, Operation +
            4: 2,  // Node 4: Value 2, Center node - versatile operation (*)
            5: 6,  // Node 5: Value 6, Operation -
            6: 3   // Node 6: Value 3, Operation /
        ]
        
        // Operations: +, -, *, /
        // With this layout, there are multiple winning paths:
        // 3+ → 2* = (3+2)*5 = 25 (too high)
        // 4+ → 2* → 6- = (4+2)*6-3 = 33 (too high)
        // 4+ → 2* → 5 = (4+2)*5 = 30 (too high)
        // 3+ → 2* → 5- = (3+2)*5-6 = 19 (too high)
        // 6- → 2* → 3+ = (6-2)*3+4 = 16 (just right)
        nodeOperations = [
            1: "+",
            2: "*",
            3: "+",
            4: "*",
            5: "-",
            6: "/"
        ]
        
        // Set target value - this is achievable through several different paths
        // in our new node layout, but requires strategic thinking
        targetValue = 16
        
        // Initialize with cursor in center of grid
        cursorX = 2
        cursorY = 2
    }
    
    private func isValidMove(fromX: Int, fromY: Int, toX: Int, toY: Int) -> Bool {
        // CONNECTION RULE: Orthogonal Only (Up/Down/Left/Right)
        // This function enforces that connections can only be made between
        // nodes that are directly adjacent orthogonally (not diagonally).
        // Manhattan distance must equal 1 for a valid connection.
        
        // Check if we're connecting from a node (source must be a node)
        guard grid[fromY][fromX] > 0 else { return false }
        
        // Check if destination is another node
        if grid[toY][toX] > 0 {
            // CONNECTION VALIDATION: Can only connect to another node if directly adjacent
            // This calculates Manhattan distance and ensures it equals exactly 1
            // (x1-x2) + (y1-y2) = 1 means: one step up, down, left, or right
            return abs(fromX - toX) + abs(fromY - toY) == 1
        }
        
        // For non-node destinations: check if moving orthogonally and adjacent
        // This case is for cursor movement through empty cells, not relevant for node connections
        return (fromX == toX || fromY == toY) && abs(fromX - toX) + abs(fromY - toY) == 1
    }
    
    private func connectCells(fromX: Int, fromY: Int, toX: Int, toY: Int) {
        // Verify these are valid node positions - both must be actual nodes
        guard grid[fromY][fromX] > 0 && grid[toY][toX] > 0 else { 
            print("⚠️ Connection failed: one or both positions are not nodes")
            return 
        }
        
        // Make sure the nodes are orthogonally adjacent (Manhattan distance = 1)
        let manhattanDistance = abs(fromX - toX) + abs(fromY - toY)
        guard manhattanDistance == 1 else {
            print("⚠️ Connection failed: nodes not adjacent, distance = \(manhattanDistance)")
            return
        }
        
        // Get node IDs
        let fromNodeId = grid[fromY][fromX]
        let toNodeId = grid[toY][toX]
        
        // Check if this connection already exists to avoid duplicates
        let connectionExists = connectedPaths.contains { 
            ($0.0 == fromX && $0.1 == fromY && $0.2 == toX && $0.3 == toY) || 
            ($0.0 == toX && $0.1 == toY && $0.2 == fromX && $0.3 == fromY)
        }
        
        if connectionExists {
            print("⚠️ Connection already exists between (\(fromX),\(fromY)) and (\(toX),\(toY))")
            return
        }
        
        // SEQUENTIAL PATH VALIDATION:
        // If this is not the first connection, the fromNode must be the last node in our current path
        if !currentPathNodes.isEmpty && fromNodeId != currentPathNodes.last {
            // The player is trying to start a new branch from a node that's not the last one
            showFailureMessage("Must continue from the last connected node")
            return
        }
        
        // Add to connected paths array for rendering
        connectedPaths.append((fromX, fromY, toX, toY))
        
        // Update our path tracking - add both nodes if this is the first connection
        if currentPathNodes.isEmpty {
            currentPathNodes.append(fromNodeId)
        }
        
        // Always add the destination node to our path
        currentPathNodes.append(toNodeId)
        
        // Print debug info to help trace connection issues
        print("✓ Successfully connected: (\(fromX),\(fromY)) to (\(toX),\(toY))")
        print("→ Current path: \(currentPathNodes)")
        print("→ Total connections: \(connectedPaths.count)")
        
        // Validate the potential calculation
        if let fromValue = nodeValues[fromNodeId], let toValue = nodeValues[toNodeId], 
           let operation = nodeOperations[toNodeId] {
            
            var potentialValue: Int? = nil
            
            // Calculate the result based on the operation
            switch operation {
            case "+":
                potentialValue = fromValue + toValue
                print("→ Calculation: \(fromValue) + \(toValue) = \(fromValue + toValue)")
            case "-":
                potentialValue = fromValue - toValue
                print("→ Calculation: \(fromValue) - \(toValue) = \(fromValue - toValue)")
            case "*":
                potentialValue = fromValue * toValue
                print("→ Calculation: \(fromValue) * \(toValue) = \(fromValue * toValue)")
            case "/":
                if toValue != 0 && fromValue % toValue == 0 {
                    potentialValue = fromValue / toValue
                    print("→ Calculation: \(fromValue) / \(toValue) = \(fromValue / toValue)")
                } else {
                    // Division error
                    showFailureMessage("Invalid division: \(fromValue) / \(toValue)")
                    
                    // Remove the invalid connection
                    if let lastIndex = connectedPaths.lastIndex(where: { $0.0 == fromX && $0.1 == fromY && $0.2 == toX && $0.3 == toY }) {
                        connectedPaths.remove(at: lastIndex)
                    }
                    currentPathNodes.removeLast() // Remove the last added node
                    return
                }
            default:
                break
            }
            
            // Check if we've passed the target value by too much
            if let value = potentialValue, value > targetValue * 2 {
                showFailureMessage("Value too high: \(value) > target")
                
                // Remove the connection that caused the overflow
                if let lastIndex = connectedPaths.lastIndex(where: { $0.0 == fromX && $0.1 == fromY && $0.2 == toX && $0.3 == toY }) {
                    connectedPaths.remove(at: lastIndex)
                }
                currentPathNodes.removeLast() // Remove the last added node
                return
            }
        }
        
        // Check if puzzle is solved with the new connection
        checkSolution()
    }
    
    private func showFailureMessage(_ message: String) {
        showFailure = true
        failureMessage = message
        failureTime = Date()
        
        // Play error sound or provide feedback here if needed
        print("FAILURE: \(message)")
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
                // Solution found - evaluatePath sets solved = true internally
                if solved {
                    // Prepare transition only if we weren't already solved
                    prepareSuccessTransition()
                }
                return
            }
        }
    }
    
    private func prepareSuccessTransition() {
        // Set up transition to next scene
        nextSceneToTransition = MemoryPuzzleScene(renderer: renderer, inputHandler: inputHandler)
    }
    
    private func evaluatePath(from node: Int, visited: inout Set<Int>, adjacencyList: [Int: [Int]], currentValue: Int) -> Bool {
        // Mark current node as visited
        visited.insert(node)
        
        // Check if we reached the target value
        if currentValue == targetValue && visited.count > 1 {
            // Mark as solved immediately when we detect a valid path
            solved = true
            showVictory = true
            victoryTime = Date()
            
            // Store the winning path for highlighting
            print("Puzzle solved! Path: \(visited), Final value: \(currentValue)")
            
            // Prepare for transition but don't force it immediately
            // Let the player see they've won and press Enter to continue
            prepareSuccessTransition()
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
                
                // Check if going over the target would be wasteful
                if nextValue > targetValue * 2 {
                    continue // Skip paths that lead to excessively large values
                }
                
                if evaluatePath(from: neighbor, visited: &visited, adjacencyList: adjacencyList, currentValue: nextValue) {
                    // Make sure our winning path is recorded clearly
                    if solved {
                        return true
                    }
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
                // Ensure we have the next scene ready for transition
                if nextSceneToTransition == nil {
                    prepareSuccessTransition()
                }
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
                // The player has already selected a node and is now trying to connect
                
                // Check if the cursor is on a different node from the selected one
                let onDifferentNode = (selected.0 != cursorX || selected.1 != cursorY) && grid[cursorY][cursorX] > 0
                
                if onDifferentNode {
                    // Player is on a different node - try to complete a connection
                    if isValidMove(fromX: selected.0, fromY: selected.1, toX: cursorX, toY: cursorY) {
                        // Only add the connection if it's between two nodes
                        if grid[selected.1][selected.0] > 0 && grid[cursorY][cursorX] > 0 {
                            // Create visual feedback that connection is being made
                            print("Creating connection: (\(selected.0),\(selected.1)) to (\(cursorX),\(cursorY))")
                            
                            // Add the connection between the selected nodes
                            connectCells(fromX: selected.0, fromY: selected.1, toX: cursorX, toY: cursorY)
                            
                            // Immediately check if we've solved the puzzle
                            if solved {
                                // If we just solved the puzzle, make sure next scene is ready
                                prepareSuccessTransition()
                            }
                            
                            // After successfully connecting, the second node becomes the new selected node
                            // This allows chaining multiple connections
                            selectedCell = (cursorX, cursorY)
                        }
                    } else {
                        // Invalid move - clear selection
                        selectedCell = nil
                    }
                } else if grid[cursorY][cursorX] > 0 {
                    // Player pressed Enter on the same node or another non-adjacent node
                    // Cancel the current selection and select the current node instead
                    selectedCell = (cursorX, cursorY)
                } else {
                    // Player is on an empty cell - deselect
                    selectedCell = nil
                }
            } else if grid[cursorY][cursorX] > 0 {
                // No node was previously selected - select this node if it's a valid one
                selectedCell = (cursorX, cursorY)
            }
        case "r", "R": // Reset puzzle
            connectedPaths = []
            currentPathNodes = []
            selectedCell = nil
            solved = false
            showFailure = false
            showVictory = false
            failureMessage = ""
            failureTime = nil
            victoryTime = nil
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
            
            // Double-check solution on each update cycle
            // This ensures we don't miss any win conditions
            checkSolution()
            
            // Check if we need to clear failure message
            if showFailure, let failTime = failureTime {
                let timeSinceFailure = Date().timeIntervalSince(failTime)
                if timeSinceFailure >= failureDisplayDuration {
                    // Time to hide the failure message
                    showFailure = false
                    failureMessage = ""
                    failureTime = nil
                }
            }
        }
        
        // If puzzle is solved, update game state
        if solved {
            gameState.skills[.systemsKnowledge] = (gameState.skills[.systemsKnowledge] ?? 0) + 1
            gameState.puzzlesSolved += 1
        }
    }
    
    // This function is called once per frame
    func render(renderer: Renderer) {
        // Call the main rendering function with default opacity
        renderWithOpacity(renderer: renderer, opacity: 1.0)
    }
    
    // Main rendering function that draws the entire scene
    func renderWithOpacity(renderer: Renderer, opacity: Double) {
        // CRITICAL: Make sure we properly clear the previous frame to prevent ghosting
        renderer.clearScreen()  // Full screen clear
        renderer.beginFrame()   // Initialize the buffer for this frame
        
        // Define colors for the UI
        let baseColor = Renderer.Colors.brightCyan
        let dimmedColor = Renderer.Colors.cyan
        let highlightColor = Renderer.Colors.brightYellow
        let successColor = Renderer.Colors.brightGreen
        let selectedColor = Renderer.Colors.brightMagenta
        let connectionColor = Renderer.Colors.brightWhite
        let errorColor = Renderer.Colors.brightRed
        
        // Calculate safe text widths to prevent overflow
        let safeMargin = 4 // Wider margin to ensure no text gets cut off
        let maxTextWidth = max(10, renderer.terminalWidth - safeMargin) // Never use width < 10
        let headerWidth = min(maxTextWidth, 40) // Limit headers to 40 chars max
        
        // Debug terminal dimensions to help track UI issues
        print("Terminal dimensions: \(renderer.terminalWidth) x \(renderer.terminalHeight)")
        
        // DRAW HEADER - Single draw only!
        // Choose the appropriate header based on game state
        let headerY = 2
        let subHeaderY = 3
        
        if solved {
            // VICTORY STATE
            renderer.drawTextCentered(y: headerY, text: "LOGIC NETWORK ESTABLISHED", color: successColor)
            renderer.drawTextCentered(y: subHeaderY, text: "Target Value Reached: \(targetValue)", color: successColor)
            renderer.drawTextCentered(y: subHeaderY + 1, text: "Press ENTER to continue", color: dimmedColor)
        } 
        else if showFailure {
            // FAILURE STATE  
            renderer.drawTextCentered(y: headerY, text: "LOGIC NETWORK CHALLENGE", color: baseColor)
            
            // Truncate error message if needed
            let errorMsg = "Error: \(failureMessage)"
            let safeMsg = errorMsg.count > maxTextWidth ? String(errorMsg.prefix(maxTextWidth-3)) + "..." : errorMsg
            renderer.drawTextCentered(y: subHeaderY, text: safeMsg, color: errorColor)
            
            renderer.drawTextCentered(y: subHeaderY + 1, text: "Press R to reset", color: dimmedColor)
        } 
        else {
            // NORMAL GAMEPLAY STATE
            renderer.drawTextCentered(y: headerY, text: "LOGIC NETWORK CHALLENGE", color: baseColor)
            
            // Truncate instruction if needed
            let instruction = "Connect nodes to reach: \(targetValue)"
            let safeInstruction = instruction.count > maxTextWidth ? String(instruction.prefix(maxTextWidth-3)) + "..." : instruction
            renderer.drawTextCentered(y: subHeaderY, text: safeInstruction, color: dimmedColor)
        }
        
        // --- TIMER DISPLAY ---
        // Draw time elapsed in top-left corner, only if we have enough space
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let timeString = String(format: "Time: %02d:%02d", minutes, seconds)
        
        // Calculate if there's enough space to draw the timer without overlapping the title
        let timeX = 3 // Safe margin from left edge
        let titleXStart = (renderer.terminalWidth - headerWidth) / 2
        
        // Only draw time if it won't overlap with the centered title
        if timeX + timeString.count < titleXStart - 1 {
            renderer.drawText(x: timeX, y: 2, text: timeString, color: dimmedColor)
        }
        
        // --- GRID LAYOUT ---
        // Calculate grid position - ensure it's centered properly
        let cellWidth = 4
        let cellHeight = 2
        let gridWidth = grid[0].count * cellWidth + 1
        let gridHeight = grid.count * cellHeight + 1
        
        // Make sure grid fits within terminal width
        let gridX = max(3, (renderer.terminalWidth - gridWidth) / 2)
        let gridY = 6 // Move grid down slightly to avoid overlapping with header text
        
        // Draw grid background box - make sure dimensions are correct and match the grid
        let gridBoxWidth = gridWidth + 4
        let gridBoxHeight = gridHeight + 2
        if gridX + gridBoxWidth <= renderer.terminalWidth && gridY + gridBoxHeight <= renderer.terminalHeight {
            renderer.drawBox(
                x: gridX - 2, 
                y: gridY - 1, 
                width: gridBoxWidth, 
                height: gridBoxHeight, 
                color: solved ? successColor : baseColor
            )
        }
        
        // --- CONNECTION LINES ---
        // Draw connections FIRST so nodes will appear on top
        // This is crucial for proper layering
        
        // Debug the current connections
        print("Drawing \(connectedPaths.count) connections")
        renderer.drawText(x: gridX, y: gridY - 2, text: "Connections: \(connectedPaths.count)", color: dimmedColor)
        
        for (index, connection) in connectedPaths.enumerated() {
            let (fromX, fromY, toX, toY) = connection
            
            // Double check these are valid node positions to connect
            guard grid[fromY][fromX] > 0 && grid[toY][toX] > 0 else {
                print("Skipping invalid connection \(index): (\(fromX),\(fromY)) to (\(toX),\(toY))")
                continue 
            }
            
            // Debug information
            print("Drawing connection \(index): (\(fromX),\(fromY)) to (\(toX),\(toY))")
            
            // Calculate the precise screen coordinates for each node
            // We need to find the exact center points for proper line drawing
            let fromCellX = gridX + fromX * cellWidth
            let fromCellY = gridY + fromY * cellHeight
            let toCellX = gridX + toX * cellWidth
            let toCellY = gridY + toY * cellHeight
            
            // Vertical connection (nodes in same column)
            if fromX == toX {
                // Get center X and range of Y coordinates
                let lineX = fromCellX + cellWidth/2 // Center of the cell horizontally
                let minY = min(fromCellY, toCellY) + 1 // Start below top cell
                let maxY = max(fromCellY, toCellY) // End at bottom cell
                
                // Draw vertical line segment - make sure every position gets a character
                for y in minY..<maxY {
                    renderer.drawText(x: lineX, y: y, text: "│", color: connectionColor)
                }
                
                // Debug output
                print("  Drew vertical line at x=\(lineX) from y=\(minY) to y=\(maxY)")
            } 
            // Horizontal connection (nodes in same row)
            else if fromY == toY {
                // Get center Y and range of X coordinates
                let lineY = fromCellY + 0 // Align to top of cell where values are
                let minX = min(fromCellX, toCellX) + 1 // Start after left cell
                let maxX = max(fromCellX, toCellX) + cellWidth/2 // End at center of right cell
                
                // Draw horizontal line segment - ensure full coverage
                for x in minX..<maxX {
                    renderer.drawText(x: x, y: lineY, text: "─", color: connectionColor)
                }
                
                // Debug output
                print("  Drew horizontal line at y=\(lineY) from x=\(minX) to x=\(maxX)")
            }
        }
        
        // --- GRID CELL RENDERING ---
        // Draw all grid cells (nodes and empty spaces)
        for y in 0..<grid.count {
            for x in 0..<grid[y].count {
                let cellX = gridX + x * cellWidth
                let cellY = gridY + y * cellHeight
                
                // Skip if cell would be drawn outside the terminal
                if cellX < 0 || cellX >= renderer.terminalWidth || 
                   cellY < 0 || cellY >= renderer.terminalHeight {
                    continue
                }
                
                // Determine cell color based on state
                var cellColor = dimmedColor
                var cellBorderColor: String? = nil
                
                // Logic for determining highlight colors
                let isSelected = selectedCell != nil && selectedCell! == (x, y)
                let isCursor = (x, y) == (cursorX, cursorY)
                let isNode = grid[y][x] > 0
                let nodeId = isNode ? grid[y][x] : 0
                
                // Color priority: selected > cursor > normal node
                if isSelected {
                    cellColor = selectedColor
                    cellBorderColor = selectedColor
                } else if isCursor {
                    cellColor = highlightColor
                    cellBorderColor = highlightColor
                } else if isNode {
                    // Part of a connected path?
                    let isPartOfPath = currentPathNodes.contains(nodeId)
                    cellColor = isPartOfPath ? connectionColor : baseColor
                }
                
                // Different rendering for nodes vs empty cells
                if isNode {
                    // This is a node - get its value and operation
                    let nodeValue = nodeValues[nodeId] ?? 0
                    let nodeOp = nodeOperations[nodeId] ?? ""
                    let nodeText = String(format: "%d%@", nodeValue, nodeOp)
                    
                    // Add a node ID for clarity
                    let nodeIdText = String(format: "[%d]", nodeId)
                    
                    // Draw highlight box if node is selected or has cursor
                    if cellBorderColor != nil {
                        let boxChar = isSelected ? "★" : "◆"
                        renderer.drawText(x: cellX, y: cellY, text: boxChar, color: cellBorderColor!)
                    }
                    
                    // Draw the node value in the appropriate color
                    renderer.drawText(x: cellX + 1, y: cellY, text: nodeText, color: cellColor)
                    
                    // Draw small node ID below if space allows
                    if cellY + 1 < renderer.terminalHeight {
                        renderer.drawText(x: cellX + 1, y: cellY + 1, text: nodeIdText, color: dimmedColor)
                    }
                } else {
                    // Empty cell - just show cursor if applicable
                    if isCursor {
                        renderer.drawText(x: cellX + 1, y: cellY, text: "◎", color: highlightColor)
                    } else {
                        // Truly empty
                        renderer.drawText(x: cellX + 1, y: cellY, text: "  ", color: dimmedColor)
                    }
                }
            }
        }
        
        // Controls help - more vertically formatted for better readability
        let controlsY = gridY + gridHeight + 2
        
        // Draw a box around the controls to make them stand out
        let controlsBoxWidth = 40
        let controlsBoxHeight = 3
        let controlsBoxX = (renderer.terminalWidth - controlsBoxWidth) / 2
        
        if controlsBoxX > 0 && controlsBoxX + controlsBoxWidth < renderer.terminalWidth {
            renderer.drawBox(x: controlsBoxX, y: controlsY, width: controlsBoxWidth, height: controlsBoxHeight, color: dimmedColor)
            
            // More concise controls
            let navigateText = "WASD/←↑↓→: Navigate"
            let connectText = "SPACE/ENTER: Connect nodes"
            let resetText = "R: Reset   Q: Quit"
            
            renderer.drawTextCentered(y: controlsY + 1, text: "\(navigateText)  \(connectText)  \(resetText)", color: dimmedColor)
        }
        
        // Status messages with more details based on game state
        if solved {
            renderer.drawTextCentered(y: controlsY + 4, text: "◈ Network connection established successfully! ◈", color: successColor)
            renderer.drawTextCentered(y: controlsY + 5, text: "System access granted: ADMIN SECTOR", color: successColor)
        } else if !showFailure && !currentPathNodes.isEmpty {
            // Show current path progress
            let pathInfo = "Current path: " + currentPathNodes.map { String($0) }.joined(separator: " → ")
            let truncatedPath = pathInfo.count > maxTextWidth ? String(pathInfo.prefix(maxTextWidth)) + "..." : pathInfo
            renderer.drawTextCentered(y: controlsY + 4, text: truncatedPath, color: baseColor)
        }
        
        // Always call endFrame at the end of rendering to ensure the frame is properly displayed
        // This is crucial for preventing flickering and visual artifacts
        renderer.endFrame()
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
        // Properly clear the screen and setup the frame buffer
        renderer.clearScreen()
        renderer.beginFrame()
        
        let baseColor = Renderer.Colors.brightCyan
        renderer.drawTextCentered(y: 10, text: "Memory Puzzle - This would be the next challenge", color: baseColor)
        renderer.drawTextCentered(y: 12, text: "Press Q to return to the main menu", color: baseColor)
        
        // Ensure we end the frame properly to prevent artifacts
        renderer.endFrame()
    }
    
    func nextScene() -> Scene? {
        return nextSceneToTransition
    }
}