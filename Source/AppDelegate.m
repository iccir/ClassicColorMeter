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
    NSWindow       *o_window;

    NSView         *o_leftContainer;
    NSView         *o_middleContainer;
    NSView         *o_rightContainer;

    PreviewView    *o_previewView;
    NSPopUpButton  *o_colorModePopUp;
    NSView         *o_container;
    ResultView     *o_resultView;
    NSSlider       *o_apertureSizeSlider;

    NSTextField    *o_apertureSizeLabel;
    NSTextField    *o_statusText;

    NSTextField    *o_label1;
    NSTextField    *o_label2;
    NSTextField    *o_label3;

    NSTextField    *o_value1;
    NSTextField    *o_value2;
    NSTextField    *o_value3;

    NSTextField    *o_holdingLabel;
    RecessedButton *o_profileButton;
    RecessedButton *o_topHoldLabelButton;
    RecessedButton *o_bottomHoldLabelButton;

    NSSlider       *o_slider1;
    NSSlider       *o_slider2;
    NSSlider       *o_slider3;

    NSView         *m_layerContainer;
    CALayer        *m_leftSnapshot;
    CALayer        *m_middleSnapshot;
    CALayer        *m_rightSnapshot;
    NSImage        *m_leftHoldImage;
    NSImage        *m_middleHoldImage;
    NSImage        *m_rightHoldImage;
    NSImage        *m_leftViewImage;
    NSImage        *m_middleViewImage;
    NSImage        *m_rightViewImage;

    PreferencesController *m_preferencesController;
    SnippetsController    *m_snippetsController;

    NSTimer          *m_timer;
    NSPoint           m_lastMouseLocation;
    NSTimeInterval    m_lastUpdateTimeInterval;
    CGDirectDisplayID m_lastDisplayID;
    CGFloat           m_screenZeroHeight;

    ColorSyncTransformRef m_colorSyncTransform;

    CGFloat        m_lockedX;
    CGFloat        m_lockedY;
    
    CGRect         m_screenBounds;
    CGRect         m_apertureRect;
    
    BOOL           m_isHoldingColor;
    Color         *m_color;
    
    // Cached prefs
    ColorMode        m_colorMode;
    ColorProfileType m_colorProfileType;
    NSInteger        m_zoomLevel;
    NSInteger        m_updatesContinuously;
    NSInteger        m_showMouseCoordinates;
    BOOL             m_usesLowercaseHex;
    BOOL             m_usesPoundPrefix;
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
    m_color = [[Color alloc] init];

    [(ColorSliderCell *)[o_slider1 cell] setColor:m_color];
    [(ColorSliderCell *)[o_slider2 cell] setColor:m_color];
    [(ColorSliderCell *)[o_slider3 cell] setColor:m_color];
    [o_resultView setColor:m_color];
    
    [o_resultView setDelegate:self];

    m_lockedX                = NAN;
    m_lockedY                = NAN;
    m_lastMouseLocation      = NSMakePoint(NAN, NAN);
    m_lastUpdateTimeInterval = NAN;
    m_zoomLevel              = 1.0;

    m_timer = [NSTimer timerWithTimeInterval:(1.0 / 30.0) target:self selector:@selector(_timerTick:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:m_timer forMode:NSRunLoopCommonModes];

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
    
    addEtching(o_value1,      0.10, 0.33, 0.0, 0.1);
    addEtching(o_value2,      0.12, 0.33, 0.0, 0.1);
    addEtching(o_value3,      0.15, 0.33, 0.0, 0.1);
    addEtching(o_resultView,  0.0,  0.33, 0.0, 0.1);
    addEtching(o_previewView, 0.0,  0.33, 0.0, 0.1);
    
    NSMenu *menu = [o_colorModePopUp menu];
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
    addMenu( ColorMode_HSL   );
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
    
    NSRect frame = [o_window frame];
    frame.size.width = 350.0;
    [o_window setFrame:frame display:NO animate:NO];

    [o_window setContentBorderThickness:0.0 forEdge:NSMinYEdge];
    [o_window setContentBorderThickness:172.0 forEdge:NSMaxYEdge];
    [o_window setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
    [o_window setAutorecalculatesContentBorderThickness:NO forEdge:NSMaxYEdge];

    [[o_apertureSizeLabel cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [[o_statusText        cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [[o_holdingLabel      cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [[o_label1            cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [[o_label2            cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [[o_label3            cell] setBackgroundStyle:NSBackgroundStyleRaised];

    [self _setupHoldAnimation];

    [self applicationDidChangeScreenParameters:nil];
    [self _updateStatusText];
    [self _handlePreferencesDidChange:nil];
    [self _handleScreenColorSpaceDidChange:nil];
    
    [o_window makeKeyAndOrderFront:self];
}


- (void) dealloc
{
    [[ShortcutManager sharedInstance] removeListener:self];

    [m_layerContainer release];
    m_layerContainer = nil;

    if (m_colorSyncTransform) CFRelease(m_colorSyncTransform);
    m_colorSyncTransform = NULL;

    [m_preferencesController release];
    m_preferencesController = nil;
    
    [m_snippetsController release];
    m_snippetsController = nil;

    [m_timer release];
    m_timer = nil;

    [super dealloc];
}


- (void) applicationWillTerminate:(NSNotification *)notification
{
    [m_timer invalidate];
    m_timer = nil;
}


- (void) applicationDidChangeScreenParameters:(NSNotification *)notification
{
    NSArray  *screensArray = [NSScreen screens];
    NSScreen *screenZero   = [screensArray count] ? [screensArray objectAtIndex:0] : nil;

    m_screenZeroHeight = screenZero ? [screenZero frame].size.height : 0.0;
}


- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
    SEL action = [menuItem action];

    if (action == @selector(lockPosition:)) {
        [menuItem setState:!isnan(m_lockedX) && !isnan(m_lockedY)];
    
    } else if (action == @selector(lockX:)) {
        [menuItem setState:!isnan(m_lockedX)];

    } else if (action == @selector(lockY:)) {
        [menuItem setState:!isnan(m_lockedY)];
        
    } else if (action == @selector(updateMagnification:)) {
        [menuItem setState:([menuItem tag] == m_zoomLevel)];

    } else if (action == @selector(toggleContinuous:)) {
        [menuItem setState:m_updatesContinuously];

    } else if (action == @selector(toggleMouseLocation:)) {
        [menuItem setState:m_showMouseCoordinates];

    } else if (action == @selector(holdColor:)) {
        [menuItem setState:m_isHoldingColor];

    } else if (action == @selector(toggleFloatWindow:)) {
        [menuItem setState:[[Preferences sharedInstance] floatWindow]];

    } else if (action == @selector(showSnippets:)) {
        NSUInteger flags     = [NSEvent modifierFlags];
        NSUInteger mask      = NSControlKeyMask | NSCommandKeyMask | NSAlternateKeyMask;
        BOOL       isVisible = ((flags & mask) == mask);
         
        [menuItem setHidden:!isVisible];

    } else if (action == @selector(changeColorConversionValue:)) {
        BOOL state = ([menuItem tag] == m_colorProfileType);
        [menuItem setState:state];
    }

    return YES;
}


- (void) cancel:(id)sender
{
    if ([o_window firstResponder] != o_window) {
        [o_window makeFirstResponder:o_window];
    }
}


- (void) windowWillClose:(NSNotification *)note
{
    if ([note object] == o_window) {
        [NSApp terminate:self];
    }
}


#pragma mark -
#pragma mark Glue

static ColorMode sGetCurrentColorMode(AppDelegate *self)
{
    if (self->m_isHoldingColor) {
        Preferences *preferences = [Preferences sharedInstance];
        if ([preferences usesDifferentColorSpaceInHoldColor]) {
            return [preferences holdColorMode];
        }
    }
    
    return self->m_colorMode;
}


static void sUpdateColorViews(AppDelegate *self)
{
    [self->o_resultView setNeedsDisplay:YES];
    [self->o_slider1 setNeedsDisplay:YES];
    [self->o_slider2 setNeedsDisplay:YES];
    [self->o_slider3 setNeedsDisplay:YES];
}


static void sUpdateHoldLabels(AppDelegate *self)
{
    ColorMode mode      = sGetCurrentColorMode(self);
    BOOL      lowercase = self->m_usesLowercaseHex;
    Color    *color     = self->m_color;

    long r = lroundf([color red]   * 255);
    long g = lroundf([color green] * 255);
    long b = lroundf([color blue]  * 255);

    if      (r > 255) r = 255;
    else if (r <   0) r = 0;
    if      (g > 255) g = 255;
    else if (g <   0) g = 0;
    if      (b > 255) b = 255;
    else if (b <   0) b = 0;
    
    NSString *hexFormat = nil;
    if (self->m_usesPoundPrefix) {
        hexFormat = lowercase ? @"#%02x%02x%02x" : @"#%02X%02X%02X";
    } else {
        hexFormat = lowercase ?  @"%02x%02x%02x" :  @"%02X%02X%02X";
    }

    NSString *hexString = [NSString stringWithFormat:hexFormat, r, g, b];
    
    if (ColorModeIsRGB(mode)) {
        float f1, f2, f3;
        [color getHue:&f1 saturation:&f2 brightness:&f3];
    
        long h = lroundf(f1 * 360);
        long s = lroundf(f2 * 100);
        long b = lroundf(f3 * 100);

        while   (h > 360) h -= 360;
        while   (h < 360) h += 360;
        if      (s > 100) s = 100;
        else if (s < 0)   s = 0;
        if      (b > 100) b = 100;
        else if (b < 0)   b = 0;

        NSString *hsbString = [NSString stringWithFormat:@"%ld%C, %ld%%, %ld%%", h, 0x00b0, s, b];

        [self->o_topHoldLabelButton setTitle:hsbString];
        [self->o_bottomHoldLabelButton setTitle:hexString];

    } else if (ColorModeIsHue(mode)) {
        long r100 = lroundf([color red]   * 100);
        long g100 = lroundf([color green] * 100);
        long b100 = lroundf([color blue]  * 100);

        if      (r100 > 100) r100 = 100;
        else if (r100 <   0) r100 = 0;
        if      (g100 > 100) g100 = 100;
        else if (g100 <   0) g100 = 0;
        if      (b100 > 100) b100 = 100;
        else if (b100 <   0) b100 = 0;

        NSString *decimalString = [NSString stringWithFormat:@"%ld%%, %ld%%, %ld%%", r100, g100, b100];

        [self->o_topHoldLabelButton setTitle:decimalString];
        [self->o_bottomHoldLabelButton setTitle:hexString];
    }
}


static void sUpdatePopUpAndComponentLabels(AppDelegate *self)
{
    ColorMode colorMode = sGetCurrentColorMode(self);
    
    [self->o_colorModePopUp selectItemWithTag:colorMode];

    NSArray *labels = ColorModeGetComponentLabels(colorMode);
    if ([labels count] == 3) {
        [self->o_label1 setStringValue:[labels objectAtIndex:0]];
        [self->o_label2 setStringValue:[labels objectAtIndex:1]];
        [self->o_label3 setStringValue:[labels objectAtIndex:2]];
    }
}


static void sUpdateSliders(AppDelegate *self)
{
    ColorMode colorMode = sGetCurrentColorMode(self);
    NSSlider *slider1   = self->o_slider1;
    NSSlider *slider2   = self->o_slider2;
    NSSlider *slider3   = self->o_slider3;
    Color    *color     = self->m_color;

    BOOL      isRGB     = ColorModeIsRGB(colorMode);
    BOOL      isHue     = ColorModeIsHue(colorMode);
    BOOL      isEnabled = isRGB || isHue;

    ColorComponent component1 = ColorComponentNone;
    ColorComponent component2 = ColorComponentNone;
    ColorComponent component3 = ColorComponentNone;

    
    if (isRGB) {
        isEnabled = YES;

        component1 = ColorComponentRed;
        component2 = ColorComponentGreen;
        component3 = ColorComponentBlue;

    } else if (colorMode == ColorMode_HSB) {
        isEnabled = YES;

        component1 = ColorComponentHue;
        component2 = ColorComponentSaturationHSB;
        component3 = ColorComponentBrightness;

    } else if (colorMode == ColorMode_HSL) {
        isEnabled = YES;

        component1 = ColorComponentHue;
        component2 = ColorComponentSaturationHSL;
        component3 = ColorComponentLightness;
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
    Color    *color     = self->m_color;
    ColorMode colorMode = sGetCurrentColorMode(self);

    NSString *value1 = nil;
    NSString *value2 = nil;
    NSString *value3 = nil;
    BOOL clipped1, clipped2, clipped3;
    ColorModeMakeComponentStrings(colorMode, color, self->m_usesLowercaseHex, self->m_usesPoundPrefix, &value1, &value2, &value3, &clipped1, &clipped2, &clipped3);

    if (value1) [self->o_value1 setStringValue:value1];
    if (value2) [self->o_value2 setStringValue:value2];
    if (value3) [self->o_value3 setStringValue:value3];
    
    static NSColor *sRedColor = nil;
    static NSColor *sBlackColor = nil;
    
    if (!sRedColor) {
        sRedColor   = [[NSColor redColor]   retain];
        sBlackColor = [[NSColor blackColor] retain];
    }

    BOOL isEditable = (ColorModeIsRGB(colorMode) || ColorModeIsHue(colorMode)) && self->m_isHoldingColor;

    [self->o_value1 setTextColor:((clipped1 && !isEditable) ? sRedColor : sBlackColor)];
    [self->o_value2 setTextColor:((clipped2 && !isEditable) ? sRedColor : sBlackColor)];
    [self->o_value3 setTextColor:((clipped3 && !isEditable) ? sRedColor : sBlackColor)];

    [self->o_value1 setEditable:isEditable];
    [self->o_value2 setEditable:isEditable];
    [self->o_value3 setEditable:isEditable];
}


static void sUpdateColorSync(AppDelegate *self)
{
    if (self->m_colorSyncTransform) {
        CFRelease(self->m_colorSyncTransform);
        self->m_colorSyncTransform = NULL;
    }

    ColorMode mode = sGetCurrentColorMode(self);
    ColorProfileType type = self->m_colorProfileType;

    ColorSyncProfileRef fromProfile   = ColorSyncProfileCreateWithDisplayID(self->m_lastDisplayID);
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
        
        self->m_colorSyncTransform = ColorSyncTransformCreate((CFArrayRef)profileSequence, NULL);

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
        
        [self->o_profileButton setTitle:joinedString];
    }

cleanup:
    if (fromProfile) CFRelease(fromProfile);
    if (toProfile)   CFRelease(toProfile);
}


#pragma mark -
#pragma mark Private Methods

- (void) _updateScreenshot
{
    CGPoint locationToUse = m_lastMouseLocation;
    
    if (!isnan(m_lockedX)) locationToUse.x = m_lockedX;
    if (!isnan(m_lockedY)) locationToUse.y = m_lockedY;

    CGPoint convertedPoint = CGPointMake(locationToUse.x, m_screenZeroHeight - locationToUse.y);

    CGRect screenBounds = m_screenBounds;
    screenBounds.origin.x += convertedPoint.x;
    screenBounds.origin.y += convertedPoint.y;
    CGImageRef screenShot = CGWindowListCreateImage(screenBounds, kCGWindowListOptionAll, kCGNullWindowID, kCGWindowImageDefault);
    
    CGDirectDisplayID displayID = m_lastDisplayID;
    uint32_t matchingDisplayCount;
    CGGetDisplaysWithPoint(convertedPoint, 1, &displayID, &matchingDisplayCount);

    if (m_lastDisplayID != displayID) {
        m_lastDisplayID = displayID;
        sUpdateColorSync(self);
    }
    
    if (!m_isHoldingColor) {
        float r, g, b;
        GetAverageColor(screenShot, m_apertureRect, &r, &g, &b);
        
        if (m_colorSyncTransform) {
            float src[3];
            float dst[3];
            
            src[0] = r;  src[1] = g;  src[2] = b;
            
            if (ColorSyncTransformConvert(m_colorSyncTransform,
                1, 1,
                &dst, kColorSync32BitFloat, 0, 12,
                &src, kColorSync32BitFloat, 0, 12,
                NULL
            )) {
                r = dst[0];  g = dst[1];  b = dst[2];
            }
        }

        [m_color setRed:r green:g blue:b];

        sUpdateColorViews(self);
        sUpdateTextFields(self);
    }

    if (screenShot) {
        [o_previewView setImage:screenShot];
        CFRelease(screenShot);
    }
    
    if (m_showMouseCoordinates) {
        [o_previewView setMouseLocation:convertedPoint];
    }
    
    [o_previewView setZoomLevel:m_zoomLevel];
}


- (void) _timerTick:(NSTimer *)timer
{
    NSPoint mouseLocation = [NSEvent mouseLocation];
    NSTimeInterval now    = [NSDate timeIntervalSinceReferenceDate];
    BOOL didMouseMove     = (m_lastMouseLocation.x != mouseLocation.x) || (m_lastMouseLocation.y != mouseLocation.y);
    BOOL needsUpdateTick  = (now - m_lastUpdateTimeInterval) > 0.5;

    if (didMouseMove) {
        m_lastMouseLocation = mouseLocation;
    }
    
    if (m_updatesContinuously || didMouseMove || needsUpdateTick) {
        [self _updateScreenshot];
        m_lastUpdateTimeInterval = now;
    }
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    Preferences *preferences  = [Preferences sharedInstance];
    NSInteger    apertureSize = [preferences apertureSize];

    m_colorProfileType     = [preferences colorProfileType];
    m_usesLowercaseHex     = [preferences usesLowercaseHex];
    m_usesPoundPrefix      = [preferences usesPoundPrefix];
    m_colorMode            = [preferences colorMode];
    m_zoomLevel            = [preferences zoomLevel];
    m_updatesContinuously  = [preferences updatesContinuously];
    m_showMouseCoordinates = [preferences showMouseCoordinates];

    BOOL showsHoldLabels = [preferences showsHoldLabels];
    [o_topHoldLabelButton setHidden:!showsHoldLabels];
    [o_bottomHoldLabelButton setHidden:!showsHoldLabels];

    [o_apertureSizeSlider setIntegerValue:apertureSize];
    [o_previewView setShowsLocation:[preferences showMouseCoordinates]];
    [o_previewView setApertureSize:apertureSize];
    [o_previewView setApertureColor:[preferences apertureColor]];

    [o_resultView setClickEnabled:[preferences clickInSwatchEnabled]];
    [o_resultView setDragEnabled: [preferences dragInSwatchEnabled]];

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
        [o_window setLevel:NSFloatingWindowLevel];
    } else {
        [o_window setLevel:NSNormalWindowLevel];
    }

    sUpdateColorSync(self);
    sUpdatePopUpAndComponentLabels(self);
    sUpdateSliders(self);
    sUpdateHoldLabels(self);

    if (m_zoomLevel < 1) {
        m_zoomLevel = 1;
    }
    
    {
        CGFloat pixelsToCapture = 120.0 / m_zoomLevel;
        CGFloat captureOffset   = floor(pixelsToCapture / 2.0);

        CGFloat pixelsToAverage = ((apertureSize * 2) + 1) * (8.0 / m_zoomLevel);
        CGFloat averageOffset   = floor((pixelsToCapture - pixelsToAverage) / 2.0);

        m_screenBounds = CGRectMake(-captureOffset, -captureOffset, pixelsToCapture, pixelsToCapture);
        m_apertureRect = CGRectMake( averageOffset,  averageOffset, pixelsToAverage, pixelsToAverage);
    }

    sUpdateTextFields(self);
    
    [self _updateScreenshot];
    
    if (m_isHoldingColor) {
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

    if (!isnan(m_lockedX) && !isnan(m_lockedY)) {
        [status addObject: NSLocalizedString(@"Locked Position", @"Status text: locked position")];
    } else if (!isnan(m_lockedX)) {
        [status addObject: NSLocalizedString(@"Locked X", @"Status text: locked x")];
    } else if (!isnan(m_lockedY)) {
        [status addObject: NSLocalizedString(@"Locked Y", @"Status text: locked y")];
    }

    [o_statusText setStringValue:[status componentsJoinedByString:@", "]];

    [status release];
}


- (NSImage *) _imageFromPreviewView
{
    NSSize   size  = [o_previewView bounds].size;
    NSImage *image = [[NSImage alloc] initWithSize:size];
    
    [image lockFocus];
    [o_previewView drawRect:[o_previewView bounds]];
    [image unlockFocus];
    
    return [image autorelease];
}


- (NSEvent *) _handleLocalEvent:(NSEvent *)event
{
    if (![o_window isKeyWindow]) {
        return event;
    }

    NSEventType type = [event type];

    if (type == NSKeyDown) {
        NSUInteger modifierFlags = [event modifierFlags];
        NSUInteger modifierMask  = (NSCommandKeyMask | NSAlternateKeyMask | NSControlKeyMask);

        if ((modifierFlags & modifierMask) == 0) {
            id        firstResponder = [o_window firstResponder];
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
                if (firstResponder != o_window) {
                    [o_window makeFirstResponder:o_window];
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
                CGPoint convertedPoint = CGPointMake(location.x + xDelta, m_screenZeroHeight - (location.y + yDelta));

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
        result = [m_color NSColor];

    } else if (actionTag == CopyColorAsText) {
        Preferences *preferences = [Preferences sharedInstance];

        ColorMode mode = m_colorMode;

        if (m_isHoldingColor && [preferences usesDifferentColorSpaceInHoldColor] && ![preferences usesMainColorSpaceForCopyAsText]) {
            mode = [preferences holdColorMode];
        }
        
        ColorModeMakeClipboardString(mode, m_color, m_usesLowercaseHex, m_usesPoundPrefix, &clipboardText);

    } else if (actionTag == CopyColorAsImage) {
        NSRect   bounds = NSMakeRect(0, 0, 64.0, 64.0);
        NSImage *image = [[[NSImage alloc] initWithSize:bounds.size] autorelease];
        
        [image lockFocus];
        [[m_color NSColor] set];
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
        clipboardText = GetCodeSnippetForColor(m_color, m_usesLowercaseHex, template);
        
        if (!m_usesPoundPrefix && [clipboardText hasPrefix:@"#"]) {
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

    Color *colorCopy = [m_color copy];

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

    m_layerContainer = [[NSView alloc] initWithFrame:[contentView bounds]];
    [m_layerContainer setWantsLayer:YES];

    m_leftSnapshot   = [[CALayer alloc] init];
    m_middleSnapshot = [[CALayer alloc] init];
    m_rightSnapshot  = [[CALayer alloc] init];

    [m_leftSnapshot   setDelegate:self];
    [m_middleSnapshot setDelegate:self];
    [m_rightSnapshot  setDelegate:self];

    [m_leftSnapshot   setAnchorPoint:CGPointMake(0, 0)];
    [m_middleSnapshot setAnchorPoint:CGPointMake(0, 0)];
    [m_rightSnapshot  setAnchorPoint:CGPointMake(0, 0)];
    
    [[m_layerContainer layer] addSublayer:m_leftSnapshot];
    [[m_layerContainer layer] addSublayer:m_middleSnapshot];
    [[m_layerContainer layer] addSublayer:m_rightSnapshot];

    [m_leftSnapshot   setFrame:[[self leftContainer]   frame]];
    [m_middleSnapshot setFrame:[[self middleContainer] frame]];
    [m_rightSnapshot  setFrame:[[self rightContainer]  frame]];

    [contentView addSubview:m_layerContainer];
}


#pragma mark -
#pragma mark Animation

- (void) _animateSnapshotsIfNeeded
{
    void (^setSnapshotsHidden)(BOOL) = ^(BOOL yn) {
        [o_leftContainer   setHidden:!yn];
        [o_middleContainer setHidden:!yn];
        [o_rightContainer  setHidden:!yn];
        [m_layerContainer  setHidden: yn];
    };
    
    void (^layout)(NSView *, CALayer *, CGFloat *) = ^(NSView *view, CALayer *layer, CGFloat *inOutX) {
        CGRect frame = [view frame];
        frame.origin.x = *inOutX;

        [view  setFrame:frame];
        [layer setFrame:frame];

        *inOutX = NSMaxX(frame);
    };
    
    BOOL showSliders = m_isHoldingColor && [[Preferences sharedInstance] showsHoldColorSliders];
    CGFloat xOffset  = showSliders ? -128.0 : 0.0;

    NSDisableScreenUpdates();
    {
        setSnapshotsHidden(NO);

        [CATransaction setAnimationDuration:0.3];
        [CATransaction setCompletionBlock:^{
            NSDisableScreenUpdates();

            setSnapshotsHidden(YES);
            [o_window displayIfNeeded];

            NSEnableScreenUpdates();
        }];

        [m_leftSnapshot   setContents:GetSnapshotImageForView(o_leftContainer)];
        [m_middleSnapshot setContents:GetSnapshotImageForView(o_middleContainer)];
        [m_rightSnapshot  setContents:GetSnapshotImageForView(o_rightContainer)];

        layout(o_leftContainer,   m_leftSnapshot,   &xOffset);
        layout(o_middleContainer, m_middleSnapshot, &xOffset);
        layout(o_rightContainer,  m_rightSnapshot,  &xOffset);

        [m_leftSnapshot  setOpacity:showSliders ? 0.0 : 1.0];
        [m_rightSnapshot setOpacity:showSliders ? 1.0 : 0.0];

        [o_window displayIfNeeded];
    }
    NSEnableScreenUpdates();
}


- (id<CAAction>) actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    if (m_isHoldingColor && [event isEqualToString:@"contents"]) {
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
        
        [o_resultView doPopOutAnimation];
    }
}


- (void) resultView:(ResultView *)view dragInitiatedWithEvent:(NSEvent *)event
{
    Preferences *preferences = [Preferences sharedInstance];

    if ([preferences dragInSwatchEnabled]) {
        NSInteger action   = [preferences dragInSwatchAction];
        NSPoint   location = [event locationInWindow];

        location = [o_resultView convertPoint:location fromView:nil];

        NSDraggingItem *item  = [self _draggingItemForColorAction:action cursorOffset:location];
        NSArray        *items = [NSArray arrayWithObject:item];

        [o_resultView beginDraggingSessionWithItems:items event:event source:self];
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
        [o_window makeKeyAndOrderFront:self];
        yn = YES;
    }

    return yn;
}


#pragma mark -
#pragma mark IBActions

- (IBAction) changeColorMode:(id)sender
{
    NSInteger tag = [sender selectedTag];
    
    if ([[Preferences sharedInstance] usesDifferentColorSpaceInHoldColor] && m_isHoldingColor) {
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
    BOOL isHue = ColorModeIsHue(mode);

    ColorComponent component = ColorComponentNone;

    if (isRGB || isHue) {
        if (sender == o_slider1 || sender == o_value1) {
            component = isRGB ? ColorComponentRed :ColorComponentHue;

        } else if (sender == o_slider2 || sender == o_value2) {
            if (isRGB) {
                component = ColorComponentGreen;
            } else if (mode == ColorMode_HSB) {
                component = ColorComponentSaturationHSB;
            } else if (mode == ColorMode_HSL) {
                component = ColorComponentSaturationHSL;
            }

        } else if (sender == o_slider3 || sender == o_value3) {
            if (isRGB) {
                component = ColorComponentBlue;
            } else if (mode == ColorMode_HSB) {
                component = ColorComponentBrightness;
            } else if (mode == ColorMode_HSL) {
                component = ColorComponentLightness;
            }
        }
    }
    
    if (component != ColorComponentNone) {
        float floatValue = [sender floatValue];

        if ([sender isKindOfClass:[NSTextField class]]) {
            floatValue = ColorModeParseComponentString(mode, component, [sender stringValue]);            
        }
    
        [m_color setFloatValue:floatValue forComponent:component];
    }

    sUpdateColorViews(self);
    sUpdateSliders(self);
    sUpdateHoldLabels(self);
    sUpdateTextFields(self);
}


- (IBAction) showSnippets:(id)sender
{
    if (!m_snippetsController) {
        m_snippetsController = [[SnippetsController alloc] init];
    }
    
    [m_snippetsController showWindow:self];
}


- (IBAction) showPreferences:(id)sender
{
    if (!m_preferencesController) {
        m_preferencesController = [[PreferencesController alloc] init];
    }
    
    [m_preferencesController showWindow:self];
}


- (IBAction) changeColorConversionValue:(id)sender
{
    NSInteger tag = [sender tag];
    [[Preferences sharedInstance] setColorProfileType:tag];
}


- (IBAction) writeTopLabelValueToPasteboard:(id)sender
{
    [self _writeString:[o_topHoldLabelButton title] toPasteboard:[NSPasteboard generalPasteboard]];
}


- (IBAction) writeBottomLabelValueToPasteboard:(id)sender
{
    [self _writeString:[o_bottomHoldLabelButton title] toPasteboard:[NSPasteboard generalPasteboard]];
}


- (IBAction) lockPosition:(id)sender
{
    if (isnan(m_lockedX) || isnan(m_lockedY)) {
        CGPoint mouseLocation = [NSEvent mouseLocation];
        m_lockedX = mouseLocation.x;
        m_lockedY = mouseLocation.y;

    } else {
        m_lockedX = NAN;
        m_lockedY = NAN;
    }
    
    [self _updateStatusText];
    [self _updateScreenshot];
}


- (IBAction) lockX:(id)sender
{
    if (isnan(m_lockedX)) {
        m_lockedX = [NSEvent mouseLocation].x;
    } else {
        m_lockedX = NAN;
    }

    [self _updateStatusText];
    [self _updateScreenshot];
}


- (IBAction) lockY:(id)sender
{
    if (isnan(m_lockedY)) {
        m_lockedY = [NSEvent mouseLocation].y;
    } else {
        m_lockedY = NAN;
    }

    [self _updateStatusText];
    [self _updateScreenshot];
}


- (IBAction) updateMagnification:(id)sender
{
    NSInteger tag = [sender tag];
    [[Preferences sharedInstance] setZoomLevel:[sender tag]];
    m_zoomLevel = tag;

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
    
    [savePanel beginSheetModalForWindow:o_window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [[image TIFFRepresentation] writeToURL:[savePanel URL] atomically:YES];
        }
    }];
}


- (IBAction) holdColor:(id)sender
{
    m_isHoldingColor = !m_isHoldingColor;

    [o_holdingLabel setHidden:!m_isHoldingColor];
    [o_holdingLabel setStringValue: NSLocalizedString(@"Holding Color", @"Status text: holding color")];
    [o_profileButton setHidden:m_isHoldingColor];

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
        [m_color setRed:[parsedColor red] green:[parsedColor green] blue:[parsedColor blue]];

        sUpdateColorViews(self);
        sUpdateTextFields(self);

        if (!m_isHoldingColor) {
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

@synthesize window                = o_window,
            leftContainer         = o_leftContainer,
            middleContainer       = o_middleContainer,
            rightContainer        = o_rightContainer,
            colorModePopUp        = o_colorModePopUp,
            previewView           = o_previewView,
            resultView            = o_resultView,
            apertureSizeLabel     = o_apertureSizeLabel,
            statusText            = o_statusText,
            apertureSizeSlider    = o_apertureSizeSlider,
            label1                = o_label1,
            label2                = o_label2,
            label3                = o_label3,
            value1                = o_value1,
            value2                = o_value2,
            value3                = o_value3,
            holdingLabel          = o_holdingLabel,
            profileButton         = o_profileButton,
            topHoldLabelButton    = o_topHoldLabelButton,
            bottomHoldLabelButton = o_bottomHoldLabelButton,
            slider1               = o_slider1,
            slider2               = o_slider2,
            slider3               = o_slider3;

@end
