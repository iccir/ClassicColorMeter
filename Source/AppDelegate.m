//
//  AppDelegate.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

#import "BackgroundView.h"
#import "Util.h"
#import "EtchingView.h"
#import "Preferences.h"
#import "PreferencesController.h"
#import "PreviewView.h"
#import "ResultView.h"
#import "ColorSliderCell.h"


static NSString * const sFeedbackURL = @"http://iccir.com/feedback/ClassicColorMeter";

@class PreviewView;

@interface AppDelegate () {
    NSWindow      *oWindow;

    NSView        *oLeftContainer;
    NSView        *oMiddleContainer;
    NSView        *oRightContainer;

    PreviewView   *oPreviewView;
    NSPopUpButton *oColorModePopUp;
    NSView        *oContainer;
    ResultView    *oResultView;
    NSSlider      *oApertureSizeSlider;

    NSTextField   *oProfileField;
    NSTextField   *oStatusText;

    NSTextField   *oLabel1;
    NSTextField   *oLabel2;
    NSTextField   *oLabel3;

    NSTextField   *oValue1;
    NSTextField   *oValue2;
    NSTextField   *oValue3;

    NSSlider      *oSlider1;
    NSSlider      *oSlider2;
    NSSlider      *oSlider3;

    NSView        *_layerContainer;
    CALayer       *_leftSnapshot;
    CALayer       *_middleSnapshot;
    CALayer       *_rightSnapshot;

    PreferencesController *_preferencesController;

    NSTimer       *_timer;
    NSPoint        _lastMouseLocation;
    NSTimeInterval _lastUpdateTimeInterval;
    CGFloat        _screenZeroHeight;

    CGFloat        _lockedX;
    CGFloat        _lockedY;
    
    CGRect         _screenBounds;
    CGRect         _apertureRect;
    
    BOOL           _isHoldingColor;
    Color         *_color;
    
    // Cached prefs
    BOOL           _usesLowercaseHex;
    ColorMode      _colorMode;
    NSInteger      _zoomLevel;
    NSInteger      _updatesContinuously;
    NSInteger      _showMouseCoordinates;
}

- (void) _updateStatusText;
- (void) _handlePreferencesDidChange:(NSNotification *)note;
- (void) _handleScreenColorSpaceDidChange:(NSNotification *)note;
- (NSEvent *) _handleLocalEvent:(NSEvent *)event;

@end


