//
// wren-binding
//

#include <stdio.h>
#include <string.h>
#include <time.h>
#include "wren.h"

extern WrenVM *vm;

void initialiseGUI();
void doTerminate();
void doCommandArgs();
void doCreateView();
void doPaneFrame();
void doGetFrame();
void doPaneColour();
void doPaneBorder();
void doPaneBorderColour();
void doAddPane();
void doPaneVisibility();
void doCreateButton();
void doButtonTitle();
void doControlText();
void doControlTextGet();
void doCreateLabel();
void doCreateTextField();
void doTextColour();
void doAppRun();
void doAppClose();
void doCreateWindow();
void doShowWindow();
void doCloseWindow();
void doMainScreenFrame();
void doMainWindow();
void doWindowTitle();
void doWindowFrame();
void doWindowCentre();
void doWindowColour();
void doMouseLocation();
void doMouseLocationInView();
void doCreateFont();
void doSetFont();
void doShowPane();
void doRemovePane();
void doFlipPane();
void doCornerPane();
void doShadowPane();
void doCreateScrollPane();
void doAddPaneToScrollPane();
void doScrollPaneRect();
void doStartTimer();
void doStopTimer();
void doCreateImage();
void doSetImage();
void doSetImageFromFile();
void doSetAlpha();
void doSetTopMost();
void doCreatePlayerPane();
void doPlay();
void doStopPlay();
void doPlayVolume();
void doPlayRate();
void doPlaySoundFile();
void doPlaySoundVolume();
void doEnableMouseMoveEvents();
void doRotateByDegrees();
void doTranslateXY();
void doCreateRotateByDegrees();
void doCreateTranslateXY();
void doScaleXY();
void doShearXY();
void doCreateScaleXY();
void doApplyTransform();
void doConcatTransform();
void doCreateAnimation();
void doAlertPanel();
void doGetExecutablePath();
void doGetResourcePath();
void doGetHomePath();
void doGetDocumentsPath();
void doOpenPanel();
void doSavePanel();
void doReadFile();
void doWriteFile();
void doCopyFile();
void doCreateDirectory();
void doDeleteDirectory();
void doExistsFile();
void doRenameFile();
void doFileSize();
void doFileOpen();
void doFileRead();
void doFileWrite();
void doFileClose();
void doButtonKey();
void doExecuteTask();
void doTintImage();
void doCreatePolygonView();
void doPolygonPoints();
void doFillColour();
void doStrokeColour();
void doPolyBorder();
void doButtonGetState();
void doButtonSetState();
void doButtonType();
void doButtonStyle();

void transformAllocate();
void fileAllocate();
void fileFinalize();

void doGetMenubar();
void doCreateMenu();
void doCreateMenuItem();
void doCreateMenuItemSeparator();
void doAddMenuItem();
void doMenuAsSubmenu();
void doMenuItemText();
void doMenuItemEnable();

struct _bindings {
	char *module;
	char *class;
    bool isStatic;
    char *signature;
	void *func;
};

struct _bindings meths[];

//some c routines
//----------------------------------------------------------------------------
//date and time
void dateTime() {
    wrenEnsureSlots(vm, 1);
    wrenSetSlotDouble(vm, 0, (double) time(NULL));
}
//clock ticks
void clockTicks() {
    wrenEnsureSlots(vm, 1);
    wrenSetSlotDouble(vm, 0, (double) clock());
}

// Function to sleep for a given number of seconds with high precision
void sleep_seconds() {
    wrenEnsureSlots(vm, 1);
    double seconds = wrenGetSlotDouble(vm, 1);
    struct timespec req;
    req.tv_sec = (time_t)seconds;
    req.tv_nsec = (long)((seconds - req.tv_sec) * 1e9);
    nanosleep(&req, NULL);
}

//----------------------------------------------------------------------------
//formatted date and time
void stringDateTime() {
	struct tm *loctime;
	char *buf = malloc(50);
    wrenEnsureSlots(vm, 1);
    long num = (long) wrenGetSlotDouble(vm, 1);
	loctime = (struct tm *) localtime((const time_t *) &num);
	sprintf(buf, "%d-%02d-%02d %02d:%02d:%02d", loctime->tm_year+1900, loctime->tm_mon+1, loctime->tm_mday, loctime->tm_hour, loctime->tm_min, loctime->tm_sec);
    wrenSetSlotString(vm, 0, buf);
    free(buf);
}

//bind foreign methods to wren
WrenForeignMethodFn bindMethods(WrenVM* vm, const char* module, const char* className, bool isStatic, const char* signature) {
    int i = -1;
    while (meths[++i].module != NULL) {
        if ((strcmp(module, meths[i].module) == 0) &&
            (strcmp(className, meths[i].class) == 0) &&
            (isStatic == meths[i].isStatic) &&
            (strcmp(signature, meths[i].signature) == 0)) return meths[i].func;
    }
    return NULL;
}

