import Foundation

class InputHandler {
    private var buffer: [Character] = []
    private var rawMode = false
    private var oldSettings: termios = termios()
    
    init() {
        enableRawMode()
    }
    
    deinit {
        disableRawMode()
    }
    
    private func enableRawMode() {
        var raw = termios()
        tcgetattr(STDIN_FILENO, &oldSettings)
        raw = oldSettings
        
        raw.c_iflag &= ~UInt(ICRNL | IXON)
        raw.c_oflag &= ~UInt(OPOST)
        raw.c_lflag &= ~UInt(ECHO | ICANON | IEXTEN | ISIG)
        
        // Set timeout for read
        raw.c_cc.8 = 0  // VMIN = 0 (no minimum characters)
        raw.c_cc.7 = 1  // VTIME = 1 (0.1 seconds timeout)
        
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
        rawMode = true
    }
    
    private func disableRawMode() {
        if rawMode {
            tcsetattr(STDIN_FILENO, TCSAFLUSH, &oldSettings)
            rawMode = false
        }
    }
    
    func getInput(timeout: TimeInterval? = nil) -> Character? {
        // Check if we have buffered input
        if !buffer.isEmpty {
            return buffer.removeFirst()
        }
        
        // Simplified input handling - just a basic read
        var buffer = [UInt8](repeating: 0, count: 1)
        
        // Handle non-blocking mode with poll
        if let timeout = timeout {
            // For simplicity, we'll just use a polling approach
            usleep(UInt32(timeout * 1_000_000))
            
            // Check if input is available using poll()
            var pfd = pollfd()
            pfd.fd = STDIN_FILENO
            pfd.events = Int16(POLLIN)
            
            let result = poll(&pfd, 1, 0)
            if result <= 0 {
                return nil // No input available or error
            }
        }
        
        // Read a character
        let bytesRead = read(STDIN_FILENO, &buffer, 1)
        if bytesRead == 1 {
            return Character(UnicodeScalar(buffer[0]))
        }
        
        return nil
    }
    
    func readLine(prompt: String? = nil, echo: Bool = true) -> String {
        var oldSettings = termios()
        if rawMode {
            // Temporarily disable raw mode
            tcgetattr(STDIN_FILENO, &oldSettings)
            disableRawMode()
        }
        
        if let prompt = prompt {
            print(prompt, terminator: "")
        }
        
        let input = Swift.readLine() ?? ""
        
        if rawMode {
            // Restore raw mode
            enableRawMode()
        }
        
        return input
    }
}