@implementation AppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _color = [[Color alloc] init];

    [(ColorSliderCell *)[oSlider1 cell] setColor:_color];
    [(ColorSliderCell *)[oSlider2 cell] setColor:_color];
    [(ColorSliderCell *)[oSlider3 cell] setColor:_color];
    [oResultView setColor:_color];

    _lockedX                = NAN;
    _lockedY                = NAN;
    _lastMouseLocation      = NSMakePoint(NAN, NAN);
    _lastUpdateTimeInterval = NAN;
    _zoomLevel              = 1.0;

    _timer = [NSTimer timerWithTimeInterval:(1.0 / 30.0) target:self selector:@selector(_timerTick:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];

    void (^addEtching)(NSView *, CGFloat, CGFloat, CGFloat, CGFloat) = ^(NSView *host, CGFloat aD, CGFloat aL, CGFloat iD, CGFloat iL) {
        NSRect frame = [host frame];
        
        frame.size.height = 2.0;
        frame.origin.y   -= 1.0;
        
        EtchingView *etching = [[EtchingView alloc] initWithFrame:frame];
        [etching setActiveDarkOpacity:aD]; 
        [etching setActiveLightOpacity:aL]; 
        [etching setInactiveDarkOpacity:iD]; 
        [etching setInactiveLightOpacity:iL]; 
        
        [[host superview] addSubview:etching positioned:NSWindowAbove relativeTo:host];
        
        [etching release];
    };
    
    addEtching(oValue1,      0.10, 0.33, 0.0, 0.1);
    addEtching(oValue2,      0.12, 0.33, 0.0, 0.1);
    addEtching(oValue3,      0.15, 0.33, 0.0, 0.1);
    addEtching(oResultView,  0.0,  0.33, 0.0, 0.1);
    addEtching(oPreviewView, 0.0,  0.33, 0.0, 0.1);
    
    NSMenu *menu = [oColorModePopUp menu];
    void (^addMenu)(ColorMode) = ^(ColorMode mode) {
        NSString   *title = ColorModeGetName(mode);
        NSMenuItem *item  = [[NSMenuItem alloc] initWithTitle:title action:NULL keyEquivalent:@""];
        
        [item setTag:mode];

        [menu addItem:item];
        
        [item release];
    };

    addMenu( ColorMode_RGB_Percentage );
    addMenu( ColorMode_RGB_Value_8 );
    addMenu( ColorMode_RGB_Value_16 );
    addMenu( ColorMode_RGB_HexValue_8 );
    addMenu( ColorMode_RGB_HexValue_16 );
    [menu addItem:[NSMenuItem separatorItem]];
    addMenu( ColorMode_HSB   );
    [menu addItem:[NSMenuItem separatorItem]];
    addMenu( ColorMode_YPbPr_601   );
    addMenu( ColorMode_YPbPr_709   );
    addMenu( ColorMode_YCbCr_601   );
    addMenu( ColorMode_YCbCr_709   );
    [menu addItem:[NSMenuItem separatorItem]];
    addMenu( ColorMode_CIE_1931    );
    addMenu( ColorMode_CIE_1976    );
    addMenu( ColorMode_CIE_Lab     );
    addMenu( ColorMode_Tristimulus );
    
    [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:^(NSEvent *inEvent) {
        return [self _handleLocalEvent:inEvent];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handlePreferencesDidChange:)      name:PreferencesDidChangeNotification        object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleScreenColorSpaceDidChange:) name:NSScreenColorSpaceDidChangeNotification object:nil];
    
    NSRect frame = [oWindow frame];
    frame.size.width = 350.0;
    [oWindow setFrame:frame display:NO animate:NO];

    NSView *contentView = [oWindow contentView];
    _layerContainer = [[NSView alloc] initWithFrame:[contentView bounds]];
    [_layerContainer setWantsLayer:YES];

    _leftSnapshot   = [[CALayer alloc] init];
    _middleSnapshot = [[CALayer alloc] init];
    _rightSnapshot  = [[CALayer alloc] init];

    [_leftSnapshot   setDelegate:self];
    [_middleSnapshot setDelegate:self];
    [_rightSnapshot  setDelegate:self];

    [_leftSnapshot   setAnchorPoint:CGPointMake(0, 0)];
    [_middleSnapshot setAnchorPoint:CGPointMake(0, 0)];
    [_rightSnapshot  setAnchorPoint:CGPointMake(0, 0)];
    
    [[_layerContainer layer] addSublayer:_leftSnapshot];
    [[_layerContainer layer] addSublayer:_middleSnapshot];
    [[_layerContainer layer] addSublayer:_rightSnapshot];

    [_leftSnapshot   setFrame:[oLeftContainer   frame]];
    [_middleSnapshot setFrame:[oMiddleContainer frame]];
    [_rightSnapshot  setFrame:[oRightContainer  frame]];

    [contentView addSubview:_layerContainer];

    [self applicationDidChangeScreenParameters:nil];
    [self _updateStatusText];
    [self _handlePreferencesDidChange:nil];
    [self _handleScreenColorSpaceDidChange:nil];
    
    [oWindow makeKeyAndOrderFront:self];
}


- (void) dealloc
{
    [_preferencesController release];
    _preferencesController = nil;

    [_layerContainer release];
    _layerContainer = nil;

    [_timer release];
    _timer = nil;

    [super dealloc];
}


- (void) applicationWillTerminate:(NSNotification *)notification
{
    [_timer invalidate];
    _timer = nil;
}


- (void) applicationDidChangeScreenParameters:(NSNotification *)notification
{
    NSArray  *screensArray = [NSScreen screens];
    NSScreen *screenZero   = [screensArray count] ? [screensArray objectAtIndex:0] : nil;

    _screenZeroHeight = screenZero ? [screenZero frame].size.height : 0.0;
}


- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
    SEL action = [menuItem action];

    if (action == @selector(lockPosition:)) {
        [menuItem setState:!isnan(_lockedX) && !isnan(_lockedY)];
    
    } else if (action == @selector(lockX:)) {
        [menuItem setState:!isnan(_lockedX)];

    } else if (action == @selector(lockY:)) {
        [menuItem setState:!isnan(_lockedY)];
        
    } else if (action == @selector(updateMagnification:)) {
        [menuItem setState:([menuItem tag] == _zoomLevel)];

    } else if (action == @selector(toggleContinuous:)) {
        [menuItem setState:_updatesContinuously];

    } else if (action == @selector(toggleMouseLocation:)) {
        [menuItem setState:_showMouseCoordinates];

    } else if (action == @selector(holdColor:)) {
        [menuItem setState:_isHoldingColor];

    } else if (action == @selector(toggleFloatWindow:)) {
        [menuItem setState:[[Preferences sharedInstance] floatWindow]];
    }

    return YES;
}


