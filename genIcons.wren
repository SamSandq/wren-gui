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

// # https://developer.apple.com/design/human-interface-guidelines/macos/icons-and-images/app-icon#app-icon-sizes

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
    Application.executeFile("/usr/bin/sips", ["-z", w.toString, w.toString, originalPicture, "--out", iconsetDir + "/" + ip], true)
}

//convert iconset to icns file
Application.executeFile("/usr/bin/iconutil", ["-c", "icns", iconsetDir, "-o", fname + ".icns"], true)

Application.terminate
