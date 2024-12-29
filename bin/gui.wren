//Wren GUI
//
// Sam Sandqvist 2024
//
// v1.01 2024-12-15
//

class Set {
  construct new() {
    _map = Map.new()
  }

  // Adds an item to the set
  add(item) {
    _map[item] = true
  }

  // Removes an item from the set
  remove(item) {
    _map.remove(item)
  }

  // Checks if the set contains an item
  contains(item) {
    return _map.containsKey(item)
  }

  // Gets the size of the set
  count {
    return _map.count
  }

  // Clears the set
  clear() {
    _map.clear()
  }

  // Converts the set to a list
  toList() {
    return _map.keys
  }

  // Iterates over the set
  iterate(fn) {
    for (key in _map.keys) {
      fn.call(key)
    }
  }
}

class Time {
    foreign static now
    foreign static ticks
    foreign static dateTime(x)
    static today {Time.dateTime(now)}
    foreign static sleep(secs)
}

class Point {
    construct new(x,y) {
        _p = [x, y]
    }
    construct new() {
        _p = [0, 0]
    }
    static new {
        return new(0,0)
    }
    x { _p[0] }
    y { _p[1] }
    x = (value) { _p[0] = value }
    y = (value) { _p[1] = value }
    + (value) { _p = [this.x + value.x, this.y + value.y] }
    - (value) { _p = [this.x - value.x, this.y - value.y] }
    toString { _p.toString }
    static close(first, second, delta) {
        if ((first[0] - second[0]).abs > delta) return null
        if ((first[1] - second[1]).abs > delta) return null
        return second
    }
}

class Size {
    construct new(w,h) {
        _p = [w, h]
    }
    construct new() {
        _p = [0, 0]
    }
    width { _p[0] }
    height { _p[1] }
    width = (value) { _p[0] = value }
    height = (value) { _p[1] = value }
    + (value) { _p = [this.width + value.width, this.height + value.height] }
    - (value) { _p = [this.width - value.width, this.height - value.height] }
    toString { _p.toString }
}

class Colour {
    construct rgba(ll) {
        _value = ll     //list value
    }
    construct rgba(r, g, b, a) {
        _value = [r/255, g/255, b/255, a/255]
    }
    construct rgb(r, g, b) {
        _value = [r/255, g/255, b/255, 1.0]
    }
    value { _value }
    toString { _value[0].toString + ";" + _value[1].toString + ";" + _value[2].toString + ";" + _value[3].toString }
    static blue   { [0.0, 0.0, 1.0, 1.0] }
    static red    { [1.0, 0.0, 0.0, 1.0] }
    static green  { [0.0, 1.0, 0.0, 1.0] }
    static yellow { [1.0, 1.0, 0.0, 1.0] }
    static black  { [0.0, 0.0, 0.0, 1.0] }
    static white  { [1.0, 1.0, 1.0, 1.0] }
    static grey       { [190/255, 190/255, 190/255, 1.0] }
    static lightGrey  { [211/255, 211/255, 211/255, 1.0] }
    static darkGrey   { [ 77/255,  77/255,  77/255, 1.0] }
    static darkSlateGrey { [47/255, 79/255, 79/255, 1.0] }
    static grey20     { [ 51/255,  51/255,  51/255, 1.0] }
    static grey60     { [153/255, 153/255, 153/255, 1.0] }
    static grey70     { [178/255, 178/255, 178/255, 1.0] }
    static grey78     { [199/255, 199/255, 199/255, 1.0] }
    static maroon     { [128/255,     0.0,     0.0, 1.0] }
    static brown      { [165/255,  42/255,  42/255, 1.0] }
    static orange     { [    1.0, 165/255,     0.0, 1.0] }
    //settable components
    red = (value) { _value[0] = value}
    green = (value) { _value[1] = value}
    blue = (value) { _value[2] = value}
    alpha = (value) { _value[3] = value}
    opacity(value) {_value[3] = value}
}

foreign class File {
    construct fileOpen(path, mode) {}

    foreign fileWrite(text)
    foreign fileRead()
    foreign fileSize()
    foreign fileClose()

    static create(path) { fileOpen(path, "w+") }
    static open(path) { fileOpen(path, "r+") }
    static openMode(path, mode) { fileOpen(path, mode) }
    close() { fileClose() }
    write(text) { fileWrite(text) }
    read() { fileRead() }
    size { fileSize() }
}

