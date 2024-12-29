//
//GUI module for Wren
// (c) Sam Sandqvist 2024
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <AVKit/AVKit.h>
// #import <PDFKit/PDFKit.h>
#import <AVFoundation/AVFoundation.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#import "wren.h"

extern WrenVM *vm;                  //setup at init
extern const char *script;
extern const char *readFile(const char *path);
extern char *time_buf;
extern int storedArgc;
extern char **storedArgv;

bool disableActions = false;

WrenForeignMethodFn bindMethods(WrenVM* vm, const char* module, const char* className, bool isStatic, const char* signature);
WrenForeignClassMethods bindClasses(WrenVM* vm, const char* module, const char* className);
void doBindings(const char *module);
extern const char* readFile(const char* path);
extern void appEnd();
extern char *nowTime();
FILE *log_file;

WrenHandle *appEvents = NULL;              //used for sending events to be handled in Application
WrenHandle *appNotifications = NULL;              //used for sending notifications to be handled in Application
WrenHandle *appTimer = NULL;              //used for timed events to be handled in Application
WrenHandle *appClass = NULL;               //used for getting the Application class

NSString *exPath;
NSString *resPath;
NSString *startup;
NSString *homePath;
NSString *docPath;

NSWindow *createWindow();

id myMainWindow = NULL;
id myDelegate = NULL;


//see also Alert
static void writeFn(WrenVM* vm, const char* text) {
    printf("%s", text);
}

static WrenLoadModuleResult loadModule(WrenVM* vm, const char* module) {
    WrenLoadModuleResult result = {0};
  
    char *path = malloc(60);

    //add resource directory
    strcat(path, [resPath UTF8String]);
    strcat(path, "/");
    strcat(path, module);

    // Add a ".wren" file extension.
    strcat(path, ".wren");

    result.source = readFile(path);
  
    // If we didn't find it, it may be a module built into the CLI or VM, so keep
    // going.
    if (result.source != NULL) return result;

    // Otherwise, see if it's a built-in module.
    return result; //loadBuiltInModule(module);
}



// WrenLoadModuleFn loadModule(WrenVM* vm, const char* name) {

//     WrenLoadModuleResult res;
//     res.source = readFile(name);
//     return *res;
//  }

//if in GUI this should be an Alert?
void errorFn(WrenVM* vm, WrenErrorType errorType, const char* module, const int line, const char* msg) {
    switch (errorType) {
        case WREN_ERROR_COMPILE:
            printf("[%s line %d] [Error] %s\n", module, line, msg);
            break;
        case WREN_ERROR_STACK_TRACE:
            printf("[%s line %d] in %s\n", module, line, msg);
            break;
        case WREN_ERROR_RUNTIME:
            printf("[Runtime Error] %s\n", msg);
            break;
    }
}

@interface MyAppDelegate : NSWindow <NSApplicationDelegate, NSTextFieldDelegate, NSWindowDelegate> {
    NSWindow *window;
}
@end

//-----------------------------------------------------------------------------
//check if action has been specified for the event and execute the block if so
void eventCommon(void *view, NSEvent *theEvent) {
    NSEventType type = [theEvent type];

     //form pointers
     char *ptr = malloc(40);

    int modifier = [theEvent modifierFlags];
    if (type == NSEventTypeKeyDown) {
        //get key
        int keyCode = [theEvent keyCode];
        //form pointer
        sprintf(ptr, "%p_%d_%d_k", view, keyCode, modifier>>17);
        // NSLog(@"Detecting: %s", ptr);
    } else {
        sprintf(ptr, "%p_%lu_%d_m", view, type, modifier>>17);
    }

    //ok, now we have the name and ptr. Call Wren with them
    disableActions = true;
    wrenEnsureSlots(vm, 2);
    wrenSetSlotHandle(vm, 0, appClass);
    wrenSetSlotString(vm, 1, ptr);
    WrenInterpretResult res = wrenCall(vm, appEvents);
    if (res != WREN_RESULT_SUCCESS) NSLog(@"Error calling Wren!");
    disableActions = false;

    free(ptr);
}

//-----------------------------------------------------------------------------
//own classes
@interface MyView : NSView {
    BOOL acceptResponder;
    BOOL isFlipped;
}
@property BOOL acceptResponder, isFlipped;
- (BOOL) acceptResponder;
- (BOOL) isFlipped;
@end

@implementation MyView

@synthesize acceptResponder;
@synthesize isFlipped;

//init
- (id) init {
    self = [super init];
    acceptResponder = YES;           //default is yes
    isFlipped = NO;                 //normally no
    return self;
}

// -----------------------------------
// First Responder Methods
- (BOOL) acceptsFirstResponder {
    return acceptResponder;         //when asked... NOTE: may be set with [myView setAcceptResponder: YES]; !!
}

//catch the events
- (void) mouseDown: (NSEvent *) theEvent {
    eventCommon(self, theEvent);
}

- (void) mouseDragged: (NSEvent *) theEvent {
    // Bring the view to front
    self.layer.zPosition = 1.0;
    eventCommon(self, theEvent);
}

- (void) mouseUp: (NSEvent *) theEvent {
    eventCommon(self, theEvent);
}

- (void) mouseMoved: (NSEvent *) theEvent {
    eventCommon(self, theEvent);
}

- (void) rightMouseDown: (NSEvent *) theEvent {
    eventCommon(self, theEvent);
}

- (void) rightMouseDragged: (NSEvent *) theEvent {
    eventCommon(self, theEvent);
}

- (void) rightMouseUp: (NSEvent *) theEvent {
    eventCommon(self, theEvent);
}

- (void) keyDown: (NSEvent *) theEvent {
    eventCommon(self, theEvent);
}

@end

//-----------------------------------------------------------------------------
//own class for non-rectangular view

@interface PolygonView : MyView

@property (nonatomic, strong) NSBezierPath *polygonPath;
@property (nonatomic, strong) NSColor *fillColour;
@property (nonatomic, strong) NSColor *strokeColour;
@property CGFloat borderWidth;

@end

@implementation PolygonView

- (instancetype) initWithFrame: (NSRect) frame {
    _fillColour = [NSColor whiteColor];
    _strokeColour = [NSColor whiteColor];
    _borderWidth = 1.0;

    return [super initWithFrame: frame];
}

//override to draw the polygon
- (void) drawRect: (NSRect) dirtyRect {
    [super drawRect: dirtyRect];
    
    // Set the fill color and fill the polygon
    [_fillColour setFill];
    [self.polygonPath fill];

    // Set the stroke color and stroke the outline of the polygon
    [_strokeColour setStroke];
    [self.polygonPath setLineWidth: self.borderWidth];
    [self.polygonPath stroke];
}

 // Allows transparency outside the polygon shape
- (BOOL) isOpaque {
    return NO;
}

// Override hitTest to detect clicks only inside the polygon
- (NSView *) hitTest: (NSPoint) point {
    // Convert the point to the view's local coordinate system
    NSPoint localPoint = [self convertPoint: point fromView: self.superview];
    
    // Check if the point is within the polygon path
    if ([self.polygonPath containsPoint: localPoint]) {
        return self; // Only respond to clicks inside the polygon
    }
    
    return nil; // Ignore clicks outside the polygon shape
}

@end

//-----------------------------------------------------------------------------
//own class for images

@interface MyImageView : NSImageView {
    BOOL acceptResponder;
}
@property BOOL acceptResponder;
- (BOOL) acceptResponder;
@end

@implementation MyImageView

@synthesize acceptResponder;

//init
- (id) init {
    self = [super init];
    acceptResponder = NO;           //default is not
    return self;
}

// -----------------------------------
// First Responder Methods
- (BOOL) acceptsFirstResponder {
    return acceptResponder;         //when asked... NOTE: may be set with [myView setAcceptResponder: YES]; !!
}

//catch the events
- (void) mouseDown: (NSEvent *) theEvent {
    eventCommon(self, theEvent);
}

- (void) mouseDragged: (NSEvent *) theEvent {
    // Bring the view to front
    self.layer.zPosition = 1.0;
    eventCommon(self, theEvent);
}

- (void) mouseUp: (NSEvent *) theEvent {
    eventCommon(self, theEvent);
}

- (void) mouseMoved: (NSEvent *) theEvent {
    eventCommon(self, theEvent);
}

- (void) rightMouseDown: (NSEvent *) theEvent {
    eventCommon(self, theEvent);
}

- (void) rightMouseDragged: (NSEvent *) theEvent {
    eventCommon(self, theEvent);
}

- (void) rightMouseUp: (NSEvent *) theEvent {
    eventCommon(self, theEvent);
}

- (void) keyDown: (NSEvent *) theEvent {
    eventCommon(self, theEvent);
}

@end


//-----------------------------------------------------------------------------
//HELPER: set object pointer into slot
void setObjectInSlot(void *object, int slot) {
    //form pointer
    wrenEnsureSlots(vm, 1);
    char *ptr = malloc(15);
    sprintf(ptr, "%p", object);
    wrenSetSlotString(vm, slot, ptr);
    free(ptr);
}

//-----------------------------------------------------------------------------
//create image view
void doCreateImage() {

    MyImageView *view = [[[MyImageView alloc] initWithFrame: CGRectZero] autorelease];
    [view setLayer: [CALayer new]];
    [view setWantsLayer: YES];     // the order of setLayer and setWantsLayer is crucial!
    [view.layer setMasksToBounds: YES];

    [view setAcceptResponder: YES];

    wrenEnsureSlots(vm, 1);
    setObjectInSlot(view, 0);
}

//-----------------------------------------------------------------------------
//set image in view
void doSetImage() {

    wrenEnsureSlots(vm, 5);
    const char *ptr1 = wrenGetSlotString(vm, 1);
    const char *ptr2 = wrenGetSlotString(vm, 2);
    long len = (long) wrenGetSlotDouble(vm, 3);             //length of data
    int scale = (int)  wrenGetSlotDouble(vm, 4);            //scaling mode

    NSImageView *w = (NSImageView *) strtol(ptr1, NULL, 0); //view
    void *im = (void *) strtol(ptr2, NULL, 0);              //image data

    id scaleMode;
    switch (scale) {
        case 0: scaleMode = kCAGravityCenter; break;
        case 1: scaleMode = kCAGravityResize; break;
        case 2: scaleMode = kCAGravityResizeAspect; break;
        case 3: scaleMode = kCAGravityResize; break;
        default: scaleMode = kCAGravityResizeAspect; break;
    }

    //set the scaling
    [((NSImageView *) w).layer setContentsGravity: scaleMode];

    //set the image
    if (len == 0) {
        //our image data implicitly contains the size.
        [((NSImageView *) w).layer setContents: im];
    } else {
        //param len contains the length
        NSData *data = [NSData dataWithBytes: im length: (NSUInteger) len];
        [((NSImageView *) w).layer setContents: [[NSImage alloc] initWithData: data]];
    }
}

//-----------------------------------------------------------------------------
//set image in view direct from file
void doSetImageFromFile() {

    wrenEnsureSlots(vm, 4);
    const char *ptr1 = wrenGetSlotString(vm, 1);
    const char *fil = wrenGetSlotString(vm, 2);             //file
    int scale = (int)  wrenGetSlotDouble(vm, 3);            //scaling mode

    NSImageView *w = (NSImageView *) strtol(ptr1, NULL, 0); //view
    NSString *fileName = [NSString stringWithUTF8String: fil];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile: fileName];

    id scaleMode;
    switch (scale) {
        case 0: scaleMode = kCAGravityCenter; break;
        case 1: scaleMode = kCAGravityResize; break;
        case 2: scaleMode = kCAGravityResizeAspect; break;
        case 3: scaleMode = kCAGravityResize; break;
        default: scaleMode = kCAGravityResizeAspect; break;
    }

    [w.layer setContents: image];
    [w.layer setContentsGravity: scaleMode];

}

