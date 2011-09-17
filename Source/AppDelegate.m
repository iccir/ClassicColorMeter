//
//  AppDelegate.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

#import "ColorSliderCell.h"
#import "EtchingView.h"
#import "Preferences.h"
#import "PreferencesController.h"
#import "PreviewView.h"
#import "RecessedButton.h"
#import "ResultView.h"
#import "ShortcutManager.h"
#import "SnippetsController.h"
#import "Util.h"


enum {
    CopyColorAsColor            = 0,

    CopyColorAsText             = 1,
    CopyColorAsImage            = 2,

    CopyColorAsNSColorSnippet   = 3,
    CopyColorAsUIColorSnippet   = 4,
    CopyColorAsHexColorSnippet  = 5,
    CopyColorAsRGBColorSnippet  = 6,
    CopyColorAsRGBAColorSnippet = 7
};


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

    NSTextField   *oApertureSizeLabel;
    NSTextField   *oStatusText;

    NSTextField   *oLabel1;
    NSTextField   *oLabel2;
    NSTextField   *oLabel3;

    NSTextField   *oValue1;
    NSTextField   *oValue2;
    NSTextField   *oValue3;

    NSTextField    *oHoldingLabel;
    RecessedButton *oProfileButton;
    RecessedButton *oTopHoldLabelButton;
    RecessedButton *oBottomHoldLabelButton;

    NSSlider      *oSlider1;
    NSSlider      *oSlider2;
    NSSlider      *oSlider3;

    NSView        *_layerContainer;
    CALayer       *_leftSnapshot;
    CALayer       *_middleSnapshot;
    CALayer       *_rightSnapshot;
    NSImage       *_leftHoldImage;
    NSImage       *_middleHoldImage;
    NSImage       *_rightHoldImage;
    NSImage       *_leftViewImage;
    NSImage       *_middleViewImage;
    NSImage       *_rightViewImage;

    PreferencesController *_preferencesController;
    SnippetsController    *_snippetsController;

    NSTimer          *_timer;
    NSPoint           _lastMouseLocation;
    NSTimeInterval    _lastUpdateTimeInterval;
    CGDirectDisplayID _lastDisplayID;
    CGFloat           _screenZeroHeight;

    ColorSyncTransformRef _colorSyncTransform;

    CGFloat        _lockedX;
    CGFloat        _lockedY;
    
    CGRect         _screenBounds;
    CGRect         _apertureRect;
    
    BOOL           _isHoldingColor;
    Color         *_color;
    
    // Cached prefs
    ColorMode        _colorMode;
    ColorProfileType _colorProfileType;
    NSInteger        _zoomLevel;
    NSInteger        _updatesContinuously;
    NSInteger        _showMouseCoordinates;
    BOOL             _usesLowercaseHex;
    BOOL             _usesPoundPrefix;
}

- (void) _updateStatusText;
- (void) _handlePreferencesDidChange:(NSNotification *)note;
- (void) _handleScreenColorSpaceDidChange:(NSNotification *)note;
- (NSEvent *) _handleLocalEvent:(NSEvent *)event;

- (void) _setupHoldAnimation;
- (void) _animateSnapshotsIfNeeded;

@end