- (void) cancel:(id)sender
{
    if ([oWindow firstResponder] != oWindow) {
        [oWindow makeFirstResponder:oWindow];
    }
}


- (void) windowWillClose:(NSNotification *)note
{
    if ([note object] == oWindow) {
        [NSApp terminate:self];
    }
}


#pragma mark -
#pragma mark Glue

static void sUpdateSnapshots(AppDelegate *self)
{
    void (^updateSnapshot)(NSView *, CALayer *) = ^(NSView *view, CALayer *layer) {
        NSRect   bounds = [view bounds];
        NSImage *image  = [[NSImage alloc] initWithSize:bounds.size];

        [image lockFocus];
        [view displayRectIgnoringOpacity:[view bounds] inContext:[NSGraphicsContext currentContext]];
        [image unlockFocus];
        [layer setContents:image];

        [image release];
    };

    updateSnapshot(self->oLeftContainer,   self->_leftSnapshot);
    updateSnapshot(self->oMiddleContainer, self->_middleSnapshot);
    updateSnapshot(self->oRightContainer,  self->_rightSnapshot);
}


static void sUpdateColorViews(AppDelegate *self)
{
    [self->oResultView setNeedsDisplay:YES];
    [self->oSlider1 setNeedsDisplay:YES];
    [self->oSlider2 setNeedsDisplay:YES];
    [self->oSlider3 setNeedsDisplay:YES];
}


static void sUpdateSliders(AppDelegate *self)
{
    NSSlider *slider1   = self->oSlider1;
    NSSlider *slider2   = self->oSlider2;
    NSSlider *slider3   = self->oSlider3;
    ColorMode colorMode = self->_colorMode;
    Color    *color     = self->_color;

    BOOL      isRGB     = ColorModeIsRGB(colorMode);
    BOOL      isHSB     = ColorModeIsHSB(colorMode);

    BOOL      isEnabled = NO;

    ColorComponent component1 = ColorComponentNone;
    ColorComponent component2 = ColorComponentNone;
    ColorComponent component3 = ColorComponentNone;

    if (isRGB) {
        isEnabled = YES;

        component1 = ColorComponentRed;
        component2 = ColorComponentGreen;
        component3 = ColorComponentBlue;

    } else if (isHSB) {
        isEnabled = YES;

        component1 = ColorComponentHue;
        component2 = ColorComponentSaturation;
        component3 = ColorComponentBrightness;
    }
    
    ColorSliderCell *cell1 = (ColorSliderCell *)[slider1 cell];
    ColorSliderCell *cell2 = (ColorSliderCell *)[slider2 cell];
    ColorSliderCell *cell3 = (ColorSliderCell *)[slider3 cell];

    [slider1 setEnabled:isEnabled];
    [slider2 setEnabled:isEnabled];
    [slider3 setEnabled:isEnabled];
    
    [slider1 setFloatValue:[color floatValueForComponent:component1]];
    [slider2 setFloatValue:[color floatValueForComponent:component2]];
    [slider3 setFloatValue:[color floatValueForComponent:component3]];

    [cell1 setComponent:component1];
    [cell2 setComponent:component2];
    [cell3 setComponent:component3];
}


static void sUpdateTextFields(AppDelegate *self)
{
    ColorMode colorMode = self->_colorMode;

    NSString *value1    = nil;
    NSString *value2    = nil;
    NSString *value3    = nil;
    NSString *clipboard = nil;
    ColorModeMakeComponentStrings(colorMode, self->_color, self->_usesLowercaseHex, &value1, &value2, &value3, &clipboard);

    if (value1) [self->oValue1 setStringValue:value1];
    if (value2) [self->oValue2 setStringValue:value2];
    if (value3) [self->oValue3 setStringValue:value3];
    
    BOOL isEditable = ColorModeIsRGB(colorMode) || ColorModeIsHSB(colorMode);
    [self->oValue1 setEditable:isEditable];
    [self->oValue2 setEditable:isEditable];
    [self->oValue3 setEditable:isEditable];
}


