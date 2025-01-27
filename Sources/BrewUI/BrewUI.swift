import SwiftIO
import MadBoard
import ST7789
import MadGraphics

// MARK: - Type Erasure for MyView

/// A type-erased wrapper for any MyView conforming type.
public struct AnyMyView: MyView {
    private let _makeButtons: () -> [ButtonView]
    
    public init<V: MyView>(_ view: V) {
        self._makeButtons = view.makeButtons
    }
    
    public func makeButtons() -> [ButtonView] {
        _makeButtons()
    }
}

// MARK: - MyView Protocol

/// A protocol for any “view” in our minimal framework.
public protocol MyView {
    func makeButtons() -> [ButtonView]
}

// MARK: - ViewBuilder

/// A result builder to compose multiple MyView instances.
@resultBuilder
public struct ViewBuilder {
    public static func buildBlock(_ views: AnyMyView...) -> AnyMyView {
        AnyMyView(ViewGroup(children: views))
    }
    
    // Optional: Handle conditionals, loops, etc., if needed.
}

// MARK: - ViewGroup

/// A container that holds multiple AnyMyView instances.
public struct ViewGroup: MyView {
    let children: [AnyMyView]
    
    public func makeButtons() -> [ButtonView] {
        children.flatMap { $0.makeButtons() }
    }
}

// MARK: - Layout Containers

/// A vertical stack that arranges child buttons in a top-to-bottom layout.
public struct VStack: MyView {
    let startX: Int
    let startY: Int
    let spacing: Int
    let content: AnyMyView
    
    public init(startX: Int = 20,
                startY: Int = 20,
                spacing: Int = 10,
                @ViewBuilder _ builder: () -> AnyMyView) {
        self.startX = startX
        self.startY = startY
        self.spacing = spacing
        self.content = builder()
    }
    
    public func makeButtons() -> [ButtonView] {
        var all = [ButtonView]()
        var currentY = startY
        
        let childButtons = content.makeButtons()
        for btn in childButtons {
            let newBtn = ButtonView(
                x: startX,
                y: currentY,
                width: btn.width,
                height: btn.height,
                normalColor: btn.normalColor,
                highlightColor: btn.highlightColor,
                pressColor: btn.pressColor,
                beepOnSelect: btn.beepOnSelect,
                beepOnPress: btn.beepOnPress,
                action: btn.action
            )
            all.append(newBtn)
            currentY += (btn.height + spacing)
        }
        return all
    }
}

/// A horizontal stack that arranges child buttons in a left-to-right layout.
public struct HStack: MyView {
    let startX: Int
    let startY: Int
    let spacing: Int
    let content: AnyMyView
    
    public init(startX: Int = 20,
                startY: Int = 20,
                spacing: Int = 10,
                @ViewBuilder _ builder: () -> AnyMyView) {
        self.startX = startX
        self.startY = startY
        self.spacing = spacing
        self.content = builder()
    }
    
    public func makeButtons() -> [ButtonView] {
        var all = [ButtonView]()
        var currentX = startX
        
        let childButtons = content.makeButtons()
        for btn in childButtons {
            let newBtn = ButtonView(
                x: currentX,
                y: startY,
                width: btn.width,
                height: btn.height,
                normalColor: btn.normalColor,
                highlightColor: btn.highlightColor,
                pressColor: btn.pressColor,
                beepOnSelect: btn.beepOnSelect,
                beepOnPress: btn.beepOnPress,
                action: btn.action
            )
            all.append(newBtn)
            currentX += (btn.width + spacing)
        }
        return all
    }
}

// MARK: - Button

/// A user-facing struct to define a Button.
public struct Button: MyView {
    public let width: Int
    public let height: Int
    public let normalColor: UInt32
    public let highlightColor: UInt32
    public let pressColor: UInt32
    public let beepOnSelect: Int
    public let beepOnPress: Int
    public let action: () -> Void
    
    public init(width: Int,
                height: Int,
                normalColor: UInt32,
                highlightColor: UInt32,
                pressColor: UInt32,
                beepOnSelect: Int,
                beepOnPress: Int,
                action: @escaping () -> Void) {
        self.width = width
        self.height = height
        self.normalColor = normalColor
        self.highlightColor = highlightColor
        self.pressColor = pressColor
        self.beepOnSelect = beepOnSelect
        self.beepOnPress = beepOnPress
        self.action = action
    }
    
    public func makeButtons() -> [ButtonView] {
        let internalBtn = ButtonView(
            x: 0, y: 0, // Placeholder; actual position is set by the stack.
            width: width,
            height: height,
            normalColor: normalColor,
            highlightColor: highlightColor,
            pressColor: pressColor,
            beepOnSelect: beepOnSelect,
            beepOnPress: beepOnPress,
            action: action
        )
        return [internalBtn]
    }
}

/// Internal struct used at render time, with final (x, y) positions.
public struct ButtonView {
    let x: Int
    let y: Int
    let width: Int
    let height: Int
    let normalColor: UInt32
    let highlightColor: UInt32
    let pressColor: UInt32
    let beepOnSelect: Int
    let beepOnPress: Int
    let action: () -> Void
}

// MARK: - MyUIApp Protocol

/// A SwiftUI-like App protocol requiring a body that conforms to MyView.
public protocol MyUIApp {
    associatedtype Body: MyView
    
    @ViewBuilder var body: Body { get }
}

/// Extension to provide a default main implementation.
/// Users are expected to call UIHost.runApp from their executable.
public extension MyUIApp {
    static func main() {
        fatalError("Please call UIHost.runApp(app, hardware: yourHardwareConfig) from your executable.")
    }
}

// MARK: - UIHost