@implementation AppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _color = [[Color alloc] init];

    [(ColorSliderCell *)[oSlider1 cell] setColor:_color];
    [(ColorSliderCell *)[oSlider2 cell] setColor:_color];
    [(ColorSliderCell *)[oSlider3 cell] setColor:_color];
    [oResultView setColor:_color];
    
    [oResultView setDelegate:self];

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

    [oWindow setContentBorderThickness:0.0 forEdge:NSMinYEdge];
    [oWindow setContentBorderThickness:172.0 forEdge:NSMaxYEdge];
    [oWindow setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
    [oWindow setAutorecalculatesContentBorderThickness:NO forEdge:NSMaxYEdge];

    [[oApertureSizeLabel cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [[oStatusText        cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [[oHoldingLabel      cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [[oLabel1            cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [[oLabel2            cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [[oLabel3            cell] setBackgroundStyle:NSBackgroundStyleRaised];

    [self _setupHoldAnimation];

    [self applicationDidChangeScreenParameters:nil];
    [self _updateStatusText];
    [self _handlePreferencesDidChange:nil];
    [self _handleScreenColorSpaceDidChange:nil];
    
    [oWindow makeKeyAndOrderFront:self];
}


- (void) dealloc
{
    [[ShortcutManager sharedInstance] removeListener:self];

    [_layerContainer release];
    _layerContainer = nil;

    if (_colorSyncTransform) CFRelease(_colorSyncTransform);
    _colorSyncTransform = NULL;

    [_preferencesController release];
    _preferencesController = nil;
    
    [_snippetsController release];
    _snippetsController = nil;

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

    } else if (action == @selector(showSnippets:)) {
        NSUInteger flags     = [NSEvent modifierFlags];
        NSUInteger mask      = NSControlKeyMask | NSCommandKeyMask | NSAlternateKeyMask;
        BOOL       isVisible = ((flags & mask) == mask);
         
        [menuItem setHidden:!isVisible];

    } else if (action == @selector(changeColorConversionValue:)) {
        BOOL state = ([menuItem tag] == _colorProfileType);
        [menuItem setState:state];
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

static ColorMode sGetCurrentColorMode(AppDelegate *self)
{
    if (self->_isHoldingColor) {
        Preferences *preferences = [Preferences sharedInstance];
        if ([preferences usesDifferentColorSpaceInHoldColor]) {
            return [preferences holdColorMode];
        }
    }
    
    return self->_colorMode;
}


static void sUpdateColorViews(AppDelegate *self)
{
    [self->oResultView setNeedsDisplay:YES];
    [self->oSlider1 setNeedsDisplay:YES];
    [self->oSlider2 setNeedsDisplay:YES];
    [self->oSlider3 setNeedsDisplay:YES];
}


static void sUpdateHoldLabels(AppDelegate *self)
{
    ColorMode mode      = sGetCurrentColorMode(self);
    BOOL      lowercase = self->_usesLowercaseHex;
    Color    *color     = self->_color;

    long r = lroundf([color red]   * 255);
    long g = lroundf([color green] * 255);
    long b = lroundf([color blue]  * 255);
    
    NSString *hexFormat = nil;
    if (self->_usesPoundPrefix) {
        hexFormat = lowercase ? @"#%02x%02x%02x" : @"#%02X%02X%02X";
    } else {
        hexFormat = lowercase ?  @"%02x%02x%02x" :  @"%02X%02X%02X";
    }

    NSString *hexString = [NSString stringWithFormat:hexFormat, r, g, b];
    
    if (ColorModeIsRGB(mode)) {
        long h = lroundf([color hue]        * 360);
        long s = lroundf([color saturation] * 100);
        long b = lroundf([color brightness] * 100);

        NSString *hsbString = [NSString stringWithFormat:@"%ld%C, %ld%%, %ld%%", h, 0x00b0, s, b];

        [self->oTopHoldLabelButton setTitle:hsbString];
        [self->oBottomHoldLabelButton setTitle:hexString];

    } else if (ColorModeIsHSB(mode)) {
        long r100 = lroundf([color red]   * 100);
        long g100 = lroundf([color green] * 100);
        long b100 = lroundf([color blue]  * 100);

        NSString *decimalString = [NSString stringWithFormat:@"%ld%%, %ld%%, %ld%%", r100, g100, b100];

        [self->oTopHoldLabelButton setTitle:decimalString];
        [self->oBottomHoldLabelButton setTitle:hexString];
    }
}


static void sUpdatePopUpAndComponentLabels(AppDelegate *self)
{
    ColorMode colorMode = sGetCurrentColorMode(self);
    
    [self->oColorModePopUp selectItemWithTag:colorMode];

    NSArray *labels = ColorModeGetComponentLabels(colorMode);
    if ([labels count] == 3) {
        [self->oLabel1 setStringValue:[labels objectAtIndex:0]];
        [self->oLabel2 setStringValue:[labels objectAtIndex:1]];
        [self->oLabel3 setStringValue:[labels objectAtIndex:2]];
    }
}


static void sUpdateSliders(AppDelegate *self)
{
    ColorMode colorMode = sGetCurrentColorMode(self);
    NSSlider *slider1   = self->oSlider1;
    NSSlider *slider2   = self->oSlider2;
    NSSlider *slider3   = self->oSlider3;
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
    Color    *color     = self->_color;
    ColorMode colorMode = sGetCurrentColorMode(self);

    NSString *value1 = nil;
    NSString *value2 = nil;
    NSString *value3 = nil;
    BOOL clipped1, clipped2, clipped3;
    ColorModeMakeComponentStrings(colorMode, color, self->_usesLowercaseHex, self->_usesPoundPrefix, &value1, &value2, &value3, &clipped1, &clipped2, &clipped3);

    if (value1) [self->oValue1 setStringValue:value1];
    if (value2) [self->oValue2 setStringValue:value2];
    if (value3) [self->oValue3 setStringValue:value3];
    
    static NSColor *sRedColor = nil;
    static NSColor *sBlackColor = nil;
    
    if (!sRedColor) {
        sRedColor   = [[NSColor redColor]   retain];
        sBlackColor = [[NSColor blackColor] retain];
    }

    BOOL isEditable = (ColorModeIsRGB(colorMode) || ColorModeIsHSB(colorMode)) && self->_isHoldingColor;

    [self->oValue1 setTextColor:((clipped1 && !isEditable) ? sRedColor : sBlackColor)];
    [self->oValue2 setTextColor:((clipped2 && !isEditable) ? sRedColor : sBlackColor)];
    [self->oValue3 setTextColor:((clipped3 && !isEditable) ? sRedColor : sBlackColor)];

    [self->oValue1 setEditable:isEditable];
    [self->oValue2 setEditable:isEditable];
    [self->oValue3 setEditable:isEditable];
}


static void sUpdateColorSync(AppDelegate *self)
{
    if (self->_colorSyncTransform) {
        CFRelease(self->_colorSyncTransform);
        self->_colorSyncTransform = NULL;
    }

    ColorMode mode = sGetCurrentColorMode(self);
    ColorProfileType type = self->_colorProfileType;

    ColorSyncProfileRef fromProfile   = ColorSyncProfileCreateWithDisplayID(self->_lastDisplayID);
    CFStringRef         toProfileName = NULL;
    ColorSyncProfileRef toProfile     = NULL;

    if (!fromProfile) goto cleanup;


    if (type == ColorProfileConvertToSRGB) {
        toProfileName = kColorSyncSRGBProfile;
    } else if (type == ColorProfileConvertToAdobeRGB) {
        toProfileName = kColorSyncAdobeRGB1998Profile;
    } else if (type == ColorProfileConvertToGenericRGB) {
        toProfileName = kColorSyncGenericRGBProfile;
    }
    
    if (toProfileName) {
        toProfile = ColorSyncProfileCreateWithName(toProfileName);
        if (!toProfile) goto cleanup;

        NSMutableDictionary *fromDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
            (id)fromProfile,                       (id)kColorSyncProfile,
            (id)kColorSyncRenderingIntentRelative, (id)kColorSyncRenderingIntent,
            (id)kColorSyncTransformDeviceToPCS,    (id)kColorSyncTransformTag,
            nil];

        NSMutableDictionary *toDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
            (id)toProfile,                         (id)kColorSyncProfile,
            (id)kColorSyncRenderingIntentRelative, (id)kColorSyncRenderingIntent,
            (id)kColorSyncTransformPCSToDevice,    (id)kColorSyncTransformTag,
            nil];
            
        NSArray *profileSequence = [[NSArray alloc] initWithObjects:fromDictionary, toDictionary, nil];
        
        self->_colorSyncTransform = ColorSyncTransformCreate((CFArrayRef)profileSequence, NULL);

        [profileSequence release];
        [toDictionary    release];
        [fromDictionary  release];
    }

    // Update profile name
    {
        NSString *name = [(id)ColorSyncProfileCopyDescriptionString(fromProfile) autorelease];
        if (![name length]) name = NSLocalizedString(@"Display", @"");

        NSMutableArray *profiles = [NSMutableArray array];

        [profiles addObject:name];

        if (type == ColorProfileConvertToSRGB) {
            [profiles addObject:NSLocalizedString(@"sRGB", @"")];
        } else if (type == ColorProfileConvertToGenericRGB) {
            [profiles addObject:NSLocalizedString(@"Generic RGB", @"")];
        } else if (type == ColorProfileConvertToAdobeRGB) {
            [profiles addObject:NSLocalizedString(@"Adobe RGB", @"")];
        }
        
        if (mode == ColorMode_CIE_Lab) {
            [profiles addObject:NSLocalizedString(@"Lab", @"")];
        } else if (ColorModeIsXYZ(mode)) {
            [profiles addObject:NSLocalizedString(@"XYZ", @"")];
        }

        NSString *joiner       = [NSString stringWithFormat:@" %C ", 0x279D];
        NSString *joinedString = [profiles componentsJoinedByString:joiner];
        
        [self->oProfileButton setTitle:joinedString];
    }

cleanup:
    if (fromProfile) CFRelease(fromProfile);
    if (toProfile)   CFRelease(toProfile);
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
    
    CGDirectDisplayID displayID = _lastDisplayID;
    uint32_t matchingDisplayCount;
    CGGetDisplaysWithPoint(convertedPoint, 1, &displayID, &matchingDisplayCount);

    if (_lastDisplayID != displayID) {
        _lastDisplayID = displayID;
        sUpdateColorSync(self);
    }
    
    if (!_isHoldingColor) {
        float r, g, b;
        GetAverageColor(screenShot, _apertureRect, &r, &g, &b);
        
        if (_colorSyncTransform) {
            float src[3];
            float dst[3];
            
            src[0] = r;  src[1] = g;  src[2] = b;
            
            if (ColorSyncTransformConvert(_colorSyncTransform,
                1, 1,
                &dst, kColorSync32BitFloat, 0, 12,
                &src, kColorSync32BitFloat, 0, 12,
                NULL
            )) {
                r = dst[0];  g = dst[1];  b = dst[2];
            }
        }

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

    _colorProfileType     = [preferences colorProfileType];
    _usesLowercaseHex     = [preferences usesLowercaseHex];
    _usesPoundPrefix      = [preferences usesPoundPrefix];
    _colorMode            = [preferences colorMode];
    _zoomLevel            = [preferences zoomLevel];
    _updatesContinuously  = [preferences updatesContinuously];
    _showMouseCoordinates = [preferences showMouseCoordinates];

    BOOL showsHoldLabels = [preferences showsHoldLabels];
    [oTopHoldLabelButton setHidden:!showsHoldLabels];
    [oBottomHoldLabelButton setHidden:!showsHoldLabels];

    [oApertureSizeSlider setIntegerValue:apertureSize];
    [oPreviewView setShowsLocation:[preferences showMouseCoordinates]];
    [oPreviewView setApertureSize:apertureSize];
    [oPreviewView setApertureColor:[preferences apertureColor]];

    [oResultView setClickEnabled:[preferences clickInSwatchEnabled]];
    [oResultView setDragEnabled: [preferences dragInSwatchEnabled]];

    NSMutableArray *shortcuts = [NSMutableArray array];
    if ([preferences showApplicationShortcut]) {
        [shortcuts addObject:[preferences showApplicationShortcut]];
    }
    if ([preferences holdColorShortcut]) {
        [shortcuts addObject:[preferences holdColorShortcut]];
    }
    if ([shortcuts count] || [ShortcutManager hasSharedInstance]) {
        [[ShortcutManager sharedInstance] addListener:self];
        [[ShortcutManager sharedInstance] setShortcuts:shortcuts];
    }

    if ([preferences floatWindow]) {
        [oWindow setLevel:NSFloatingWindowLevel];
    } else {
        [oWindow setLevel:NSNormalWindowLevel];
    }

    sUpdateColorSync(self);
    sUpdatePopUpAndComponentLabels(self);
    sUpdateSliders(self);
    sUpdateHoldLabels(self);

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
    
    if (_isHoldingColor) {
        [self _animateSnapshotsIfNeeded];
    }
}


- (void) _handleScreenColorSpaceDidChange:(NSNotification *)note
{
    sUpdateColorSync(self);
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
            if ([firstResponder isKindOfClass:[NSTextField class]] ||
                [firstResponder isKindOfClass:[NSTextView  class]])
            {
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


- (void) _addImage:(NSImage *)image toPasteboard:(NSPasteboard *)pboard
{
    [pboard clearContents];
    [pboard addTypes:[NSArray arrayWithObjects:NSPasteboardTypeTIFF, nil] owner:nil];
    [pboard setData:[image TIFFRepresentation] forType:NSPasteboardTypeTIFF];
}

#pragma mark -
#pragma mark Pasteboard / Dragging

- (id<NSPasteboardWriting>) _pasteboardWriterForColorAction:(NSInteger)actionTag
{
    Preferences *preferences = [Preferences sharedInstance];

    id<NSPasteboardWriting> result = nil;

    NSString *template      = nil;
    NSString *clipboardText = nil;

    if (actionTag == CopyColorAsColor) {
        result = [_color NSColor];

    } else if (actionTag == CopyColorAsText) {
        Preferences *preferences = [Preferences sharedInstance];

        ColorMode mode = _colorMode;

        if (_isHoldingColor && [preferences usesDifferentColorSpaceInHoldColor] && ![preferences usesMainColorSpaceForCopyAsText]) {
            mode = [preferences holdColorMode];
        }
        
        ColorModeMakeClipboardString(mode, _color, _usesLowercaseHex, _usesPoundPrefix, &clipboardText);

    } else if (actionTag == CopyColorAsImage) {
        NSRect   bounds = NSMakeRect(0, 0, 64.0, 64.0);
        NSImage *image = [[[NSImage alloc] initWithSize:bounds.size] autorelease];
        
        [image lockFocus];
        [[_color NSColor] set];
        NSRectFill(bounds);
        [image unlockFocus];

        result = image;

    } else if (actionTag == CopyColorAsNSColorSnippet) {
        template = [preferences nsColorSnippetTemplate];

    } else if (actionTag == CopyColorAsUIColorSnippet) {
        template = [preferences uiColorSnippetTemplate];

    } else if (actionTag == CopyColorAsHexColorSnippet) {
        template = [preferences hexColorSnippetTemplate];

    } else if (actionTag == CopyColorAsRGBColorSnippet) {
        template = [preferences rgbColorSnippetTemplate];
    
    } else if (actionTag == CopyColorAsRGBAColorSnippet) {
        template = [preferences rgbaColorSnippetTemplate];
    }

    if (template) {
        clipboardText = GetCodeSnippetForColor(_color, _usesLowercaseHex, template);
        
        if (!_usesPoundPrefix && [clipboardText hasPrefix:@"#"]) {
            clipboardText = [clipboardText substringFromIndex:1]; 
        }
    }
    
    if (clipboardText) {
        NSPasteboardItem *item = [[[NSPasteboardItem alloc] initWithPasteboardPropertyList:clipboardText ofType:NSPasteboardTypeString] autorelease];
        result = item;
    }

    return result;
}


- (NSDraggingImageComponent *) _draggingImageComponentForColor:(Color *)color action:(NSInteger)colorAction
{
    CGRect imageRect  = CGRectMake(0, 0, 48.0, 48.0);
    CGRect circleRect = CGRectInset(imageRect, 8.0, 8.0);
    
    NSImage *image = [[NSImage alloc] initWithSize:imageRect.size];
    
    [image lockFocus];
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:circleRect];

    {
        CGContextSaveGState(context);

        NSShadow *shadow = [[NSShadow alloc] init];
        
        [shadow setShadowOffset:CGSizeMake(0.0, -1.0)];
        [shadow setShadowBlurRadius:4.0];
        [shadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:1.0]];

        [shadow set];
        [[NSColor whiteColor] set];
        [path fill];

        [shadow release];
        
        CGContextRestoreGState(context);
    }

    {
        CGContextSaveGState(context);
        [path addClip];

        [[color NSColor] set];
        NSRectFill(circleRect);

        {
            NSColor *startColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.2];
            NSColor *endColor   = [NSColor colorWithCalibratedWhite:1.0 alpha:0.0];

            NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
            [gradient drawInRect:circleRect angle:-90];
            [gradient release];
        }
        
        CGContextRestoreGState(context);
    }

    [[NSColor whiteColor] set];
    [path setLineWidth:2.0];
    [path stroke];

    [image unlockFocus];
    

    NSString *key = NSDraggingImageComponentIconKey;
    NSDraggingImageComponent *component = [[[NSDraggingImageComponent alloc] initWithKey:key] autorelease];

    [component setContents:image];
    [component setFrame:imageRect];

    [image release];
    
    return component;
}


- (NSDraggingItem *) _draggingItemForColorAction:(NSInteger)colorAction cursorOffset:(NSPoint)location
{
    id<NSPasteboardWriting> pboardWriter = [self _pasteboardWriterForColorAction:colorAction];

    Color *colorCopy = [_color copy];

    NSDraggingItem *draggingItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pboardWriter];

    [draggingItem setImageComponentsProvider: ^{
        NSDraggingImageComponent *component = [self _draggingImageComponentForColor:colorCopy action:colorAction];
        
        NSRect frame = [component frame];
        frame.origin = NSMakePoint(location.x - (frame.size.width / 2.0), location.y - (frame.size.height / 2.0));
        [component setFrame:frame];

        return [NSArray arrayWithObject:component];
    }];
    
    [colorCopy release];

    return [draggingItem autorelease];
}


- (void) _writeString:(NSString *)string toPasteboard:(NSPasteboard *)pasteboard
{
    if (string) {
        NSPasteboardItem *item = [[NSPasteboardItem alloc] initWithPasteboardPropertyList:string ofType:NSPasteboardTypeString];

        [pasteboard clearContents];
        [pasteboard writeObjects:[NSArray arrayWithObject:item]];

        [item release];
    }
}


- (NSDragOperation) draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    return NSDragOperationGeneric | NSDragOperationCopy;
}


#pragma mark -
#pragma mark Animation

- (void) _setupHoldAnimation
{
    NSView *contentView = [[self window] contentView];

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

    [_leftSnapshot   setFrame:[[self leftContainer]   frame]];
    [_middleSnapshot setFrame:[[self middleContainer] frame]];
    [_rightSnapshot  setFrame:[[self rightContainer]  frame]];

    [contentView addSubview:_layerContainer];
}


#pragma mark -
#pragma mark Animation

- (void) _animateSnapshotsIfNeeded
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

        [_leftSnapshot   setContents:GetSnapshotImageForView(oLeftContainer)];
        [_middleSnapshot setContents:GetSnapshotImageForView(oMiddleContainer)];
        [_rightSnapshot  setContents:GetSnapshotImageForView(oRightContainer)];

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
#pragma mark ResultViewDelegate

- (void) resultViewClicked:(ResultView *)view
{
    Preferences *preferences = [Preferences sharedInstance];

    if ([preferences clickInSwatchEnabled]) {
        NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
        
        id<NSPasteboardWriting> pboardWriter = [self _pasteboardWriterForColorAction:[preferences clickInSwatchAction]];

        [pboard clearContents];
        [pboard writeObjects:[NSArray arrayWithObject:pboardWriter]];
        
        [oResultView doPopOutAnimation];
    }
}


- (void) resultView:(ResultView *)view dragInitiatedWithEvent:(NSEvent *)event
{
    Preferences *preferences = [Preferences sharedInstance];

    if ([preferences dragInSwatchEnabled]) {
        NSInteger action   = [preferences dragInSwatchAction];
        NSPoint   location = [event locationInWindow];

        location = [oResultView convertPoint:location fromView:nil];

        NSDraggingItem *item  = [self _draggingItemForColorAction:action cursorOffset:location];
        NSArray        *items = [NSArray arrayWithObject:item];

        [oResultView beginDraggingSessionWithItems:items event:event source:self];
    }
}


#pragma mark -
#pragma mark Shortcuts

- (BOOL) performShortcut:(Shortcut *)shortcut
{
    Preferences *preferences = [Preferences sharedInstance];
    BOOL yn = NO;

    if ([[preferences holdColorShortcut] isEqual:shortcut]) { 
        [self holdColor:self];
        yn = YES;
    }
    
    if ([[preferences showApplicationShortcut] isEqual:shortcut]) {
        [NSApp activateIgnoringOtherApps:YES];
        [oWindow makeKeyAndOrderFront:self];
        yn = YES;
    }

    return yn;
}


#pragma mark -
#pragma mark IBActions

- (IBAction) changeColorMode:(id)sender
{
    NSInteger tag = [sender selectedTag];
    
    if ([[Preferences sharedInstance] usesDifferentColorSpaceInHoldColor] && _isHoldingColor) {
        [[Preferences sharedInstance] setHoldColorMode:tag];
    } else {
        [[Preferences sharedInstance] setColorMode:tag];
    }
}


- (IBAction) changeApertureSize:(id)sender
{
    [[Preferences sharedInstance] setApertureSize:[sender integerValue]];
}


- (IBAction) updateComponent:(id)sender
{
    ColorMode mode = sGetCurrentColorMode(self);

    BOOL isRGB = ColorModeIsRGB(mode);
    BOOL isHSB = ColorModeIsHSB(mode);

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
            floatValue = ColorModeParseComponentString(mode, component, [sender stringValue]);            
        }
    
        [_color setFloatValue:floatValue forComponent:component];
    }

    sUpdateColorViews(self);
    sUpdateSliders(self);
    sUpdateHoldLabels(self);
    sUpdateTextFields(self);
}


- (IBAction) showSnippets:(id)sender
{
    if (!_snippetsController) {
        _snippetsController = [[SnippetsController alloc] init];
    }
    
    [_snippetsController showWindow:self];
}


- (IBAction) showPreferences:(id)sender
{
    if (!_preferencesController) {
        _preferencesController = [[PreferencesController alloc] init];
    }
    
    [_preferencesController showWindow:self];
}


- (IBAction) changeColorConversionValue:(id)sender
{
    NSInteger tag = [sender tag];
    [[Preferences sharedInstance] setColorProfileType:tag];
}


- (IBAction) writeTopLabelValueToPasteboard:(id)sender
{
    [self _writeString:[oTopHoldLabelButton title] toPasteboard:[NSPasteboard generalPasteboard]];
}


- (IBAction) writeBottomLabelValueToPasteboard:(id)sender
{
    [self _writeString:[oBottomHoldLabelButton title] toPasteboard:[NSPasteboard generalPasteboard]];
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
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    [self _addImage:image toPasteboard:pboard];
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

    [oHoldingLabel setHidden:!_isHoldingColor];
    [oHoldingLabel setStringValue: NSLocalizedString(@"Holding Color", @"Status text: holding color")];
    [oProfileButton setHidden:_isHoldingColor];

    // If coming from UI, we will have a sender.  Sender=nil for pasteTextAsColor:
    if (sender) {
        [self _updateScreenshot];
    }

    sUpdatePopUpAndComponentLabels(self);
    sUpdateSliders(self);
    sUpdateTextFields(self);
    sUpdateHoldLabels(self);
    
    if ([[Preferences sharedInstance] showsHoldColorSliders]) {
        [self _animateSnapshotsIfNeeded];
    }
}


- (IBAction) pasteTextAsColor:(id)sender
{
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    NSString     *string = [pboard stringForType:NSPasteboardTypeString];

    Color *parsedColor = GetColorFromParsedString(string);
    if (parsedColor) {
        [_color setRed:[parsedColor red] green:[parsedColor green] blue:[parsedColor blue]];

        sUpdateColorViews(self);
        sUpdateTextFields(self);

        if (!_isHoldingColor) {
            [self holdColor:nil];
        }
        
    } else {
        NSBeep();
    }

}


- (IBAction) performColorActionForSender:(id)sender
{
    NSInteger tag = [sender tag];
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    
    id<NSPasteboardWriting> writer = [self _pasteboardWriterForColorAction:tag];
    
    [pboard clearContents];
    [pboard writeObjects:[NSArray arrayWithObject:writer]];
}


- (IBAction) sendFeedback:(id)sender
{
    NSURL *url = [NSURL URLWithString:sFeedbackURL];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


#pragma mark -
#pragma mark Accessors

@synthesize window                = oWindow,
            leftContainer         = oLeftContainer,
            middleContainer       = oMiddleContainer,
            rightContainer        = oRightContainer,
            colorModePopUp        = oColorModePopUp,
            previewView           = oPreviewView,
            resultView            = oResultView,
            apertureSizeLabel     = oApertureSizeLabel,
            statusText            = oStatusText,
            apertureSizeSlider    = oApertureSizeSlider,
            label1                = oLabel1,
            label2                = oLabel2,
            label3                = oLabel3,
            value1                = oValue1,
            value2                = oValue2,
            value3                = oValue3,
            holdingLabel          = oHoldingLabel,
            profileButton         = oProfileButton,
            topHoldLabelButton    = oTopHoldLabelButton,
            bottomHoldLabelButton = oBottomHoldLabelButton,
            slider1               = oSlider1,
            slider2               = oSlider2,
            slider3               = oSlider3;

@end
