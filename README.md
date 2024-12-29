# GUI for wren on MacOS

The wren language is a very nice, small, object-oriented language designed for easy embedding in applications written in the C language. As such, it lacks virtually all I/O, although some are added to the language in the wren-cli project.

Wren has very good performance, and I believe it could be used for general-purpose applications as well. However, since it lacks a modern GUI I decided to implement one for MacOS.

## Introduction

The aim was to enable virtually all GUI elements and constructs on the Mac to be used in a suitable library module, as well as use the excellent closure capabilities of wren to enable call-backs (event handling) in wren. The following short example shows a full Mac application.

```c
import "gui" for Application, Window, Button, Label

class Hello is Application {
    construct new(name) {
        Application.new()
        _w = Window.standardWindow
        _w.title = name
    }
    window {_w}
}

//create application and its window
var myApp = Hello.new("HELLO WORLD")
var w = myApp.window

//A button first
var b = Button.new("OK", [10, 40, 100, 30])
b.onClick {
    myApp.terminate()
}
w.addPane(b)

//label
var lb = Label.new("Hello world!", [200, 150, 100, 20])
w.addPane(lb)

myApp.run()
```

Let's comment the code a little so we understand what's going on. Firstly, we create a class *Hello* to handle application-wide functions, such as providing the window reference. In there we create an *Application*, and using the provided *Window* class asks for a *standardWindow*; it asks for the reference for the main screen from *Application*, and sets a standard size and location for the window.

In this simple example the application only has one method, a getter for the window.

We then instantiate the *myApp* application from the *Hello* class, and asks for its window; we could of course also use the *myApp.window *reference instead if we so prefer.

We then create a button, placing it somewhere in the bottom left corner with a suitable frame. Frames are lists, *[x, y, width, height]*. Note how we give the button something to do when pressed: we use a closure (nameless function). Do note that these are used very frequently, and will execute in the context of the definition. In this case it would know about the *myApp*, w and b variables.

We then have to add it to the window. Note that in fact it is not added directly to the window, but to a pane (the socalled document view in Mac-speak), which is automatically created if not there.

If we create our own panes, we can add components to them in the same way. Please see the class hierarchy for the pane types we may use.

We do the same for a label, placing it somewhere in the middle of the window. The end result looks like this.