//--HELPER--------------------------------------------------------------------
//provide tinted image from original
NSImage *tintImage(NSImage *image, NSColor *tintColour) {
    NSImage *tintedImage = [image copy];

    NSSize imageSize = image.size;
    [tintedImage lockFocus];

    [tintColour set];
    NSRect imageRect = NSMakeRect(0, 0, imageSize.width, imageSize.height);
    NSRectFillUsingOperation(imageRect, NSCompositingOperationSourceAtop);

    [tintedImage unlockFocus];

    return tintedImage;
}

//-----------------------------------------------------------------------------
//tint image
void doTintImage(){
    wrenEnsureSlots(vm, 7);
    const char *ptr1 = wrenGetSlotString(vm, 1);
    wrenGetListElement(vm, 2, 0, 3);    //from slot 2, get list element 0 = red
    wrenGetListElement(vm, 2, 1, 4);    //green
    wrenGetListElement(vm, 2, 2, 5);    //blue
    wrenGetListElement(vm, 2, 3, 6);    //alpha
    double red = wrenGetSlotDouble(vm, 3);
    double green = wrenGetSlotDouble(vm, 4);
    double blue = wrenGetSlotDouble(vm, 5);
    double alpha = wrenGetSlotDouble(vm, 6);

    NSColor *colour = [NSColor colorWithCalibratedRed: red
                                                  green: green
                                                  blue:  blue
                                                  alpha: alpha ];

    NSImageView *w = (NSImageView *) strtol(ptr1, NULL, 0); //view
    NSImage *orig = [w.layer contents];
    NSImage *tinted = tintImage(orig, colour);

    [w.layer setContents: tinted];
}

//-----------------------------------------------------------------------------
//adjust opacity
void doSetAlpha() {
    wrenEnsureSlots(vm, 3);
    const char *ptr = wrenGetSlotString(vm, 1);
    double alpha = wrenGetSlotDouble(vm, 2);

    NSView *w = (NSView *) strtol(ptr, NULL, 0); //view

    [w.layer setOpacity: alpha];
}

//-----------------------------------------------------------------------------
//adjust anchor point for rotations
void setMyAnchorPoint(NSView *w, double x, double y) {
    // Convert the anchor point to the layer's coordinate space
    CGPoint newPoint = CGPointMake(w.bounds.size.width * x, w.bounds.size.height * y);
    CGPoint oldPoint = CGPointMake(w.bounds.size.width * w.layer.anchorPoint.x, w.bounds.size.height * w.layer.anchorPoint.y);
    
    // Adjust the layer's position to maintain the view's visual position
    CGPoint position = w.layer.position;
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    position.y -= oldPoint.y;
    position.y += newPoint.y;

    w.layer.position = position;
    w.layer.anchorPoint = CGPointMake(x, y);
}

//-----------------------------------------------------------------------------
//rotate view layer
void doRotateByDegrees() {
    wrenEnsureSlots(vm, 3);
    const char *ptr = wrenGetSlotString(vm, 1);
    double degrees = wrenGetSlotDouble(vm, 2);
 
    NSView *w = (NSView *) strtol(ptr, NULL, 0); //view

    // Convert degrees to radians
    CGFloat radians = degrees * (M_PI / 180.0);

    // Apply rotation transform to the layer
    setMyAnchorPoint(w, 0.5, 0.5);      //in the centre
    CATransform3D rotationTransform = CATransform3DMakeRotation(radians, 0.0, 0.0, 1.0);
    [w.layer setTransform: rotationTransform];
}

//-----------------------------------------------------------------------------
//rotation transform
void doCreateRotateByDegrees() {
    wrenEnsureSlots(vm, 2);

    CATransform3D *tf = wrenGetSlotForeign(vm, 0);
    double degrees = wrenGetSlotDouble(vm, 1);
    
    // Convert degrees to radians
    CGFloat radians = degrees * (M_PI / 180.0);

    CATransform3D transform = CATransform3DMakeRotation(radians, 0.0, 0.0, 1.0);
    memcpy(tf, &transform, sizeof(CATransform3D));
}

//-----------------------------------------------------------------------------
//translate view layer
void doTranslateXY() {
    wrenEnsureSlots(vm, 4);
    const char *ptr = wrenGetSlotString(vm, 1);
    double x = wrenGetSlotDouble(vm, 2);
    double y = wrenGetSlotDouble(vm, 3);
 
    NSView *w = (NSView *) strtol(ptr, NULL, 0); //view

    // Apply translation transform to the layer
    CATransform3D translationTransform = CATransform3DMakeTranslation(x, y, 0.0);
    [w.layer setTransform: translationTransform];
}

//-----------------------------------------------------------------------------
//translation transform
void doCreateTranslateXY() {
    wrenEnsureSlots(vm, 3);

    CATransform3D *tf = wrenGetSlotForeign(vm, 0);
    double x = wrenGetSlotDouble(vm, 1);
    double y = wrenGetSlotDouble(vm, 2);
 
    CATransform3D transform = CATransform3DMakeTranslation(x, y, 0.0);
    memcpy(tf, &transform, sizeof(CATransform3D));
}

//-----------------------------------------------------------------------------
//scale view layer
void doScaleXY() {
    wrenEnsureSlots(vm, 4);
    const char *ptr = wrenGetSlotString(vm, 1);
    double x = wrenGetSlotDouble(vm, 2);
    double y = wrenGetSlotDouble(vm, 3);
 
    NSView *w = (NSView *) strtol(ptr, NULL, 0); //view

    // Apply translation transform to the layer
    CATransform3D scaleTransform = CATransform3DMakeScale(x, y, 1.0);
    [w.layer setTransform: scaleTransform];
}

//-----------------------------------------------------------------------------
//scaling transform
void doCreateScaleXY() {
    wrenEnsureSlots(vm, 3);

    CATransform3D *tf = wrenGetSlotForeign(vm, 0);
    double x = wrenGetSlotDouble(vm, 1);
    double y = wrenGetSlotDouble(vm, 2);

    CATransform3D transform = CATransform3DMakeScale(x, y, 1.0);
    memcpy(tf, &transform, sizeof(CATransform3D));
}

//-----------------------------------------------------------------------------
//shear (skew) view layer
void doShearXY() {
    wrenEnsureSlots(vm, 4);
    const char *ptr = wrenGetSlotString(vm, 1);
    double xShear = wrenGetSlotDouble(vm, 2);
    double yShear = wrenGetSlotDouble(vm, 3);
 
    NSView *w = (NSView *) strtol(ptr, NULL, 0); //view

     // Convert angles from degrees to radians
    CGFloat xRadians = xShear * (M_PI / 180.0);
    CGFloat yRadians = yShear * (M_PI / 180.0);
    
    // // Create the affine transform for skew
    // CATransform3D shearTransform = CATransform3DIdentity;
    // // shearTransform.m34 = -1.0 / 500.0; // Apply perspective -- not sure how it works??

    // // Set skew values: m12 for y-axis skew, m21 for x-axis skew
    // shearTransform.m21 = tan(xRadians);
    // shearTransform.m12 = tan(yRadians);

    // // Apply the affine transform to the view's layer
    // w.layer.transform = shearTransform;
    
    // Apply translation transform to the layer
    CGAffineTransform shearTransform = CGAffineTransformMake(1, yRadians, xRadians, 1, 0, 0);
    [w.layer setAffineTransform: shearTransform];
}

//-----------------------------------------------------------------------------
//shear (skew) transform
void doCreateShearXY() {
    wrenEnsureSlots(vm, 3);

    CGAffineTransform *tf = wrenGetSlotForeign(vm, 0);
    double xShear = wrenGetSlotDouble(vm, 1);
    double yShear = wrenGetSlotDouble(vm, 2);

    CGAffineTransform transform = CGAffineTransformMake(1, yShear, xShear, 1, 0, 0);
    memcpy(tf, &transform, sizeof(CGAffineTransform));
}

//-----------------------------------------------------------------------------
//concatenate transforms
void doConcatTransform() {
    CATransform3D *tf = wrenGetSlotForeign(vm, 0);      //target
    CATransform3D *trf1 = wrenGetSlotForeign(vm, 1);

    CATransform3D transform = CATransform3DConcat(*tf, *trf1);
    memcpy(tf, &transform, sizeof(CATransform3D));
}

//-----------------------------------------------------------------------------
//apply transform
void doApplyTransform() {
    wrenEnsureSlots(vm, 3);
    const char *ptr = wrenGetSlotString(vm, 1);
    CATransform3D *trf = wrenGetSlotForeign(vm, 2);

    NSView *w = (NSView *) strtol(ptr, NULL, 0); //view

    [w.layer setTransform: *trf];
}

//-----------------------------------------------------------------------------
//animations
void doCreateAnimation() {

/* Some interesting animations.
See https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreAnimation_guide/AnimatableProperties/AnimatableProperties.html#//apple_ref/doc/uid/TP40004514-CH11-SW1
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
*/
    wrenEnsureSlots(vm, 7);
    const char *ptr = wrenGetSlotString(vm, 1);

    //type, e.g. opacity
    const char *type = wrenGetSlotString(vm, 2);

    //for now, assume from/to/by are doubles
    //params
    double fromValue = wrenGetSlotDouble(vm, 3);
    double toValue = wrenGetSlotDouble(vm, 4);
    double byValue = wrenGetSlotDouble(vm, 5);
    double duration = wrenGetSlotDouble(vm, 6);

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath: [NSString stringWithUTF8String: type]];
    animation.fromValue = [NSNumber numberWithFloat: fromValue];
    animation.toValue = [NSNumber numberWithFloat: toValue];
    animation.byValue = [NSNumber numberWithFloat: byValue];
    animation.duration = duration;
    animation.removedOnCompletion = NO;

    // Keep the final state of the animation
    animation.fillMode = kCAFillModeForwards;
    
    NSView *w = (NSView *) strtol(ptr, NULL, 0); //view
    setMyAnchorPoint(w, 0.5, 0.5);
    [w.layer addAnimation: animation forKey: nil];
}

//MENUS
//-----------------------------------------------------------------------------
//create and return empty menubar. Use: mb := MacApp menu.
void doGetMenubar() {

    id menubar = [[NSMenu new] autorelease];        //create a menu...
    [NSApp setMainMenu: menubar];                   //...and make it main.

    // NSLog(@"Menubar %@ created", menubar);

    setObjectInSlot(menubar, 0);
}

//-----------------------------------------------------------------------------
//create and return empty menu. Use m1 := Menu new: title
void doCreateMenu() {

    wrenEnsureSlots(vm, 2);
    const char *title = wrenGetSlotString(vm, 1);

    id menu = [[NSMenu new] autorelease];        //create a menu...
    [menu setTitle: [NSString stringWithUTF8String: title]];
    [menu setAutoenablesItems: NO];
    // id menu = [NSMenu initWithTitle: [NSString stringWithUTF8String: title]];

    // NSLog(@"Menu %@ created", menu);

    setObjectInSlot(menu, 0);
}

//-----------------------------------------------------------------------------
//create new menu item (not yet connected to anything)
void *menuItemCommon(const char *key, const char *title, SEL select) {

    NSString *t = [NSString stringWithUTF8String: title];
    NSString *k = [NSString stringWithUTF8String: key];

    id menuItem = [[[NSMenuItem alloc]
        initWithTitle: t
        action: select
        keyEquivalent: k] autorelease];

    // NSLog(@"Menuitem %@ created", menuItem);

    return (void *) menuItem;
}

//-----------------------------------------------------------------------------
//create new menu item (not yet connected to anything)
void doCreateMenuItem() {
    wrenEnsureSlots(vm, 3);
    const char *title = wrenGetSlotString(vm, 1);
    const char *key = wrenGetSlotString(vm, 2);

    setObjectInSlot( menuItemCommon(key, title, @selector(action:)), 0);
}

// //-----------------------------------------------------------------------------
// //create copy item
// long long doCreateMenuItemCopy(char *key, char *title) {
//     return menuItemCommon(key, title, @selector(copy:));
// }

// //-----------------------------------------------------------------------------
// //create cut item
// long long doCreateMenuItemCut(char *key, char *title) {
//     return menuItemCommon(key, title, @selector(cut:));
// }

