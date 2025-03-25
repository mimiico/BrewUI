import MadGraphics
import MadBoard
import SwiftIO
import ST7789

// -----------------------------------------------------------------------------
// MARK: - Font Configuration System
// This allows customizing fonts throughout the UI system
public struct FontConfiguration {
    public let defaultFontPath: String
    public let defaultPointSize: Int
    public let defaultDPI: Int
    
    public init(
        defaultFontPath: String = "/lfs/Resources/Fonts/Roboto-Regular.ttf",
        defaultPointSize: Int = 8,
        defaultDPI: Int = 220
    ) {
        self.defaultFontPath = defaultFontPath
        self.defaultPointSize = defaultPointSize
        self.defaultDPI = defaultDPI
    }
    
    public func defaultFont() -> Font {
        return Font(path: defaultFontPath, pointSize: defaultPointSize, dpi: defaultDPI)
    }
    
    public func font(withSize pointSize: Int) -> Font {
        return Font(path: defaultFontPath, pointSize: pointSize, dpi: defaultDPI)
    }
}

// -----------------------------------------------------------------------------
// MARK: - Helper Drawing Functions
// These functions use your provided APIs to draw on the screen.
func clearScreen(layer: Layer,
                 width: Int,
                 height: Int) {
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
    let mask = font.getMask(text)
    layer.draw { canvas in
        canvas.blend(
            from: mask,
            foregroundColor: Color(color),
            to: Point(x: x, y: y)
        )
    }
}

