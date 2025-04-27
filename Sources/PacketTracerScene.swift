import Foundation

class PacketTracerScene: Scene {
    private let renderer: Renderer
    private let inputHandler: InputHandler
    private var nextSceneToTransition: Scene? = nil
    
    // Game state
    private var grid: [[Character]] = []
    private var packets: [(x: Int, y: Int, targetX: Int, targetY: Int, delivered: Bool)] = []
    private var cursorX = 0
    private var cursorY = 0
    private var securityNodes: [(x: Int, y: Int, radius: Int, active: Bool)] = []
    private var routerNodes: [(x: Int, y: Int)] = []
    private var detectionLevel: Double = 0.0
    private var startTime = Date()
    private var timeLeft: TimeInterval = 60 // 60 seconds by default
    private var won = false
    private var lost = false
    private var selectedRouterIndex: Int? = nil
    private var difficulty = 1 // 1-3 for easy, medium, hard
    
    init(renderer: Renderer, inputHandler: InputHandler, difficulty: Int = 1) {
        self.renderer = renderer
        self.inputHandler = inputHandler
        self.difficulty = min(3, max(1, difficulty))
        self.timeLeft = 90.0 - Double(difficulty) * 15.0 // Adjust time based on difficulty
        self.startTime = Date()
        setupGame()
    }
    
    private func setupGame() {
        // Create a grid of appropriate size
        let gridSize = 10 + (difficulty * 2) // Larger grid for higher difficulties
        grid = Array(repeating: Array(repeating: " ", count: gridSize), count: gridSize)
        
        // Place routers - more routers for higher difficulties
        let routerCount = 5 + difficulty * 2
        routerNodes = []
        
        for _ in 0..<routerCount {
            let x = Int.random(in: 1..<gridSize-1)
            let y = Int.random(in: 1..<gridSize-1)
            routerNodes.append((x, y))
            grid[y][x] = "R"
        }
        
        // Place security nodes - more security for higher difficulties
        let securityCount = 2 + difficulty
        securityNodes = []
        
        for _ in 0..<securityCount {
            var x, y: Int
            repeat {
                x = Int.random(in: 1..<gridSize-1)
                y = Int.random(in: 1..<gridSize-1)
            } while grid[y][x] != " " || isNearRouter(x: x, y: y, distance: 3)
            
            securityNodes.append((x, y, 2 + difficulty, true))
            grid[y][x] = "S"
        }
        
        // Create data packets - more packets for higher difficulties
        let packetCount = 3 + difficulty
        packets = []
        
        for _ in 0..<packetCount {
            // Source position - edge of grid
            let sourceEdge = Int.random(in: 0...3) // 0: top, 1: right, 2: bottom, 3: left
            let sourceX, sourceY: Int
            
            switch sourceEdge {
            case 0: // Top edge
                sourceX = Int.random(in: 1..<gridSize-1)
                sourceY = 0
            case 1: // Right edge
                sourceX = gridSize - 1
                sourceY = Int.random(in: 1..<gridSize-1)
            case 2: // Bottom edge
                sourceX = Int.random(in: 1..<gridSize-1)
                sourceY = gridSize - 1
            default: // Left edge
                sourceX = 0
                sourceY = Int.random(in: 1..<gridSize-1)
            }
            
            // Target position - opposite edge
            let targetEdge = (sourceEdge + 2) % 4
            let targetX, targetY: Int
            
            switch targetEdge {
            case 0: // Top edge
                targetX = Int.random(in: 1..<gridSize-1)
                targetY = 0
            case 1: // Right edge
                targetX = gridSize - 1
                targetY = Int.random(in: 1..<gridSize-1)
            case 2: // Bottom edge
                targetX = Int.random(in: 1..<gridSize-1)
                targetY = gridSize - 1
            default: // Left edge
                targetX = 0
                targetY = Int.random(in: 1..<gridSize-1)
            }
            
            packets.append((sourceX, sourceY, targetX, targetY, false))
            // Mark source and target on grid
            grid[sourceY][sourceX] = "P"
            grid[targetY][targetX] = "T"
        }
        
        // Place cursor near the center
        cursorX = gridSize / 2
        cursorY = gridSize / 2
    }
    
    private func isNearRouter(x: Int, y: Int, distance: Int) -> Bool {
        for router in routerNodes {
            let dx = abs(router.x - x)
            let dy = abs(router.y - y)
            if dx <= distance && dy <= distance {
                return true
            }
        }
        return false
    }
    
