import SwiftIO
import MadBoard
import ST7789
import MadGraphics

// -----------------------------------------------------------------------------
// MARK: - Helper Drawing Functions
// These functions use your provided APIs to draw on the screen.

func clearScreen(layer: Layer, width: Int, height: Int) {
    for y in 0..<height {
        layer.draw { canvas in
            canvas.drawLine(
                from: Point(x: 0, y: y),
                to: Point(x: width - 1, y: y),
                data: Color.black.rawValue
            )
        }
    }
}

func drawRectangle(layer: Layer,
                   x: Int, y: Int,
                   width: Int, height: Int,
                   color: UInt32) {
    // Top edge
    layer.draw { canvas in
        canvas.drawLine(
            from: Point(x: x, y: y),
            to: Point(x: x + width, y: y),
            data: color
        )
    }
    // Bottom edge
    layer.draw { canvas in
        canvas.drawLine(
            from: Point(x: x, y: y + height),
            to: Point(x: x + width, y: y + height),
            data: color
        )
    }
    // Left edge
    layer.draw { canvas in
        canvas.drawLine(
            from: Point(x: x, y: y),
            to: Point(x: x, y: y + height),
            data: color
        )
    }
    // Right edge
    layer.draw { canvas in
        canvas.drawLine(
            from: Point(x: x + width, y: y),
            to: Point(x: x + width, y: y + height),
            data: color
        )
    }
}

// -----------------------------------------------------------------------------
// MARK: - BrewUI Declarative Framework

// A simple structure to represent a rectangular frame.
public struct Frame {
    public let x: Int
    public let y: Int
    public let width: Int
    public let height: Int
    
    public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

// The drawing context provided during rendering.
public struct BrewUIContext {
    public var layer: Layer
    public let width: Int
    public let height: Int
    /// The currently highlighted (selected) button index.
    public var selectedButtonIndex: Int
    /// A counter that increments as each Button renders.
    public var currentButtonIndex: Int = 0
    
    public init(layer: Layer, width: Int, height: Int, selectedButtonIndex: Int) {
        self.layer = layer
        self.width = width
        self.height = height
        self.selectedButtonIndex = selectedButtonIndex
    }
}

// The protocol for all BrewUI views.
public protocol BrewView {
    /// Render the view into the drawing context.
    func render(in context: inout BrewUIContext)
    /// If the view (or one of its descendants) is a Button, return its action
    /// when the given “button index” is reached.
    func actionForButton(at index: Int) -> (() -> Void)?
    /// Count the number of Button views contained in this view.
    func buttonCount() -> Int
}

// Provide default implementations.
public extension BrewView {
    func actionForButton(at index: Int) -> (() -> Void)? { return nil }
    func buttonCount() -> Int { return 0 }
}

// -----------------------------------------------------------------------------
// MARK: - Type Eraser for BrewView
// Because using a protocol with mutating/inout methods in an array causes
// “embedded Swift” errors, we use a type eraser.

public struct AnyBrewView: BrewView {
    private let _render: (inout BrewUIContext) -> Void
    private let _actionForButton: (Int) -> (() -> Void)?
    private let _buttonCount: () -> Int

    public init<V: BrewView>(_ view: V) {
        self._render = view.render
        self._actionForButton = view.actionForButton
        self._buttonCount = view.buttonCount
    }

    public func render(in context: inout BrewUIContext) {
        _render(&context)
    }

    public func actionForButton(at index: Int) -> (() -> Void)? {
        return _actionForButton(index)
    }

    public func buttonCount() -> Int {
        return _buttonCount()
    }
}

// -----------------------------------------------------------------------------
// MARK: - BrewUI Result Builder
// This result builder lets you compose views in a SwiftUI-like way.

@resultBuilder
public struct BrewUIBuilder {
    public static func buildBlock(_ components: AnyBrewView...) -> [AnyBrewView] {
        return components
    }
    public static func buildExpression<V: BrewView>(_ expression: V) -> AnyBrewView {
        return AnyBrewView(expression)
    }
    public static func buildOptional(_ component: [AnyBrewView]?) -> [AnyBrewView] {
        return component ?? []
    }
    public static func buildEither(first component: [AnyBrewView]) -> [AnyBrewView] {
        return component
    }
    public static func buildEither(second component: [AnyBrewView]) -> [AnyBrewView] {
        return component
    }
    public static func buildArray(_ components: [[AnyBrewView]]) -> [AnyBrewView] {
        return components.flatMap { $0 }
    }
}

// -----------------------------------------------------------------------------
// MARK: - Group Container
// A container that simply groups its children.

public struct Group: BrewView {
    public let children: [AnyBrewView]
    
    public init(@BrewUIBuilder _ content: () -> [AnyBrewView]) {
        self.children = content()
    }
    
    public func render(in context: inout BrewUIContext) {
        for child in children {
            child.render(in: &context)
        }
    }
    
    public func actionForButton(at index: Int) -> (() -> Void)? {
        var remaining = index
        for child in children {
            let count = child.buttonCount()
            if remaining < count {
                return child.actionForButton(at: remaining)
            } else {
                remaining -= count
            }
        }
        return nil
    }
    