#pragma mark -
#pragma mark Private Methods

- (void) _updateScreenshot
{
    CGPoint locationToUse = _lastMouseLocation;
    
    if (!isnan(_lockedX)) locationToUse.x = _lockedX;
    if (!isnan(_lockedY)) locationToUse.y = _lockedY;

    CGPoint convertedPoint = CGPointMake(locationToUse.x, _screenZeroHeight - locationToUse.y);

    CGRect screenBounds = _screenBounds;
    screenBounds.origin.x += convertedPoint.x;
    screenBounds.origin.y += convertedPoint.y;
    CGImageRef screenShot = CGWindowListCreateImage(screenBounds, kCGWindowListOptionAll, kCGNullWindowID, kCGWindowImageDefault);
    
    if (!_isHoldingColor) {
        float r, g, b;
        GetAverageColor(screenShot, _apertureRect, &r, &g, &b);
        [_color setRed:r green:g blue:b];

        sUpdateColorViews(self);
        sUpdateTextFields(self);
    }

    if (screenShot) {
        [oPreviewView setImage:screenShot];
        CFRelease(screenShot);
    }
    
    if (_showMouseCoordinates) {
        [oPreviewView setMouseLocation:convertedPoint];
    }
    
    [oPreviewView setZoomLevel:_zoomLevel];
}


- (void) _timerTick:(NSTimer *)timer
{
    NSPoint mouseLocation = [NSEvent mouseLocation];
    NSTimeInterval now    = [NSDate timeIntervalSinceReferenceDate];
    BOOL didMouseMove     = (_lastMouseLocation.x != mouseLocation.x) || (_lastMouseLocation.y != mouseLocation.y);
    BOOL needsUpdateTick  = (now - _lastUpdateTimeInterval) > 0.5;

    if (didMouseMove) {
        _lastMouseLocation = mouseLocation;
    }
    
    if (_updatesContinuously || didMouseMove || needsUpdateTick) {
        [self _updateScreenshot];
        _lastUpdateTimeInterval = now;
    }
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    Preferences *preferences  = [Preferences sharedInstance];
    NSInteger    apertureSize = [preferences apertureSize];

    _usesLowercaseHex     = [preferences usesLowercaseHex];
    _colorMode            = [preferences colorMode];
    _zoomLevel            = [preferences zoomLevel];
    _updatesContinuously  = [preferences updatesContinuously];
    _showMouseCoordinates = [preferences showMouseCoordinates];

    [oApertureSizeSlider setIntegerValue:apertureSize];
    [oColorModePopUp selectItemWithTag:[preferences colorMode]];
    [oPreviewView setShowsLocation:[preferences showMouseCoordinates]];
    [oPreviewView setApertureSize:apertureSize];
    [oPreviewView setApertureColor:[preferences apertureColor]];

    if ([preferences floatWindow]) {
        [oWindow setLevel:NSFloatingWindowLevel];
    } else {
        [oWindow setLevel:NSNormalWindowLevel];
    }

    NSArray *labels = ColorModeGetComponentLabels(_colorMode);
    if ([labels count] == 3) {
        [oLabel1 setStringValue:[labels objectAtIndex:0]];
        [oLabel2 setStringValue:[labels objectAtIndex:1]];
        [oLabel3 setStringValue:[labels objectAtIndex:2]];
    }

    sUpdateSliders(self);

    if (_zoomLevel < 1) {
        _zoomLevel = 1;
    }
    
    {
        CGFloat pixelsToCapture = 120.0 / _zoomLevel;
        CGFloat captureOffset   = floor(pixelsToCapture / 2.0);

        CGFloat pixelsToAverage = ((apertureSize * 2) + 1) * (8.0 / _zoomLevel);
        CGFloat averageOffset   = floor((pixelsToCapture - pixelsToAverage) / 2.0);

        _screenBounds = CGRectMake(-captureOffset, -captureOffset, pixelsToCapture, pixelsToCapture);
        _apertureRect = CGRectMake( averageOffset,  averageOffset, pixelsToAverage, pixelsToAverage);
    }

    sUpdateTextFields(self);
    
    [self _updateScreenshot];
}


- (void) _handleScreenColorSpaceDidChange:(NSNotification *)note
{

    NSScreen *mainScreen = [NSScreen mainScreen];
    NSString *name       = [[mainScreen colorSpace] localizedName];
    
    [oProfileField setStringValue:(name ? name : @"")];
}