// //-----------------------------------------------------------------------------
// //create paste item
// long long doCreateMenuItemPaste(char *key, char *title) {
//     return menuItemCommon(key, title, @selector(paste:));
// }

// //-----------------------------------------------------------------------------
// //create select all item
// long long doCreateMenuItemSelectAll(char *key, char *title) {
//     return menuItemCommon(key, title, @selector(selectAll:));
// }

//-----------------------------------------------------------------------------
//create separator item
void doCreateMenuItemSeparator() {
    setObjectInSlot([NSMenuItem separatorItem], 0);
}

//-----------------------------------------------------------------------------
//add menu as submenu to another menu (connect it)
void doMenuAsSubmenu() {
    wrenEnsureSlots(vm, 3);
    const char *ptr1 = wrenGetSlotString(vm, 1);
    const char *ptr2 = wrenGetSlotString(vm, 2);

    id menu = (id) strtol(ptr1, NULL, 0);
    id sub  = (id) strtol(ptr2, NULL, 0);

    // NSLog(@"sub: %@", sub);
    // NSLog(@"menu: %@", menu);

    [sub setSubmenu: menu];
}

//-----------------------------------------------------------------------------
//add menu item as submenu to another menu (connect it)
void doSetMenuAsSubmenuForItem() {
    wrenEnsureSlots(vm, 4);
    const char *ptr1 = wrenGetSlotString(vm, 1);
    const char *ptr2 = wrenGetSlotString(vm, 2);
    const char *ptr3 = wrenGetSlotString(vm, 3);

    id menu = (id) strtol(ptr1, NULL, 0);
    id sub  = (id) strtol(ptr2, NULL, 0);
    id item = (id) strtol(ptr3, NULL, 0);

    //NSLog(@"set menu %lld to be submenu for item %lld in menu %lld", sub, item, menu);
    [(id) menu setSubmenu: (id) sub forItem: (id) item];
}

//-----------------------------------------------------------------------------
//add item to menu
void doAddMenuItem() {
    wrenEnsureSlots(vm, 3);
    const char *ptr1 = wrenGetSlotString(vm, 1);
    const char *ptr2 = wrenGetSlotString(vm, 2);

    id menu = (id) strtol(ptr1, NULL, 0);
    id item = (id) strtol(ptr2, NULL, 0);

    // NSInteger howMany = [(NSMenu *) menu numberOfItems];
    // NSLog(@"items in menu: %d", howMany);

    // [(NSMenuItem *) item setTag: howMany];           //not used (yet?)
    [(NSMenu *) menu addItem: (NSMenuItem *) item];
    // NSLog(@"added item %@ to menu %@", item, menu);
}

//-----------------------------------------------------------------------------
//add menu as popup menu to a view (connect it)
void doAddMenuToView() {
    wrenEnsureSlots(vm, 3);
    const char *ptr1 = wrenGetSlotString(vm, 1);
    const char *ptr2 = wrenGetSlotString(vm, 2);

    id w = (id) strtol(ptr1, NULL, 0);
    id m = (id) strtol(ptr2, NULL, 0);
    
    [(NSView *) w setMenu: (NSMenu *) m];
    //NSLog(@"set menu %lld to view %lld", m, w);
}

//-----------------------------------------------------------------------------
//enable/disable menu item
void doMenuItemEnable() {
    wrenEnsureSlots(vm, 3);
    const char *ptr1 = wrenGetSlotString(vm, 1);
    bool enab = wrenGetSlotBool(vm, 2);

    id mi = (id) strtol(ptr1, NULL, 0);

    [mi setEnabled: enab];
}

//-----------------------------------------------------------------------------
//set menu item text
void doMenuItemText() {
    wrenEnsureSlots(vm, 3);
    const char *ptr1 = wrenGetSlotString(vm, 1);
    const char *text = wrenGetSlotString(vm, 2);

    id mi = (id) strtol(ptr1, NULL, 0);

    [mi setTitle: [NSString stringWithUTF8String: text]];
}

//-----------------------------------------------------------------------------
//timer for scheduled repetitive or one-off tasks
void doStartTimer() {
    //we have the seconds interval
    wrenEnsureSlots(vm, 3);
    double seconds = wrenGetSlotDouble(vm, 1);
    bool repeat = wrenGetSlotBool(vm ,2);

    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval: seconds
                                                  target: myDelegate
                                                selector: @selector(timerFired:)
                                                userInfo: nil
                                                 repeats: repeat];
    setObjectInSlot(timer, 0);
}

//-----------------------------------------------------------------------------
//stop timer for scheduled repetitive tasks. Recreate if necessary
void doStopTimer() {
    wrenEnsureSlots(vm, 2);
    const char *ptr = wrenGetSlotString(vm, 1);

    NSTimer *timer = (NSTimer *) strtol(ptr, NULL, 0);

    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
}

//-----------------------------------------------------------------------------
//Get mouse position in window
void doMouseLocation() {
	NSPoint mousePos = [myMainWindow mouseLocationOutsideOfEventStream];

    //store frame in slots 1..2
    wrenEnsureSlots(vm, 3);
    wrenSetSlotDouble(vm, 1, (double) mousePos.x);
    wrenSetSlotDouble(vm, 2, (double) mousePos.y);

    //the frame is an pos - convert to wren list [x,y]
    wrenSetSlotNewList(vm, 0);
    wrenInsertInList(vm, 0, 0, 1);
    wrenInsertInList(vm, 0, 1, 2);
}

//-----------------------------------------------------------------------------
//Get mouse position in view
void doMouseLocationInView() {
	NSPoint mousePos = [myMainWindow mouseLocationOutsideOfEventStream];

    wrenEnsureSlots(vm, 4);

    const char *ptr = wrenGetSlotString(vm, 1);

    NSView *view = (NSView *) strtol(ptr, NULL, 0);
    NSPoint mousePointInView = [view convertPoint: mousePos fromView: nil];

    //store frame in slots 2..3
    wrenSetSlotDouble(vm, 2, (double) mousePointInView.x);
    wrenSetSlotDouble(vm, 3, (double) mousePointInView.y);

    //the frame is an pos - convert to wren list [x,y]
    wrenSetSlotNewList(vm, 0);
    wrenInsertInList(vm, 0, 0, 2);
    wrenInsertInList(vm, 0, 1, 3);
}

//-----------------------------------------------------------------------------
//set view on top
void doSetTopMost() {
    wrenEnsureSlots(vm, 2);
    const char *ptr = wrenGetSlotString(vm, 1);

    NSView *view = (NSView *) strtol(ptr, NULL, 0);

    view.layer.zPosition = 1.0;
}

//-----------------------------------------------------------------------------
//add view as subview
void doAddPane() {
    //we have two arguments: the ptr (string format) and the child ptr
    wrenEnsureSlots(vm, 3);
    const char *ptr1 = wrenGetSlotString(vm, 1);
    const char *ptr2 = wrenGetSlotString(vm, 2);

    NSView *parent = (NSView *) strtol(ptr1, NULL, 0);
    NSView *child  = (NSView *) strtol(ptr2, NULL, 0);

    if ([parent isKindOfClass: [NSWindow class]]) parent = [(NSWindow *) parent contentView];

    [parent addSubview: child];

    setObjectInSlot(parent, 0);
}

//-----------------------------------------------------------------------------
//remove view from view
void doRemovePane() {
    wrenEnsureSlots(vm, 2);
    const char *ptr = wrenGetSlotString(vm, 1);
    NSView *view = (NSView *) strtol(ptr, NULL, 0);
   [view removeFromSuperview];
}

//SCROLLVIEW
//-----------------------------------------------------------------------------
//create scroll view
void doCreateScrollPane() {

    NSScrollView *view = [[NSScrollView alloc] initWithFrame: CGRectZero];
    // the scroll view should have both horizontal and vertical scrollers (settable?)
    [view setHasVerticalScroller: YES];
    [view setHasHorizontalScroller: YES];
    [view setLineScroll: 1];

    wrenEnsureSlots(vm, 1);
    setObjectInSlot(view, 0);
}

//-----------------------------------------------------------------------------
//add view  to scrollview
void doAddPaneToScrollPane() {
    wrenEnsureSlots(vm, 3);
    const char *ptr1 = wrenGetSlotString(vm, 1);
    const char *ptr2 = wrenGetSlotString(vm, 2);

    NSScrollView *scrollPane = (NSScrollView *) strtol(ptr1, NULL, 0);    
    NSView *view = (NSView *) strtol(ptr2, NULL, 0);
    [scrollPane setDocumentView: view];
}

//-----------------------------------------------------------------------------
//obtain scroll view's visible rectangle
void doScrollPaneRect() {

    wrenEnsureSlots(vm, 6);
    const char *ptr1 = wrenGetSlotString(vm, 1);
    NSScrollView *scrollPane = (NSScrollView *) strtol(ptr1, NULL, 0);
    NSRect mf = [scrollPane documentVisibleRect];

    //store frame in slots 2..5
    wrenSetSlotDouble(vm, 2, (double) mf.origin.x);
    wrenSetSlotDouble(vm, 3, (double) mf.origin.y);
    wrenSetSlotDouble(vm, 4, (double) mf.size.width);
    wrenSetSlotDouble(vm, 5, (double) mf.size.height);

    //the frame is an NSRect - convert to wren list [x,y,w,h]
    wrenSetSlotNewList(vm, 0);
    wrenInsertInList(vm, 0, 0, 2);
    wrenInsertInList(vm, 0, 1, 3);
    wrenInsertInList(vm, 0, 2, 4);
    wrenInsertInList(vm, 0, 3, 5);
}

//PLAYERVIEW
//-----------------------------------------------------------------------------
//create player view
void doCreatePlayerPane() {

    //create the view
    id view = [[[AVPlayerView alloc] initWithFrame: CGRectZero] autorelease];

    wrenEnsureSlots(vm, 1);
    setObjectInSlot(view, 0);

}

//-----------------------------------------------------------------------------
//play a URL in the playerview
void doPlay() {

    wrenEnsureSlots(vm, 3);
    const char *ptr1 = wrenGetSlotString(vm, 1);    //the view
    const char *urlString = wrenGetSlotString(vm, 2);    //the URL

    AVPlayerView *w = (AVPlayerView *) strtol(ptr1, NULL, 0);

    NSURL *videoURL = [NSURL URLWithString: [[NSString stringWithUTF8String: urlString]
        stringByAddingPercentEncodingWithAllowedCharacters: [NSCharacterSet URLQueryAllowedCharacterSet]]];

    //delete possible old player
    AVPlayer *old = [w player];
    if (old != nil) {
        [old pause];
        [old replaceCurrentItemWithPlayerItem: nil];
    }

    //do it
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL: videoURL];

    playerItem.preferredForwardBufferDuration = 10;         //?or leave automatic

    AVPlayer *player = [AVPlayer playerWithPlayerItem: playerItem];

    [w setPlayer: player];
    [player play];

    //return the player
    setObjectInSlot(player, 0);
}

//-----------------------------------------------------------------------------
//stop playing
void doStopPlay() {

    wrenEnsureSlots(vm, 2);
    const char *ptr1 = wrenGetSlotString(vm, 1);    //the player

    AVPlayer *p = (AVPlayer *) strtol(ptr1, NULL, 0);

    [p pause];
    [p replaceCurrentItemWithPlayerItem: nil];

}

//-----------------------------------------------------------------------------
//volume (media URL)
void doPlayVolume() {

    wrenEnsureSlots(vm, 3);
    const char *ptr1 = wrenGetSlotString(vm, 1);    //the player
    double volume = wrenGetSlotDouble(vm, 2);

    AVPlayer *p = (AVPlayer *) strtol(ptr1, NULL, 0);

    [p setVolume: volume];
}

//-----------------------------------------------------------------------------
//rate
void doPlayRate() {

    wrenEnsureSlots(vm, 3);
    const char *ptr1 = wrenGetSlotString(vm, 1);    //the player
    double rate = wrenGetSlotDouble(vm, 2);

    AVPlayer *p = (AVPlayer *) strtol(ptr1, NULL, 0);

    [p setRate: rate];
}