class Event {
    //notifications are normally system-wide and always have a name
    static onNotification(name, sender) {
        //these are only called once each, but not depending on the ptr
        if (__startupFunction && name == "NSApplicationDidFinishLaunchingNotification") __startupFunction.call()
        if (__closeFunction   && name == "NSApplicationWillTerminateNotification")      __closeFunction.call()
        var fn = __eventMap[sender]
        if (!fn) return     //no function, bail
        //this is called at the end of every field entry
        if (name == "NSControlTextDidEndEditingNotification") fn.call(sender)
        //window resizing
        if (name == "NSWindowDidResizeNotification") fn.call(sender)
    }
    //mouse events have a ptr like 'sender_type_modifier_m', where
    //type=1 down, 2=up; 3=right down, 4=right up; 5=move, 6=left drag, 7=right drag
    //modifier=0 plain, 1=shift, 2=ctrl, 4=alt, 8=cmd, fn=64
    //key events have a ptr like 'sender_keycode_modifier_k', where modifier same as above, and keycodes are Apple keyboard codes
    //they have to be looked up
    static onEvent(ptr) {
        var fn = __eventMap[ptr]
        if (fn) fn.call(ptr)
    }
    static onTimer(ptr) {
        var fn = __timerMap[ptr]
        if (fn) fn.call(ptr)
    }
    static [ind] = (value) {__eventMap[ind] = value}

    static eventMap(ptr, block) {
        __eventMap[ptr] = block
    }
    static timerMap(ptr, block) {
        __timerMap[ptr] = block
    }
    static startUp = (value) {__startupFunction = value}
    static closeDown = (value) {__closeFunction = value}
    static eventMap = (value) {__eventMap = value}
    static timerMap = (value) {__timerMap = value}
    static eventMap {__eventMap}
    static timerMap {__timerMap}
}

class Timer {
    construct new(value) {
        _id = Application.startTimer(value, true)
    }
    onTimer(block) {
        Event.timerMap(_id, block)
    }
    stop {
        Application.stopTimer(_id)
    }
    static after(secs, block) {
        Event.timerMap(Application.startTimer(secs, false), block)
    }
}

class Pointer {
    foreign static location
    static loc { Point.new(location[0], location[1]) }
}

class Font {
    foreign createFont(name, size, bold, italic)
    construct new(name, size, bold, italic) {
        _id = createFont(name, size, bold, italic)
    }
    id {_id}
}

class Application {
    foreign run
    foreign close
    foreign static terminate
    foreign static commandArguments
    foreign mainScreenFrame         //display dimensions [0, 0, w, h]
    foreign mainWindow              //the automatically created window (id)
    foreign static startTimer(seconds, repeat)
    foreign static stopTimer(id)
    foreign static playSound(file)
    foreign static playSoundVolume(sound, volume)
    foreign static alert(title, message, style, button1, button2)
    foreign static executablePath
    foreign static resourcePath
    foreign static homePath
    foreign static documentsPath
    foreign static openPanel(types, multiple, directory)
    foreign static savePanel(defaultname, canCreateDirectory)
    foreign static readFile(fileName)
    foreign static copyFile(from, to)
    foreign static renameFile(from, to)
    foreign static fileExists(name)
    foreign static createDirectory(name)
    foreign static deleteDirectory(name)
    foreign static executeFile(name, args, wait)

    static mainWindow { __mainWindow }
    static mainScreen { __mainScreenFrame }
    
    static new {
        Event.eventMap = {}
        Event.timerMap = {}
        return new()
    }

    static applicationSupportPath { homePath+"/Library/"+executablePath.split("/")[-1]+"/" }

    static playSoundFile(file) { playSound(file.contains("/") ? file: resourcePath + "/" + file) }
    static playSoundFile(file, volume) {
        var sound = Application.playSoundFile(file)
        Application.playSoundVolume(sound, volume)
        return sound
    }