- (void) _updateStatusText
{
    NSMutableArray *status = [[NSMutableArray alloc] init];

    if (!isnan(_lockedX) && !isnan(_lockedY)) {
        [status addObject: NSLocalizedString(@"Locked Position", @"Status text: locked position")];
    } else if (!isnan(_lockedX)) {
        [status addObject: NSLocalizedString(@"Locked X", @"Status text: locked x")];
    } else if (!isnan(_lockedY)) {
        [status addObject: NSLocalizedString(@"Locked Y", @"Status text: locked y")];
    }

    if (_isHoldingColor) {
        [status addObject: NSLocalizedString(@"Holding Color", @"Status text: holding color")];
    }

    [oStatusText setStringValue:[status componentsJoinedByString:@", "]];

    [status release];
}


- (NSImage *) _imageFromPreviewView
{
    NSSize   size  = [oPreviewView bounds].size;
    NSImage *image = [[NSImage alloc] initWithSize:size];
    
    [image lockFocus];
    [oPreviewView drawRect:[oPreviewView bounds]];
    [image unlockFocus];
    
    return [image autorelease];
}


- (NSEvent *) _handleLocalEvent:(NSEvent *)event
{
    if (![oWindow isKeyWindow]) {
        return event;
    }

    NSEventType type = [event type];

    if (type == NSKeyDown) {
        NSUInteger modifierFlags = [event modifierFlags];
        NSUInteger modifierMask  = (NSCommandKeyMask | NSAlternateKeyMask | NSControlKeyMask);

        if ((modifierFlags & modifierMask) == 0) {
            id        firstResponder = [oWindow firstResponder];
            NSString *characters     = [event charactersIgnoringModifiers];
            unichar   c              = [characters length] ? [characters characterAtIndex:0] : 0; 
            BOOL      isShift        = (modifierFlags & NSShiftKeyMask) > 0;
            BOOL      isLeftOrRight  = (c == NSLeftArrowFunctionKey) || (c == NSRightArrowFunctionKey);
            BOOL      isUpOrDown     = (c == NSUpArrowFunctionKey)   || (c == NSDownArrowFunctionKey);
            BOOL      isArrowKey     = isLeftOrRight || isUpOrDown;

            // Text fields get all events
            if ([firstResponder isKindOfClass:[NSTextField class]]) {
                return event;

            // Pop-up menus that are first responder get up/down events
            } else if ([firstResponder isKindOfClass:[NSPopUpButton class]] && isUpOrDown) {
                return event;

            // Sliders that are first responder get left/right events
            } else if ([firstResponder isKindOfClass:[NSSlider class]] && isLeftOrRight) {
                return event;
            }

            if (isArrowKey && [[Preferences sharedInstance] arrowKeysEnabled]) {
                if (firstResponder != oWindow) {
                    [oWindow makeFirstResponder:oWindow];
                }

                CGFloat xDelta = 0.0;
                CGFloat yDelta = 0.0;

                if (c == NSUpArrowFunctionKey) {
                    yDelta =  1.0;
                } else if (c == NSDownArrowFunctionKey) {
                    yDelta = -1.0;
                } else if (c == NSLeftArrowFunctionKey) {
                    xDelta = -1.0;
                } else if (c == NSRightArrowFunctionKey) {
                    xDelta =  1.0;
                }
                
                if (isShift) {
                    xDelta *= 10.0;
                    yDelta *= 10.0;
                }

                CGPoint location = [NSEvent mouseLocation];
                CGPoint convertedPoint = CGPointMake(location.x + xDelta, _screenZeroHeight - (location.y + yDelta));

                CGWarpMouseCursorPosition(convertedPoint);

                return nil;
            }
        }
    }

    return event;
}


- (void) _copyImageToClipboard:(NSImage *)image
{
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];

    [pboard clearContents];
    [pboard addTypes:[NSArray arrayWithObjects:NSPasteboardTypeTIFF, nil] owner:nil];
    [pboard setData:[image TIFFRepresentation] forType:NSPasteboardTypeTIFF];
}


- (void) _copyTextToClipboard:(NSString *)text
{
    if (!text) return;

    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    [pboard clearContents];
    [pboard addTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:nil];
    [pboard setString:text forType:NSPasteboardTypeString];
}


#pragma mark -
#pragma mark Animation