//-----------------------------------------------------------------------------
//play sound file asynchronously without blocking main thread
NSSound *playSoundAsync(const char *fileName) {
    NSString *file = [NSString stringWithUTF8String: fileName];
    NSSound *sound = [[NSSound alloc] initWithContentsOfFile: file byReference: YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // NSSound *sound = [[NSSound alloc] initWithContentsOfFile: [NSString stringWithUTF8String: fileName] byReference: YES];
        if (sound) {
            [sound play];
        } else {
            NSLog(@"Failed to initialize NSSound");
        }
    });
    return sound;
}

//-----------------------------------------------------------------------------
//play sound file
void doPlaySoundFile() {
    wrenEnsureSlots(vm, 2);
    const char *fileName = wrenGetSlotString(vm, 1);        //filename
        
    //NSSound *sound = [[NSSound alloc] initWithContentsOfFile: [NSString stringWithUTF8String: fileName] byReference:YES];
    //if (sound) [sound play];
    
    NSSound *snd = playSoundAsync(fileName);
    setObjectInSlot(snd, 0);
}

//-----------------------------------------------------------------------------
//volume (audio file)
void doPlaySoundVolume() {

    wrenEnsureSlots(vm, 3);
    const char *ptr1 = wrenGetSlotString(vm, 1);    //the sound
    double volume = wrenGetSlotDouble(vm, 2);

    NSSound *p = (NSSound *) strtol(ptr1, NULL, 0);

    [p setVolume: volume];
}

//TODO: implement loops and stop/resume too; all booleans

//-----------------------------------------------------------------------------
//flip view: flip 0 do not, 1 do.
void doFlipPane() {
    wrenEnsureSlots(vm, 3);
    const char *ptr = wrenGetSlotString(vm, 1);
    bool flip = wrenGetSlotBool(vm, 2);

    MyView *view = (MyView *) strtol(ptr, NULL, 0);

    [view setIsFlipped: flip];
}

//-----------------------------------------------------------------------------
//make view have rounded corners: radius in pixels
void doCornerPane() {
    wrenEnsureSlots(vm, 3);
    const char *ptr = wrenGetSlotString(vm, 1);
    double radius = wrenGetSlotDouble(vm, 2);

    NSView *view = (NSView *) strtol(ptr, NULL, 0);

    view.wantsLayer = YES;
    view.layer.cornerRadius  = radius; //view.frame.size.width/2; use this for circle!
    view.layer.masksToBounds = YES;

}

//-----------------------------------------------------------------------------
//make view have shadow: radius in pixels, opacity in percent
void doShadowPane() {
    wrenEnsureSlots(vm, 4);
    const char *ptr = wrenGetSlotString(vm, 1);
    double radius = wrenGetSlotDouble(vm, 2);
    double opacity = wrenGetSlotDouble(vm, 3);

    NSView *view = (NSView *) strtol(ptr, NULL, 0);

    view.wantsLayer = YES;
    view.layer.shadowOpacity = opacity; //0.5f;
    view.layer.shadowRadius =  radius;   //5.0f;
    view.layer.shadowOffset = CGSizeMake(2.0f, [view isFlipped] ? 3.0f: -3.0f);
    view.layer.masksToBounds = NO;
}

//-----------------------------------------------------------------------------
//create button
void doCreateButton() {
    NSButton *button = [[[NSButton alloc] initWithFrame: CGRectZero] autorelease];
    [button setBezelStyle: NSBezelStyleRounded]; //Set what style you want (normal default)
    [button setAction: @selector(action:)];
    setObjectInSlot(button, 0);
}

//-----------------------------------------------------------------------------
//set button type
//0 = momentaryLight, 1 = pushOnOff, 2 = toggle, 3 = switch (checkbox), 4 = radio
//5 = momentaryChange, 6 = onOff, 7 = momentaryPushIn, 8 = accelerator, 9 = multilevel accelerator
void doButtonType() {
    wrenEnsureSlots(vm, 3);
    const char *ptr = wrenGetSlotString(vm, 1);
    const int type = (int) wrenGetSlotDouble(vm, 2);

    NSButton *c = (NSButton *) strtol(ptr, NULL, 0);
    [c setButtonType: type];
}

//-----------------------------------------------------------------------------
//set button bezel type (style)
//1=rounded, 2=regular square, 3= ?, 4= ?, 5=disclosure, 6=shadowless square, 7=circular, 8=textured square, 9=help,
//10=small square, 11=textured rounded, 12=roundrect, 13=recessed, 14=rounded disclosure, 15=inline
void doButtonStyle() {
    wrenEnsureSlots(vm, 3);
    const char *ptr = wrenGetSlotString(vm, 1);
    const int style = (int) wrenGetSlotDouble(vm, 2);

    NSButton *c = (NSButton *) strtol(ptr, NULL, 0);
    [c setBezelStyle: style];
}

//-----------------------------------------------------------------------------
//get button state
void doButtonGetState() {
    wrenEnsureSlots(vm, 2);
    const char *ptr = wrenGetSlotString(vm, 1);

    NSButton *c = (NSButton *) strtol(ptr, NULL, 0);
    int state = [c state];
    wrenSetSlotDouble(vm, 0, (double) state);
}

//-----------------------------------------------------------------------------
//set button state
void doButtonSetState() {
    wrenEnsureSlots(vm, 3);
    const char *ptr = wrenGetSlotString(vm, 1);
    const int state = (int) wrenGetSlotDouble(vm, 2);

    NSButton *c = (NSButton *) strtol(ptr, NULL, 0);
    [c setState:  state == 0 ? NSControlStateValueOff:  NSControlStateValueOn];
}

//-----------------------------------------------------------------------------
//set button title (not string value)
void doButtonTitle() {
    //we have two arguments: the ptr (string format) and the title string
    wrenEnsureSlots(vm, 3);
    const char *ptr = wrenGetSlotString(vm, 1);
    const char *txt = wrenGetSlotString(vm, 2);

    NSButton *c = (NSButton *) strtol(ptr, NULL, 0);
    [c setTitle: [NSString stringWithUTF8String: txt]];
}

//-----------------------------------------------------------------------------
//set button key
void doButtonKey() {
    //we have two arguments: the ptr (string format) and the title string
    wrenEnsureSlots(vm, 3);
    const char *ptr = wrenGetSlotString(vm, 1);
    const char *txt = wrenGetSlotString(vm, 2);

    NSButton *c = (NSButton *) strtol(ptr, NULL, 0);
    [c setKeyEquivalent: [NSString stringWithUTF8String: txt]];
}

//-----------------------------------------------------------------------------
//create new Pane
void doCreateView() {
//    MyView * view = [[[MyView alloc] initWithFrame: CGRectZero] autorelease];
    MyView * view = [[MyView alloc] initWithFrame: CGRectZero];
    view.wantsLayer = YES;
    [view setAcceptResponder: YES];
    setObjectInSlot(view, 0);
}

//-----------------------------------------------------------------------------
//create new Polygon Pane
void doCreatePolygonView() {
    PolygonView *view = [[PolygonView alloc] initWithFrame: CGRectZero];

    view.wantsLayer = YES;
    [view setAcceptResponder: YES];

//     //get points
//     //get number of list elements; each element is a point [x, y] (another list!)

//     //for first move to it, all others line to it
//     //close path

     setObjectInSlot(view, 0);
}

//-----------------------------------------------------------------------------
//set points in a Polygon view
void doPolygonPoints() {
    int i;
    //get view
    wrenEnsureSlots(vm, 4);
    const char *ptr = wrenGetSlotString(vm, 1);

    PolygonView *v = (PolygonView *) strtol(ptr, NULL, 0);

    //get list of points
    //first, how many?
    int many = wrenGetListCount(vm, 2);
    wrenEnsureSlots(vm, 5);

    //init path
    bool first = true;
    v.polygonPath = [NSBezierPath bezierPath];

    //get each point
    for (i = 0; i < many; i++) {
        //each element is another 2-element list:: wrenGetListElement(WrenVM* vm, int listSlot, int index, int elementSlot)
        wrenGetListElement(vm, 2, i, 3);
        wrenGetListElement(vm, 3, 0, 4);
        double x = wrenGetSlotDouble(vm, 4);
        wrenGetListElement(vm, 3, 1, 4);
        double y = wrenGetSlotDouble(vm, 4);
        NSLog(@"got %d = %f, %f", i, x, y);
        if (first) {
            [v.polygonPath moveToPoint: NSMakePoint(x, y)];
            first = false;
        } else {
            [v.polygonPath lineToPoint: NSMakePoint(x, y)];
        }
    }

    //close path and redisplay
    [v.polygonPath closePath]; 
    [v setNeedsDisplay: YES];
}

//-----------------------------------------------------------------------------
//create new label
void doCreateLabel() {
    NSTextField *textField = [[NSTextField alloc] initWithFrame: CGRectZero];
    [textField setBezeled:NO];
    [textField setDrawsBackground: NO];
    [textField setEditable:NO];
    [textField setSelectable:NO];
    setObjectInSlot(textField, 0);
}

//-----------------------------------------------------------------------------
//create new label
void doCreateTextField(){

    NSTextField *textField = [[NSTextField alloc] initWithFrame: CGRectZero];

    //all of these should be separately settable
    [textField setBezeled: YES];
    [textField setDrawsBackground: NO];
    [textField setEditable: YES];
    [textField setSelectable: YES];
    [textField setUsesSingleLineMode: YES];
    [textField setMaximumNumberOfLines: 1];

    [myMainWindow makeFirstResponder: textField];
    //create mechanism for knowing when something happens
    [textField setDelegate: myDelegate];

    setObjectInSlot(textField, 0);
}

//-----------------------------------------------------------------------------
//set control text
void doControlText() {
    //we have two arguments: the ptr (string format) and the text
    wrenEnsureSlots(vm, 3);
    const char *ptr = wrenGetSlotString(vm, 1);
    const char *txt = wrenGetSlotString(vm, 2);
    NSControl *c = (NSControl *) strtol(ptr, NULL, 0);
    [c setStringValue: [NSString stringWithUTF8String: txt]];
}

//-----------------------------------------------------------------------------
//get control text
void doControlTextGet() {
    wrenEnsureSlots(vm, 2);
    const char *ptr = wrenGetSlotString(vm, 1);
    NSControl *c = (NSControl *) strtol(ptr, NULL, 0);
    NSString *s = [c stringValue];
    wrenSetSlotString(vm, 0, [s UTF8String]);
}

//-----------------------------------------------------------------------------
//set text colour
void doTextColour() {
    //we have two arguments: the ptr (string format) and the colour list
    wrenEnsureSlots(vm, 7);
    const char *ptr = wrenGetSlotString(vm, 1);
    wrenGetListElement(vm, 2, 0, 3);    //from slot 2, get list element 0 = red
    wrenGetListElement(vm, 2, 1, 4);    //green
    wrenGetListElement(vm, 2, 2, 5);    //blue
    wrenGetListElement(vm, 2, 3, 6);    //alpha
    double red = wrenGetSlotDouble(vm, 3);
    double green = wrenGetSlotDouble(vm, 4);
    double blue = wrenGetSlotDouble(vm, 5);
    double alpha = wrenGetSlotDouble(vm, 6);

    NSColor *colour = [NSColor colorWithCalibratedRed: red
                                                  green: green
                                                  blue:  blue
                                                  alpha: alpha ];

    NSControl *v = (NSControl *) strtol(ptr, NULL, 0);
    [v setTextColor: colour];

}