    construct new() {
        __mainWindow = mainWindow 
        __mainScreenFrame = mainScreenFrame
        Event.eventMap = {}
        Event.timerMap = {}
    }
    onStartup(block) {
        Event.startUp = block
    }
    onClose(block) {
        Event.closeDown = block
    }
    terminate() { Application.terminate }
    run() {run}
    playSoundFile(file) { Application.playSoundFile(file) }
    playSoundFile(file, volume) {
        var sound = Application.playSoundFile(file)
        Application.playSoundVolume(sound, volume)
        return sound
    }
    // alert(title, message, style, button1, button2, button3) {
    //     Application.alert(title, message, style, button1, button2, button3)
    // }
    alert(title, message, style, button1, button2) {
        Application.alert(title, message, style, button1, button2)
    }
    alert(message, style, button1, button2) {
        Application.alert(window.title, message, style, button1, button2)
    }
    alert(message, style, button1) {
        Application.alert(window.title, message, style, button1, "")
    }
}

class Menu {
    foreign getMenubar
    foreign createMenu(title)
    foreign addItem(m, item)
    foreign menuAsSubmenu(menu, sub)

    construct new(title) {
        _id = createMenu(title)
    }
    construct menubar() {
        _id = getMenubar
    }
    menu(sub) {
        menuAsSubmenu(this.id, sub.id)
    }
    addMenuItem(item) {
        addItem(this.id, item.id)
    }
    addMenu(title, items) {
        var mi = MenuItem.new(title)
        addItem(this.id, mi.id)
        var m = Menu.new(title)
        items.each {|x| m.addMenuItem(x)}
        m.menu(mi)
    }
    id {_id}
}

class MenuItem {
    foreign createMenuItem(title, key)
    foreign separator
    foreign setText(item, text)
    foreign setEnable(item, enab)

    construct new(title, key) {
        _id = createMenuItem(title, key)
    }
    construct new(title) {
        _id = createMenuItem(title, "")
    }
    construct separator() {
        _id = separator
    }
    construct new(title, key, block) {
        _id = createMenuItem(title, key)
        Event[this.id] = block
    }
    onClick(block) {
        Event[this.id] = block
    }
    text = (t) {
        setText(this.id, t)
    }
    enable = (enab) {
        setEnable(this.id, enab)
    } 
    id {_id}
}

//windows have frames and title and other characteristics
class Window {
    foreign createWindow
    foreign setTitle(ptr, text)
    foreign setFrame(ptr, fram)
    foreign getFrame(ptr)
    foreign centreWindow(ptr)
    foreign showWindow(ptr)
    foreign closeWindow(ptr)
    foreign addSubPane(parent, child)
    foreign setColour(id, colour)
    foreign enableMouseMoveEvents(id, b)

    construct new() {
        _frame
        _title
        _flags
    //        _colour = Colour.white
        _id = createWindow
        _pane
    }
    static new(title) {
        var w = new()
        w.title = title
        return w    
    }
    static new(title, fr) {
        var w = new()
        w.title = title
        w.frame = fr
        return w    
    }
    static standardWindow {         //perhaps unnecessary? or add OK, cancel buttons?
        var w = new()
        w.id = Application.mainWindow
        w.frame = [0, 0, 500, 300]
        w.centre
        return w
    }

