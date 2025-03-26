// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftIO
import MadBoard
import ST7789
import MadGraphics
import BrewUI

print("Hello, BrewUI!")

class ContentViewModel {
    var showExtraOption: Bool = false
    var showCalculator: Bool = false
    var calculatorDisplay: String = "0"
    var firstOperand: Int = 0
    var operation: String? = nil
    var resetDisplayOnNextInput: Bool = true
    
    func appendDigit(_ digit: Int) {
        if resetDisplayOnNextInput {
            calculatorDisplay = "\(digit)"
            resetDisplayOnNextInput = false
        } else {
            if calculatorDisplay == "0" {
                calculatorDisplay = "\(digit)"
            } else {
                calculatorDisplay += "\(digit)"
            }
        }
    }
    
    func setOperation(_ op: String) {
        firstOperand = Int(calculatorDisplay) ?? 0
        operation = op
        resetDisplayOnNextInput = true
    }
    
    func calculate() {
        guard let op = operation else { return }
        
        let secondOperand = Int(calculatorDisplay) ?? 0
        var result = 0
        
        switch op {
        case "+":
            result = firstOperand + secondOperand
        case "-":
            result = firstOperand - secondOperand
        case "*":
            result = firstOperand * secondOperand
        case "/":
            if secondOperand != 0 {
                result = firstOperand / secondOperand
            } else {
                calculatorDisplay = "Err"
                return
            }
        default:
            break
        }
        
        calculatorDisplay = "\(result)"
        operation = nil
        resetDisplayOnNextInput = true
    }
    
    func clear() {
        calculatorDisplay = "0"
        firstOperand = 0
        operation = nil
        resetDisplayOnNextInput = true
    }
}

