// The Swift Programming Language
// https://docs.swift.org/swift-book
print("Hello, world!")
import SwiftIO
import MadBoard
import ST7789
import MadGraphics
import BrewUI

// Define an EmptyView for conditionals.
struct EmptyView: BrewView, FramedView, OffsetRenderable {
    let frame: Frame = Frame(x: 0, y: 0, width: 0, height: 0)
    func render(in context: inout BrewUIContext) { }
    func render(withOffsetX offsetX: Int, offsetY: Int, in context: inout BrewUIContext) { }
}

// -----------------------------------------------------------------------------
// MARK: - Sample Usage: ContentView and App Launch
// This sample content view is written using the new flexible layout system.
struct ContentView: BrewView {
    // Declare the UI in a computed property, similar to SwiftUI.
    var body: some BrewView {
        VStack(spacing: 10, alignment: .center) {
            AnyFramedView(Button(text: "Option A",
                                 frame: Frame(x: 0, y: 0, width: 200, height: 30)) {
                print("Option A selected")
            })
            AnyFramedView(Button(text: "Option B",
                                 frame: Frame(x: 0, y: 0, width: 200, height: 30)) {
                print("Option B selected")
            })
            AnyFramedView(Button(text: "Option C",
                                 frame: Frame(x: 0, y: 0, width: 200, height: 30),
                                 foregroundColor: Color.blue.rawValue) {
                print("Option C selected")
            })
            // Conditional UI logic:
            // If the condition is true, show the extra button; otherwise, show an EmptyView.
            if true { // Replace 'true' with your condition (e.g., showExtraOption)
                AnyFramedView(Button(text: "Extra Option",
                                     frame: Frame(x: 0, y: 0, width: 200, height: 30),
                                     foregroundColor: Color.green.rawValue) {
                    print("Extra Option selected")
                })
            } else {
                AnyFramedView(EmptyView())
            }
            
            AnyFramedView(Text("Hello, world!",
                               frame: Frame(x: 0, y: 0, width: 200, height: 30)))
        }
    }
    
    // Render the computed body.
    func render(in context: inout BrewUIContext) {
        body.render(in: &context)
    }
}

// ----------------------------------------------------------------------------
// MARK: - App Entry Point
let bl = DigitalOut(Id.D2)
let rst = DigitalOut(Id.D12)
let dc = DigitalOut(Id.D13)
let cs = DigitalOut(Id.D5)
let spi = SPI(Id.SPI0, speed: 30_000_000)
let screen = ST7789(spi: spi, cs: cs, dc: dc, rst: rst, bl: bl, rotation: .angle90)
var screenBuffer = [UInt16](repeating: 0, count: screen.width * screen.height)
let layer = Layer(at: .zero, anchorPoint: .zero,
                 width: screen.width, height: screen.height)
var frameBuffer = [UInt32](repeating: 0, count: screen.width * screen.height)
let pot = AnalogIn(Id.A0)
let hwButton = DigitalIn(Id.D1)
let buzzer = PWMOut(Id.PWM5A)
buzzer.suspend() // Buzzer off initially

// Create the content view.
let contentView = ContentView()

// Create the app.
var app = BrewUIApp(content: contentView,
                   pot: pot,
                   hwButton: hwButton,
                   buzzer: buzzer,
                   screen: screen,
                   layer: layer,
                   screenBuffer: screenBuffer,
                   frameBuffer: frameBuffer)

// Run the app.
app.run()