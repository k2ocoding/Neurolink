import Foundation

class Renderer {
    private(set) var terminalWidth: Int
    private(set) var terminalHeight: Int
    private var buffer: [[Character]]
    private var colorBuffer: [[String]]
    
    // ANSI color codes
    struct Colors {
        static let reset = "\u{001B}[0m"
        static let black = "\u{001B}[30m"
        static let red = "\u{001B}[31m"
        static let green = "\u{001B}[32m"
        static let yellow = "\u{001B}[33m"
        static let blue = "\u{001B}[34m"
        static let magenta = "\u{001B}[35m"
        static let cyan = "\u{001B}[36m"
        static let white = "\u{001B}[37m"
        static let brightBlack = "\u{001B}[90m"
        static let brightRed = "\u{001B}[91m"
        static let brightGreen = "\u{001B}[92m"
        static let brightYellow = "\u{001B}[93m"
        static let brightBlue = "\u{001B}[94m"
        static let brightMagenta = "\u{001B}[95m"
        static let brightCyan = "\u{001B}[96m"
        static let brightWhite = "\u{001B}[97m"
        
        // Background colors
        static let bgBlack = "\u{001B}[40m"
        static let bgRed = "\u{001B}[41m"
        static let bgGreen = "\u{001B}[42m"
        static let bgYellow = "\u{001B}[43m"
        static let bgBlue = "\u{001B}[44m"
        static let bgMagenta = "\u{001B}[45m"
        static let bgCyan = "\u{001B}[46m"
        static let bgWhite = "\u{001B}[47m"
    }
    
    init() {
        // Get terminal size
        var w = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 {
            terminalWidth = Int(w.ws_col)
            terminalHeight = Int(w.ws_row)
        } else {
            // Default fallback sizes
            terminalWidth = 80
            terminalHeight = 24
        }
        
        // Initialize buffers
        buffer = Array(repeating: Array(repeating: " ", count: terminalWidth), count: terminalHeight)
        colorBuffer = Array(repeating: Array(repeating: Colors.reset, count: terminalWidth), count: terminalHeight)
    }
    
    func clearScreen() {
        print("\u{001B}[2J", terminator: "") // Clear entire screen
        print("\u{001B}[H", terminator: "")  // Move cursor to top-left
        buffer = Array(repeating: Array(repeating: " ", count: terminalWidth), count: terminalHeight)
        colorBuffer = Array(repeating: Array(repeating: Colors.reset, count: terminalWidth), count: terminalHeight)
    }
    
    func hideCursor() {
        print("\u{001B}[?25l", terminator: "")
    }
    
    func showCursor() {
        print("\u{001B}[?25h", terminator: "")
    }
    
    func resetTerminal() {
        print("\u{001B}[0m", terminator: "")
        showCursor()
        clearScreen()
    }
    
    func beginFrame() {
        buffer = Array(repeating: Array(repeating: " ", count: terminalWidth), count: terminalHeight)
        colorBuffer = Array(repeating: Array(repeating: Colors.reset, count: terminalWidth), count: terminalHeight)
    }
    
    func endFrame() {
        print("\u{001B}[H", terminator: "") // Move cursor to top-left
        
        // Render the buffer
        var currentColor = Colors.reset
        print(currentColor, terminator: "")
        
        for y in 0..<terminalHeight {
            for x in 0..<terminalWidth {
                if colorBuffer[y][x] != currentColor {
                    currentColor = colorBuffer[y][x]
                    print(currentColor, terminator: "")
                }
                print(buffer[y][x], terminator: "")
            }
            if y < terminalHeight - 1 {
                print("\r\n", terminator: "")
            }
        }
        
        print(Colors.reset, terminator: "")
        fflush(stdout)
    }
    
    func drawText(x: Int, y: Int, text: String, color: String = Colors.reset) {
        guard y >= 0 && y < terminalHeight else { return }
        
        var currentX = x
        for char in text {
            if currentX >= 0 && currentX < terminalWidth {
                buffer[y][currentX] = char
                colorBuffer[y][currentX] = color
            }
            currentX += 1
        }
    }
    
    func drawTextCentered(y: Int, text: String, color: String = Colors.reset) {
        let x = (terminalWidth - text.count) / 2
        drawText(x: x, y: y, text: text, color: color)
    }
    
    func drawBox(x: Int, y: Int, width: Int, height: Int, title: String = "", color: String = Colors.reset) {
        // Top border with title
        var topBorder = "╭" + String(repeating: "─", count: width - 2) + "╮"
        if !title.isEmpty {
            let titleText = " \(title) "
            let titleStart = (width - titleText.count) / 2
            let titleEnd = titleStart + titleText.count
            
            if titleStart > 0 && titleEnd < width - 1 {
                let prefix = String(topBorder.prefix(titleStart))
                let suffix = String(topBorder.suffix(width - titleEnd))
                topBorder = prefix + titleText + suffix
            }
        }
        
        drawText(x: x, y: y, text: topBorder, color: color)
        
        // Sides
        for i in 1..<height-1 {
            drawText(x: x, y: y + i, text: "│", color: color)
            drawText(x: x + width - 1, y: y + i, text: "│", color: color)
        }
        
        // Bottom border
        drawText(x: x, y: y + height - 1, text: "╰" + String(repeating: "─", count: width - 2) + "╯", color: color)
    }
    
    func drawProgressBar(x: Int, y: Int, width: Int, progress: Double, color: String = Colors.brightGreen, backgroundColor: String = Colors.brightBlack) {
        let filledWidth = Int(Double(width) * max(0, min(1, progress)))
        let emptyWidth = width - filledWidth
        
        // Draw filled portion
        let filledChar = "█"
        drawText(x: x, y: y, text: String(repeating: filledChar, count: filledWidth), color: color)
        
        // Draw empty portion
        let emptyChar = "░"
        drawText(x: x + filledWidth, y: y, text: String(repeating: emptyChar, count: emptyWidth), color: backgroundColor)
    }
    
    func transition(duration: TimeInterval, render: @escaping (Double) -> Void) {
        let steps = 20
        let stepDuration = duration / TimeInterval(steps)
        
        for i in 0...steps {
            let progress = Double(i) / Double(steps)
            beginFrame()
            render(progress)
            endFrame()
            Thread.sleep(forTimeInterval: stepDuration)
        }
    }
}