- (void) _doHoldColorAnimation
{
    void (^setSnapshotsHidden)(BOOL) = ^(BOOL yn) {
        [oLeftContainer   setHidden:!yn];
        [oMiddleContainer setHidden:!yn];
        [oRightContainer  setHidden:!yn];
        [_layerContainer  setHidden: yn];
    };
    
    void (^layout)(NSView *, CALayer *, CGFloat *) = ^(NSView *view, CALayer *layer, CGFloat *inOutX) {
        CGRect frame = [view frame];
        frame.origin.x = *inOutX;

        [view  setFrame:frame];
        [layer setFrame:frame];

        *inOutX = NSMaxX(frame);
    };
    
    BOOL showSliders = _isHoldingColor && [[Preferences sharedInstance] showsHoldColorSliders];
    CGFloat xOffset  = showSliders ? -128.0 : 0.0;

    NSDisableScreenUpdates();
    {
        setSnapshotsHidden(NO);

        [CATransaction setAnimationDuration:0.3];
        [CATransaction setCompletionBlock:^{
            NSDisableScreenUpdates();

            setSnapshotsHidden(YES);
            [oWindow displayIfNeeded];

            NSEnableScreenUpdates();
        }];

        sUpdateSnapshots(self);

        layout(oLeftContainer,   _leftSnapshot,   &xOffset);
        layout(oMiddleContainer, _middleSnapshot, &xOffset);
        layout(oRightContainer,  _rightSnapshot,  &xOffset);

        [_leftSnapshot  setOpacity:showSliders ? 0.0 : 1.0];
        [_rightSnapshot setOpacity:showSliders ? 1.0 : 0.0];

        [oWindow displayIfNeeded];
    }
    NSEnableScreenUpdates();
}


- (id<CAAction>) actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    if (_isHoldingColor && [event isEqualToString:@"contents"]) {
        return (id<CAAction>)[NSNull null];
    }
    
    return nil;
}


#pragma mark -
#pragma mark IBActions

- (IBAction) changeColorMode:(id)sender
{
    NSInteger tag = [sender selectedTag];
    [[Preferences sharedInstance] setColorMode:tag];
}


- (IBAction) changeApertureSize:(id)sender
{
    [[Preferences sharedInstance] setApertureSize:[sender integerValue]];
}


- (IBAction) updateComponent:(id)sender
{
    BOOL  isRGB  = ColorModeIsRGB(_colorMode);
    BOOL  isHSB  = ColorModeIsHSB(_colorMode);

    ColorComponent component = ColorComponentNone;

    if (isRGB || isHSB) {
        if (sender == oSlider1 || sender == oValue1) {
            component = isRGB ? ColorComponentRed :ColorComponentHue;
        } else if (sender == oSlider2 || sender == oValue2) {
            component = isRGB ? ColorComponentGreen : ColorComponentSaturation;
        } else if (sender == oSlider3 || sender == oValue3) {
            component = isRGB ? ColorComponentBlue  : ColorComponentBrightness;
        }
    }
    
    if (component != ColorComponentNone) {
        float floatValue = [sender floatValue];

        if ([sender isKindOfClass:[NSTextField class]]) {
            floatValue = ColorModeParseComponentString(_colorMode, component, [sender stringValue]);            
        }
    
        [_color setFloatValue:floatValue forComponent:component];
    }

    sUpdateColorViews(self);
    sUpdateSliders(self);
    sUpdateTextFields(self);
}


- (IBAction) showPreferences:(id)sender
{
    if (!_preferencesController) {
        _preferencesController = [[PreferencesController alloc] init];
    }
    
    [_preferencesController showWindow:self];
}


- (IBAction) lockPosition:(id)sender
{
    if (isnan(_lockedX) || isnan(_lockedY)) {
        CGPoint mouseLocation = [NSEvent mouseLocation];
        _lockedX = mouseLocation.x;
        _lockedY = mouseLocation.y;

    } else {
        _lockedX = NAN;
        _lockedY = NAN;
    }
    
    [self _updateStatusText];
    [self _updateScreenshot];
}


- (IBAction) lockX:(id)sender
{
    if (isnan(_lockedX)) {
        _lockedX = [NSEvent mouseLocation].x;
    } else {
        _lockedX = NAN;
    }

    [self _updateStatusText];
    [self _updateScreenshot];
}


- (IBAction) lockY:(id)sender
{
    if (isnan(_lockedY)) {
        _lockedY = [NSEvent mouseLocation].y;
    } else {
        _lockedY = NAN;
    }

    [self _updateStatusText];
    [self _updateScreenshot];
}