    private func movePackets() {
        // For each packet that isn't delivered yet
        for i in 0..<packets.count where !packets[i].delivered {
            let packet = packets[i]
            
            // If packet is at destination, mark as delivered
            if packet.x == packet.targetX && packet.y == packet.targetY {
                packets[i].delivered = true
                continue
            }
            
            // Find closest router to the packet
            var closestRouterIdx = -1
            var minDistance = Int.max
            
            for (idx, router) in routerNodes.enumerated() {
                // Skip deactivated routers
                if selectedRouterIndex == idx {
                    continue
                }
                
                let distance = abs(router.x - packet.x) + abs(router.y - packet.y)
                
                if distance < minDistance {
                    minDistance = distance
                    closestRouterIdx = idx
                }
            }
            
            // Move packet toward closest router or target if no router is available
            var nextX = packet.x
            var nextY = packet.y
            
            if closestRouterIdx >= 0 {
                let router = routerNodes[closestRouterIdx]
                // Move toward router
                if router.x > packet.x { nextX += 1 }
                else if router.x < packet.x { nextX -= 1 }
                else if router.y > packet.y { nextY += 1 }
                else if router.y < packet.y { nextY -= 1 }
            } else {
                // Move toward target
                if packet.targetX > packet.x { nextX += 1 }
                else if packet.targetX < packet.x { nextX -= 1 }
                else if packet.targetY > packet.y { nextY += 1 }
                else if packet.targetY < packet.y { nextY -= 1 }
            }
            
            // Update packet position
            packets[i].x = nextX
            packets[i].y = nextY
            
            // Check if packet is in detection range of any security node
            for security in securityNodes where security.active {
                let dx = abs(security.x - nextX)
                let dy = abs(security.y - nextY)
                let inRange = dx*dx + dy*dy <= security.radius*security.radius
                
                if inRange {
                    detectionLevel += 5.0 * Double(difficulty) / 100.0 // Increase detection level
                }
            }
        }
        
        // Check win/lose conditions
        if packets.allSatisfy({ $0.delivered }) {
            won = true
        }
        
        if detectionLevel >= 1.0 || timeLeft <= 0 {
            lost = true
        }
    }
    
    func handleInput(_ input: Character, gameState: inout GameState) {
        if won || lost {
            if input == " " || input == "\r" {
                // Progress to next scene on Enter/Space when game is over
                nextSceneToTransition = MainMenuScene(renderer: renderer, inputHandler: inputHandler)
                return
            } else if input == "r" || input == "R" {
                // Restart on R when game is over
                setupGame()
                detectionLevel = 0.0
                timeLeft = 90.0 - Double(difficulty) * 15.0
                startTime = Date()
                won = false
                lost = false
                selectedRouterIndex = nil
                return
            }
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
        case " ", "\r": // Space or Enter - toggle router
            // Check if cursor is on a router
            for (idx, router) in routerNodes.enumerated() {
                if router.x == cursorX && router.y == cursorY {
                    // Toggle router selection
                    if selectedRouterIndex == idx {
                        selectedRouterIndex = nil
                    } else {
                        selectedRouterIndex = idx
                    }
                    break
                }
            }
        case "1", "2", "3", "4", "5", "6", "7", "8", "9":
            // Quick select routers by number (if within range)
            let idx = Int(String(input))! - 1
            if idx >= 0 && idx < routerNodes.count {
                if selectedRouterIndex == idx {
                    selectedRouterIndex = nil
                } else {
                    selectedRouterIndex = idx
                }
                
                // Move cursor to the selected router
                cursorX = routerNodes[idx].x
                cursorY = routerNodes[idx].y
            }
        case "q", "Q": // Quit puzzle
            nextSceneToTransition = MainMenuScene(renderer: renderer, inputHandler: inputHandler)
        case "r", "R": // Reset puzzle
            setupGame()
            detectionLevel = 0.0
            timeLeft = 90.0 - Double(difficulty) * 15.0
            startTime = Date()
            won = false
            lost = false
            selectedRouterIndex = nil
        default:
            break
        }
    }
    