//-----------------------------------------------------------------------------
//set view border colour
void doPaneBorderColour() {
    //we have two arguments: the ptr (string format) and the colour list
    wrenEnsureSlots(vm, 7);
    const char *ptr = wrenGetSlotString(vm, 1);
    wrenGetListElement(vm, 2, 0, 3);    //from slot 2, get list element 0 = red
    wrenGetListElement(vm, 2, 1, 4);    //green
    wrenGetListElement(vm, 2, 2, 5);    //blue
    wrenGetListElement(vm, 2, 3, 6);    //alpha
    double red = wrenGetSlotDouble(vm, 3);
    double green = wrenGetSlotDouble(vm, 4);
    double blue = wrenGetSlotDouble(vm, 5);
    double alpha = wrenGetSlotDouble(vm, 6);

    NSView *v = (NSView *) strtol(ptr, NULL, 0);
    v.wantsLayer = YES;

    NSColor *colour = [NSColor colorWithCalibratedRed: red
                                                  green: green
                                                  blue:  blue
                                                  alpha: alpha ];

    //set the view's layer border
    v.wantsLayer = YES;
    [v.layer setBorderColor: colour.CGColor];
}

//-----------------------------------------------------------------------------
//set view border
void doPaneBorder() {
    //we have two arguments: the ptr (string format) and the width
    wrenEnsureSlots(vm, 3);
    const char *ptr = wrenGetSlotString(vm, 1);
    double num = wrenGetSlotDouble(vm, 2);

    NSView *v = (NSView *) strtol(ptr, NULL, 0);
    v.wantsLayer = YES;

    [v.layer setBorderWidth: num];
}

//-----------------------------------------------------------------------------
//set polygon view border
void doPolyBorder() {
    //we have two arguments: the ptr (string format) and the width
    wrenEnsureSlots(vm, 3);
    const char *ptr = wrenGetSlotString(vm, 1);
    double num = wrenGetSlotDouble(vm, 2);

    PolygonView *v = (PolygonView *) strtol(ptr, NULL, 0);

    v.borderWidth = num;
    [v setNeedsDisplay: YES];
}

//-----------------------------------------------------------------------------
//set control frame: args id and frame
void doPaneFrame() {
    //we have the ptr (string format)
    wrenEnsureSlots(vm, 7);
    const char *ptr = wrenGetSlotString(vm, 1);

    NSView *v = (NSView *) strtol(ptr, NULL, 0);

    wrenGetListElement(vm, 2, 0, 3);    //from slot 2, get list element 0 = x
    wrenGetListElement(vm, 2, 1, 4);    //y
    wrenGetListElement(vm, 2, 2, 5);    //w
    wrenGetListElement(vm, 2, 3, 6);    //h
    double x = wrenGetSlotDouble(vm, 3);
    double y = wrenGetSlotDouble(vm, 4);
    double w = wrenGetSlotDouble(vm, 5);
    double h = wrenGetSlotDouble(vm, 6);

    NSRect f = NSMakeRect(x, y, w, h);
    [v setFrame: f];
}

//-----------------------------------------------------------------------------
//hide or show view
void doShowPane() {
    //we have the ptr (string format)
    wrenEnsureSlots(vm, 3);
    const char *ptr = wrenGetSlotString(vm, 1);
    bool show = wrenGetSlotBool(vm, 2);
    NSView *v = (NSView *) strtol(ptr, NULL, 0);
    [v setHidden: !show];
}

//-----------------------------------------------------------------------------
//get hide or show view status (visibility)
void doPaneVisibility() {
    //we have the ptr (string format)
    wrenEnsureSlots(vm, 2);
    const char *ptr = wrenGetSlotString(vm, 1);
    NSView *v = (NSView *) strtol(ptr, NULL, 0);
    wrenSetSlotBool(vm, 0, (bool) [v isHidden]);
}

//-----------------------------------------------------------------------------
//set pane colour
void doPaneColour() {
    //we have two arguments: the ptr (string format) and the colour list
    wrenEnsureSlots(vm, 7);
    const char *ptr = wrenGetSlotString(vm, 1);
    wrenGetListElement(vm, 2, 0, 3);    //from slot 2, get list element 0 = red
    wrenGetListElement(vm, 2, 1, 4);    //green
    wrenGetListElement(vm, 2, 2, 5);    //blue
    wrenGetListElement(vm, 2, 3, 6);    //alpha
    double red = wrenGetSlotDouble(vm, 3);
    double green = wrenGetSlotDouble(vm, 4);
    double blue = wrenGetSlotDouble(vm, 5);
    double alpha = wrenGetSlotDouble(vm, 6);

    NSView *v = (NSView *) strtol(ptr, NULL, 0);
    v.wantsLayer = YES;

    NSColor *colour = [NSColor colorWithCalibratedRed: red
                                                  green: green
                                                  blue:  blue
                                                  alpha: alpha ];

    //set it to the view's layer
    [v.layer setBackgroundColor: colour.CGColor];
}

//-----------------------------------------------------------------------------
//set polygon pane colour
void doFillColour() {
    //we have two arguments: the ptr (string format) and the colour list
    wrenEnsureSlots(vm, 7);
    const char *ptr = wrenGetSlotString(vm, 1);
    wrenGetListElement(vm, 2, 0, 3);    //from slot 2, get list element 0 = red
    wrenGetListElement(vm, 2, 1, 4);    //green
    wrenGetListElement(vm, 2, 2, 5);    //blue
    wrenGetListElement(vm, 2, 3, 6);    //alpha
    double red = wrenGetSlotDouble(vm, 3);
    double green = wrenGetSlotDouble(vm, 4);
    double blue = wrenGetSlotDouble(vm, 5);
    double alpha = wrenGetSlotDouble(vm, 6);

    PolygonView *v = (PolygonView *) strtol(ptr, NULL, 0);

    NSColor *colour = [NSColor colorWithCalibratedRed: red
                                                  green: green
                                                  blue:  blue
                                                  alpha: alpha ];

    //set it to the view's polygon
    v.fillColour = colour;
    [v setNeedsDisplay: YES];
}

//-----------------------------------------------------------------------------
//set polygon stroke colour
void doStrokeColour() {
    //we have two arguments: the ptr (string format) and the colour list
    wrenEnsureSlots(vm, 7);
    const char *ptr = wrenGetSlotString(vm, 1);
    wrenGetListElement(vm, 2, 0, 3);    //from slot 2, get list element 0 = red
    wrenGetListElement(vm, 2, 1, 4);    //green
    wrenGetListElement(vm, 2, 2, 5);    //blue
    wrenGetListElement(vm, 2, 3, 6);    //alpha
    double red = wrenGetSlotDouble(vm, 3);
    double green = wrenGetSlotDouble(vm, 4);
    double blue = wrenGetSlotDouble(vm, 5);
    double alpha = wrenGetSlotDouble(vm, 6);

    PolygonView *v = (PolygonView *) strtol(ptr, NULL, 0);

    NSColor *colour = [NSColor colorWithCalibratedRed: red
                                                  green: green
                                                  blue:  blue
                                                  alpha: alpha ];

    //set it to the view's stroke
    v.strokeColour = colour;
    [v setNeedsDisplay: YES];
}

//-----------------------------------------------------------------------------
//set text font for stuff
void doSetFont() {
    //we have the ptr (string format)
    wrenEnsureSlots(vm, 3);
    const char *ptr = wrenGetSlotString(vm, 1);
    const char *fnt = wrenGetSlotString(vm, 2);

    NSControl *c = (NSControl *) strtol(ptr, NULL, 0);
    NSFont *f = (NSFont *) strtol(fnt, NULL, 0);

    [c setFont: f];
}

//-----------------------------------------------------------------------------
//create font
// use: createFont(name, size, bold, italic). eg. createFont("Arial", 16, true, false)
//
void doCreateFont() {
    wrenEnsureSlots(vm, 5);
    NSString *name = [NSString stringWithUTF8String: wrenGetSlotString(vm, 1)];
    double size = wrenGetSlotDouble(vm, 2);
    bool bold = wrenGetSlotBool(vm, 3);
    bool italic = wrenGetSlotBool(vm, 4);

//    NSFont *font = [[NSFontManager sharedFontManager] convertFont: [[NSFontManager sharedFontManager] convertFont: [NSFont fontWithName: name size: size]]];
    NSFont *font = [NSFont fontWithName: name size: size];
    if (bold) [[NSFontManager sharedFontManager] convertFont: font toHaveTrait: NSFontBoldTrait];
    if (italic) [[NSFontManager sharedFontManager] convertFont: font toHaveTrait: NSFontItalicTrait];

    setObjectInSlot(font, 0);
}

//-----------------------------------------------------------------------------
//create new window
void doCreateWindow() {
    //we need the ptr (string format)
    wrenEnsureSlots(vm, 1);
    NSWindow *w = createWindow();
    setObjectInSlot(w, 0);
}

//-----------------------------------------------------------------------------
//show window (for second etc.)
void doShowWindow() {
    //we have the ptr (string format)
    wrenEnsureSlots(vm, 2);
    const char *ptr = wrenGetSlotString(vm, 1);

    NSWindow *w = (NSWindow *) strtol(ptr, NULL, 0);

    [w setFrame: [w frame] display: YES];
    NSWindowController *windowController = [[NSWindowController alloc] initWithWindow: w];
    [windowController showWindow:nil];
}

//-----------------------------------------------------------------------------
//close window
void doCloseWindow() {
    //we have the ptr (string format)
    wrenEnsureSlots(vm, 2);
    const char *ptr = wrenGetSlotString(vm, 1);

    NSWindow *w = (NSWindow *) strtol(ptr, NULL, 0);

    [w close];
    [w release];
}

//-----------------------------------------------------------------------------
void doWindowTitle() {
    //we have two arguments: the ptr (string format) and the title string
    wrenEnsureSlots(vm, 3);
    const char *ptr = wrenGetSlotString(vm, 1);
    const char *txt = wrenGetSlotString(vm, 2);

    NSWindow *w = (NSWindow *) strtol(ptr, NULL, 0);
    [w setTitle: [NSString stringWithUTF8String: txt]];
}

//-----------------------------------------------------------------------------
void doWindowCentre() {
    //we have the ptr (string format)
    wrenEnsureSlots(vm, 2);
    const char *ptr = wrenGetSlotString(vm, 1);

    NSWindow *w = (NSWindow *) strtol(ptr, NULL, 0);
    [w center];
}

//-----------------------------------------------------------------------------
void doWindowFrame() {
    //we have two arguments: the ptr (string format) and the frame list [x,y,w,h]
    wrenEnsureSlots(vm, 7);
    const char *ptr = wrenGetSlotString(vm, 1);     //the ptr in slot 1 (slot 0 is reserved for outputs)
    wrenGetListElement(vm, 2, 0, 3);    //from slot 2, get list element 0 = x
    wrenGetListElement(vm, 2, 1, 4);    //y
    wrenGetListElement(vm, 2, 2, 5);    //w
    wrenGetListElement(vm, 2, 3, 6);    //h
    double x = wrenGetSlotDouble(vm, 3);
    double y = wrenGetSlotDouble(vm, 4);
    double w = wrenGetSlotDouble(vm, 5);
    double h = wrenGetSlotDouble(vm, 6);

    NSRect f = NSMakeRect(x, y, w, h);
    NSWindow *win = (NSWindow *) strtol(ptr, NULL, 0);

    //disable notifications when this is done

    [[NSNotificationCenter defaultCenter] removeObserver: myDelegate];

    [win setFrame: f display: YES];

    //reenable
    [[NSNotificationCenter defaultCenter] addObserver: myDelegate selector: @selector(windowDidResize:) name: NSWindowDidResizeNotification object: myMainWindow];
}

//-----------------------------------------------------------------------------
//set window background colour
void doWindowColour() {
    //we have two arguments: the ptr (string format) and the colour list
    wrenEnsureSlots(vm, 7);
    const char *ptr = wrenGetSlotString(vm, 1);
    wrenGetListElement(vm, 2, 0, 3);    //from slot 2, get list element 0 = red
    wrenGetListElement(vm, 2, 1, 4);    //green
    wrenGetListElement(vm, 2, 2, 5);    //blue
    wrenGetListElement(vm, 2, 3, 6);    //alpha
    double red = wrenGetSlotDouble(vm, 3);
    double green = wrenGetSlotDouble(vm, 4);
    double blue = wrenGetSlotDouble(vm, 5);
    double alpha = wrenGetSlotDouble(vm, 6);

    NSWindow *w = (NSWindow *) strtol(ptr, NULL, 0);

    NSColor *colour = [NSColor colorWithCalibratedRed: red
                                                  green: green
                                                  blue:  blue
                                                  alpha: alpha ];

    [w setBackgroundColor: colour];
}