![Hello world screenshot](file:///Users/sam/Documents/wren-project/hello_world.png?msec=1735458552468)

We could streamline this particular example and omit the application class (and thus not have a way of adding application-wide methods if we need some).

```c
import "gui" for Application, Window, Button, Label

//create application and its window
var myApp = Application.new()
var w = Window.standardWindow

//controls
var b = Button.new("OK", [10, 40, 100, 30]) { myApp.terminate() }
var lb = Label.new("Hello world!", [200, 150, 100, 20])

w.addPane(b)
w.addPane(lb)

myApp.run()
```

However, we recommend create a subclass of *Application* for the app.

## Running applications

The easiest way to run the application is to invoke the wren compiler/interpreter with the file as argument from a terminal window.

```
wren hello_world.wren
```

There are a couple of considerations to keep in mind.

1. keep all files together in the same folder (or hierarchy). The wren `#import`statement will accept directory names, but it's definitely easer to use only only folder tree.
2. the *gui.wren* file must be included using `#import "gui" for ...`, as well as any of your modules
3. if the file name is *main.wren* it may be omitted. Wren will use this as a default; this is mainly used in real Mac applications (not invoked from the command line) as the binary in an application bundle cannot use any arguments
4. the default directory for imports is the executable directory if invoked on the command line; in an application bundle it's the *Resources* folder.

Of course the compiler/interpreter may have any suitable name; we used *wren* above.

## Implementation

Basically, this is an unmodified implementation of the *wren-main* distribution from Github (not the *wren-cli*), but with a driving *main.c* program as well as bindings to GUI elements.

The files are

| File | Description | Location |
| --- | --- | --- |
| libwren.a | wren library, generated from the distribution | ./lib |
| libwren.d | wren debugging library, generated from the distribution | ./lib |
| wren.h | wren header file | ./include |
| main.c | main C driving routine | ./src |
| wren-bindings.c | wren bindings between C and wren | ./src |
| wren-gui.m | GUI elements in Objective-C | ./src |
| wgd.sh | shell commands to compile/link debugging version | .   |
| wgp.sh | shell commands to compile/link production version | .   |
| wgd   wgp | wren CLI and virtual machine with GUI support | ./bin |
| gui.wren | GUI classes in wren | ./bin |

I haven't used Xcode, since this project is quite small and lends itself well to just an editor (I use VSCodium, with wren syntax colouring from *nelarius.vscode-wren-0.1.1.vsix*) and shell commands.

```shell
# compile GUI version with DEBUG
# execute in <root>, binary to ./bin and named wgd
clang -w -g -o bin/wgd -DDEBUG -framework Cocoa -framework AVFoundation ⏎
 -framework AVKit -framework Quartz -framework UniformTypeIdentifiers ⏎
 src/main.c src/wren-binding.c src/wren-gui.m -Iinclude lib/libwren_d.a
```

```shell
# compile GUI version, production
# execute in <root>, binary to ./bin and named wgp
clang -o bin/wgp -framework Cocoa  -framework AVFoundation -framework AVKit ⏎
 -framework Quartz  -framework UniformTypeIdentifiers ⏎
 src/main.c src/wren-binding.c src/wren-gui.m -Iinclude lib/libwren.a
# remove symbols
strip bin/wgp
```

These are in *wgd.sh* and *wgp.sh*, respectively.

If you aren't interested in developing the GUI further, and only wish to use it for your own applications, the simplest way forward is to create a suitable project directory and copy the *wgp* and *gui.wren* files to it and implement your own wren application there.

Note that in order to create 'real' MacOS applications, and not only command line ones (even if they do have a GUI) you must create an application bundle suitable for invoking with a double-click in the Finder. An application for this purpose is included in the appendix, *Create a MacOS Application*. It's also a good example of one!

You also may want to create a proper icon for your app. An example is in the appendix *Create a MacOS Icon*. This is a command line application, which nonetheless using the *gui.wren* framework.

<div style="page-break-after: always;"></div>

## Class hierarchy

The classes provided in the module *gui* stored in *gui.wren* are the following.

```
Application
Window
Pane
    ScrollPane
    ImagePane
    PlayerPane
    PolygonPane
    Control
        Button
        Label
        TextField
Set
Time
Timer
Point
Size
Colour
File
Event
Pointer
Font
Menu
MenuItem
Transform
```

Some of these are used extensively, others not at all (but included for completeness' sake). They are described below, together with all there methods.

Remember to import the classes you use.

### Application

This is the core of the implementation, and has several getter methods for obtaining information from the system.

```c
new()
```

The main constructor for an application. There can only be one *Application* at any one time. It provides the following information and components.

```c
mainScreen        the dimensions of the main display
mainWindow        the frame for the main window, [x, y, width, heigth]
executablePath    path to the wren executable
resourcePath      path to resources; for a terminal app it's the
                  executable path
homePath          path to the user's home directory
documentsPath     path to the user's document directory
applicationSupportPath    path to the app's support folder in ~/Library/...
commandArguments    list of strings with the command line used to start;
                    first is executable, the rest are arguments
```

We have many methods as well. They are listed below with comments.

```c
openPanel(types, multiple, directory)
```

types are allowed file types in a list. multiple and directory a true/false values if we allow multiple files to the selected and/or directories. The methods .returns a list of paths the user selected. Empty if none. Note that the types should be a list, e.g., ['txt', 'doc', 'log'], empty for any type [""].

The return is a list of files, or empty list if cancelled:

```c
var fileNames = Application.openPanel(["wren"], false, false)
if (fileNames.count == 0) ...
else ...
```

One may also save files.

```c
savePanel(defaultname, canCreateDirectory)
```

defaultName will be provided as the default (use "" for no default); canCreateDirectory is true/false to enable the user to optionally create new folders. The method returns the file name, or an empty string if cancelled.

```c
run()
terminate()
```

run() starts the application. MUST be last command in the script as nothing below this will be executed. terminate() is typically executed in response to a menu choice or button press, or some other user action.

```c
alert(title, message, style, button1, button2)
alert(message, style, button1, button2)    use window's title as title
alert(message, style, button1)             no second button
```

Opens an alert box with the indicated title and message. The styles are

```
0    normal (warning)
1    information
2    critical
```

The button1 and button2 are strings. Note that button2 may be omitted, e.g., for a simple OK message. The alert box returns the following values

```
1000    first (or only) button pressed
1001    second button
```

As an example, typical alert message use could be

```c
if (myApp.alert("Are you sure you want to exit", 1, "OK", "Cancel) == 1000) {
    myApp.terminate()
}
```

There is also support for playing sounds in Application:

```c
playSoundFile(file)            play file with full volume
playSoundFile(file, volume)    play with volume (0..1)
```

There is support for automatically executing code at startup and shutdown as follows.

```c
onStartup {...code...}    execute just before normal processing starts
onClose {...code...}      execute just before shutting everything down
```

Not that these may be invoked with *onStartup(function)* or *onClose(function)* as well, in which case the function will be executed; recall that the *{...}* syntax really is a shorthand for this.

There are methods for file and directory I/O as well.

```c
readFile(fileName)              read an existing file (name obtained with openPanel)
copyFile(from, to)              copy a file. Will silently overwrite
renameFile(from, to)            rename a file
fileExists(name)                true/false if a file exists. Use with savePanel
createDirectory(name)           create directory
deleteDirectory(name)           delete directory
executeFile(name, args, wait)   execute file with args as argument list.
                                Wait = true will suspend, else continue immediately
```

The I/O methods should really be moved to the *File* class.

## Window

The Window class is used to create the main window, as well as any other the application wish to use (such as, e.g., a preference window).

It has the following constructors.

```c
new()
new(title)
new(title, frame)
standardWindow    centred window, main for app, frame [0, 0, 500, 300]
```

We recommend that you use the standardWindow, giving it a title and colours as desired for the app's main window.

If you create a window in addition to the main window, you have to show and optionally close them as well.

```c
show()        show the newly created window
close()       close a window. Closing the last window terminates the app
```

We have the following dimension-related methods and setters/getters.

```c
frame              provide the list [x, y, width, height]
frame = (value)    set the frame
origin             provide the list [x, y]
origin = (value)   set the origin
x                  provide x (lower left corner)
x = (value)        set the x coordinate
y                  provide y (lower left corner)
y = (value)        set the y coordinate
width              provide the width
width = (value)    set the width
height             provide the height
height = (value)   set the height
size               provide the [width, height] list
size = (value)     set the size
centre             centre window on the screen
```

Note that the various methods all set and retrieve elements from the frame list.

Other similar setters/getters are

```c
title             provide the title string
title = (value)   set the title
colour            provide the window's background colour
colour = (value)  set the colour; please see Colour class
pane              the window's main (document) pane
pane = (value)    set the pane; please see Pane class
```

There are methods for event handling as well.

```c
mouseMoveEvents = (value)    enable (true) or disable (false) mouse movement events
mouseMove(block)    execute block code when a mouse is moved and events are enabled
```

These are not often used, since they enable events for all mouse movements and thus are quite demanding, and not only clicks and drags (for those, please see the Pane class). A typical use might be

```c
myWindow.mouseMoveEvents = true
myWindow.mouseMove {
    if ( Pointer.location ...) {
        ...do stuff
    }
}
```

On the other hand, the following is quite often used.

```c
onResize(block)     execute block code when window is resized
```

For example, suppose you write a game and do not want the user to be able to change the window size since it would mess up the careful placement of your wonderful components, you might write something like

```c
//ensure all things stay in place if window resized
var oldHeight = myGame.window.height
var oldWidth = myGame.window.width
myGame.window.onResize {
    myGame.window.height = oldHeight
    myGame.window.width = oldWidth
}
```

This would effectively ensure the width and height of the window always stays the same.

There is one method for handling key presses on the window (although this is normally handled by the Pane).

```c
keyDown(key, modifier, block)

where
   modifier=0 plain, 1=shift, 2=ctrl, 4=alt, 8=cmd, 64=fn
```

Unfortunately, the key is not the keyboard key but an Apple-defined code for the physical keys on the keyboard. The keys may be looked up here [https://stackoverflow.com/questions/1918841/how-to-convert-ascii-character-to-cgkeycode/14529841#14529841](https://stackoverflow.com/questions/1918841/how-to-convert-ascii-character-to-cgkeycode/14529841#14529841). And yes, I should provide this in the code (one day RSN).

There is a special method for changing the coordinate system of a window pane . The default value of this property is false which results in a non-flipped coordinate system. In a non-flipped coordinate system, the origin is in the lower-left corner of the view and positive y-values extend upward. In a flipped coordinate system, the origin is in the upper-left corner of the view and y-values extend downward. X-values always extend to the right.

```c
flip = (value)    set flip status to true or false
```

Note that this method changes the window's document pane, not the window itself; it's really a *Pane* method.

## Pane

All components are really added to panes (*NSViews* under the hood), as pointed out above in the discussion about *Windows*. Virtually all are also children of *NSViews*, and inherit most of their characteristics.

There are two constructors for *Panes*.

```c
new()            new 'bare' pane, without any properties, which have to be added later
new(frame)       create a pane with the given frame [x, y, width, height].
```

Its default colour is black. Arguably the most important method is to add panes, and perhaps to remove them too. See below.

```c
addPane(aPane)      add aPane as a subpane to the recipient pane.
removePane()        remove the recipient pane from the superpane where it resides
```

There are many methods related to the position and dimensions of a pane.

```c
frame                provide the current frame [x, y, width, height]
frame = (value)      set the frame
origin               provide the position of the frame [x, y]
origin = (value)     set the origin
position(x, y)       set the origin
x                    provide x coordinate
x = (value)          set the x
y                    provide the y coordinate
y = (value)          set the y
width                provide the width
width = (value)      set the width
height               provide the height
height = (value)     set the height
size                 provide the size [width, height]
size = (value)       set the size
```

There are some methods for colours and borders, too.

```c
colour                   provide the current background colour of a pane
colour = (value)         set the colour (see Colour class)
border = (value)         set the border width. Default is 0, no border
borderColour             get the border colour
borderColour = (value)   set the border colour
corner = (value)         set corner radius in pixels
shadow = (value)         set a shadow for the pane [radius, opacity]
opacity = (value)        set a pane's opacity, 0 fully transparent, 1 opaque
opacity(value)           set opacity
```

To make a pane circular you may write

```c
var myCircle = Pane.new([100, 100, 50, 50])  //create a square pane
myCircle.corner = 25                         //set to width/2
myCircle.colour = Colour.red
```

This would create a red circle at position [100, 100].

We may show and hide the pane as well.

```c
show                show a pane
hide                hide a pane
visible = (value)   same, show if true, hide if false
visible             provide visibility
setTopMost          place the pane above all others
```

There are some methods for animation and changing various characteristics of a pane.

```c
animate(type, from, to, by, duration)    animate of the type (string), from and to
                depend on the type (values or points); by is length of step
                until duration. Types are
anchorPoint
backgroundColor
borderColor
borderWidth
bounds
contents
contentsRect
cornerRadius
opacity
origin.*        x,y
position.*      x,y
rotation.*      x,y,z just rotation for z  (radians)
scale.*         x,y,z just scale for all
shadowColor
shadowOffset
shadowOpacity
shadowPath
shadowRadius
size.*          height, width
translation.*   x,y,z
transform.scale.*   x,y,z
```

Please see [https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreAnimation\_guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreAnimation_guide/AnimatableProperties/AnimatableProperties.html#//apple_ref/doc/uid/TP40004514-CH11-SW1) for details (Appendix B).

As an example, we may want to have a pane move from one position to another, and slowly fading away as it is doing so.

```c
moveFade(from, to, duration) {
    this.show
    this.animate("opacity", 1, 0, 0.1, duration)    //fade from 1 to 0 with 0.1s steps
    this.animate("position.x", from[0], to[0], 0.1, duration)
    this.animate("position.y", from[1], to[1], 0.1, duration)
    Timer.after(duration) {
        this.hide
    }
}
```

where from and to are *Points* [x, y] and duration is in seconds. Note that there is also a class *Transform* to create concatenable transformations and a method *applyTransform(trf)* on a recipient *Pane*. However, the above animations (at least partially) supercede this mechanism, and seem more flexible.

However, note that animations are transient, the underlying properties of the pane are not changed. For this reason it is advisable to first change the property one wishes to animated to its end value, and then affect the transformation from the beginning to the end. In this way the object will not 'snap' back to its pre-animated state once the animation is over.

We also provide full mouse and keyboard event support for *Panes*.

```c
getMouseLocation        get the [x, y] mouse position within the pane; see Pointer
mouseDown(block)        mouse event handling
mouseUp(block)
mouseMove(block)
mouseDrag(block)
rightMouseDown(block)
rightMouseUp(block)
rightMouseDrag(block)
keyDown(key, modifier, block)    key codes, modifiers as described in Window
```

Like for *Window*, we also have the flip method

```c
flip = (value)        set normal (false) or inverted y axis (true)
```

### ScrollPane

Quite often we wish to include larger contents in pane that would fit in the visible space. Then we can use a scrolling pane to keep the contents only partly visible, and scroll it either horizontally or vertically to show more as needed from time to time.

We use the following methods.

```c
new(frame)        create a scroll pane with the frame [x, y, width, height]
scrollFrame       provide the scrolling frame (the visible part of the pane)
```

Note that it is crucial to use a large enough size for the *ScrollPane* and to add it to a smaller *Pane*, which will contain the *ScrollPane* and that in turn will include any other components you wish to scroll into and out of view.

### ImagePane

In order to show images, such as photos or graphics files, we use *ImagePanes*. They may be constructed as follows.

```c
new(frame)              create with frame [x, y, width, height]
new(frame, file)        create with given frame and file. Scaling is default
                        so that the image fits with its original aspect
new(frame, file, scale) create with given frame, file and scale.
    The scale constants are
    0    centre image in pane, no resizing
    1    resize image to fit in frame; aspect not preserved
    2    resize image to fit in frame; preserve aspect
    3    same as 1
```

There are other useful methods as well.

```c
image(buffer, length, scale)    set image contained in memory buffer, with given
                                length, into the Pane. Scale as above.
imageFile(file, scale)          set image from file, with given scale
imageFile = (file)              set image from file, default scale 2 (see above)
tintImage(colour)               tint the image with colour (see class Colour).
                                Set opacity in the colour, else it will be opaque.
```

### PlayerPane

In order to show video content, we use a *PlayerPane*. It is also suitable for audio, even if the *Application* also supports playing local audio files.

```c
new(frame)           create a player with the frame [x, y, width, height]
play(url)            in the recipient player pane, show the video (or audio) from url
stop()               stop the playback
volume = (value)     set the volume, 0 silent to 1 full volume
rate = (value)       set the playback rate, 0 stopped, 1 full speed, >1 faster
```

Note that local files are perfectly OK, just use the proper url *file:///file_name*.

### PolygonPane

Sometimes we want to have a pane that isn't rectangular. For that use a *PolygonPane*.

```c
new(frame)              create the pane within the given frame rectangle
points = (value)        a list of the points that make of the polygon,
                        [[x0, y0], [x1, y1]...[xn, yn]].
                        The polygon will be closed (from [xn, yn] to [x0, y0]).
colour = (value)        set fill colour
border = (value)        set border width in pixels
borderColour = (value)  set border colour
```

### Control

*Control* is the superclass for all normal UI controls (and *Pane* is its superclass).

It has some generic methods common to virtually all controls.

```c
text                    get the text on the control
text = (value)          set the text on the control
textColour = (value)    set the text colour
font = (value)          set the font, see Font class
```

All controls of course respond to the *Pane's* methods as well.

#### Button

The standard button has many methods; it is one of the most used controls. Its constructors are

```c
new(title)                   button with the title
new(title, frame)            and also frame
new(title, frame, block)     and code to execute on clicks
```

There are methods for obtaining and changing its properties.

```c
keyEquivalent = (value)    pressing this key acts as if the button had been pressed
setAsDefault               setting the key equivalent to ENTER
setAsCancel                setting the key equivalent to ESC
style = (value)            set the style; values are
    1=rounded, 2=regular square, 5=disclosure, 6=shadowless square, 7=circular,
    8=textured square, 9=help, 10=small square, 11=textured rounded, 12=roundrect,
    13=recessed, 14=rounded disclosure, 15=inline
type = (value)             set the type of button; values are
    0=momentaryLight, 1=pushOnOff, 2=toggle, 3=switch (checkbox), 4=radio
    5=momentaryChange, 6=onOff, 7=momentaryPushIn, 8=accelerator,
    9=multilevel accelerator
state                      get current state (0=not pressed, 1=pressed)
state = (value)            set the state
```

In addition, we may set the code to execute on a press using

```c
onClick(block)            execute code in block
```

As an example, we can write

```c
var myButton = Button.new("OK", [10, 10, 100, 30])
myButton.onClick {
    System.print("Really OK?")
}
```

This can be written in many ways; one-liner, or several.

#### Label

A simple label may be created as follows.

```c
new(title)                create with title
new(title, frame)         in the frame
onClick(block)            execute block on clicks
```

Yes, a label can function as a feature-less button.

#### TextField

A *TextField* is also quite simple.

```c
new(text)               create with pre-filled text
new(text, frame)        in the frame
onTextEnd(block)        execute block on when exiting the field, ending editing
```

Most often we do not pre-fill the field:

```c
var myField = TextField.new("", [10, 10, 100, 20])
myField.onTextEnd {
    System.print("You entered %(myField.text)")
}
```

## Time

We have a number of methods to obtain times. All are *static* methods on the class *Time*.

```c
now                  provide number of seconds since 1.1.1970 (Unix time)
ticks                provide number of ticks since program started
dateTime(value)      get string date and time from value (returned from now)
today                get current date
sleep(secs)          sleep process for secs (blocking execution)
```

The returned string times are of the format YYYY-MM-DD HH:MM:SS, e.g., 2024-12-26 14:45. All numerical values are zero-padded on the left.

## Timer

It is very useful to be able to execute code after some time, or regularly.

```c
new(seconds)             create timer with seconds and start it
onTimer(block)           execute code with time is up
stop                     stop the timer
after(seconds, block)    execute code block when time is up
```

These are very useful. For instance, the following example.

```c
Timer.after(1) {
    System.print("There went your second!")
}
```

A second example shows a repetitive timer.

```c
var tmr = Timer.new(0.01)
tmr.onTimer {
    myMovingObject.update()
}
```

In that example we update an object 100 times a second. Note that we should stop that timer with a `tmr.stop` when we no longer wish to use it.

These timers are *not* blocking.

## Colour

Colours are created from four values: red, green, blue, and alpha (opacity). We have the following constructors.

```c
rgba(value)            value is a list [red, green, blue, alpha],
                       with each value 0..1 from none to full.
rgab(r, g, b, a)       colour from values in the range 0..255 from none to full
rgb(r, g, b)           same as above but with alpha pre-set to 1.0
```

We also have a range of pre-defined colours directly from the class.

```c
blue
red
green
yellow
black
white
grey
lightGrey
darkGrey
darkSlate
grey20
grey60
grey70
grey78
maroon
brown
orange
```

These are all used in the same way, e.g., `myPane.colour = Colour.red`. This is also the most common usage for *Colour*.

## File

In order to do file I/O, we use the *File* class.

```c
create(path)                create a new file from path. Existing files will be overwritten
open(path)                  open an existing file
openMode(path, mode)        open or create file with a given mode
                            (a combination of r, w, a, and +)
close()                     close an open file
write(text)                 write text to a file
read()                      read the whole file
size                        provide file size
```

We must ensure that we handle errors correctly. For instance, in order to read a file it should exist. We could use something like the following.

```c
        ...
        var f
        var fiber = Fiber.new {
            f = File.open(n)
        }
        var error = fiber.try()
        if (error) return ""        //handle error somehow
        var b = f.read()            //get whole file
        ...
```

## Pointer

In order to obtain the current cursor position, we use

```c
location    get position of cursor [x, y]
```

Thus we always use this a *Pointer.location*.

## Font

Very often we wish to show labels and other components in a specific font. We create these as follows.

```c
new(name, size, bold, italic)    create new font with the indicated characteristics.
```

For example, we may want to show a time in a game quite prominently, and use

```c
var tm = Label.new("", [550, 450, 400, 200])  //show time in seconds
tm.font = Font.new("Helvetica-Bold", 200, true, false)
tm.textColour = Colour.orange
```

We then use a timer to actually show the current

```c
var seconds = 0
var tmr = Timer.new(1)
tmr.onTimer {
    seconds = seconds + 1
    tm.text = seconds.toString
}
```

This would then update the counter every seconds independently from any other code, until the timer is stopped.

## Menu

On the Mac virtually all applications use menus (if for nothing else, then to provide an About box and a way to exit the application with COMMAND-Q). For that, we use the *Menu* and *MenuItem* classes

```c
new(title)             create menu with title
menubar                get the main menu bar for the application
menu(submenu)          set the submenu as a subordinate menu for the recipient
addMenuItem(item)      add item to a menu
addMenu(title, items)  add list of items to a menu with title
```

See example below *MenuItem*.

## MenuItem

The actual menu items are created using this class.

```c
new(title, key, block)    create item with text, key equivalent to launch it, and code
new(title, key)           create with title and key
new(title)                create with title only
onClick(block)            set code to execute for item
text = (value)            set item text
enable = (value)          enable (true) or disable (false) item
separator()               create separator line item
```

As an example, a typical menu would be created as follows.

```c
//create main menu (bar)
var mb = Menu.menubar()

var m1 = []                    //list of first menu items
var miAbout = MenuItem.new("About", "") {
    myApp.alert("TEST", "About me", 1, "OK", "")
}
var miQuit = MenuItem.new("Quit", "q") {
    myApp.terminate()
}

m1.add(miAbout)
m1.add(MenuItem.separator())
m1.add(miQuit)

mb.addMenu("Test", m1)    //NB: the first menu's name will always be the process name
                          //(not 'Test' as here)!
```

We could of course write this more concisely as

```c
...
m1.add(MenuItem.new("About", "") { myApp.alert("TEST", "About me", 1, "OK", "") } )
m1.add(MenuItem.new("Quit", "q") { myApp.terminate() } )
mb.addMenu("", m1)
```

or even everything on one line.

## Transform

Sometimes it is useful to apply transformations to *Panes* for special effects.

```c
scale(x, y)        create scaling transform
rotate(x)          rotation x degrees
translate(x, y)    move transform
shear(x, y)        shear transform (turn x and y axes separately indicated degrees)
concat(trf)        concatenate trf to recipient transform
```

In order to use the transform, we *applyTransform(trf)* on the recipient *Pane*.

Note that a transform only affects the rendering of a *Pane*, not its underlying real properties.

It may be preferable to use animations (see *Pane*) instead as they seem more flexible.

---

<div style="page-break-after: always;"></div>

# Appendix: Create a MacOS Application

As a full example, we write a program to create a real MacOS application. Note that several lines are too long to fit within the margins; for these they end in ⏎ which means that the line that follows should be combined with this into one line.

```c
//
// create Mac app from wren source files
//
// V1.0 Sam Sandqvist 2024

import "gui" for Application, Window, Button, Pane, Label, TextField, ImagePane, ⏎
 Colour, File, Time, Menu, MenuItem

class CreateApp is Application {
    construct new(name) {
        Application.new
        _w = Window.standardWindow
        _w.title = name
        _w.colour = Colour.lightGrey
    }
    window {_w}
}

//the program structure we want to create
class Program {
    construct new(name) {
        _targetFile = name
        _name = name.split("/")[-1]
        _copy = "© 2024 Sam Sandqvist / Cogex AB"
        _version = "1.0"
        _sign = "SSQ"
        _file = ""
    }
    vm = (value) { _vm = value }
    main = (value) { _main = value }
    icon = (value) { _icon = value }
    image = (value) { _image = value }
    file = (value) { _file = value }
    version = (value) { _version = value }
    sign = (value) { _sign = value }
    copyright = (value) { _copy = value}
    resources = (value) { _resources = value }

    create() {
        //directory structure
        Application.createDirectory(_targetFile)
        Application.createDirectory(_targetFile + "/Contents")
        Application.createDirectory(_targetFile + "/Contents/MacOS")
        Application.createDirectory(_targetFile + "/Contents/Resources")
        //icon file
        if (_icon != "") {
            Application.copyFile(_icon, _targetFile + "/Contents/Resources/" ⏎
            + _icon.split("/")[-1])
        }
        //vm file
        Application.copyFile(_vm, _targetFile + "/Contents/MacOS/" + _name)
        //main file
        Application.copyFile(_main, _targetFile + "/Contents/Resources/main.wren")
        //resources
        for (each in _resources) {
            Application.copyFile(each, _targetFile + "/Contents/Resources/" ⏎
            + each.split("/")[-1])
        }
        //create Info.plist
        var nl = "\n"
        var s = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" + nl
        s = s + "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" ⏎
         \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">" + nl
        s = s + "<plist version=\"1.0\">" + nl
        s = s + "<dict>" + nl
        s = s + "<key>CFBundleDevelopmentRegion</key>" + nl
        s = s + "<string>English</string>" + nl
        s = s + "<key>CFBundleDisplayName</key>" + nl
        s = s + "<string>" + _name + "</string>" + nl
        s = s + "<key>CFBundleExecutable</key>" + nl
        s = s + "<string>" + _name + "</string>" + nl
        s = s + "<key>CFBundleIconFile</key>" + nl
        s = s + "<string>" + _icon.split("/")[-1] + "</string>" + nl
        s = s + "<key>CFBundleIdentifier</key>" + nl
        s = s + "<string>org.cogex." + _name + "</string>" + nl
        s = s + "<key>CFBundleInfoDictionary</key>" + nl
        s = s + "<string>6.0</string>" + nl
        s = s + "<key>CFBundlePackageType</key>" + nl
        s = s + "<string>APPL</string>" + nl
        s = s + "<key>CFBundleShortVersionString</key>" + nl
        s = s + "<string>" + _version + "</string>" + nl
        s = s + "<key>CFBundleLongVersionString</key>" + nl
        s = s + "<string>" + _version + "</string>" + nl
        s = s + "<key>CFBundleSignature</key>" + nl
        s = s + "<string>" + _sign + "</string>" + nl
        s = s + "<key>CFBundleTypeName</key>" + nl
        s = s + "<string>" + _name + " file</string>" + nl
        s = s + "<key>CFBundleExtensions</key>" + nl
        s = s + "<array>" + nl
        s = s + "<string>" + _file + "</string>" + nl
        s = s + "</array>" + nl
        s = s + "<key>CFBundleVersion</key>" + nl
        s = s + "<string>" + _version + "</string>" + nl
        s = s + "<key>NSHumanReadableCopyright</key>" + nl
        s = s + "<string>" + _copy + "</string>" + nl
        s = s + "</dict>" + nl
        s = s + "</plist>" + nl

        var infoFile = File.create(_targetFile + "/Contents/Info.plist")
        infoFile.write(s)
        infoFile.close()

        //rename directory to .app, first delete old
        Application.deleteDirectory(_targetFile + ".app")
        Application.renameFile(_targetFile, _targetFile + ".app")
    }
}

//create application and its window
var myApp = CreateApp.new("Create Wren Application")
var wh = 530
var ww = 600
myApp.window.frame = [0, 0, ww, wh]
myApp.window.centre

//standard buttons
var ok = Button.new("OK", [10, 10, 80, 30])
ok.setAsDefault
var cancel = Button.new("Cancel", [95, 10, 80, 30])
cancel.setAsCancel

var nameLabel = Label.new("Application name:", [20, wh - 100, 120, 20])
var btnName = Button.new("Save as...", [250, wh - 100, 100, 20])
var nameText = Label.new("", [350, wh - 100, 100, 20])
var programLabel = Label.new("Wren virtual machine file:", [20, wh - 160, 300, 20])
var btnProgram = Button.new("Select...", [250, wh - 162, 80, 30])
var programName = Label.new("", [350, wh - 160, 100, 20])
var versionLabel = Label.new("Version:", [460, wh - 160, 100, 20])
var versionField = TextField.new("1.0", [530, wh - 160, 50, 20])
var iconLabel = Label.new("Icon:", [20, wh - 200, 100, 20])
var btnIcon = Button.new("Select...", [250, wh - 202, 80, 30])
var iconImage = ImagePane.new([350, wh - 200, 30, 30])
iconImage.border = 1
iconImage.colour = Colour.grey
var signLabel = Label.new("Sign:", [460, wh - 200, 100, 20])
var signField = TextField.new("SSQ", [530, wh - 200, 50, 20])
var mainLabel = Label.new("Main Wren [.wren] file:", [20, wh - 240, 200, 20])
var btnMain = Button.new("Select...", [250, wh - 240, 80, 30])
var mainFile = Label.new("", [350, wh - 240, 100, 20])
var resourceLabel = Label.new("Other [.wren] and resource files:", ⏎
 [20, wh - 280, 300, 20])
var btnResource = Button.new("Select...", [250, wh - 282, 80, 30])
var fileLabel = Label.new("Opens files of type:", [400, wh - 280, 200, 20])
var fileField = TextField.new("", [530, wh - 280, 50, 20])
var resourceList = Label.new("", [20, wh - 420, 560, 130])
resourceList.border= 1
resourceList.borderColour = Colour.darkGrey
var copyLabel = Label.new("Copyright message:", [20, wh - 450, 200, 20])
var copyField = TextField.new("", [250, wh - 450, 330, 20])

//actions
var temp
var nameField = ""
var program = ""
var iconName = ""
var mainName = ""
var resources = []
btnName.onClick {
    nameField = Application.savePanel("", true)
    if (nameField != "") nameText.text = nameField.split("/")[-1]
}
btnProgram.onClick {
    temp = Application.openPanel("", false, false)
    if (temp.count == 0) return
    program = temp[0]
    programName.text = program.split("/")[-1]
}
btnIcon.onClick {
    temp = Application.openPanel(["icns"], false, false)
    if (temp.count == 0) return
    iconName = temp[0]
    if (iconName != "") {
        iconImage.imageFile(iconName, 2)
    }
}
btnMain.onClick {
    temp = Application.openPanel(["wren"], false, false)
    if (temp.count == 0) return
    mainName = temp[0]
    mainFile.text = mainName.split("/")[-1]
}
btnResource.onClick {
    resources = Application.openPanel("", true, false)
    resourceList.text = resources.join("\n")
}

//create the app
var prg

ok.onClick {
    //checks
    if (nameField == "") {
        myApp.alert("Target name missing", 2, "OK")
        return
    } else {
        prg = Program.new(nameField)
    }
    if (program == "") {
        myApp.alert("Virtual machine name missing", 2, "OK")
        return
    } else {
        prg.vm = program
    }
    prg.icon = iconName
    prg.file = fileField.text
    prg.version = versionField.text
    prg.sign = signField.text
    if (mainName == "") {
        myApp.alert("Main wren file missing", 2, "OK", "")
        return
    } else {
        prg.main = mainName
    }
    prg.resources = resources
    prg.copyright = copyField.text

    if (Application.fileExists(nameField + ".app") && 1000 == ⏎
     myApp.alert("Create App", "File exists! Continue?", 2, "OK", "Cancel")) return
    if (myApp.alert("Create App", "Are you sure you want to create this app?", ⏎
     0, "OK", "Cancel") != 1001) {
        prg.create()
        myApp.alert("Saved", 1, "OK")
        myApp.window.close
    }
}
cancel.onClick { myApp.window.close }

//create main menu (bar)
var mb = Menu.menubar()

var m1 = []
var miAbout = MenuItem.new("About", "") { myApp.alert("Create Wren Application", ⏎
 "Create proper MacOS application V1.0\nCopyright © Sam Sandqvist 2024", 1, "OK", "")}
var miQuit  = MenuItem.new("Quit", "q") { myApp.terminate() }

m1.add(miAbout)
m1.add(MenuItem.separator())
m1.add(miQuit)
mb.addMenu("", m1)

myApp.window.addPane(ok)
myApp.window.addPane(cancel)
myApp.window.addPane(nameLabel)
myApp.window.addPane(btnName)
myApp.window.addPane(nameText)
myApp.window.addPane(programLabel)
myApp.window.addPane(btnProgram)
myApp.window.addPane(programName)
myApp.window.addPane(versionLabel)
myApp.window.addPane(versionField)
myApp.window.addPane(iconLabel)
myApp.window.addPane(btnIcon)
myApp.window.addPane(iconImage)
myApp.window.addPane(signLabel)
myApp.window.addPane(signField)
myApp.window.addPane(fileLabel)
myApp.window.addPane(fileField)
myApp.window.addPane(mainLabel)
myApp.window.addPane(btnMain)
myApp.window.addPane(mainFile)
myApp.window.addPane(resourceLabel)
myApp.window.addPane(btnResource)
myApp.window.addPane(resourceList)
myApp.window.addPane(copyLabel)
myApp.window.addPane(copyField)

myApp.run
```

The application will look like this.

![createAppscreenshotpng](file:///Users/sam/Documents/wren-project/createApp_screenshot.png?msec=1735458552457)

The application name is the target application, e.g. **CreateApp**, and the wren virtual machine file is the compiler/interpreter (I have two: **wgd** for debugging, and **wgp** for production use). This will be renamed to the application name in the application bundle. The version number may be entered as desired. The icon must be a MacOS icon file (e.g., **createApp.icns**). The sign is required by the Mac; you may put in whatever signature you like. The main wren file should then be given, e.g., selecte **createApp.wren**. It will be renamed in the application bundle to **main.wren** in order for the interpreter to start it automatically. Then the resources, i.e., other files that your application requires. Please enter at least **gui.wren**, and perhaps image files if you use any. The open files of type indicates which files this application can open when a file of that time is double-clicked. Your app should be able to handle them in that case. Finally, you may enter an optional copyright message,

The application has a minimal menu as well: just an About item and quit (which may be invoked with COMMAND-Q).

If all goes well it will tell you so, or if not, what's wrong.

<div style="page-break-after: always;"></div>

# Appendix: Create a MacOS Icon

As an example of a command-line application that uses some of the classes in *gui.wren* we have the quite useful program to generate a proper MacOS icon (**.icns**) from an image file (e.g., **.png**).

We include this in the file *genicons.wren*.

```c
//generate icons, based on Python genicons.py
//use:
// bin/wgp genicons.wren myicon.png
//
// will create a directory myicon.iconset and a ready icon file myicon.icns

import "gui" for Application

//get image filename
if (Application.commandArguments.count < 3) {
    System.print("No image file specified")
    Application.terminate
}

var originalPicture = Application.commandArguments[2]
if (!Application.fileExists(originalPicture)) {
    System.print("No such image file")
    Application.terminate
}

//form variables and create directory
var fname = originalPicture.split("/")[-1].split(".")[0]
var ext = originalPicture.split("/")[-1].split(".")[-1]
var iconsetDir = fname + ".iconset"

if (Application.fileExists(iconsetDir)) {
    Application.deleteDirectory(iconsetDir)
}
Application.createDirectory(iconsetDir)

//function to create correct icon file names
var iconPars = Fn.new {|width, scale|
    return (scale == 2) ? ("icon_" + width.toString + "x" + width.toString + "." + ext) : ("icon_" + (width/2).toString + "x" + (width/2).toString + "@2x." + ext)
}

// https://developer.apple.com/design/human-interface-guidelines/macos/ ⏎
//  icons-and-images/app-icon#app-icon-sizes

var listOfIconParameters = [
    iconPars.call(16, 2),
    iconPars.call(32, 2),
    iconPars.call(64, 1),
    iconPars.call(64, 2),
    iconPars.call(128, 2),
    iconPars.call(256, 2),
    iconPars.call(512, 1),
    iconPars.call(512, 2),
    iconPars.call(1024, 1),
    iconPars.call(1024, 2)
]

//generate iconset
for (ip in listOfIconParameters) {
    var w = Num.fromString(ip.split("_")[-1].split("x")[0])
    w = ip.contains("@") ? w*2: w
    Application.executeFile("/usr/bin/sips", ["-z", w.toString, w.toString, ⏎
 originalPicture, "--out", iconsetDir + "/" + ip], true)
}

//convert iconset to icns file
Application.executeFile("/usr/bin/iconutil", ["-c", "icns", iconsetDir, "-o", ⏎
 fname + ".icns"], true)

Application.terminate
```
