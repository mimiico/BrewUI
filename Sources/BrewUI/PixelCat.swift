// Simple Pixel Cat Animation
class PixelCat{
    public let frame: Frame
    private var position: Point
    private var frameIndex: Int = 0
    private var frameTimer: Int = 0
    private var isWalking: Bool = false
    private var velocity: Float = 0
    
    // Cat sprite frames
    private let sittingFrames: [[[Int]]] = [
        // Frame 1
        [[0,0,0,0,0,0,0,0],
         [0,1,1,0,0,1,1,0],
         [0,1,1,0,0,1,1,0],
         [0,2,2,2,2,2,2,0],
         [0,2,3,2,2,3,2,0],
         [0,2,2,2,2,2,2,0],
         [0,2,2,1,1,2,2,0],
         [0,2,2,2,2,2,2,0]],
        // Frame 2 (blinking)
        [[0,0,0,0,0,0,0,0],
         [0,1,1,0,0,1,1,0],
         [0,1,1,0,0,1,1,0],
         [0,2,2,2,2,2,2,0],
         [0,2,1,2,2,1,2,0],
         [0,2,2,2,2,2,2,0],
         [0,2,2,1,1,2,2,0],
         [0,2,2,2,2,2,2,0]]
    ]
    
    private let walkingFrames: [[[Int]]] = [
        // Frame 1
        [[0,0,0,0,0,0,0,0],
         [0,1,1,0,0,1,1,0],
         [0,1,1,0,0,1,1,0],
         [0,2,2,2,2,2,2,0],
         [0,2,3,2,2,3,2,0],
         [0,2,2,2,2,2,2,0],
         [0,2,0,2,2,0,2,0],
         [0,2,0,2,0,2,0,0]],
        // Frame 2
        [[0,0,0,0,0,0,0,0],
         [0,1,1,0,0,1,1,0],
         [0,1,1,0,0,1,1,0],
         [0,2,2,2,2,2,2,0],
         [0,2,3,2,2,3,2,0],
         [0,2,2,2,2,2,2,0],
         [0,0,2,0,0,2,0,0],
         [0,2,0,0,2,0,2,0]]
    ]
    
    // Color map
    private let colors: [UInt32] = [
        0x00000000, // 0: Transparent
        0xFF000000, // 1: Black
        0xFFFFA500, // 2: Orange
        0xFFFFFFFF  // 3: White
    ]
    
    init(x: Int, y: Int) {
        self.frame = Frame(x: x, y: y, width: 16, height: 16)
        self.position = Point(x: x, y: y)
    }
    
    // Start walking animation (no mutating needed for class)
    func walk(direction: Float) {
        isWalking = true
        velocity = direction
    }
    
    // Stop and sit (no mutating needed for class)
    func sit() {
        isWalking = false
        velocity = 0
        frameIndex = 0
    }
    
    // Render the cat (no mutating needed for class)
    func render(in context: inout BrewUIContext) {
        // Update position if walking
        if isWalking {
            // Clear previous position
            drawCurrentFrame(context.layer, clear: true)
            
            // Update position (simple animation without delta time)
            position.x += Int(velocity)
            
            // Check boundaries
            if position.x < 10 || position.x > context.width - 26 {
                velocity = -velocity
            }
        }
        
        // Update animation frame
        frameTimer += 1
        if frameTimer >= 5 {  // Change frame every 5 renders (adjust for speed)
            frameTimer = 0
            frameIndex = (frameIndex + 1) % (isWalking ? walkingFrames.count : sittingFrames.count)
        }
        
        // Draw the cat
        drawCurrentFrame(context.layer, clear: false)
    }
    
    // Helper to draw the current frame
    private func drawCurrentFrame(_ layer: Layer, clear: Bool) {
        let frames = isWalking ? walkingFrames : sittingFrames
        let frame = frames[frameIndex]
        let size = 2  // Scale factor for the cat
        
        for y in 0..<frame.count {
            for x in 0..<frame[y].count {
                if x < frame[y].count {
                    let colorIndex = frame[y][x]
                    if colorIndex > 0 {  // Skip transparent pixels
                        let color = clear ? 0x00000000 : colors[colorIndex]
                        
                        layer.draw { canvas in
                            canvas.fillRectangle(
                                at: Point(x: position.x + x*size, y: position.y + y*size),
                                width: size,
                                height: size,
                                data: color
                            )
                        }
                    }
                }
            }
        }
    }
}

// Extension to support OffsetRenderable
extension PixelCat{
    func render(withOffsetX offsetX: Int, offsetY: Int, in context: inout BrewUIContext) {
        // Store original position
        let originalX = position.x
        let originalY = position.y
        
        // Temporarily move to the offset position
        position.x += offsetX
        position.y += offsetY
        
        // Render at the offset position
        render(in: &context)
        
        // Restore original position
        position.x = originalX
        position.y = originalY
    }
}