//-----------------------------------------------------------------------------
void doGetFrame() {
    wrenEnsureSlots(vm, 5);
    const char *ptr = wrenGetSlotString(vm, 1);

    //get object frame
    NSRect mf = [(id) strtol(ptr, NULL, 0) frame];

    //store frame in slots 1..4
    wrenSetSlotDouble(vm, 1, (double) mf.origin.x);
    wrenSetSlotDouble(vm, 2, (double) mf.origin.y);
    wrenSetSlotDouble(vm, 3, (double) mf.size.width);
    wrenSetSlotDouble(vm, 4, (double) mf.size.height);

    //the frame is an NSRect - convert to wren list [x,y,w,h]
    wrenSetSlotNewList(vm, 0);
    wrenInsertInList(vm, 0, 0, 1);
    wrenInsertInList(vm, 0, 1, 2);
    wrenInsertInList(vm, 0, 2, 3);
    wrenInsertInList(vm, 0, 3, 4);
}

//-----------------------------------------------------------------------------
void doMainScreenFrame() {
    wrenEnsureSlots(vm, 5);

    //store mainScreenFrame for later use
    NSRect mf = [[NSScreen mainScreen] frame];

    //store frame in slots 1..4
    wrenSetSlotDouble(vm, 1, (double) mf.origin.x);
    wrenSetSlotDouble(vm, 2, (double) mf.origin.y);
    wrenSetSlotDouble(vm, 3, (double) mf.size.width);
    wrenSetSlotDouble(vm, 4, (double) mf.size.height);

    //the frame is an NSRect - convert to wren list [x,y,w,h]
    wrenSetSlotNewList(vm, 0);
    wrenInsertInList(vm, 0, 0, 1);
    wrenInsertInList(vm, 0, 1, 2);
    wrenInsertInList(vm, 0, 2, 3);
    wrenInsertInList(vm, 0, 3, 4);
}

//-----------------------------------------------------------------------------
void doMainWindow() {
    setObjectInSlot(myMainWindow, 0);
}

//-----------------------------------------------------------------------------
//provide command line arguments
void doCommandArgs() {
    wrenEnsureSlots(vm, storedArgc+1);
    int i;

    //create result list
    wrenSetSlotNewList(vm, 0);

    //store args in slots 1..argc and then in list
    for (i = 0; i < storedArgc; i++) {
        wrenSetSlotString(vm, i+1, storedArgv[i]);
        wrenInsertInList(vm, 0, i, i+1);
    }
}

//-----------------------------------------------------------------------------
//AlertPanel:  result := Alert title: 'Application' message: 'Are you sure?'. result= 1000 OK, 1001 cancel, 1002 third button.
// res := Alert title: tit message: msg style: x button: 'OK' button: 'Cancel'. Leave the last button blank if you don't want it.
//styles: Warning: 0, Info: 1, Critical: 2

void doAlertPanel() {
    wrenEnsureSlots(vm, 7);
    const char *title = wrenGetSlotString(vm, 1);
    const char *message = wrenGetSlotString(vm, 2);
    double style = wrenGetSlotDouble(vm, 3);
    const char *button1 = wrenGetSlotString(vm, 4);
    const char *button2 = wrenGetSlotString(vm, 5);
    // const char *button3 = wrenGetSlotString(vm, 6);

    NSAlert* alert = [[NSAlert alloc] init];
    [alert setMessageText: [NSString stringWithUTF8String: title]];
    [alert setInformativeText: [NSString stringWithUTF8String: message]];
    [alert setAlertStyle: (int) style];
    if (button1 != NULL) [alert addButtonWithTitle: [NSString stringWithUTF8String: button1]];
    if (button2 != NULL) [alert addButtonWithTitle: [NSString stringWithUTF8String: button2]];
    // if (button3 != NULL) [alert addButtonWithTitle: [NSString stringWithUTF8String: button3]];

    NSModalResponse response = [alert runModal];
    
    wrenSetSlotBool(vm, 0, response);
}

//-----------------------------------------------------------------------------
//savePanel: result := Application savePanel: 'default.txt'.
//on cancel returns the empty, otherwise file name.
void doSavePanel() {

    wrenEnsureSlots(vm, 3);
    const char *title = wrenGetSlotString(vm, 1);
    bool canCreateDir = wrenGetSlotBool(vm, 2);

    NSSavePanel* saveFileDialog = [[[NSSavePanel alloc] init] autorelease];

    [saveFileDialog setCanCreateDirectories: canCreateDir];
//   [saveFileDialog setAllowedFileTypes:[NSArray arrayWithObjects:@"txt", @"md", nil]];
//   [saveFileDialog setDirectoryURL:[NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject]]];
    [saveFileDialog setNameFieldStringValue: [NSString stringWithUTF8String: title]];

//    NSLog(@"Save with: %s", title);

    NSModalResponse response = [saveFileDialog runModal];
    if (response == NSModalResponseOK) {
        wrenSetSlotString(vm, 0, [[[saveFileDialog URL] path] UTF8String]);
    } else {
        wrenSetSlotString(vm, 0, "");
    }
}

//-----------------------------------------------------------------------------
//OpenPanel:  Application openPanel type: 'txt' multi: 0/1 dir: 0/1. If type is empty all files are accepted
//returns List with results. Empty if cancelled
void doOpenPanel() {

    const char *type = "";
    int listCount = 0;                      //counter for list. 0 for no list
    wrenEnsureSlots(vm, 5);
    if (wrenGetSlotType(vm, 1) == WREN_TYPE_STRING) {
        type = wrenGetSlotString(vm, 1);
    } else if (wrenGetSlotType(vm, 1) == WREN_TYPE_LIST) {
        listCount = wrenGetListCount(vm, 1);
        wrenEnsureSlots(vm, 5+listCount);
        int i;
        for (i = 0; i < listCount; i++) {
            wrenGetListElement(vm, 1, i, 5+i);    //from slot 1, get list element i and put in slot 5+i
        }
    }
    int multi = (int) wrenGetSlotBool(vm, 2);
    int dir = (int) wrenGetSlotBool(vm, 3);

    NSURL *dirURL = nil;
    int listSize = 0;

    int canDir = 0;
    int mulFil = 0;
    int canFil = 1;

    if (multi > 0) {
        mulFil = 1;
    }

    if (dir > 0) {
        canDir = 1;
        canFil = 0;
    }

    NSOpenPanel* openFileDialog = [[[NSOpenPanel alloc] init] autorelease];
    [openFileDialog setCanChooseFiles: canFil];
    [openFileDialog setCanChooseDirectories: canDir];
    [openFileDialog setAllowsMultipleSelection: mulFil];
    if (listCount > 0) {
        NSMutableArray *customExtensions = [NSMutableArray array];
        int i;
        for (i = 0; i < listCount; i++) {
            [customExtensions addObject: [NSString stringWithUTF8String: wrenGetSlotString(vm, 5+i)]];
        }

        NSMutableArray<UTType *> *allowedTypes = [NSMutableArray array];
        for (NSString *extension in customExtensions) {
            UTType *type = [UTType typeWithFilenameExtension:extension];
            if (type) {
                [allowedTypes addObject:type];
            }
        }
        openFileDialog.allowedContentTypes = allowedTypes;
    }

//  [openFileDialog setDirectoryURL:[NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject]]];

    NSModalResponse response = [openFileDialog runModal];

    wrenSetSlotNewList(vm, 0);              //return list; empty if aborted
    if (response == NSModalResponseOK) {
        dirURL = [[openFileDialog URLs] objectAtIndex: 0];
        wrenSetSlotNewList(vm, 0);
        if (mulFil && !canDir) {

            listSize = [[openFileDialog URLs] count];
            wrenEnsureSlots(vm, listSize+5);
            int i = 0;
            for ( NSURL * thisURL in [openFileDialog URLs] ) {
                wrenSetSlotString(vm, i+4, (char *) [[thisURL path] UTF8String]);
                wrenInsertInList(vm, 0, i, i+4);
                i++;
            }

        } else if (mulFil && canDir) {    //directory
            NSArray *dirContents = [[NSFileManager defaultManager]  contentsOfDirectoryAtPath:
                [[[openFileDialog URLs] objectAtIndex: 0] path] error: nil];

            listSize = [dirContents count];
            wrenEnsureSlots(vm, listSize+4);
            int i = 0;
            for ( NSString * thisPath in dirContents ) {
                NSString *fullPath = [[ (NSString *) [dirURL path] stringByAppendingString: @"/" ] stringByAppendingString: thisPath];
                wrenSetSlotString(vm, i+4, (char *) [fullPath UTF8String]);
                wrenInsertInList(vm, 0, i, i+4);
                i++;
            }

        } else if (canDir && !mulFil){ //just dir
            wrenEnsureSlots(vm, 5);
            wrenSetSlotString(vm, 4, (char *) [[dirURL path] UTF8String]);
            wrenInsertInList(vm, 0, 0, 4);
        } else {    //single file
            wrenEnsureSlots(vm, 5);
            wrenSetSlotString(vm, 4, (char *) [[(NSURL*)[[openFileDialog URLs] objectAtIndex: 0] path] UTF8String]);
            wrenInsertInList(vm, 0, 0, 4);
        }
    }
}

//-----------------------------------------------------------------------------
//close file (ptr)
void doFileClose() {
    FILE **file = (FILE **) wrenGetSlotForeign(vm, 0);

    //if already closed do nothing
    if (*file == NULL) return;

    fclose(*file);
}

//-----------------------------------------------------------------------------
//write file (ptr)
void doFileWrite(WrenVM* vm) {
    FILE **file = (FILE **) wrenGetSlotForeign(vm, 0);

    // Make sure the file is still open.
    if (*file == NULL) {
        wrenSetSlotString(vm, 0, "Cannot write to a closed file.");
        wrenAbortFiber(vm, 0);
    } else {
        const char *text = wrenGetSlotString(vm, 1);
        int n = fwrite(text, sizeof(char), strlen(text), *file);
        wrenSetSlotDouble(vm, 0, (double) n);
    }
}

//-----------------------------------------------------------------------------
//read file (ptr)
void doFileRead() {
    FILE **file = (FILE **) wrenGetSlotForeign(vm, 0);

    // Make sure the file is still open.
    if (*file == NULL) {
        wrenSetSlotString(vm, 0, "Cannot read from a closed file.");
        wrenAbortFiber(vm, 0);
    } else {
        fseek(*file, 0, SEEK_END);          //to end
        long contentSize = ftell(*file);    //how big?
        rewind(*file);                      //to beginning
        void *contents = malloc(contentSize+1);     //allocate memory
        int n = fread(contents, sizeof(char), contentSize, *file);      //read whole file
        wrenSetSlotString(vm, 0, contents);     //pass to wren
        free(contents);                     //free buffer
    }

}

//-----------------------------------------------------------------------------
//size file (ptr)
void doFileSize() {
    FILE **file = (FILE **) wrenGetSlotForeign(vm, 0);

    long now = ftell(*file);
    fseek(*file, 0, SEEK_END);
    long sz = ftell(*file);

    fseek(*file, now, SEEK_SET);
    wrenSetSlotDouble(vm, 0, (double) sz);
}

//-----------------------------------------------------------------------------
//read a file
void doReadFile() {
    wrenEnsureSlots(vm, 2);
    const char *fileName = wrenGetSlotString(vm, 1);
    wrenSetSlotString(vm, 0, readFile(fileName));
}