    title { _title }
    title = (value) {
        _title = value
        setTitle(_id, _title)
    }
    toString {_title + " " + _frame.toString}    
    addPane(value) {
        //check if there is a document pane, and create if necessary
        if (_pane == null) {
            //_pane = Pane.new(Application.mainScreen)
            _pane = Pane.newEmpty(addSubPane(_id, value.id))
            _pane.frame = Application.mainScreen
        }
        addSubPane(_pane.id, value.id)
    }
    pane { _pane }
    pane = (value) {
        _pane = value
    }
    id { _id }
    id = (value) {_id = value}
    colour = (value) {
        _colour = value
        setColour(_id, value)
    }
    colour {_colour}
    frame {
        _frame = getFrame(_id)
        return _frame
        }
    frame = (value) {
        _frame = value
        setFrame(_id, _frame)
    }
    origin {this.frame[0..1]}
    origin = (value) {
        this.frame = [value[0], value[1], this.frame[2], this.frame[3]]
    }
    x {this.frame[0]}
    x = (value) {
        this.frame = [value, this.frame[1], this.frame[2], this.frame[3]]
    }
    y {this.frame[y]}
    y = (value) {
        this.frame = [this.frame[0], value, this.frame[2], this.frame[3]]
    }
    size {this.frame[2..3]}
    size = (value) {
        this.frame = [this.frame[0], this.frame[1], value[0], value[1]]
    }
    width {this.frame[2]}
    width = (value) {
        this.frame = [this.frame[0], this.frame[1], value, this.frame[3]]
    }
    height {this.frame[3]}
    height = (value) {
        this.frame = [this.frame[0], this.frame[1], this.frame[2], value]
    }
    show {
        showWindow(_id)
    }
    show() {show}
    centre {
        centreWindow(_id)
    }
    centre() {centre}
    close {
        closeWindow(_id)
    }
    close() {close}
    mouseMoveEvents = (value) {
        enableMouseMoveEvents(_id, value)
    }
    keyDown(key, modifier, block) {
        if (!_pane) {
            _pane = Pane.new(Application.mainScreen) //[0, 0, 1000, 1000])
            addSubPane(_id, _pane.id)
        }
        Event[_pane.id + "_" + key.toString + "_" + modifier.toString + "_k"] = block
    }
    mouseMove(block) {
        Event[_pane.id + "_5_0_m"] = block
    }
    flip = (value) {
        if (!_pane) {
            _pane = Pane.new(Application.mainScreen)
            addSubPane(_id, _pane.id)
        }
        _pane.flip = value
    }
    onResize(block) {
        Event[this.id] = block
    }
}

//panes are NSViews or subclasses of NSView
class Pane {
    foreign createPane
    foreign removePane(id)
    foreign setFrame(id, fram)
    foreign addSubPane(parent, child)
    foreign setColour(id, colour)
    foreign setBorder(id, width)
    foreign setBorderColour(id, colour)
    foreign setShow(id, showHide)
    foreign setFlip(id, flip)
    foreign setCorner(id, radius)
    foreign setShadow(id, radius, opacity)
    foreign setTopMost(id)
    foreign setOpacity(pane, alpha)
    foreign setRotation(pane, degrees)
    foreign setTranslation(pane, x, y)
    foreign setScale(pane, x, y)
    foreign setShear(pane, x, y)
    foreign applyTransform(pane, trf)
    foreign createAnimation(pane, type, from, to, by, duration)
    foreign mouseLocation(pane)
    foreign getVisibility(pane)