    public func buttonCount() -> Int {
        return children.reduce(0) { $0 + $1.buttonCount() }
    }
}

// -----------------------------------------------------------------------------
// MARK: - Button Primitive
// The only currently supported UI element.

public struct Button: BrewView {
    public let frame: Frame
    public let foregroundColor: UInt32 
    public let selectionColor: UInt32 
    public let action: () -> Void
    
    public init(
        frame: Frame,
        action: @escaping () -> Void
    ) {
        self.frame = frame
        self.foregroundColor = Color.white.rawValue
        self.selectionColor = Color.yellow.rawValue
        self.action = action
    }
    
    public func render(in context: inout BrewUIContext) {
        let index = context.currentButtonIndex
        context.currentButtonIndex += 1
        
        // Draw the button: yellow if selected, blue otherwise.
        let color: UInt32 = (index == context.selectedButtonIndex) ?
            foregroundColor : selectionColor
        
        drawRectangle(layer: context.layer,
                      x: frame.x,
                      y: frame.y,
                      width: frame.width,
                      height: frame.height,
                      color: color)
    }
    
    public func actionForButton(at index: Int) -> (() -> Void)? {
        return (index == 0) ? action : nil
    }
    
    public func buttonCount() -> Int {
        return 1
    }
}  // ←–– This closing brace was missing!

// -----------------------------------------------------------------------------
// MARK: - BrewUIApp: The Declarative UI Runner
// This is the “engine” that runs the UI event loop.

public struct BrewUIApp<Content: BrewView> {
    let content: Content
    
    // Hardware and display components.
    let pot: AnalogIn
    let hwButton: DigitalIn
    let buzzer: PWMOut
    let screen: ST7789
    var layer: Layer
    var screenBuffer: [UInt16]
    var frameBuffer: [UInt32]
    
    public init(content: Content,
                pot: AnalogIn,
                hwButton: DigitalIn,
                buzzer: PWMOut,
                screen: ST7789,
                layer: Layer,
                screenBuffer: [UInt16],
                frameBuffer: [UInt32]) {
        self.content = content
        self.pot = pot
        self.hwButton = hwButton
        self.buzzer = buzzer
        self.screen = screen
        self.layer = layer
        self.screenBuffer = screenBuffer
        self.frameBuffer = frameBuffer
    }
    
    // Marked as mutating because we update self's buffers.
    public mutating func run() -> Never {
        let totalButtons = content.buttonCount()
        var lastSelectedIndex = -1
        
        while true {
            // 1) Map the potentiometer value to a button index.
            let rawValue = pot.readRawValue()
            let mapped = Int(Float(rawValue) * Float(totalButtons) / Float(pot.maxRawValue))
            let clampedIndex = max(0, min(mapped, totalButtons - 1))
            
            // 2) If the highlighted button changed, play a selection beep.
            if clampedIndex != lastSelectedIndex {
                buzzer.set(frequency: 440, dutycycle: 0.5)
                sleep(ms: 100)
                buzzer.suspend()
                lastSelectedIndex = clampedIndex
            }
            
            // 3) Clear and re-render the view hierarchy.
            clearScreen(layer: layer, width: screen.width, height: screen.height)
            var context = BrewUIContext(layer: layer,
                                        width: screen.width,
                                        height: screen.height,
                                        selectedButtonIndex: clampedIndex)
            content.render(in: &context)
            
            // Copy buffers locally to avoid overlapping access to self's properties.
            var fb = frameBuffer
            var sb = screenBuffer
            layer.render(
                into: &fb,
                output: &sb,
                transform: Color.getRGB565LE
            ) { dirty, data in
                screen.writeBitmap(
                    x: dirty.x,
                    y: dirty.y,
                    width: dirty.width,
                    height: dirty.height,
                    data: data
                )
            }
            frameBuffer = fb
            screenBuffer = sb
            
            // 4) If the hardware button is pressed, activate the selected button.
            if hwButton.read() {
                if let action = content.actionForButton(at: clampedIndex) {
                    buzzer.set(frequency: 880, dutycycle: 0.5)
                    sleep(ms: 100)
                    buzzer.suspend()
                    action()
                }
                // Wait for button release to avoid multiple activations.
                while hwButton.read() {
                    sleep(ms: 10)
                }
            }
            sleep(ms: 50)
        }
    }
}

// -----------------------------------------------------------------------------
// MARK: - Sample Usage: ContentView and App Launch
// This sample content view is written in a SwiftUI-like style.
// (Note: No text is drawn; you simply see outlined rectangles.)

struct ContentView: BrewView {
    let body: Group
    init() {
        body = Group {
            Button(frame: Frame(x: 20, y: 20, width: 140, height: 30)) {
                // Action for Button 1.
            }
            Button(frame: Frame(x: 20, y: 70, width: 140, height: 30)) {
                // Action for Button 2.
            }
            Button(frame: Frame(x: 20, y: 120, width: 140, height: 30)) {
                // Action for Button 3.
            }
            Button(frame: Frame(x: 20, y: 170, width: 140, height: 30)) {
                // Action for Button 4.
            }
        }
    }
    
    public func render(in context: inout BrewUIContext) {
        body.render(in: &context)
    }
    
    public func actionForButton(at index: Int) -> (() -> Void)? {
        return body.actionForButton(at: index)
    }
    
    public func buttonCount() -> Int {
        return body.buttonCount()
    }
}