//-----------------------------------------------------------------------------
//copy file the ObjC way
void doCopyFile() {
    wrenEnsureSlots(vm, 3);
    const char *frompath = wrenGetSlotString(vm, 1);
    const char *topath = wrenGetSlotString(vm, 2);

    NSString *srcPath = [NSString stringWithUTF8String: frompath];
    NSString *dstPath = [NSString stringWithUTF8String: topath];

    if ([[NSFileManager defaultManager] copyItemAtPath: srcPath toPath: dstPath error: nil]) {
        wrenSetSlotBool(vm, 0, TRUE);
    } else {
        wrenSetSlotBool(vm, 0, FALSE);
    }
}

//-----------------------------------------------------------------------------
//create directory the ObjC way
void doCreateDirectory() {
    wrenEnsureSlots(vm, 2);
    const char *name = wrenGetSlotString(vm, 1);

    if ([[NSFileManager defaultManager] createDirectoryAtPath: [NSString stringWithUTF8String: name]
        withIntermediateDirectories: YES attributes: nil error: nil]) {
        wrenSetSlotBool(vm, 0, TRUE);
    } else {
        wrenSetSlotBool(vm, 0, FALSE);
    }
}

//-----------------------------------------------------------------------------
//delete directory the ObjC way
void doDeleteDirectory() {
    wrenEnsureSlots(vm, 2);
    const char *name = wrenGetSlotString(vm, 1);

    if ([[NSFileManager defaultManager] removeItemAtPath: [NSString stringWithUTF8String: name] error: nil]) {
        wrenSetSlotBool(vm, 0, TRUE);
    } else {
        wrenSetSlotBool(vm, 0, FALSE);
    }
}

//-----------------------------------------------------------------------------
//file exists the ObjC way
void doExistsFile() {
    wrenEnsureSlots(vm, 2);
    const char *name = wrenGetSlotString(vm, 1);
    
    wrenSetSlotBool(vm, 0, [[NSFileManager defaultManager] fileExistsAtPath: [NSString stringWithUTF8String: name]]);
}

//-----------------------------------------------------------------------------
//rename file the ObjC way
void doRenameFile() {
    wrenEnsureSlots(vm, 3);
    const char *frompath = wrenGetSlotString(vm, 1);
    const char *topath = wrenGetSlotString(vm, 2);

    NSString *srcPath = [NSString stringWithUTF8String: frompath];
    NSString *dstPath = [NSString stringWithUTF8String: topath];

    if ([[NSFileManager defaultManager] moveItemAtPath: srcPath toPath: dstPath error: nil]) {
        wrenSetSlotBool(vm, 0, TRUE);
    } else {
        wrenSetSlotBool(vm, 0, FALSE);
    }
}

//-----------------------------------------------------------------------------
//run subprocess the ObjC way. NOTE: to run MyApp you MUST exec MyApp.app/Contents/MacOS/MyApp !! (use right filenames)
void doExecuteTask() {
    wrenEnsureSlots(vm, 4);
    const char *execpath = wrenGetSlotString(vm, 1);

    NSMutableArray *args = [NSMutableArray array];
    int listCount = wrenGetListCount(vm, 2);

    if (listCount > 0) {
        wrenEnsureSlots(vm, 4+listCount);
        int i;
        for (i = 0; i < listCount; i++) {
            wrenGetListElement(vm, 2, i, 4+i);    //from slot 2, get list element i and put in slot 4+i
            [args addObject: [NSString stringWithUTF8String: wrenGetSlotString(vm, 4+i)]];
        }
    }

    int wait = (int) wrenGetSlotBool(vm, 3);

    //get and init task
    NSURL *executableURL = [NSURL fileURLWithPath: [NSString stringWithUTF8String: execpath]];
    NSTask *task = [[NSTask alloc] init];

    // Error variable to capture any launch errors
    NSError *error = nil;

    // Set up the task
    [task setExecutableURL: executableURL];
    [task setArguments: args];
    
    int errorCode = 0;

    // Launch the task    
    [task launchAndReturnError: &error];

    // Check for errors
    if (error) {
        errorCode = 1;
        NSLog(@"Error launching task: %@", error);
    }
    
    // Wait until the task completes (optional)
    if (wait) [task waitUntilExit];
    
    wrenSetSlotDouble(vm, 0, (double) errorCode);
}


//-----------------------------------------------------------------------------
void doEnableMouseMoveEvents() {
    wrenEnsureSlots(vm, 3);
    const char *ptr = wrenGetSlotString(vm, 1);
    bool enab = wrenGetSlotBool(vm, 2);
    NSWindow *w = (NSWindow *) strtol(ptr, NULL, 0);
    [w setAcceptsMouseMovedEvents: enab];
}

//-----------------------------------------------------------------------------
void doGetExecutablePath() {
    wrenEnsureSlots(vm, 1);
    wrenSetSlotString(vm, 0, [exPath UTF8String]);
}

//-----------------------------------------------------------------------------
void doGetResourcePath() {
    wrenEnsureSlots(vm, 1);
    wrenSetSlotString(vm, 0, [resPath UTF8String]);
}

//-----------------------------------------------------------------------------
void doGetHomePath() {
    wrenEnsureSlots(vm, 1);
    wrenSetSlotString(vm, 0, [homePath UTF8String]);
}

//-----------------------------------------------------------------------------
void doGetDocumentsPath() {
    wrenEnsureSlots(vm, 1);
    wrenSetSlotString(vm, 0, [docPath UTF8String]);
}

//-----------------------------------------------------------------------------
//Application access to variables, Transform CATransform3D struct
//setting a pointer to the struct in slot 0
void transformAllocate() {
    CATransform3D *tf = (CATransform3D *) wrenSetSlotNewForeign(vm, 0, 0, sizeof (CATransform3D));      //output slot 0
}

//-----------------------------------------------------------------------------
//Application access to variables, File FILE * struct
//setting a pointer to the struct in slot 0
void fileAllocate() {
    FILE **file = (FILE **) wrenSetSlotNewForeign(vm, 0, 0, sizeof(FILE *));
    const char *path = wrenGetSlotString(vm, 1);
    const char *mode = wrenGetSlotString(vm, 2);
    *file = fopen(path, mode);
    //check if error - abort fiber
    if (*file == NULL) {
        wrenSetSlotString(vm, 0, "File not found");
        wrenAbortFiber(vm, 0);
    }
}

static void closeFile(FILE **file) {
    // Already closed.
    if (*file == NULL) return;

    fclose(*file);
    *file = NULL;
}

void fileFinalize(void* data) {
  closeFile((FILE**) data);
}

//-----------------------------------------------------------------------------
//HELPER to create main window
NSWindow *createWindow() {

    //Pick your window style:
    NSUInteger windowStyle = NSWindowStyleMaskTitled | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable;

    NSRect r = NSMakeRect(100, 100, 100, 100);
//    r = NSZeroRect;
    NSWindow *win = [[NSWindow alloc] initWithContentRect: NSZeroRect styleMask: windowStyle backing: NSBackingStoreBuffered defer: NO];

    // set the window level to be on top of everything else
    // NSInteger windowLevel = NSMainMenuWindowLevel + 1;
    // [window setLevel: windowLevel];
    [win setOpaque: YES];
    [win setHasShadow: YES];
    [win setHidesOnDeactivate: NO];

//    [win setBackgroundColor: [NSColor whiteColor]];          //separate call
//    [win setIsVisible: YES];                                 //separate call

    return win;
}

//-----------------------------------------------------------------------------
//setup the app for wren
void doAppRun() {

    //setup wren Application
    wrenEnsureSlots(vm, 1);
    wrenGetVariable(vm, "gui", "Event", 0);
    appClass = wrenGetSlotHandle(vm, 0);
    appNotifications = wrenMakeCallHandle(vm, "onNotification(_,_)");       //args: name, sender (strings)
    appEvents = wrenMakeCallHandle(vm, "onEvent(_)");                       //args: sender (string)
    appTimer = wrenMakeCallHandle(vm, "onTimer(_)");                        //args: sender (string)

}

//-----------------------------------------------------------------------------
//start proper
void appStart() {
    //and start the Mac app!
    [[NSNotificationCenter defaultCenter] addObserver: myDelegate selector: @selector(windowDidResize:) name: NSWindowDidResizeNotification object: myMainWindow];
    @autoreleasepool {
        [NSApp run];     //never returns
    }
}

//-----------------------------------------------------------------------------
void doAppClose() {
    //close main window, cannot do  [NSApp terminate: NSApp];
    //since we've said that the app terminates on last window closed, this works (if no other window is open)
    [myMainWindow close];
    [myMainWindow release];
}

//-----------------------------------------------------------------------------
//terminate
void doTerminate() {
    [NSApp terminate: NSApp];
}

//-----------------------------------------------------------------------------
//init GUI Cocoa app
void initialiseGUI() {

    //crucial
    [NSApplication sharedApplication];
    // myDelegate = [MyAppDelegate alloc];
    // [NSApp setDelegate: [[myDelegate init] autorelease]];

    myDelegate = [[MyAppDelegate new] autorelease];
    [NSApp setDelegate: myDelegate];

    NSFileManager *fileManager = [NSFileManager defaultManager];

    //Get documents directory
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);

    NSBundle *myBundle = [NSBundle mainBundle];
    docPath = [directoryPaths objectAtIndex: 0];
    exPath = [myBundle executablePath];
    resPath = [myBundle resourcePath];
    homePath = NSHomeDirectory();
    startup = [myBundle pathForResource:@"main" ofType:@"wren"];          //default is where resource is

#ifdef DEBUG
    fprintf(log_file, "%s: initial startup '%s'\n", nowTime(), [startup UTF8String]);
#endif

    if ([fileManager fileExistsAtPath: startup] != YES) {
        //if not there, perhaps in the documents directory?
        startup = [docPath stringByAppendingPathComponent:@"main.wren" ];
    }

#ifdef DEBUG
    fprintf(log_file, "%s: final startup '%s'\n", nowTime(), [startup UTF8String]);
#endif

    // const char *startFile = GC_MALLOC(FILENAME_MAX);
    // startFile = [startup UTF8String];
    // iniFile = (char *) startFile;

    // Since we are no real UI application yet and since we have no Info.plist, we must programmatically become a UI process
    //see: https://stackoverflow.com/questions/2724482/catching-multiple-keystrokes-simultaneously-in-cocoa/2731166#2731166

    ProcessSerialNumber myProcess = { 0, kCurrentProcess };
    TransformProcessType(
        &myProcess,
        kProcessTransformToForegroundApplication
    );

    return;
}

//-----------------------------------------------------------------------------
//INITIALISE gui environment -- all the stuff that really needs this environment

@implementation MyAppDelegate           //delegate and initialisation stuff

//HELPER actions and target for stuff
- (void) action: (id) sender {
    
    //check flag -- do not call wren if we are in a call (via eventCommon)
//    if (disableActions) return;

    //convert sender to string
     char *ptr = malloc(15);
     sprintf(ptr, "%p", sender);

    if (appClass != NULL) {
        disableActions = true;
        wrenEnsureSlots(vm, 2);
        wrenSetSlotHandle(vm, 0, appClass);
        wrenSetSlotString(vm, 1, ptr);
        WrenInterpretResult res = wrenCall(vm, appEvents);
        if (res != WREN_RESULT_SUCCESS) NSLog(@"Error calling Wren!");
        disableActions = false;
    }
    free(ptr);

}