    construct new(fr) {
        _frame = fr
        _id = createPane
        _colour = Colour.black
        _borderColour = Colour.white
        setFrame(_id, fr)
        setColour(_id, _colour)
    }
    construct new() {
        _id = createPane
    }
    construct newEmpty(id) {
        _id = id
    }
    addPane(value) {
        addSubPane(this.id, value.id)
    }
    removePane {
        removePane(this.id)
    }
    removePane() {removePane}
    setTopMost {
        setTopMost(this.id)
    }
    getMouseLocation {
        return mouseLocation(this.id)
    }
    setMouseEvent(block, event, modifier) {
        Event[this.id + "_" + event.toString + "_" + modifier.toString + "_m"] = block
    }
    mouseDown(block) {
        setMouseEvent(block, 1, 0)
    }
    mouseUp(block) {
        setMouseEvent(block, 2, 0)
    }
    mouseMove(block) {
        setMouseEvent(block, 5, 0)
    }
    mouseDrag(block) {
        setMouseEvent(block, 6, 0)
    }
    rightMouseDown(block) {
        setMouseEvent(block, 3, 0)
    }
    rightMouseUp(block) {
        setMouseEvent(block, 4, 0)
    }
    rightMouseDrag(block) {
        setMouseEvent(block, 7, 0)
    }
    keyDown(key, modifier, block) {
        Event[this.id + "_" + key.toString + "_" + modifier.toString + "_k"] = block
    }
    frame = (value) {
        _frame = value
        setFrame(this.id, value)
    }
    frame { _frame }
    origin {this.frame[0..1]}
    origin = (value) {
        this.frame = [value[0], value[1], this.frame[2], this.frame[3]]
    }
    position(x, y) {
        this.origin = [x, y]
    }
    x {this.frame[0]}
    x = (value) {
        this.frame = [value, this.frame[1], this.frame[2], this.frame[3]]
    }
    y {this.frame[1]}
    y = (value) {
        this.frame = [this.frame[0], value, this.frame[2], this.frame[3]]
    }
    size {this.frame[2..3]}
    size = (value) {
        this.frame = [this.frame[0], this.frame[1], value[0], value[1]]
    }
    width {this.frame[2]}
    width = (value) {
        this.frame = [this.frame[0], this.frame[1], value, this.frame[3]]
    }
    height {this.frame[3]}
    height = (value) {
        this.frame = [this.frame[0], this.frame[1], this.frame[2], value]
    }
    colour { _colour}
    colour = (value) {
        _colour = value
        setColour(this.id, _colour)
    }
    border = (value) {setBorder(this.id, value) }
    borderColour {_borderColour}
    borderColour = (value) {
        _borderColour = value
        setBorderColour(this.id, value)
    }
    show {
        setShow(this.id, true)
    }
    hide {
        setShow(this.id, false)
    }
    visible = (value) { setShow(this.id, value) }
    visible { !getVisibility(this.id) }
    flip = (value) {
        setFlip(this.id, value)
    }
    corner = (value) {
        setCorner(this.id, value)
    }
    shadow = (value) {
        setShadow(this.id, value[0], value[1])
    }
    opacity = (value) {
        setOpacity(this.id, value)
    }
    opacity(value) {
        setOpacity(this.id, value)
    }
    opacity_change(secs, from, to) {
        animate("opacity", from, to, 0.1, secs)
        // var opinc = 1 /(secs*20)   //20 times per second
        // if (to < from) opinc = -opinc
        // var opTimer = Timer.new(0.05)
        // opTimer.onTimer {
        //     from = from + opinc
        //     this.opacity = from
        //     if (opinc > 0 && from >= to) {
        //         opTimer.stop
        //     } else if (opinc < 0 && to >= from) {
        //         opTimer.stop
        //     }
        // }
    }
    rotate = (value) {
        setRotation(this.id, value)
    }
    translate(x, y) {
        setTranslation(this.id, x, y)
    }
    scale(x, y) {
        setScale(this.id, x, y)
    }
    shear(xAngle, yAngle) {
        setShear(this.id, xAngle, yAngle)
    }
    transform = (value) {
        applyTransform(this.id, value)
    }
    animate(type, from, to, by, duration) {
        createAnimation(this.id, type, from, to, by, duration)
    }
    moveFade(from, to, duration) {
        this.show
        this.animate("opacity", 1, 0, 0.1, duration)
        this.animate("position.x", from[0], to[0], 0.1, duration)
        this.animate("position.y", from[1], to[1], 0.1, duration)
        Timer.after(duration) {
            this.hide
        }
    }
    id {_id}
}

class ScrollPane is Pane {
    foreign createScrollPane
    foreign addSubPane(parent, child)
    foreign getScrollFrame(pane)

    construct new(fr) {
        _frame = fr
        _id = createScrollPane
        setFrame(_id, fr)
    }
    scrollFrame {
        return getScrollFrame(this.id)
    }
    frame { _frame }
    id {_id}
}

class ImagePane is Pane {
    foreign createImage
    foreign setImage(pane, image, length, scale)
    foreign setImageFromFile(pane, file, scale)
    foreign setTintImage(pane, colour)

    construct new(fr) {
        _frame = fr
        _id = createImage
        setFrame(_id, fr)
    }
    static new(fr, file) {
        var img = new(fr)
        img.imageFile(file, 2)      //magic 2 = resizeAspect
        return img
    }
    static new(fr, file, scale) {
        var img = new(fr)
        img.imageFile(file, scale)
        return img
    }
    image(image, length, scale) {
        setImage(this.id, image, length, scale)
    }
    imageFile(file, scale) {
        setImageFromFile(this.id, file.contains("/") ? file: Application.resourcePath + "/" + file, scale)
    }
    imageFile = (file) {
        imageFile(file, 2)
    }
    tintImage(colour) {
        setTintImage(this.id, colour)
    }
    frame {_frame}
    frame = (value) {
        _frame = value
        setFrame(this.id, value)
    }
    id {_id}
}

class PlayerPane is Pane {
    foreign createPlayerPane
    foreign playMedia(pane, url)     //returns player
    foreign stopPlay(player)
    foreign volumePlay(player, volume)
    foreign ratePlay(player, rate)