// -----------------------------------------------------------------------------
// MARK: - Sample Usage: ContentView and App Launch
// This sample content view is written using the new flexible layout system.
struct ContentView: BrewView {
    let viewModel = ContentViewModel()
    // Declare the UI in a computed property, similar to SwiftUI.
    var body: some BrewView {
        VStack(spacing: 7, alignment: .center) {
            if viewModel.showCalculator {
                // Calculator UI
                AnyFramedView(Text(" ", frame: Frame(width: 200, height: 10)))
                AnyFramedView(Text(viewModel.calculatorDisplay,
                               frame: Frame(width: 200, height: 25)))
                
                // Row 1: 7, 8, 9, +
                AnyFramedView(HStack(spacing: 5) {
                    AnyFramedView(Button(text: "7",
                                 frame: Frame(width: 45, height: 30)) {
                        print("Pressed 7")
                        viewModel.appendDigit(7)
                    })
                    AnyFramedView(Button(text: "8",
                                 frame: Frame(width: 45, height: 30)) {
                        print("Pressed 8")
                        viewModel.appendDigit(8)
                    })
                    AnyFramedView(Button(text: "9",
                                 frame: Frame(width: 45, height: 30)) {
                        print("Pressed 9")
                        viewModel.appendDigit(9)
                    })
                    AnyFramedView(Button(text: "+",
                                 frame: Frame(width: 45, height: 30)) {
                        print("Pressed +")
                        viewModel.setOperation("+")
                    })
                })
                
                // Row 2: 4, 5, 6, -
                AnyFramedView(HStack(spacing: 5) {
                    AnyFramedView(Button(text: "4",
                                 frame: Frame(width: 45, height: 30)) {
                        print("Pressed 4")
                        viewModel.appendDigit(4)
                    })
                    AnyFramedView(Button(text: "5",
                                 frame: Frame(width: 45, height: 30)) {
                        print("Pressed 5")
                        viewModel.appendDigit(5)
                    })
                    AnyFramedView(Button(text: "6",
                                 frame: Frame(width: 45, height: 30)) {
                        print("Pressed 6")
                        viewModel.appendDigit(6)
                    })
                    AnyFramedView(Button(text: "-",
                                 frame: Frame(width: 45, height: 30)) {
                        print("Pressed -")
                        viewModel.setOperation("-")
                    })
                })
                
                // Row 3: 1, 2, 3, *
                AnyFramedView(HStack(spacing: 5) {
                    AnyFramedView(Button(text: "1",
                                 frame: Frame(width: 45, height: 30)) {
                        print("Pressed 1")
                        viewModel.appendDigit(1)
                    })
                    AnyFramedView(Button(text: "2",
                                 frame: Frame(width: 45, height: 30)) {
                        print("Pressed 2")
                        viewModel.appendDigit(2)
                    })
                    AnyFramedView(Button(text: "3",
                                 frame: Frame(width: 45, height: 30)) {
                        print("Pressed 3")
                        viewModel.appendDigit(3)
                    })
                    AnyFramedView(Button(text: "*",
                                 frame: Frame(width: 45, height: 30)) {
                        print("Pressed *")
                        viewModel.setOperation("*")
                    })
                })
                
                // Row 4: 0, C, =, /
                AnyFramedView(HStack(spacing: 5) {
                    AnyFramedView(Button(text: "0",
                                 frame: Frame(width: 45, height: 30)) {
                        print("Pressed 0")
                        viewModel.appendDigit(0)
                    })
                    AnyFramedView(Button(text: "C",
                                 frame: Frame(width: 45, height: 30)) {
                        print("Pressed C")
                        viewModel.clear()
                    })
                    AnyFramedView(Button(text: "=",
                                 frame: Frame(width: 45, height: 30)) {
                        print("Pressed =")
                        viewModel.calculate()
                    })
                    AnyFramedView(Button(text: "/",
                                 frame: Frame(width: 45, height: 30)) {
                        print("Pressed /")
                        viewModel.setOperation("/")
                    })
                })
                
                // Back button
                AnyFramedView(Button(text: "BACK",
                               frame: Frame(width: 200, height: 30)) {
                    print("Exiting calculator")
                    viewModel.showCalculator = false
                })
            } else {
                // Main menu UI
                AnyFramedView(Text(" ",
                               frame: Frame(width: 200, height: 10)))
                AnyFramedView(Text("EARBII",
                               frame: Frame(width: 200, height: 25)))

                AnyFramedView(Button(text: "CALCULATOR",
                                 frame: Frame(width: 200, height: 30)) {
                    print("Calculator selected")
                    viewModel.showCalculator = true
                })
                AnyFramedView(Button(text: "OPTION B",
                                 frame: Frame(width: 200, height: 30)) {
                    print("Option B selected")
                })
                if !viewModel.showExtraOption {
                    AnyFramedView(Button(text: "MORE",
                                    frame: Frame(width: 200, height: 30)) {
                        print("More selected")
                        viewModel.showExtraOption.toggle()
                    })
                } else {
                    AnyFramedView(Button(text: "COLLAPSE",
                                    frame: Frame(width: 200, height: 30)) {
                        print("Back selected")
                        viewModel.showExtraOption.toggle()
                    })
                }

                if viewModel.showExtraOption { 
                    AnyFramedView(Button(text: "EXTRA",
                                     frame: Frame(width: 200, height: 30)) {
                        print("Extra Option selected")
                    })
                } else {
                    AnyFramedView(EmptyView())
                }

                if !viewModel.showExtraOption {
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
                } else {
                    AnyFramedView(EmptyView())
                }
            }
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

let myFontConfig = FontConfiguration(
    defaultFontPath: "/SD:/AveriaSansLibre-Bold.ttf", 
    defaultPointSize: 10, 
    defaultDPI: 240
)

// Create the app.
var app = BrewUIApp(content: contentView,
                   pot: pot,
                   hwButton: hwButton,
                   buzzer: buzzer,
                   screen: screen,
                   layer: layer,
                   screenBuffer: screenBuffer,
                   frameBuffer: frameBuffer,
                   fontConfig: myFontConfig)

// Run the app.
app.run()