//
// Example hello_world.wren
//

import "gui" for Application, Window, Button, Label, Colour, Pane

// class Hello is Application {
//     construct new(name) {
//         Application.new()
//         _w = Window.standardWindow
//         _w.title = name
//     }
//     window {_w}
// }

//create application and its window
var myApp = Application.new()
var w = Window.standardWindow

//controls
var b = Button.new("OK", [10, 40, 100, 30]) { myApp.terminate() }
var lb = Label.new("Hello world!", [200, 150, 100, 20])

w.addPane(b)
w.addPane(lb)

var myCircle = Pane.new([100, 100, 50, 50])  	//create a square pane
myCircle.corner = 25							//set to width/2
myCircle.colour = Colour.red
myCircle.border = 2
myCircle.shadow = [1, 0.15]

w.addPane(myCircle)

myApp.run()