    construct new(fr) {
        _frame = fr
        _id = createPlayerPane
        setFrame(_id, fr)
    }
    play(url) {
        if (!url.contains("/")) {
            url = Application.resourcePath + "/" + url
        }
        _player = playMedia(this.id, url)
        return _player
    }       //note: returns player!
    stop() { stopPlay(_player) }
    volume = (vol) {
        volumePlay(_player, vol)
    }
    rate = (speed) {
        ratePlay(_player, speed)
    }
    id {_id}
}

class PolygonPane is Pane {
    foreign createPoly
    foreign points(id, p)
    foreign setFillColour(id, val)
    foreign setStrokeColour(id, val)
    foreign setStrokeWidth(id, val)

    construct new(fr) {
        _frame = fr
        _id = createPoly
        setFrame(_id, fr)
    }
    points = (value) {
        points(this.id, value)
    }
    colour = (value) {
        _colour = value
        setFillColour(this.id, _colour)
    }
    border = (value) {
        setStrokeWidth(this.id, value)
    }
    // borderColour {_borderColour}
    borderColour = (value) {
        _borderColour = value
        setStrokeColour(this.id, value)
    }
    id {_id}
}

//controls, common stuff
class Control is Pane {
    foreign setText(id, text)
    foreign getText(id)
    foreign setTextColour(id, colour)
    foreign setFont(id, font)
    text { getText(this.id) }
    text = (value) {setText(this.id, value.toString) }
    textColour = (value) { setTextColour(this.id, value) }
    font = (value) { setFont(this.id, value.id) }
}

class Button is Control {
    foreign createButton
    foreign setTitle(id, text)
    foreign setKey(id, text)
    foreign setType(id, type)
    foreign setStyle(id, style)
    foreign setState(id, state)
    foreign getState(id)

    construct new(title) {
        _id = createButton
        setTitle(_id, title)
    }
    static new(title, fr) {
        var b = new(title)
        b.frame = fr
        return b
    }
    static new(title, fr, block) {
        var b = new(title, fr)
        b.onClick(block)
        return b
    }
    keyEquivalent = (value) {
        setKey(value)
    }
    setAsDefault { setKey(this.id, "\r") }
    setAsCancel { setKey(this.id, "\e") }
    onClick(block) {
        Event[this.id] = block
    }

    //1=rounded, 2=regular square, 3= ?, 4= ?, 5=disclosure, 6=shadowless square, 7=circular, 8=textured square, 9=help,
    //10=small square, 11=textured rounded, 12=roundrect, 13=recessed, 14=rounded disclosure, 15=inline
    style = (value) { setStyle(this.id, value) }

    //0 = momentaryLight, 1 = pushOnOff, 2 = toggle, 3 = switch (checkbox), 4 = radio
    //5 = momentaryChange, 6 = onOff, 7 = momentaryPushIn, 8 = accelerator, 9 = multilevel accelerator
    type = (value) { setType(this.id, value) }
    state = (value) { setState(this.id, value) }
    state  { getState(this.id) }
    id {_id}
}

class Label is Control {
    foreign createLabel

    construct new(title) {
        _id = createLabel
        setText(_id, title)
    }
    static new(title, fr) {
        var b = new(title)
        b.frame = fr
        return b
    }
    onClick(block) {
        Event[_id] = block
    }
    id {_id}
}

class TextField is Control {
    foreign createTextField

    construct new(text) {
        _id = createTextField
        setText(_id, text)
    }
    construct new(text, fr) {
        _id = createTextField
        setText(_id, text)
        setFrame(_id, fr)
    }
    onTextEnd(block) {
        Event[_id] = block
    }
    id {_id}
}

//TODO: tables and outlines

//pane transformations (animations are directly in Pane)
foreign class Transform {
    construct new() {}
    foreign setScale(x, y)
    foreign setRotation(degrees)
    foreign setTranslation(x, y)
    foreign concat(trf)

    static scale(x, y) {
        var n = new()
        n.setScale(x, y)
        return n
    }
    static rotate(x) {
        var n = new()
        n.rotate = x
        return n
    }
    static translate(x, y) {
        var n = new()
        n.translate(x, y)
        return n
    }
    scale(x, y) {
        setScale(x, y)
    }
    rotate = (value) {
        setRotation(value)
    }
    translate(x, y) {
        setTranslation(x, y)
    }
}