func fillRectangle(layer: Layer,
                   x: Int, y: Int,
                   width: Int, height: Int,
                   color: UInt32) {
    layer.draw { canvas in
        canvas.fillRectangle(at: Point(x, y), width: width, height: height, data: color)
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

func drawPolygon(layer: Layer,
                 points: [Point],
                 radius: Int,
                 color: UInt32) {
    // Draw line combinations consists of two points
    for index in 0..<points.count {
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

func drawCircle(layer: Layer,
                x: Int,
                y: Int,
                radius: Int,
                color: UInt32) {
    layer.draw { canvas in
        canvas.fillCircle(
            at: Point(x: x, y: y),
            radius: radius,
            data: color
        )
    }
}

func fillRoundedRectangle(layer: Layer,
                         x: Int, y: Int,
                         width: Int, height: Int,
                         cornerRadius: Int,
                         color: UInt32) {
    // Ensure cornerRadius isn't too large
    let r = min(cornerRadius, min(width/2, height/2))
    
    // Fill the center rectangle (full width)
    layer.draw { canvas in
        canvas.fillRectangle(at: Point(x: x, y: y + r),
                           width: width,
                           height: height - 2*r,
                           data: color)
    }
    
    // Fill the top and bottom rectangles (reducing width by 2*cornerRadius)
    layer.draw { canvas in
        canvas.fillRectangle(at: Point(x: x + r, y: y),
                           width: width - 2*r,
                           height: r,
                           data: color)
        canvas.fillRectangle(at: Point(x: x + r, y: y + height - r),
                           width: width - 2*r,
                           height: r,
                           data: color)
    }
    
    // Fill the four corner arcs using circle quarters
    layer.draw { canvas in
        canvas.fillCircle(at: Point(x: x + r, y: y + r),
                        radius: r,
                        data: color)
        canvas.fillCircle(at: Point(x: x + width - r, y: y + r),
                        radius: r,
                        data: color)
        canvas.fillCircle(at: Point(x: x + r, y: y + height - r),
                        radius: r,
                        data: color)
        canvas.fillCircle(at: Point(x: x + width - r, y: y + height - r),
                        radius: r,
                        data: color)
    }
}

// Draw a rounded rectangle outline using Bresenham's circle algorithm
func drawRoundedRectangleOutline(layer: Layer,
                                x: Int, y: Int,
                                width: Int, height: Int,
                                cornerRadius: Int,
                                color: UInt32) {
    // Ensure cornerRadius isn't too large
    let r = min(cornerRadius, min(width/2, height/2))
    
    // Draw the straight lines
    // Top edge
    layer.draw { canvas in
        canvas.drawLine(
            from: Point(x: x + r, y: y),
            to: Point(x: x + width - r, y: y),
            data: color
        )
    }
    
    // Bottom edge
    layer.draw { canvas in
        canvas.drawLine(
            from: Point(x: x + r, y: y + height),
            to: Point(x: x + width - r, y: y + height),
            data: color
        )
    }
    
    // Left edge
    layer.draw { canvas in
        canvas.drawLine(
            from: Point(x: x, y: y + r),
            to: Point(x: x, y: y + height - r),
            data: color
        )
    }
    
    // Right edge
    layer.draw { canvas in
        canvas.drawLine(
            from: Point(x: x + width, y: y + r),
            to: Point(x: x + width, y: y + height - r),
            data: color
        )
    }
    
    // Draw the four corner arcs using Bresenham's circle algorithm
    // Top-left corner (only the top-left quadrant)
    drawCircleQuadrant(layer: layer, xc: x + r, yc: y + r, r: r, quadrant: 2, color: color)
    
    // Top-right corner (only the top-right quadrant)
    drawCircleQuadrant(layer: layer, xc: x + width - r, yc: y + r, r: r, quadrant: 1, color: color)
    
    // Bottom-left corner (only the bottom-left quadrant)
    drawCircleQuadrant(layer: layer, xc: x + r, yc: y + height - r, r: r, quadrant: 3, color: color)
    
    // Bottom-right corner (only the bottom-right quadrant)
    drawCircleQuadrant(layer: layer, xc: x + width - r, yc: y + height - r, r: r, quadrant: 4, color: color)
}

// Draw only one quadrant of a circle using Bresenham's algorithm
// quadrant: 1=top-right, 2=top-left, 3=bottom-left, 4=bottom-right
func drawCircleQuadrant(layer: Layer, xc: Int, yc: Int, r: Int, quadrant: Int, color: UInt32) {
    var x = 0
    var y = r
    var d = 3 - 2 * r
    
    func plotPoint(_ x: Int, _ y: Int) {
        var px = x
        var py = y
        
        switch quadrant {
        case 1: // Top-right
            px = xc + x
            py = yc - y
        case 2: // Top-left
            px = xc - x
            py = yc - y
        case 3: // Bottom-left
            px = xc - x
            py = yc + y
        case 4: // Bottom-right
            px = xc + x
            py = yc + y
        default:
            return
        }
        
        layer.draw { canvas in
            canvas.fillRectangle(at: Point(x: px, y: py), width: 1, height: 1, data: color)
        }
    }
    
    while y >= x {
        plotPoint(x, y)
        plotPoint(y, x)
        
        if d > 0 {
            y -= 1
            d = d + 4 * (x - y) + 10
        } else {
            d = d + 4 * x + 6
        }
        x += 1
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

    public init(width: Int, height: Int) {
        self.init(x: 0, y: 0, width: width, height: height)
    }

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
    public var selectionManager: SelectionManager?
    public let fontConfig: FontConfiguration

    public init(
        layer: Layer,
        width: Int,
        height: Int,
        selectionManager: SelectionManager? = nil,
        fontConfig: FontConfiguration = FontConfiguration()
    ) {
        self.layer = layer
        self.width = width
        self.height = height
        self.selectionManager = selectionManager
        self.fontConfig = fontConfig
    }
}

// The base protocol for all views - only concerned with rendering.
public protocol BrewView {
    /// Render the view into the drawing context.
    func render(in context: inout BrewUIContext)
}

// -----------------------------------------------------------------------------
// MARK: - Interactive Components
/// Interface for views that can be interacted with via selection.
/// (We're not using a protocol because of embedded Swift limitations)
public struct InteractiveState {
    public var isSelected: Bool = false
    public var action: (() -> Void)?

    public init(isSelected: Bool = false, action: (() -> Void)? = nil) {
        self.isSelected = isSelected
        self.action = action
    }
}

/// Manages selection state indices.
final public class SelectionManager {
    public private(set) var selectedIndex: Int = 0
    public private(set) var totalItems: Int = 0
    private var actions: [(() -> Void)?] = []
    
    public init() { }
    
    public func register(action: (() -> Void)?) {
        actions.append(action)
        totalItems = actions.count
    }
    
    public func select(index: Int) {
        if totalItems > 0 {
            selectedIndex = max(0, min(index, totalItems - 1))
        }
    }
    
    public var count: Int {
        return totalItems
    }
    
    public var currentAction: (() -> Void)? {
        guard !actions.isEmpty, selectedIndex < actions.count else {
            return nil
        }
        return actions[selectedIndex]
    }
    
    public func isSelected(at index: Int) -> Bool {
        return index == selectedIndex
    }
    
    /// Clear all registered actions for the next render pass.
    public func reset() {
        actions.removeAll()
        totalItems = 0
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

        // Check if this is a Button and store its action if it is.
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
// Has interactive properties but doesn't use protocol due to embedded Swift limitations.
// Update Button struct to use rounded rectangles
public struct Button: BrewView, FramedView {
    public let text: String?
    public let frame: Frame
    public let foregroundColor: UInt32
    public let selectionColor: UInt32
    public let onAction: () -> Void
    public let textPointSize: Int
    public let cornerRadius: Int

    // Static counter used during rendering to track button indices.
    static var currentButtonIndex = 0

    public var action: (() -> Void)? {
        return onAction
    }

    public init(
        text: String? = nil,
        frame: Frame,
        action: @escaping () -> Void
    ) {
        self.init(
            text: text,
            frame: frame,
            foregroundColor: Color.white.rawValue,
            selectionColor: Color.yellow.rawValue,
            textPointSize: 8,
            cornerRadius: 8,
            action: action
        )
    }

    public init(
        text: String? = nil,
        frame: Frame,
        foregroundColor: UInt32 = Color.white.rawValue,
        selectionColor: UInt32 = Color.yellow.rawValue,
        textPointSize: Int = 8,
        cornerRadius: Int = 8,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.frame = frame
        self.foregroundColor = foregroundColor
        self.selectionColor = selectionColor
        self.textPointSize = textPointSize
        self.cornerRadius = cornerRadius
        self.onAction = action
    }

    public func render(in context: inout BrewUIContext) {
        // Get the current button's index and increment the counter.
        let buttonIndex = Button.currentButtonIndex
        Button.currentButtonIndex += 1

        // Register this button's action with the selection manager if available.
        if let selManager = context.selectionManager, buttonIndex >= selManager.totalItems {
            selManager.register(action: action)
        }

        // Check if this button is selected.
        let isSelected = context.selectionManager?.isSelected(at: buttonIndex) ?? false

        // Use the appropriate color based on selection.
        let color: UInt32 = isSelected ? selectionColor : foregroundColor

        // Draw the button with rounded corners.
        fillRoundedRectangle(
            layer: context.layer,
            x: frame.x,
            y: frame.y,
            width: frame.width,
            height: frame.height,
            cornerRadius: cornerRadius,
            color: color
        )

        if let text = text {
            // Center text within button
            let verticalOffset = max(0, (frame.height - textPointSize) / 3)
            
            drawText(
                layer: context.layer,
                x: frame.x + cornerRadius,
                y: frame.y + verticalOffset,
                text: text,
                font: context.fontConfig.font(withSize: textPointSize),
                color: Color.black.rawValue
            )
        }
    }
}


public struct Text: BrewView, FramedView {
    public let text: String
    public let frame: Frame
    public let foregroundColor: UInt32
    public let pointSize: Int

    public init(
        _ text: String,
        frame: Frame,
        foregroundColor: UInt32 = Color.white.rawValue,
        pointSize: Int = 8
    ) {
        self.frame = frame
        self.text = text
        self.foregroundColor = foregroundColor
        self.pointSize = pointSize
    }

    public func render(in context: inout BrewUIContext) {
        let font = context.fontConfig.font(withSize: pointSize)
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
// These functions collect interactive elements and build a selection manager.
public func collectInteractiveViewsFromGroup(_ group: Group) -> SelectionManager {
    let selectionManager = SelectionManager()
    for child in group.children {
        // Check if the AnyBrewView wraps a Button.
        if child.isButton {
            selectionManager.register(action: child.buttonAction)
        }
        // Other container types could be handled here (e.g. nested groups).
    }
    return selectionManager
}

public func collectInteractiveViews<T: BrewView>(from view: T) -> SelectionManager {
    if let group = view as? Group {
        return collectInteractiveViewsFromGroup(group)
    } else if let button = view as? Button {
        let selectionManager = SelectionManager()
        selectionManager.register(action: button.action)
        return selectionManager
    }
    return SelectionManager()
}

// -----------------------------------------------------------------------------
// MARK: - BrewUIApp: The Declarative UI Runner
// This is the "engine" that runs the UI event loop.
public struct BrewUIApp<Content: BrewView> {
    var content: Content
    var selectionManager: SelectionManager
    let fontConfig: FontConfiguration

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
                frameBuffer: [UInt32],
                fontConfig: FontConfiguration = FontConfiguration()) {
        self.content = content
        self.pot = pot
        self.hwButton = hwButton
        self.buzzer = buzzer
        self.screen = screen
        self.layer = layer
        self.screenBuffer = screenBuffer
        self.frameBuffer = frameBuffer
        self.fontConfig = fontConfig

        // Initialize the selection manager.
        self.selectionManager = SelectionManager()

        // Reset the button counter before rendering.
        Button.currentButtonIndex = 0

        // Create a context with our selection manager for the initial render.
        var initialContext = BrewUIContext(
            layer: layer,
            width: screen.width,
            height: screen.height,
            selectionManager: self.selectionManager,
            fontConfig: self.fontConfig
        )

        // Render once to register all buttons and their actions.
        content.render(in: &initialContext)

        // Update our selection manager with the one that was modified during rendering.
        if let updatedManager = initialContext.selectionManager {
            self.selectionManager = updatedManager
        }
    }

    // Marked as mutating because we update self's buffers.
    public mutating func run() -> Never {
        var lastSelectedIndex = -1

        while true {
            if selectionManager.count > 0 {
                // 1) Map the potentiometer value to a selection index.
                let rawValue = pot.readRawValue()
                let totalItems = selectionManager.count
                let mapped = Int(Float(rawValue) * Float(totalItems) / Float(pot.maxRawValue))
                let clampedIndex = max(0, min(mapped, totalItems - 1))

                // 2) If the selected item changed, play a selection beep.
                if clampedIndex != lastSelectedIndex {
                    buzzer.set(frequency: 440, dutycycle: 0.5)
                    sleep(ms: 100)
                    buzzer.suspend()
                    lastSelectedIndex = clampedIndex
                    // Update the selection.
                    selectionManager.select(index: clampedIndex)
                }

                // 3) Render the content.
                renderContent()

                // 4) If the hardware button is pressed, activate the selected item.
                if hwButton.read() {
                    if let action = selectionManager.currentAction {
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
            } else {
                // No interactive views, just render the content.
                renderContent()
            }
            sleep(ms: 50)
        }
    }

    private mutating func renderContent() {
        // === First Pass: Collect Interactive Items (No drawing) ===
        
        // Reset the selection manager so that only visible buttons are registered.
        selectionManager.reset()
        
        // Reset button counter so that registration starts fresh.
        Button.currentButtonIndex = 0
        
        // Create a dummy context using the existing selection manager.
        var dummyContext = BrewUIContext(
            layer: layer,
            width: screen.width,
            height: screen.height,
            selectionManager: selectionManager,
            fontConfig: fontConfig
        )
        
        // Render the content to register visible interactive items.
        content.render(in: &dummyContext)
        
        // Preserve and clamp the previous selection index.
        let previousSelectedIndex = selectionManager.selectedIndex
        if previousSelectedIndex < selectionManager.totalItems {
            selectionManager.select(index: previousSelectedIndex)
        } else if selectionManager.totalItems > 0 {
            selectionManager.select(index: selectionManager.totalItems - 1)
        }
        
        // === Second Pass: Actual Drawing with Updated Selection Manager ===
        
        // Clear the screen.
        clearScreen(layer: layer, width: screen.width, height: screen.height)
        
        // Reset button counter again for the drawing pass.
        Button.currentButtonIndex = 0
        
        // Create a render context with the updated selection manager.
        var context = BrewUIContext(
            layer: layer,
            width: screen.width,
            height: screen.height,
            selectionManager: selectionManager,
            fontConfig: fontConfig
        )
        
        // Render the content for real.
        content.render(in: &context)
        
        // Render the final image to the display.
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

// -----------------------------------------------------------------------------
// MARK: - New Flexible Layout System
// This new layout system supports mixing Buttons, Text, and other BrewViews
// in declarative containers (VStack, HStack, ZStack) with conditional logic.
// Define the StackAlignment type.
public enum StackAlignment {
    case leading, center, trailing
}

// MARK: FramedView Protocol
// Require that a view provides its intrinsic frame.
public protocol FramedView {
    var frame: Frame { get }
}


// MARK: EmptyView
// A no-op view to use in conditionals.
public struct EmptyView: BrewView, FramedView, OffsetRenderable {
    public let frame: Frame = Frame(x: 0, y: 0, width: 0, height: 0)
    public func render(in context: inout BrewUIContext) { }
    public func render(withOffsetX offsetX: Int, offsetY: Int, in context: inout BrewUIContext) { }

    public init() { }
}

// MARK: OffsetRenderable Protocol
// Ensures that Button and Text support offset rendering.
public protocol OffsetRenderable: BrewView {
    func render(withOffsetX offsetX: Int, offsetY: Int, in context: inout BrewUIContext)
}

extension Button: OffsetRenderable {
    public func render(withOffsetX offsetX: Int, offsetY: Int, in context: inout BrewUIContext) {
        let offsetFrame = Frame(
            x: self.frame.x + offsetX,
            y: self.frame.y + offsetY,
            width: self.frame.width,
            height: self.frame.height
        )
        let offsetButton = Button(
            text: self.text,
            frame: offsetFrame,
            foregroundColor: self.foregroundColor,
            selectionColor: self.selectionColor,
            textPointSize: self.textPointSize,
            cornerRadius: self.cornerRadius,
            action: self.action ?? {}
        )
        offsetButton.render(in: &context)
    }
}

extension Text: OffsetRenderable {
    public func render(withOffsetX offsetX: Int, offsetY: Int, in context: inout BrewUIContext) {
        let offsetFrame = Frame(
            x: self.frame.x + offsetX,
            y: self.frame.y + offsetY,
            width: self.frame.width,
            height: self.frame.height
        )
        let offsetText = Text(
            self.text,
            frame: offsetFrame,
            foregroundColor: self.foregroundColor,
            pointSize: self.pointSize
        )
        offsetText.render(in: &context)
    }
}

// MARK: AnyFramedView Type Eraser
// Erases the concrete type of any BrewView that conforms to FramedView and OffsetRenderable.
public struct AnyFramedView: BrewView, FramedView, OffsetRenderable {
    private let _render: (inout BrewUIContext) -> Void
    private let _renderOffset: (Int, Int, inout BrewUIContext) -> Void
    public let shouldIgnoreSpacing: Bool
    public let frame: Frame

    public init<T: BrewView & FramedView & OffsetRenderable>(_ view: T) {
        self._render = view.render
        self._renderOffset = view.render(withOffsetX:offsetY:in:)
        self.frame = view.frame
        if view as? EmptyView != nil {
            self.shouldIgnoreSpacing = true
        } else {
            self.shouldIgnoreSpacing = false
        }
    }

    public func render(in context: inout BrewUIContext) {
        _render(&context)
    }

    public func render(withOffsetX offsetX: Int, offsetY: Int, in context: inout BrewUIContext) {
        _renderOffset(offsetX, offsetY, &context)
    }
}

// MARK: FramedViewBuilder Result Builder
@resultBuilder
public struct FramedViewBuilder {
    public static func buildBlock(_ components: [AnyFramedView]...) -> [AnyFramedView] {
        return components.flatMap { $0 }
    }
    public static func buildExpression(_ expression: AnyFramedView) -> [AnyFramedView] {
        return [expression]
    }
    public static func buildOptional(_ component: [AnyFramedView]?) -> [AnyFramedView] {
        return component ?? []
    }
    public static func buildEither(first component: [AnyFramedView]) -> [AnyFramedView] {
        return component
    }
    public static func buildEither(second component: [AnyFramedView]) -> [AnyFramedView] {
        return component
    }
    public static func buildArray(_ components: [[AnyFramedView]]) -> [AnyFramedView] {
        return components.flatMap { $0 }
    }
}

// MARK: Layout Containers
/// VStack: Arranges heterogeneous framed views vertically.
public struct VStack: BrewView, FramedView, OffsetRenderable {
    public let frame: Frame
    private let children: [AnyFramedView]
    private let spacing: Int
    private let alignment: StackAlignment
    private let fillParent: Bool

    /// If no frame is provided, we compute an intrinsic frame from the children
    /// but mark the stack to fill the parent's dimensions on render.
    public init(frame: Frame? = nil,
                spacing: Int = 10,
                alignment: StackAlignment = .center,
                @FramedViewBuilder content: () -> [AnyFramedView]) {
        self.children = content()
        self.spacing = spacing
        self.alignment = alignment

        if let providedFrame = frame {
            self.frame = providedFrame
            self.fillParent = false
        } else {
            // Compute intrinsic size based on children.
            let intrinsicHeight = children.reduce(0) { $0 + $1.frame.height } +
                                  (children.count > 1 ? spacing * (children.count - 1) : 0)
            let intrinsicWidth = children.map { $0.frame.width }.max() ?? 0
            self.frame = Frame(x: 0, y: 0, width: intrinsicWidth, height: intrinsicHeight)
            self.fillParent = true
        }
    }

    public func render(in context: inout BrewUIContext) {
        render(withOffsetX: 0, offsetY: 0, in: &context)
    }

    public func render(withOffsetX offsetX: Int, offsetY: Int, in context: inout BrewUIContext) {
        // If fillParent is true, override the stored frame dimensions with the context's dimensions.
        let effectiveFrame: Frame
        if fillParent {
            effectiveFrame = Frame(x: frame.x, y: frame.y, width: context.width, height: context.height)
        } else {
            effectiveFrame = Frame(
                x: frame.x,
                y: frame.y,
                width: frame.width == 0 ? context.width : frame.width,
                height: frame.height == 0 ? context.height : frame.height
            )
        }
        
        let containerX = effectiveFrame.x + offsetX
        let containerY = effectiveFrame.y + offsetY

        var currentY = 0
        for child in children {
            let childFrame = child.frame
            let newX: Int
            switch alignment {
            case .center:
                newX = (effectiveFrame.width - childFrame.width) / 2
            case .leading:
                newX = 0
            case .trailing:
                newX = effectiveFrame.width - childFrame.width
            }
            let childOffsetX = containerX + newX - childFrame.x
            let childOffsetY = containerY + currentY - childFrame.y
            child.render(withOffsetX: childOffsetX, offsetY: childOffsetY, in: &context)
            if !child.shouldIgnoreSpacing {
                currentY += childFrame.height + spacing
            }
        }
    }
}

/// HStack: Arranges heterogeneous framed views horizontally.
public struct HStack: BrewView, FramedView, OffsetRenderable {
    public let frame: Frame
    private let children: [AnyFramedView]
    private let spacing: Int
    private let alignment: StackAlignment

    /// If no frame is provided, the intrinsic dimensions are computed from the children.
    public init(frame: Frame? = nil,
                spacing: Int = 10,
                alignment: StackAlignment = .center,
                @FramedViewBuilder content: () -> [AnyFramedView]) {
        self.children = content()
        self.spacing = spacing
        self.alignment = alignment

        // Compute intrinsic width/height from the children.
        let intrinsicWidth = children.reduce(0) { $0 + $1.frame.width } +
                             (children.count > 1 ? spacing * (children.count - 1) : 0)
        let intrinsicHeight = children.map { $0.frame.height }.max() ?? 0

        if let providedFrame = frame {
            self.frame = providedFrame
        } else {
            // Even if intrinsic size is zero, store it.
            self.frame = Frame(x: 0, y: 0, width: intrinsicWidth, height: intrinsicHeight)
        }
    }

    public func render(in context: inout BrewUIContext) {
        render(withOffsetX: 0, offsetY: 0, in: &context)
    }

    public func render(withOffsetX offsetX: Int, offsetY: Int, in context: inout BrewUIContext) {
        // If width or height is zero, default to the parent's container.
        let effectiveFrame = Frame(
            x: frame.x,
            y: frame.y,
            width: frame.width == 0 ? context.width : frame.width,
            height: frame.height == 0 ? context.height : frame.height
        )
        let containerX = effectiveFrame.x + offsetX
        let containerY = effectiveFrame.y + offsetY

        var currentX = 0
        for child in children {
            let childFrame = child.frame
            let newY: Int
            switch alignment {
            case .center:
                newY = (effectiveFrame.height - childFrame.height) / 2
            case .leading:
                newY = 0
            case .trailing:
                newY = effectiveFrame.height - childFrame.height
            }
            let childOffsetX = containerX + currentX - childFrame.x
            let childOffsetY = containerY + newY - childFrame.y
            child.render(withOffsetX: childOffsetX, offsetY: childOffsetY, in: &context)
            currentX += childFrame.width + spacing
        }
    }
}

/// ZStack: Overlays heterogeneous framed views.
public struct ZStack: BrewView, FramedView, OffsetRenderable {
    public let frame: Frame
    private let children: [AnyFramedView]

    /// If no frame is provided, the intrinsic frame is computed as the union of the children.
    public init(frame: Frame? = nil, @FramedViewBuilder content: () -> [AnyFramedView]) {
        self.children = content()
        if let first = children.first {
            var minX = first.frame.x
            var minY = first.frame.y
            var maxX = first.frame.x + first.frame.width
            var maxY = first.frame.y + first.frame.height

            for child in children.dropFirst() {
                minX = min(minX, child.frame.x)
                minY = min(minY, child.frame.y)
                maxX = max(maxX, child.frame.x + child.frame.width)
                maxY = max(maxY, child.frame.y + child.frame.height)
            }
            let intrinsicFrame = Frame(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
            if let providedFrame = frame {
                self.frame = providedFrame
            } else {
                self.frame = intrinsicFrame
            }
        } else {
            self.frame = frame ?? Frame(x: 0, y: 0, width: 0, height: 0)
        }
    }

    public func render(in context: inout BrewUIContext) {
        render(withOffsetX: 0, offsetY: 0, in: &context)
    }

    public func render(withOffsetX offsetX: Int, offsetY: Int, in context: inout BrewUIContext) {
        let effectiveFrame = Frame(
            x: frame.x,
            y: frame.y,
            width: frame.width == 0 ? context.width : frame.width,
            height: frame.height == 0 ? context.height : frame.height
        )
        let containerX = effectiveFrame.x + offsetX
        let containerY = effectiveFrame.y + offsetY

        for child in children {
            child.render(withOffsetX: containerX, offsetY: containerY, in: &context)
        }
    }
}