- (IBAction) updateMagnification:(id)sender
{
    NSInteger tag = [sender tag];
    [[Preferences sharedInstance] setZoomLevel:[sender tag]];
    _zoomLevel = tag;

    [self _updateScreenshot];
}


- (IBAction) toggleContinuous:(id)sender
{
    Preferences *preferences = [Preferences sharedInstance];
    BOOL updatesContinuously = ![preferences updatesContinuously];
    [preferences setUpdatesContinuously:updatesContinuously];
}


- (IBAction) toggleMouseLocation:(id)sender
{
    Preferences *preferences = [Preferences sharedInstance];
    BOOL showMouseCoordinates = ![preferences showMouseCoordinates];
    [preferences setShowMouseCoordinates:showMouseCoordinates];
}


- (IBAction) toggleFloatWindow:(id)sender
{
    Preferences *preferences = [Preferences sharedInstance];
    BOOL floatWindow = ![preferences floatWindow];
    [preferences setFloatWindow:floatWindow];
}


- (IBAction) copyImage:(id)sender
{
    NSImage *image = [self _imageFromPreviewView];
    [self _copyImageToClipboard:image];
}


- (IBAction) saveImage:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    NSImage     *image     = [self _imageFromPreviewView];
    
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:(id)kUTTypeTIFF]];
    
    [savePanel beginSheetModalForWindow:oWindow completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [[image TIFFRepresentation] writeToURL:[savePanel URL] atomically:YES];
        }
    }];
}


- (IBAction) holdColor:(id)sender
{
    _isHoldingColor = !_isHoldingColor;

    [self _updateStatusText];
    [self _updateScreenshot];

    sUpdateSliders(self);
    
    if ([[Preferences sharedInstance] showsHoldColorSliders]) {
        [self _doHoldColorAnimation];
    }
}


- (IBAction) copyColorAsText:(id)sender
{
    NSString *unused1, *unused2, *unused3;
    NSString *clipboard = nil;

    ColorModeMakeComponentStrings(_colorMode, _color, _usesLowercaseHex, &unused1, &unused2, &unused3, &clipboard);

    [self _copyTextToClipboard:clipboard];
}


- (IBAction) copyColorAsImage:(id)sender
{
    NSRect   bounds = NSMakeRect(0, 0, 64.0, 64.0);
    NSImage *image = [[NSImage alloc] initWithSize:bounds.size];
    
    [image lockFocus];
    [[NSColor colorWithDeviceRed:_color.red green:_color.green blue:_color.blue alpha:1.0] set];
    NSRectFill(bounds);
    [image unlockFocus];

    [self _copyImageToClipboard:image];

    [image release];
}


- (IBAction) copyColorAsCodeSnippet:(id)sender
{
    NSInteger tag = [sender tag];
    Preferences *preferences = [Preferences sharedInstance];
    
    NSString *template = nil;
    
    if (tag == 0) {
        template = [preferences nsColorSnippetTemplate];
    } else if (tag == 1) {
        template = [preferences uiColorSnippetTemplate];
    } else if (tag == 2) {
        template = [preferences hexColorSnippetTemplate];
    } else if (tag == 3) {
        template = [preferences rgbColorSnippetTemplate];
    } else if (tag == 4) {
        template = [preferences rgbaColorSnippetTemplate];
    }

    if (template) {
        NSString *snippet  = GetCodeSnippetForColor(_color, _usesLowercaseHex, template);
        [self _copyTextToClipboard:snippet];
    } else {
        NSBeep();
    }
}


- (IBAction) sendFeedback:(id)sender
{
    NSURL *url = [NSURL URLWithString:sFeedbackURL];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


#pragma mark -
#pragma mark Accessors

@synthesize window             = oWindow,
            leftContainer      = oLeftContainer,
            middleContainer    = oMiddleContainer,
            rightContainer     = oRightContainer,
            colorModePopUp     = oColorModePopUp,
            previewView        = oPreviewView,
            resultView         = oResultView,
            profileField       = oProfileField,
            statusText         = oStatusText,
            apertureSizeSlider = oApertureSizeSlider,
            label1             = oLabel1,
            label2             = oLabel2,
            label3             = oLabel3,
            value1             = oValue1,
            value2             = oValue2,
            value3             = oValue3,
            slider1            = oSlider1,
            slider2            = oSlider2,
            slider3            = oSlider3;

@end
