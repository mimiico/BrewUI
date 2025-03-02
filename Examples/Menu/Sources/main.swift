// The Swift Programming Language
// https://docs.swift.org/swift-book
print("Hello, world!")
import SwiftIO
import MadBoard
import ST7789
import MadGraphics
import BrewUI

class ContentViewModel {
    var showExtraOption: Bool = false
}

// -----------------------------------------------------------------------------
// MARK: - Sample Usage: ContentView and App Launch
// This sample content view is written using the new flexible layout system.
struct ContentView: BrewView {
    let viewModel = ContentViewModel()
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
            AnyFramedView(Button(text: "More",
                                 frame: Frame(x: 0, y: 0, width: 200, height: 30),
                                 foregroundColor: Color.blue.rawValue) {
                print("More selected")
                viewModel.showExtraOption.toggle()
            })

            if viewModel.showExtraOption { 
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