//bind foreign classes to wren
WrenForeignClassMethods bindClasses(WrenVM* vm, const char* module, const char* className) {
    WrenForeignClassMethods methods;
    if (strcmp(className, "Transform") == 0) {
        methods.allocate = transformAllocate;
        methods.finalize = NULL;
    } else if (strcmp(className, "File") == 0) {
        methods.allocate = fileAllocate;
        methods.finalize = fileFinalize;
    } else {
        // Unknown class.
        methods.allocate = NULL;
        methods.finalize = NULL;
    }
    return methods;
}

//find a module and bind its methods
void doBindings(const char *module) {
    int i = -1;
    bindClasses(vm, "gui", "Transform");
    bindClasses(vm, "gui", "File");

    while (meths[++i].module != NULL) {
        bindMethods(vm, meths[i].module, meths[i].class, meths[i].isStatic, meths[i].signature);
    }
}

struct _bindings meths[] = {
    //module, class, static, signature, function
    {"gui", "Application", false, "run", doAppRun},
    {"gui", "Application", false, "close", doAppClose},
    {"gui", "Application", true,  "terminate", doTerminate},
    {"gui", "Application", true,  "commandArguments", doCommandArgs},
    {"gui", "Application", false, "mainScreenFrame", doMainScreenFrame},
    {"gui", "Application", false, "mainWindow", doMainWindow},
    {"gui", "Application", true,  "startTimer(_,_)", doStartTimer},
    {"gui", "Application", true,  "stopTimer(_)", doStopTimer},
    {"gui", "Application", true,  "playSound(_)", doPlaySoundFile},
    {"gui", "Application", true,  "playSoundVolume(_,_)", doPlaySoundVolume},
    {"gui", "Application", true,  "alert(_,_,_,_,_)", doAlertPanel},
    {"gui", "Application", true,  "executablePath", doGetExecutablePath},
    {"gui", "Application", true,  "resourcePath", doGetResourcePath},
    {"gui", "Application", true,  "homePath", doGetHomePath},
    {"gui", "Application", true,  "documentsPath", doGetDocumentsPath},
    {"gui", "Application", true,  "openPanel(_,_,_)", doOpenPanel},
    {"gui", "Application", true,  "savePanel(_,_)", doSavePanel},
    {"gui", "Application", true,  "readFile(_)", doReadFile},
    {"gui", "Application", true,  "copyFile(_,_)", doCopyFile},
    {"gui", "Application", true,  "renameFile(_,_)", doRenameFile},
    {"gui", "Application", true,  "createDirectory(_)", doCreateDirectory},
    {"gui", "Application", true,  "deleteDirectory(_)", doDeleteDirectory},
    {"gui", "Application", true,  "fileExists(_)", doExistsFile},
    {"gui", "Application", true,  "executeFile(_,_,_)", doExecuteTask},
    {"gui", "Menu",        false, "getMenubar", doGetMenubar},
    {"gui", "Menu",        false, "createMenu(_)", doCreateMenu},
    {"gui", "Menu",        false, "addItem(_,_)", doAddMenuItem},
    {"gui", "Menu",        false, "menuAsSubmenu(_,_)", doMenuAsSubmenu},
    {"gui", "MenuItem",    false, "createMenuItem(_,_)", doCreateMenuItem},
    {"gui", "MenuItem",    false, "separator", doCreateMenuItemSeparator},
    {"gui", "MenuItem",    false, "setText(_,_)", doMenuItemText},
    {"gui", "MenuItem",    false, "setEnable(_,_)", doMenuItemEnable},
    {"gui", "Pointer",     true,  "location", doMouseLocation},
    {"gui", "Transform",   false, "setRotation(_)", doCreateRotateByDegrees},
    {"gui", "Transform",   false, "setTranslation(_,_)", doCreateTranslateXY},
    {"gui", "Transform",   false, "setScale(_,_)", doCreateScaleXY},
//    {"gui", "Transform",   false, "setShear(_,_)", doCreateShearXY},
    {"gui", "Transform",   false, "concat(_)", doConcatTransform},
    {"gui", "Time",        true,  "now", dateTime},
    {"gui", "Time",        true,  "ticks", clockTicks},
    {"gui", "Time",        true,  "dateTime(_)", stringDateTime},
    {"gui", "Time",        true,  "sleep(_)", sleep_seconds},
    {"gui", "File",        false, "fileClose()", doFileClose},
    {"gui", "File",        false, "fileWrite(_)", doFileWrite},
    {"gui", "File",        false, "fileRead()", doFileRead},
    {"gui", "File",        false, "fileSize()", doFileSize},
    {"gui", "Font",        false, "createFont(_,_,_,_)", doCreateFont},
    {"gui", "Window",      false, "enableMouseMoveEvents(_,_)", doEnableMouseMoveEvents},
    {"gui", "Window",      false, "createWindow", doCreateWindow},
    {"gui", "Window",      false, "setTitle(_,_)", doWindowTitle},
    {"gui", "Window",      false, "setFrame(_,_)", doWindowFrame},
    {"gui", "Window",      false, "getFrame(_)", doGetFrame},
    {"gui", "Window",      false, "centreWindow(_)", doWindowCentre},
    {"gui", "Window",      false, "showWindow(_)", doShowWindow},
    {"gui", "Window",      false, "closeWindow(_)", doCloseWindow},
    {"gui", "Window",      false, "addSubPane(_,_)", doAddPane},
    {"gui", "Window",      false, "setColour(_,_)", doWindowColour},
    {"gui", "Pane",        false, "applyTransform(_,_)", doApplyTransform},
    {"gui", "Pane",        false, "createPane", doCreateView},
    {"gui", "Pane",        false, "removePane(_)", doRemovePane},
    {"gui", "Pane",        false, "setFrame(_,_)", doPaneFrame},
    {"gui", "Pane",        false, "getFrame(_)", doGetFrame},
    {"gui", "Pane",        false, "addSubPane(_,_)", doAddPane},
    {"gui", "Pane",        false, "setColour(_,_)", doPaneColour},
    {"gui", "Pane",        false, "setBorder(_,_)", doPaneBorder},
    {"gui", "Pane",        false, "setBorderColour(_,_)", doPaneBorderColour},
    {"gui", "Pane",        false, "setShow(_,_)", doShowPane},
    {"gui", "Pane",        false, "setFlip(_,_)", doFlipPane},
    {"gui", "Pane",        false, "setCorner(_,_)", doCornerPane},
    {"gui", "Pane",        false, "setShadow(_,_,_)", doShadowPane},
    {"gui", "Pane",        false, "setTopMost(_)", doSetTopMost},
    {"gui", "Pane",        false, "setOpacity(_,_)", doSetAlpha},
    {"gui", "Pane",        false, "setRotation(_,_)", doRotateByDegrees},
    {"gui", "Pane",        false, "setTranslation(_,_,_)", doTranslateXY},
    {"gui", "Pane",        false, "setScale(_,_,_)", doScaleXY},
    {"gui", "Pane",        false, "setShear(_,_,_)", doShearXY},
    {"gui", "Pane",        false, "createAnimation(_,_,_,_,_,_)", doCreateAnimation},
    {"gui", "Pane",        false, "mouseLocation(_)", doMouseLocationInView},
    {"gui", "Pane",        false, "getVisibility(_)", doPaneVisibility},
    {"gui", "PolygonPane", false, "createPoly", doCreatePolygonView},
    {"gui", "PolygonPane", false, "points(_,_)", doPolygonPoints},
    {"gui", "PolygonPane", false, "setFillColour(_,_)", doFillColour},
    {"gui", "PolygonPane", false, "setStrokeColour(_,_)", doStrokeColour},
    {"gui", "PolygonPane", false, "setStrokeWidth(_,_)", doPolyBorder},
    {"gui", "ImagePane",   false, "createImage", doCreateImage},
    {"gui", "ImagePane",   false, "setImage(_,_,_,_)", doSetImage},
    {"gui", "ImagePane",   false, "setImageFromFile(_,_,_)", doSetImageFromFile},
    {"gui", "ImagePane",   false, "setTintImage(_,_)", doTintImage},
    {"gui", "ScrollPane",  false, "createScrollPane", doCreateScrollPane},
    {"gui", "ScrollPane",  false, "addSubPane(_,_)", doAddPaneToScrollPane},
    {"gui", "ScrollPane",  false, "getScrollFrame(_)", doScrollPaneRect},
    {"gui", "PlayerPane",  false, "createPlayerPane", doCreatePlayerPane},
    {"gui", "PlayerPane",  false, "playMedia(_,_)", doPlay},
    {"gui", "PlayerPane",  false, "stopPlay(_)", doStopPlay},
    {"gui", "PlayerPane",  false, "volumePlay(_,_)", doPlayVolume},
    {"gui", "PlayerPane",  false, "ratePlay(_,_)", doPlayRate},
    {"gui", "Button",      false, "createButton", doCreateButton},
    {"gui", "Button",      false, "setTitle(_,_)", doButtonTitle},
    {"gui", "Button",      false, "setKey(_,_)", doButtonKey},
    {"gui", "Button",      false, "setType(_,_)", doButtonType},
    {"gui", "Button",      false, "setStyle(_,_)", doButtonStyle},
    {"gui", "Button",      false, "setState(_,_)", doButtonSetState},
    {"gui", "Button",      false, "getState(_)", doButtonGetState},
    {"gui", "Label",       false, "createLabel", doCreateLabel},
    {"gui", "Control",     false, "setText(_,_)", doControlText},
    {"gui", "Control",     false, "getText(_)", doControlTextGet},
    {"gui", "Control",     false, "setTextColour(_,_)", doTextColour},
    {"gui", "Control",     false, "setFont(_,_)", doSetFont},
    {"gui", "TextField",   false, "createTextField", doCreateTextField},
    {NULL, NULL, NULL}
};