//NOTIFICATION actions
- (void) noteAction: (id) sender name: (id) noteName {

    // NSLog(@"notification: %@ (disabled = %d)", noteName, disableActions);

    if ([noteName isEqualToString: @"NSApplicationDidFinishLaunchingNotification"]) {

        disableActions = TRUE;

        //initialise wren
        WrenConfiguration config;
        wrenInitConfiguration(&config);
        config.writeFn = &writeFn;
        config.errorFn = &errorFn;
        config.loadModuleFn = &loadModule;
        config.bindForeignMethodFn = &bindMethods;
        config.bindForeignClassFn = &bindClasses;

        vm = wrenNewVM(&config);

        const char* module = "main";
        doBindings(module);

        //execute script
        WrenInterpretResult result = wrenInterpret(vm, module, script);

        //result?
        switch (result) {
            case WREN_RESULT_COMPILE_ERROR:
                printf("Compile Error!\n");
                exit(1);                        //don't continue if error in code
            case WREN_RESULT_RUNTIME_ERROR:
                printf("Runtime Error!\n");
                exit(1);                        //don't continue if error in code
            case WREN_RESULT_SUCCESS:
            //      printf("Success!\n");
                break;
        }
        disableActions = FALSE;

        //return;
    }

    //check if allowed
    if (disableActions) return;

    //convert sender to string
     char *ptr = malloc(15);
     sprintf(ptr, "%p", sender);

    if (appClass != NULL) {
        disableActions = true;
        wrenEnsureSlots(vm, 3);
        wrenSetSlotHandle(vm, 0, appClass);
        wrenSetSlotString(vm, 1, [noteName UTF8String]);
        wrenSetSlotString(vm, 2, ptr);
        WrenInterpretResult res = wrenCall(vm, appNotifications);
        if (res != WREN_RESULT_SUCCESS) NSLog(@"Error calling Wren!");
        disableActions = false;
    }
    free(ptr);
}

//Timer action, which calls wren
- (void) timerFired: (NSTimer *) timer {

    //check flag -- do not call wren if we are in a call (via eventCommon)
    if (disableActions) return;

    //convert sender to string
     char *ptr = malloc(15);
     sprintf(ptr, "%p", timer);

    if (appClass != NULL) {
        disableActions = true;
        wrenEnsureSlots(vm, 2);
        wrenSetSlotHandle(vm, 0, appClass);
        wrenSetSlotString(vm, 1, ptr);
        WrenInterpretResult res = wrenCall(vm, appTimer);
        if (res != WREN_RESULT_SUCCESS) NSLog(@"Error calling Wren!");
        disableActions = false;
    }
    free(ptr);
}

//-----------------------------------------------------------------------------
//INIT APP
- (id) init {
    self = [super init];
    if (self) {

        //we must have a window, so create if not yet there, using default size and title below
        if (myMainWindow == NULL) myMainWindow = createWindow();

        window = myMainWindow;      //save for later use
        [window center];
        window.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;

        //or separate activation call?
        // [[NSNotificationCenter defaultCenter] addObserver: myDelegate selector: @selector(windowDidResize:) name: NSWindowDidResizeNotification object: myMainWindow];

    }
    return self;
}

// -----------------------------------
// First Responder Methods
//- (BOOL) acceptsFirstResponder {
//	printf("Accept\n");
//    return YES;
//}

//DEINIT app
- (void) dealloc {
    // release your window and other stuff //
    [window release];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [super dealloc];
}

//set button colours
// - (void) setButtonTitleFor: (NSButton*) button toString: (NSString*) title withColor: (NSColor*) color {
//     NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
//     [style setAlignment: NSTextAlignmentCenter];
//     NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
//         color, NSForegroundColorAttributeName, style, NSParagraphStyleAttributeName, nil];
//     NSAttributedString *attrString = [[NSAttributedString alloc] initWithString: title attributes: attrsDictionary];

//     [button setAttributedTitle: attrString];
//     [style release];
//     [attrString release];
// }

//APPLICATION delegate
//do other stuff like responding to notifications (resize, keys etc.)
- (void) windowDidResize: (NSNotification *) aNotification {
    id sender = [aNotification object];
    //have to reset the frame; do it in the action if necessary
     id name =[aNotification name];
     [self noteAction: sender name: name];
};

//ensure app closes when last window is closed
- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) sender {
//    [self action: sender];
//     printf("\nsender: %p\n", sender);
//    [self noteAction: sender name: @"NSApplicationWillTerminateNotification"];
    return YES;
};

//ensure app closes when quit
- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication *) sender {
//   [self action: sender];     //not really needed
    [self noteAction: sender name: @"NSApplicationWillTerminateNotification"];
    appEnd();
    return NSTerminateNow;
};

- (void) applicationWillFinishLaunching: (NSNotification *) aNotification {
    // make the window visible when the app is about to finish launching //
    [window makeKeyAndOrderFront: self];
    //do layout and cool stuff here
    id sender = [aNotification object];
    id name =[aNotification name];
    [self noteAction: sender name: name];
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification {
    // initialize your code stuff here
    id sender = [aNotification object];
    id name =[aNotification name];
    [self noteAction: sender name: name];
}

- (void) applicationWillTerminate: (NSNotification *) aNotification {
    // tear down stuff here
    id sender = [aNotification object];
    id name =[aNotification name];
    [self noteAction: sender name: name];
}

//when used as a real app and you click on an associated file, this will launch to read it
// - (BOOL) application: (NSApplication *) sender openFile: (NSString *) filename {
//     //set info in Application
//     Object *application = lookup2("Application", globalTable);
//     Object *fn = newString((char *) [filename UTF8String]);
//     application->vars = insertInTree("openFile", fn, application->vars);

// //   NSAlert* alert = [[NSAlert alloc] init];
// //   [alert setMessageText: [NSString stringWithUTF8String: "Kanban"]];
// //   [alert setInformativeText: filename];
// //
// //     NSModalResponse response = [alert runModal];

//     return YES;
// }

//pick up colour changes in colour picker (well?)
// - (void) changeColor: (id) sender {

//     [self action: sender];
// }

//TABLEVIEW delegate
//number of data rows
// - (long int) numberOfRowsInTableView: (NSTableView *) table {
//     //provide number of data rows -- from the array we used to populate the table

//     //convert table ptr to string
//     char *ptr = GC_MALLOC(40);
//     sprintf(ptr, "%p", table);

//     //get table object
//     Object *tableObject = lookup2(ptr, tableViews);
//     if (tableObject == NULL) return 0;

//     //get contents from table
//     Object *contents = lookup2("contents", tableObject->vars);
//     if (contents == NULL) return 0;

//     //get the dictionary
//     Tree *dic = contents->code->value.symtab;
//     if (dic == NULL) return 0;

//     //we need the number of items in the arrays corresponding to columns...
//     //get first column
//     char *arr = next2("", dic);
//     if (arr == NULL) return 0;

//     //get actual array...
//     Object *n = lookup2(arr, dic);
//     if (n == NULL) return 0;

//     //...and its size
//     return vectorSize(n->code->value.pointer);
// }

// - (void)tableView:(NSTableView *)aTableView setObjectValue:(id)object forTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger)rowIndex {

//     //get column ID
//     char *colId = (char *) [[aTableColumn identifier] UTF8String];

//     //get contents dictionary

//     //convert table ptr to string
//     char *ptr = GC_MALLOC(40);
//     sprintf(ptr, "%p", aTableView);

//     Object *table = lookup2(ptr, tableViews);
//     Object *contents = lookup2("contents", table->vars);

//     //get array from dict using ID
//     Object *array = lookup2(colId, contents->code->value.symtab);

//     //the object is a NSString
//     char *s = (char *) [object UTF8String];
// //    printf("Setting %p, col %s, row %ld with %s\n", ptr, colId, rowIndex, s);

//     //set item to array using rowIndex
//     Object *item = getVectorItem(array->code->value.pointer, rowIndex);

//     //and update the value with the new string
//     char *newString = GC_MALLOC(strlen(s)+1);
//     strcpy(newString, s);
//     item->code->value.string = newString;

//     return;
// };

// //provide data for each column cell
// - (id)tableView:(NSTableView *) aTableView objectValueForTableColumn: (NSTableColumn *) aTableColumn row: (NSInteger)rowIndex {

//     //get column ID
//     char *colId = (char *) [[aTableColumn identifier] UTF8String];

//     //get contents dictionary

//     //convert table ptr to string
//     char *ptr = GC_MALLOC(40);
//     sprintf(ptr, "%p", aTableView);

//     Object *table = lookup2(ptr, tableViews);
//     Object *contents = lookup2("contents", table->vars);

//     //get array from dict using ID
//     Object *array = lookup2(colId, contents->code->value.symtab);

//     //get item from array using rowIndex
//     Object *item = getVectorItem(array->code->value.pointer, rowIndex);

// //    printf("Getting %p, col %s, row %ld with %s\n", ptr, colId, rowIndex, item->code->value.string);

//     //return as NSString
//     return [NSString stringWithUTF8String: item->code->value.string];
// }

// //respond to clicks in table
// - (void) selectionDidChange: (NSNotification *) aNotification {
//      id sender = [aNotification object];
//      id name =[aNotification name];
//      [self noteAction: sender name: name];
// };

// - (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
// {
//     if(tableView == self.tableView)
//     {
//         if (row == [tableView editedRow] && [[tableView tableColumns] indexOfObject:tableColumn] == [tableView editedColumn])
//             {
//              NSLog(@"cell string value is %@",[cell stringValue]);
//             }
//     }
// }

//TEXTFIELD delegate
- (void) controlTextDidEndEditing: (NSNotification *) aNotification {
     id sender = [aNotification object];
     id name =[aNotification name];
     [self noteAction: sender name: name];
};

- (void) controlTextDidChange: (NSNotification *) aNotification {
     id sender = [aNotification object];
     id name =[aNotification name];
     [self noteAction: sender name: name];
};

- (void) controlTextDidBeginEditing: (NSNotification *) aNotification {
     id sender = [aNotification object];
     id name =[aNotification name];
     [self noteAction: sender name: name];
};

//NSOUTLINE delegate
// NSDictionary *firstParent = @{@"parent": @"Foo", @"children": @[@"Foox", @"Fooz"]};
// NSDictionary *secondParent = @{@"parent": @"Bar", @"children": @[@"Barx", @"Barz"]};
// NSArray *list = @[firstParent, secondParent];

// - (BOOL) outlineView: (NSOutlineView *) outlineView isItemExpandable: (id) item {
// //    printf("Is item expandable?\n");
// //    if ([item isKindOfClass:[NSDictionary class]]) {
//         return YES;
// //     } else {
// //         return NO;
// //     }
// }

// - (NSInteger) outlineView: (NSOutlineView *) outlineView numberOfChildrenOfItem: (id) item {
// //    printf("Number of children\n");
// //     if (item == nil) { //item is nil when the outline view wants to inquire for root level items
// //         return [list count];
// //     }
// //
// //     if ([item isKindOfClass:[NSDictionary class]]) {
// //         return [[item objectForKey:@"children"] count];
// //     }

//     return 1;
// }

// //can this be selected (optional)
// - (BOOL) outlineView: (NSOutlineView *) outlineView shouldSelectItem: (id) item {
//     printf("Should select\n");
//     return YES;
// };

// //provide value of child of item
// - (id) outlineView: (NSOutlineView *) outlineView child: (NSInteger) index ofItem: (id) item {
// //    printf("View of child\n");
// //     if (item == nil) { //item is nil when the outline view wants to inquire for root level items
// //         return [list objectAtIndex:index];
// //     }
// //
// //     if ([item isKindOfClass:[NSDictionary class]]) {
// //         return [[item objectForKey:@"children"] objectAtIndex:index];
// //     }

//     return nil;
// }

// //allow editing
// - (id) outlineView:(NSOutlineView *) outlineView setObjectValue: (id) object forTableColumn: (NSTableColumn *) theColumn byItem: (id) item {
//     return nil;
// }

// //get certain items
// - (id) outlineView: (NSOutlineView *) outlineView objectValueForTableColumn: (NSTableColumn *) theColumn byItem: (id) item {
//     printf("Object for column\n");
// //     if ([[theColumn identifier] isEqualToString:@"children"]) {
// //         if ([item isKindOfClass:[NSDictionary class]]) {
// //             return [NSString stringWithFormat:@"%i kids",[[item objectForKey:@"children"] count]];
// //         }
// //         return item;
// //     } else {
// //         if ([item isKindOfClass:[NSDictionary class]]) {
// //             return [item objectForKey:@"parent"];
// //         }
// //     }

//     return nil;
// }

// //notify that selection changed
// - (void) outlineViewSelectionDidChange: (NSNotification *) aNotification {
//     printf("Outline selection\n");
//      id sender = [aNotification object];
//      id name =[aNotification name];
//      [self noteAction: sender name: name];
// };

@end
