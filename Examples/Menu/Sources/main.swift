// The Swift Programming Language
// https://docs.swift.org/swift-book
print("Hello, world!")
print(Color.red.rawValue)
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
            AnyFramedView(Text(" ",
                               frame: Frame(width: 200, height: 10)))
            AnyFramedView(Text("EARBII",
                               frame: Frame(width: 200, height: 25)))

            AnyFramedView(Button(text: "OPTION A",
                                 frame: Frame(width: 200, height: 30)) {
                print("Option A selected")
            })
            AnyFramedView(Button(text: "OPTION B",
                                 frame: Frame(width: 200, height: 30)) {
                print("Option B selected")
            })
            AnyFramedView(Button(text: "MORE",
                                 frame: Frame(width: 200, height: 30)) {
                print("More selected")
                viewModel.showExtraOption.toggle()
            })

            if viewModel.showExtraOption { 
                AnyFramedView(Button(text: "EXTRA",
                                     frame: Frame(width: 200, height: 30)) {
                    print("Extra Option selected")
                })
            } else {
                AnyFramedView(EmptyView())
            }

            AnyFramedView(HStack(spacing: 10) {
                AnyFramedView(Button(text: "X",
                                 frame: Frame(width: 60, height: 30)) {
                    print("Option C selected")
                })
                AnyFramedView(Button(text: "Y",
                                    frame: Frame(width: 60, height: 30)) {
                    print("Option D selected")
                })
                AnyFramedView(Button(text: "Z",
                                    frame: Frame(width: 60, height: 30)) {
                    print("Option E selected")
                })
            })
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

// let myFontConfig = FontConfiguration(
//     defaultFontPath: "/SD:/Itim-Regular.ttf", 
//     defaultPointSize: 10, 
//     defaultDPI: 240
// )


// Create the app.
var app = BrewUIApp(content: contentView,
                   pot: pot,
                   hwButton: hwButton,
                   buzzer: buzzer,
                   screen: screen,
                   layer: layer,
                   screenBuffer: screenBuffer,
                   frameBuffer: frameBuffer/*,
                   fontConfig: myFontConfig*/)

// Run the app.
app.run()