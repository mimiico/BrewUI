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

func drawText(layer: Layer,
              x: Int, y: Int,
              text: String,
              font: Font,
              color: UInt32) {
    let mask = font.getMask(text);
    layer.draw { canvas in
        canvas.blend(
            from: mask,
            foregroundColor: Color(color),
            to: Point(x: x, y: y)
        )
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

func drawTriangle(layer: Layer,
                   x0: Int, y0: Int,
                   x1: Int, y1: Int,
                   x2: Int, y2: Int,
                   color: UInt32) {
    // Left Line
    layer.draw { canvas in
        canvas.drawLine(
            from: Point(x: x0, y: y0),
            to: Point(x: x1, y: y1),
            data: color
        )
    }

    // Right Line
    layer.draw { canvas in
        canvas.drawLine(
            from: Point(x: x0, y: y0),
            to: Point(x: x2, y: y2),
            data: color
        )
    }

    // Bottom Line
    layer.draw { canvas in
        canvas.drawLine(
            from: Point(x: x1, y: y1),
            to: Point(x: x2, y: y2),
            data: color
        )
    }
}

func drawPolygon(layer: Layer, points: [Point], radius: Int, color: UInt32) {
    // Draw line combinations consists of two points
        for index in 0..<points.count{
                let pointA = points[index]
                let pointB: Point
                if index != points.count - 1 {
                    pointB = points[index + 1]
                } else {
                    pointB = points[0]
                }
                layer.draw { canvas in
                    canvas.drawLine(
                        from: Point(x: pointA.x, y: pointA.y),
                        to: Point(x: pointB.x, y: pointB.y),
                        data: color
                    )
                }
            }
}

func drawCircle(layer: Layer, x: Int, y: Int, radius: Int, color: UInt32) {
    layer.draw { canvas in
        canvas.fillCircle(
            at: Point(x: x, y: y), 
            radius: radius, 
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

// -----------------------------------------------------------------------------
// MARK: - Core View Protocol (View Rendering Only)

// The drawing context provided during rendering.
public struct BrewUIContext {
    public var layer: Layer
    public let width: Int
    public let height: Int
    public let selectionManager: SelectionManager?
    
    public init(
        layer: Layer, 
        width: Int, 
        height: Int, 
        selectionManager: SelectionManager? = nil
    ) {
        self.layer = layer
        self.width = width
        self.height = height
        self.selectionManager = selectionManager
    }
}

// The base protocol for all views - only concerned with rendering
public protocol BrewView {
    /// Render the view into the drawing context.
    func render(in context: inout BrewUIContext)
}

// -----------------------------------------------------------------------------
// MARK: - Interactive Components

/// Interface for views that can be interacted with via selection
/// (We're not using a protocol because of embedded Swift limitations)
public struct InteractiveState {
    public var isSelected: Bool = false
    public var action: (() -> Void)?
    
    public init(isSelected: Bool = false, action: (() -> Void)? = nil) {
        self.isSelected = isSelected
        self.action = action
    }
}

/// Manages selection state indices
public struct SelectionManager {
    /// Index of the currently selected view
    private(set) var selectedIndex: Int = 0
    
    /// Total number of interactive items
    private(set) var totalItems: Int = 0
    
    /// Actions for each interactive view
    private var actions: [(() -> Void)?] = []
    
    /// Initialize with number of items
    public init(itemCount: Int = 0) {
        self.totalItems = itemCount
    }
    
    /// Register a new item with its action
    public mutating func register(action: (() -> Void)?) {
        actions.append(action)
        totalItems = actions.count
    }
    
    /// Set the selection to a specific index
    public mutating func select(index: Int) {
        if totalItems > 0 {
            selectedIndex = max(0, min(index, totalItems - 1))
        }
    }
    
    /// Get the total number of interactive views
    public var count: Int {
        return totalItems
    }
    
    /// Get the action for the currently selected view
    public var currentAction: (() -> Void)? {
        guard !actions.isEmpty, selectedIndex < actions.count else {
            return nil
        }
        return actions[selectedIndex]
    }
    
    /// Get the selected state for a view at an index
    public func isSelected(at index: Int) -> Bool {
        return index == selectedIndex
    }
}

// -----------------------------------------------------------------------------
// MARK: - Type Eraser for BrewView
// Because using a protocol with mutating/inout methods in an array causes
// "embedded Swift" errors, we use a type eraser.

public struct AnyBrewView: BrewView {
    private let _render: (inout BrewUIContext) -> Void
    private let _isButton: () -> Bool
    private let _buttonAction: () -> (() -> Void)?
    
    public init<V: BrewView>(_ view: V) {
        self._render = view.render
        
        // Check if this is a Button and store its action if it is
        if let button = view as? Button {
            self._isButton = { true }
            self._buttonAction = { button.action }
        } else {
            self._isButton = { false }
            self._buttonAction = { nil }
        }
    }
    
    public func render(in context: inout BrewUIContext) {
        _render(&context)
    }
    
    public var isButton: Bool {
        return _isButton()
    }
    
    public var buttonAction: (() -> Void)? {
        return _buttonAction()
    }
}

// We don't need a type eraser for interactive views anymore
// as we're using a struct-based approach instead of protocols

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
}

// -----------------------------------------------------------------------------
// MARK: - Button Primitive
// Has interactive properties but doesn't use protocol due to embedded Swift limitations

public struct Button: BrewView {
    public let text: String?
    public let frame: Frame
    public let foregroundColor: UInt32 
    public let selectionColor: UInt32 
    public let onAction: () -> Void
    
    // Static counter used during rendering to track button indices
    static var currentButtonIndex = 0
    
    public var action: (() -> Void)? {
        return onAction
    }
    
    public init(
        text: String? = nil,
        frame: Frame,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.frame = frame
        self.foregroundColor = Color.white.rawValue
        self.selectionColor = Color.yellow.rawValue
        self.onAction = action
    }

    public init(
        text: String? = nil,
        frame: Frame,
        foregroundColor: UInt32 = Color.white.rawValue,
        selectionColor: UInt32 = Color.yellow.rawValue,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.frame = frame
        self.foregroundColor = foregroundColor
        self.selectionColor = selectionColor
        self.onAction = action
    }
    
    public func render(in context: inout BrewUIContext) {
        // Get the current button's index and increment the counter
        let buttonIndex = Button.currentButtonIndex
        Button.currentButtonIndex += 1
        
        // Check if this button is selected
        let isSelected = context.selectionManager?.isSelected(at: buttonIndex) ?? false
        
        // Use the appropriate color based on selection
        let color: UInt32 = isSelected ? selectionColor : foregroundColor
        
        // Draw the button
        drawRectangle(layer: context.layer,
                      x: frame.x,
                      y: frame.y,
                      width: frame.width,
                      height: frame.height,
                      color: color)

        if let text = text {
            drawText(layer: context.layer,
                x: frame.x + 5,
                y: frame.y + 5,
                text: text,
                font: Font(path: "/lfs/Resources/Fonts/Roboto-Regular.ttf", pointSize: 8, dpi: 220),
                color: color)
        }
    }
}

public struct Text: BrewView {
    public let text: String
    public let frame: Frame
    public let foregroundColor: UInt32 
    public let pointSize: Int = 8

    public init(
        _ text: String,
        frame: Frame,
        foregroundColor: UInt32 = Color.white.rawValue
    ) {
        self.frame = frame
        self.text = text
        self.foregroundColor = foregroundColor
    }

    public func render(in context: inout BrewUIContext) {
        let font = Font(path: "/lfs/Resources/Fonts/Roboto-Regular.ttf", pointSize: pointSize, dpi: 220)

        drawText(layer: context.layer,
                 x: frame.x,
                 y: frame.y,
                 text: text,
                 font: font,
                 color: foregroundColor)
    }
}

// -----------------------------------------------------------------------------
// MARK: - View Collection Functions
// These functions collect interactive elements and build a selection manager

/// Collect interactive views from a Group
public func collectInteractiveViewsFromGroup(_ group: Group) -> SelectionManager {
    var selectionManager = SelectionManager()
    
    for child in group.children {
        // Check if the AnyBrewView wraps a Button
        if child.isButton {
            selectionManager.register(action: child.buttonAction)
        }
        
        // Other container types could be handled here
        // For example, if we added nested groups
    }
    
    return selectionManager
}

/// Collect interactive views from any view (currently only supports Button and Group)
public func collectInteractiveViews<T: BrewView>(from view: T) -> SelectionManager {
    if let group = view as? Group {
        return collectInteractiveViewsFromGroup(group)
    } else if let button = view as? Button {
        var selectionManager = SelectionManager()
        selectionManager.register(action: button.action)
        return selectionManager
    }
    
    return SelectionManager()
}

// -----------------------------------------------------------------------------
// MARK: - BrewUIApp: The Declarative UI Runner
// This is the "engine" that runs the UI event loop.

public struct BrewUIApp<Content: BrewView> {
    let content: Content
    var selectionManager: SelectionManager
    
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
        
        // Initialize the selection manager
        self.selectionManager = SelectionManager()
        
        // Do a trial render to collect buttons and their actions
        var tempContext = BrewUIContext(
            layer: layer,
            width: screen.width,
            height: screen.height,
            selectionManager: nil
        )
        
        // Reset the button counter before rendering
        Button.currentButtonIndex = 0
        
        // Render to collect buttons
        content.render(in: &tempContext)
        
        // Create a selection manager with the correct number of buttons
        self.selectionManager = SelectionManager(itemCount: Button.currentButtonIndex)
        
        // Reset the button counter again
        Button.currentButtonIndex = 0
        
        // Render again to register button actions
        content.render(in: &tempContext)
    }
    
    // Marked as mutating because we update self's buffers.
    public mutating func run() -> Never {
        var lastSelectedIndex = -1
        
        while true {
            if selectionManager.count > 0 {
                // 1) Map the potentiometer value to a selection index
                let rawValue = pot.readRawValue()
                let totalItems = selectionManager.count
                let mapped = Int(Float(rawValue) * Float(totalItems) / Float(pot.maxRawValue))
                let clampedIndex = max(0, min(mapped, totalItems - 1))
                
                // 2) If the selected item changed, play a selection beep
                if clampedIndex != lastSelectedIndex {
                    buzzer.set(frequency: 440, dutycycle: 0.5)
                    sleep(ms: 100)
                    buzzer.suspend()
                    lastSelectedIndex = clampedIndex
                    
                    // Update the selection
                    selectionManager.select(index: clampedIndex)
                }
                
                // 3) Render the content
                renderContent()
                
                // 4) If the hardware button is pressed, activate the selected item
                if hwButton.read() {
                    if let action = selectionManager.currentAction {
                        buzzer.set(frequency: 880, dutycycle: 0.5)
                        sleep(ms: 100)
                        buzzer.suspend()
                        action()
                    }
                    // Wait for button release to avoid multiple activations
                    while hwButton.read() {
                        sleep(ms: 10)
                    }
                }
            } else {
                // No interactive views, just render the content
                renderContent()
            }
            
            sleep(ms: 50)
        }
    }
    
    private mutating func renderContent() {
        // Clear the screen
        clearScreen(layer: layer, width: screen.width, height: screen.height)
        
        // Reset button counter before each render
        Button.currentButtonIndex = 0
        
        // Create render context
        var context = BrewUIContext(
            layer: layer,
            width: screen.width,
            height: screen.height,
            selectionManager: selectionManager
        )
        
        // Render the content
        content.render(in: &context)
        
        // Copy buffers locally to avoid overlapping access to self's properties
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
    }
}