    func update(gameState: inout GameState) {
        // Update time remaining
        if !won && !lost {
            timeLeft = max(0, 90.0 - Double(difficulty) * 15.0 - Date().timeIntervalSince(startTime))
            
            // Move packets every few updates (based on difficulty)
            if Int(Date().timeIntervalSince1970 * 1000) % (500 - difficulty * 100) == 0 {
                movePackets()
            }
            
            // Gradually decrease detection level over time
            detectionLevel = max(0, detectionLevel - 0.001)
        }
        
        // Update game state if won
        if won {
            gameState.skills[.hacking] = (gameState.skills[.hacking] ?? 0) + 1
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
        let packetColor = Renderer.Colors.brightBlue
        
        // Title and instructions
        if won {
            renderer.drawTextCentered(y: 2, text: "DATA PACKETS DELIVERED SUCCESSFULLY", color: successColor)
        } else if lost {
            renderer.drawTextCentered(y: 2, text: "MISSION FAILED - DETECTION LEVEL CRITICAL", color: dangerColor)
        } else {
            renderer.drawTextCentered(y: 2, text: "NETWORK PACKET TRACER", color: baseColor)
        }
        
        // Instructions
        let instructionY = 3
        if won || lost {
            renderer.drawTextCentered(y: instructionY, text: "Press ENTER to continue, R to restart", color: dimmedColor)
        } else {
            renderer.drawTextCentered(y: instructionY, text: "Route data packets to destinations while avoiding security detection", color: dimmedColor)
        }
        
        // Draw time remaining
        let minutes = Int(timeLeft) / 60
        let seconds = Int(timeLeft) % 60
        let timeString = String(format: "Time: %02d:%02d", minutes, seconds)
        renderer.drawText(x: 2, y: 2, text: timeString, color: dimmedColor)
        
        // Draw detection level
        let detectionString = "Detection: "
        renderer.drawText(x: 2, y: 3, text: detectionString, color: dimmedColor)
        let detectionBarWidth = 20
        let detectionColor = detectionLevel < 0.7 ? dimmedColor : 
                            detectionLevel < 0.9 ? Renderer.Colors.yellow : dangerColor
        renderer.drawProgressBar(x: 2 + detectionString.count, y: 3, width: detectionBarWidth, 
                               progress: detectionLevel, color: detectionColor)
        
        // Calculate grid position
        let cellWidth = 3
        let cellHeight = 1
        let gridWidth = grid[0].count * cellWidth + 1
        let gridHeight = grid.count * cellHeight + 1
        let gridX = (renderer.terminalWidth - gridWidth) / 2
        let gridY = 5
        
        // Draw grid background
        let gridBorderColor = won ? successColor : lost ? dangerColor : baseColor
        renderer.drawBox(x: gridX - 2, y: gridY - 1, width: gridWidth + 4, height: gridHeight + 2, color: gridBorderColor)
        
        // Draw grid cells
        for y in 0..<grid.count {
            for x in 0..<grid[0].count {
                let cellX = gridX + x * cellWidth
                let cellY = gridY + y * cellHeight
                
                // Determine cell content and color
                var cellContent = " "
                var cellColor = dimmedColor
                
                // Draw cell content based on what's in the cell
                if let routerIndex = routerNodes.firstIndex(where: { $0.x == x && $0.y == y }) {
                    cellContent = "R\(routerIndex+1)"
                    if selectedRouterIndex == routerIndex {
                        cellColor = selectedColor
                    } else if (x, y) == (cursorX, cursorY) {
                        cellColor = highlightColor
                    } else {
                        cellColor = baseColor
                    }
                } else if let securityIndex = securityNodes.firstIndex(where: { $0.x == x && $0.y == y }) {
                    cellContent = "S"
                    cellColor = dangerColor
                } else if let packetIndex = packets.firstIndex(where: { $0.x == x && $0.y == y && !$0.delivered }) {
                    cellContent = "P"
                    cellColor = packetColor
                } else if packets.contains(where: { $0.targetX == x && $0.targetY == y }) {
                    cellContent = "T"
                    cellColor = successColor
                } else if (x, y) == (cursorX, cursorY) {
                    cellContent = "+"
                    cellColor = highlightColor
                }
                
                // Visualize security node detection radius
                for node in securityNodes where node.active {
                    let dx = abs(node.x - x)
                    let dy = abs(node.y - y)
                    if dx*dx + dy*dy <= node.radius*node.radius && 
                       !(node.x == x && node.y == y) &&
                       cellContent == " " {
                        cellContent = "·"
                        cellColor = Renderer.Colors.red
                    }
                }
                
                renderer.drawText(x: cellX + 1, y: cellY, text: cellContent, color: cellColor)
            }
        }
        
        // Controls help
        let controlsY = gridY + gridHeight + 2
        renderer.drawTextCentered(y: controlsY, text: "↑/↓/←/→: Move   SPACE: Toggle Router   1-9: Quick Select   R: Reset   Q: Quit", color: dimmedColor)
        
        // Status message
        if won {
            renderer.drawTextCentered(y: controlsY + 2, text: "All packets successfully delivered!", color: successColor)
        } else if lost {
            if detectionLevel >= 1.0 {
                renderer.drawTextCentered(y: controlsY + 2, text: "Security alert triggered - system locked down!", color: dangerColor)
            } else {
                renderer.drawTextCentered(y: controlsY + 2, text: "Time expired - mission failed!", color: dangerColor)
            }
        } else {
            let delivered = packets.filter { $0.delivered }.count
            let total = packets.count
            renderer.drawTextCentered(y: controlsY + 2, text: "Packets delivered: \(delivered)/\(total)", color: baseColor)
        }
        
        // Router instructions if selected
        if let selectedIdx = selectedRouterIndex, !won && !lost {
            let router = routerNodes[selectedIdx]
            renderer.drawTextCentered(y: controlsY + 3, text: "Router R\(selectedIdx+1) disabled - packets will avoid this node", color: selectedColor)
        }
    }
    
    func nextScene() -> Scene? {
        return nextSceneToTransition
    }
}