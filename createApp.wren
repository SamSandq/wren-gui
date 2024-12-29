//
// create Mac app from wren source files
//
// V1.0 Sam Sandqvist 2024

import "gui" for Application, Window, Button, Pane, Label, TextField, ImagePane, Colour, File, Time, Menu, MenuItem

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
            Application.copyFile(_icon, _targetFile + "/Contents/Resources/" + _icon.split("/")[-1])
        }
        //vm file
        Application.copyFile(_vm, _targetFile + "/Contents/MacOS/" + _name)
        //main file
        Application.copyFile(_main, _targetFile + "/Contents/Resources/main.wren")
        //resources
        for (each in _resources) {
            Application.copyFile(each, _targetFile + "/Contents/Resources/" + each.split("/")[-1])
        }
        //create Info.plist
        var nl = "\n"
        var s = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" + nl
        s = s + "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">" + nl
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

        //THESE ARE STRICTLY SPEAKING NOT NECESSARY
        //create version.plist
        // var versFile = File.create(_targetFile + "/Contents/version.plist")
        // s = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" + nl
        // s = s + "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">" + nl
        // s = s + "<plist version=\"1.0\">" + nl
        // s = s + "<dict>" + nl
        // s = s + "<key>ProjectName</key>" + nl
        // s = s + "<string>" + _vm.split("/")[-1] + "</string>" + nl
        // s = s + "</dict>" + nl
        // s = s + "</plist>" + nl
        // versFile.write(s)
        // versFile.close()
        
        //create PkgInfo
        // var pkgFile = File.create(_targetFile + "/Contents/PkgInfo")
        // pkgFile.write("APPL????")
        // pkgFile.close()

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
var resourceLabel = Label.new("Other [.wren] and resource files:", [20, wh - 280, 300, 20])
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

    if (Application.fileExists(nameField + ".app") && 1000 == myApp.alert("Create App", "File exists! Continue?", 2, "OK", "Cancel")) return
    if (myApp.alert("Create App", "Are you sure you want to create this app?", 0, "OK", "Cancel") != 1001) {
        prg.create()
        myApp.alert("Saved", 1, "OK")
        myApp.window.close
    }
}
cancel.onClick { myApp.window.close }

//create main menu (bar)
var mb = Menu.menubar()

var m1 = []
var miAbout = MenuItem.new("About", "") { myApp.alert("Create Wren Application", "Create proper MacOS application V1.0\nCopyright © Sam Sandqvist 2024", 1, "OK", "") }
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