/// The host that sets up hardware, handles the event loop, and renders the UI.
public struct UIHost {
    /// Configuration for hardware pins.
    public struct HardwarePins {
        public let blPin: DigitalOut
        public let rstPin: DigitalOut
        public let dcPin: DigitalOut
        public let csPin: DigitalOut
        public let spi: SPI
        public let potPin: AnalogIn
        public let hwButtonPin: DigitalIn
        public let buzzerPin: PWMOut
    
        public init(blPin: DigitalOut,
                    rstPin: DigitalOut,
                    dcPin: DigitalOut,
                    csPin: DigitalOut,
                    spi: SPI,
                    potPin: AnalogIn,
                    hwButtonPin: DigitalIn,
                    buzzerPin: PWMOut) {
            self.blPin = blPin
            self.rstPin = rstPin
            self.dcPin = dcPin
            self.csPin = csPin
            self.spi = spi
            self.potPin = potPin
            self.hwButtonPin = hwButtonPin
            self.buzzerPin = buzzerPin
        }
    }
    
    /// Runs the provided app with the specified hardware configuration.
    /// This is a generic function to handle any type conforming to MyUIApp.
    public static func runApp<T: MyUIApp>(_ app: T, hardware: HardwarePins) -> Never {
        // 1. Gather all buttons from the app's body.
        let allButtons = app.body.makeButtons()
        let buttonCount = allButtons.count
        
        // 2. Initialize the display.
        let screen = ST7789(
            spi: hardware.spi,
            cs: hardware.csPin,
            dc: hardware.dcPin,
            rst: hardware.rstPin,
            bl: hardware.blPin,
            rotation: .angle90
        )
        var screenBuffer = [UInt16](repeating: 0, count: screen.width * screen.height)
        
        let layer = Layer(
            at: .zero,
            anchorPoint: .zero,
            width: screen.width,
            height: screen.height
        )
        var frameBuffer = [UInt32](repeating: 0, count: screen.width * screen.height)
        
        // 3. Setup input devices and buzzer.
        let pot = hardware.potPin
        let hwButton = hardware.hwButtonPin
        let buzzer = hardware.buzzerPin
        buzzer.suspend()
        
        // 4. Initialize selection state.
        var selectedIndex = 0
        
        // 5. Main event loop.
        while true {
            // A. Read the potentiometer to select a button.
            if buttonCount > 0 {
                let rawValue = pot.readRawValue()
                let newIndex = Int(
                    Float(rawValue) * Float(buttonCount) / Float(pot.maxRawValue)
                )
                let clamped = max(0, min(newIndex, buttonCount - 1))
                
                if clamped != selectedIndex {
                    selectedIndex = clamped
                    let freq = allButtons[selectedIndex].beepOnSelect
                    beep(buzzer: buzzer, frequency: freq, durationMs: 80)
                }
            }
            
            // B. Check if the hardware button is pressed.
            let pressed = hwButton.read()
            if pressed && buttonCount > 0 {
                let freq = allButtons[selectedIndex].beepOnPress
                beep(buzzer: buzzer, frequency: freq, durationMs: 120)
                
                // Execute the button's action.
                allButtons[selectedIndex].action()
                
                // Prevent multiple triggers.
                sleep(ms: 300)
            }
            
            // C. Clear the screen to black.
            clearScreen(layer: layer, width: screen.width, height: screen.height)
            
            // D. Draw each button.
            for i in 0..<buttonCount {
                let b = allButtons[i]
                let color: UInt32
                if i == selectedIndex {
                    color = pressed ? b.pressColor : b.highlightColor
                } else {
                    color = b.normalColor
                }
                
                drawOutlineRect(
                    layer: layer,
                    x: b.x,
                    y: b.y,
                    w: b.width,
                    h: b.height,
                    color: color
                )
            }
            
            // E. Render the layer to the screen.
            layer.render(into: &frameBuffer, output: &screenBuffer,
                         transform: Color.getRGB565LE) { dirty, data in
                screen.writeBitmap(
                    x: dirty.x,
                    y: dirty.y,
                    width: dirty.width,
                    height: dirty.height,
                    data: data
                )
            }
            
            sleep(ms: 50)
        }
    }
    
    // MARK: - Private Helper Functions
    
    /// Clears the screen by drawing horizontal black lines.
    private static func clearScreen(layer: Layer, width: Int, height: Int) {
        for row in 0..<height {
            layer.draw { canvas in
                canvas.drawLine(
                    from: Point(x: 0, y: row),
                    to: Point(x: width - 1, y: row),
                    data: Color.black.rawValue
                )
            }
        }
    }
    
    /// Draws an outlined rectangle using four lines.
    private static func drawOutlineRect(layer: Layer,
                                        x: Int, y: Int,
                                        w: Int, h: Int,
                                        color: UInt32) {
        // Top edge
        layer.draw { c in
            c.drawLine(
                from: Point(x: x, y: y),
                to: Point(x: x + w, y: y),
                data: color
            )
        }
        // Bottom edge
        layer.draw { c in
            c.drawLine(
                from: Point(x: x, y: y + h),
                to: Point(x: x + w, y: y + h),
                data: color
            )
        }
        // Left edge
        layer.draw { c in
            c.drawLine(
                from: Point(x: x, y: y),
                to: Point(x: x, y: y + h),
                data: color
            )
        }
        // Right edge
        layer.draw { c in
            c.drawLine(
                from: Point(x: x + w, y: y),
                to: Point(x: x + w, y: y + h),
                data: color
            )
        }
    }
    
    /// Helper to beep at a given frequency for a specified duration.
    private static func beep(buzzer: PWMOut, frequency: Int, durationMs: Int) {
        buzzer.set(frequency: frequency, dutycycle: 0.5)
        sleep(ms: durationMs)
        buzzer.suspend()
    }
}