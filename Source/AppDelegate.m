//
//  AppDelegate.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

#import "Aperture.h"
#import "ColorSliderCell.h"
#import "GuideController.h"
#import "MouseCursor.h"
#import "Preferences.h"
#import "PreferencesController.h"
#import "PreviewView.h"
#import "RecessedButton.h"
#import "ResultView.h"
#import "Shortcut.h"
#import "ShortcutManager.h"
#import "MiniWindowController.h"
#import "SnippetsController.h"
#import "RecorderController.h"
#import "Util.h"


typedef NS_ENUM(NSInteger, ColorAction) {
    UnknownColorAction          = -1,

    CopyColorAsColor            = 0,

    CopyColorAsText             = 1,
    CopyColorAsImage            = 2,

    CopyColorAsNSColorSnippet   = 3,
    CopyColorAsUIColorSnippet   = 4,
    CopyColorAsHexColorSnippet  = 5,
    CopyColorAsRGBColorSnippet  = 6,
    CopyColorAsRGBAColorSnippet = 7
};


@interface AppDelegate () <ApertureDelegate, ShortcutListener, ResultViewDelegate, CALayerDelegate, NSMenuDelegate, NSDraggingSource>

@property (nonatomic, strong) IBOutlet NSWindow      *window;

@property (nonatomic, strong) IBOutlet NSView        *leftContainer;
@property (nonatomic, strong) IBOutlet NSView        *middleContainer;
@property (nonatomic, strong) IBOutlet NSView        *rightContainer;

@property (nonatomic, strong) IBOutlet NSMenuItem    *convertToGenericRGBMenuItem;
@property (nonatomic, strong) IBOutlet NSMenuItem    *convertToMainDisplayMenuItem;

@property (nonatomic, strong) IBOutlet NSPopUpButton *colorModePopUp;
@property (nonatomic, strong) IBOutlet NSSlider      *apertureSizeSlider;
@property (nonatomic, strong) IBOutlet PreviewView   *previewView;

@property (nonatomic, strong) IBOutlet ResultView    *resultView;

@property (nonatomic, strong) IBOutlet NSTextField   *label1;
@property (nonatomic, strong) IBOutlet NSTextField   *label2;
@property (nonatomic, strong) IBOutlet NSTextField   *label3;

@property (nonatomic, strong) IBOutlet NSTextField    *holdingLabel;
@property (nonatomic, strong) IBOutlet RecessedButton *profileButton;
@property (nonatomic, strong) IBOutlet RecessedButton *topHoldLabelButton;
@property (nonatomic, strong) IBOutlet RecessedButton *bottomHoldLabelButton;

@property (nonatomic, strong) IBOutlet NSTextField   *value1;
@property (nonatomic, strong) IBOutlet NSTextField   *value2;
@property (nonatomic, strong) IBOutlet NSTextField   *value3;

@property (nonatomic, strong) IBOutlet NSView        *sliderContainer;
@property (nonatomic, strong) IBOutlet NSSlider      *slider1;
@property (nonatomic, strong) IBOutlet NSSlider      *slider2;
@property (nonatomic, strong) IBOutlet NSSlider      *slider3;

@property (nonatomic, strong) IBOutlet NSWindow      *colorWindow;
@property (nonatomic, weak)   IBOutlet ResultView    *colorResultView;

@end


@implementation AppDelegate {
    NSView         *_layerContainer;
    CALayer        *_leftSnapshot;
    CALayer        *_middleSnapshot;
    CALayer        *_rightSnapshot;
    NSImage        *_leftHoldImage;
    NSImage        *_middleHoldImage;
    NSImage        *_rightHoldImage;
    NSImage        *_leftViewImage;
    NSImage        *_middleViewImage;
    NSImage        *_rightViewImage;
        
    PreferencesController *_preferencesController;
    SnippetsController    *_snippetsController;
    RecorderController    *_recorderController;
    MiniWindowController  *_miniWindowController;

    MouseCursor           *_cursor;
    Aperture              *_aperture;

    ColorStringOptions     _colorStringOptions;

    BOOL           _isHoldingColor;
    Color         *_color;
    
    BOOL _isTerminating;
    
    // Cached prefs
    ColorMode        _colorMode;
    NSInteger        _showMouseCoordinates;
    BOOL             _usesLowercaseHex;
    BOOL             _usesPoundPrefix;
}


- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _cursor   = [MouseCursor sharedInstance];
    _color    = [[Color alloc] init];
    _aperture = [[Aperture alloc] init];
    
    [_aperture setDelegate:self];

    [(ColorSliderCell *)[[self slider1] cell] setColor:_color];
    [(ColorSliderCell *)[[self slider2] cell] setColor:_color];
    [(ColorSliderCell *)[[self slider3] cell] setColor:_color];

    CGFloat  pointSize      = [[[self value1] font] pointSize];
    NSFont  *monospacedFont = [NSFont monospacedDigitSystemFontOfSize:pointSize weight:NSFontWeightRegular];

    [[self value1] setFont:monospacedFont];
    [[self value2] setFont:monospacedFont];
    [[self value3] setFont:monospacedFont];

    [[self resultView] setColor:_color];
    [[self resultView] setDelegate:self];

    [[self colorResultView] setColor:_color];
    [[self colorResultView] setDelegate:self];
    
    [[self rightContainer] setHidden:YES];

    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^(NSEvent *inEvent) {
        return [self _handleLocalEvent:inEvent];
    }];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handlePreferencesDidChange:)          name:PreferencesDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleWindowDidChangeOcclusionState:) name:NSWindowDidChangeOcclusionStateNotification object:nil];

    NSWindow *window = [self window];
    NSRect windowFrame = [window frame];
    windowFrame.size.width = 316;

    if (@available(macOS 11.0, *)) {
        // Nothing to do, as our XIB sets the height to 174.
    } else {
        // On previous versions of macOS, use a smaller height.
        windowFrame.size.height = 170;
        
        NSRect sliderFrame = [[self sliderContainer] frame];
        sliderFrame.origin.y += 2;
        [[self sliderContainer] setFrame:sliderFrame];
    }

    [window setFrame:windowFrame display:NO animate:NO];
    [window setOpaque:YES];

    [self _setupHoldAnimation];

    [[Preferences sharedInstance] migrateIfNeeded];
    [self _handlePreferencesDidChange:nil];
    
    [_aperture update];
    
    [[self resultView] setDrawsBorder:YES];

    [window makeKeyAndOrderFront:self];
    [window selectPreviousKeyView:self];

    if ([[Preferences sharedInstance] showsMiniWindow]) {
        [self toggleMiniWindow:self];
    }

    if ([[Preferences sharedInstance] showsColorWindow]) {
        [_colorWindow orderFront:nil];
    }
}


- (void) applicationDidChangeScreenParameters:(NSNotification *)notification
{
    [_cursor update];
    [_aperture update];
}


- (void) dealloc
{
    [[ShortcutManager sharedInstance] removeListener:self];
}


- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
    SEL action = [menuItem action];

    if (action == @selector(lockPosition:)) {
        BOOL xLocked = [_cursor isXLocked];
        BOOL yLocked = [_cursor isYLocked];

        NSInteger state = NSControlStateValueOff;

        if (xLocked && yLocked) {
            state = NSControlStateValueOn;
        } else if (xLocked || yLocked) {
            state = NSControlStateValueMixed;
        }

        [menuItem setState:state];
    
    } else if (action == @selector(lockX:)) {
        [menuItem setState:[_cursor isXLocked]];

    } else if (action == @selector(lockY:)) {
        [menuItem setState:[_cursor isYLocked]];

    } else if (action == @selector(toggleLockGuides:)) {
        [menuItem setState:[[Preferences sharedInstance] showsLockGuides]];

    } else if (action == @selector(changeApertureOutline:)) {
        [menuItem setState:([menuItem tag] == [[Preferences sharedInstance] apertureOutline])];
        
    } else if (action == @selector(updateMagnification:)) {
        [menuItem setState:([menuItem tag] == [_aperture zoomLevel])];

    } else if (action == @selector(toggleContinuous:)) {
        [menuItem setState:[_aperture updatesContinuously]];

    } else if (action == @selector(toggleMouseLocation:)) {
        [menuItem setState:_showMouseCoordinates];

    } else if (action == @selector(holdColor:)) {
        [menuItem setState:_isHoldingColor];

    } else if (action == @selector(toggleFloatWindow:)) {
        [menuItem setState:[[Preferences sharedInstance] floatWindow]];

    } else if (action == @selector(toggleColorWindow:)) {
        [menuItem setState:[[self colorWindow] isVisible]];

    } else if (action == @selector(toggleMiniWindow:)) {
        [menuItem setState:[[_miniWindowController window] isVisible]];

    } else if (action == @selector(showSnippets:) || action == @selector(showRecorder:)) {
        NSUInteger flags     = [NSEvent modifierFlags];
        NSUInteger mask      = NSEventModifierFlagControl | NSEventModifierFlagCommand | NSEventModifierFlagOption;
        BOOL       isVisible = ((flags & mask) == mask);
         
        [menuItem setHidden:!isVisible];

    } else if (action == @selector(changeColorConversionValue:)) {
        BOOL state = ([menuItem tag] == [_aperture colorConversion]);
        [menuItem setState:state];
    }

    return YES;
}


- (void) cancel:(id)sender
{
    NSWindow *window = [self window];

    if ([window firstResponder] != window) {
        [window makeFirstResponder:window];
    }
}


- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
    _isTerminating = YES;
    return NSTerminateNow;
}   


- (void) windowWillClose:(NSNotification *)note
{
    id object = [note object];

    if (object == [self window]) {
        [NSApp terminate:self];
    } else if (object == _colorWindow && !_isTerminating) {
        [[Preferences sharedInstance] setShowsColorWindow:NO];
    }
}


#pragma mark - Private Methods

- (ColorMode) _currentColorMode
{
    if (_isHoldingColor) {
        Preferences *preferences = [Preferences sharedInstance];
        if ([preferences usesDifferentColorSpaceInHoldColor]) {
            return [preferences holdColorMode];
        }
    }
    
    return _colorMode;
}


- (void) _updateColorViews
{
    [[self resultView]      setNeedsDisplay:YES];
    [[self colorResultView] setNeedsDisplay:YES];

    [[self slider1] setNeedsDisplay:YES];
    [[self slider2] setNeedsDisplay:YES];
    [[self slider3] setNeedsDisplay:YES];
}


- (void) _updatePopUpMenuItems
{
    Preferences *preferences = [Preferences sharedInstance];

    BOOL showsLegacy = [preferences showsLegacyColorSpaces];

    NSMenu *menu = [[self colorModePopUp] menu];
    [menu removeAllItems];

    void (^addMenu)(ColorMode, NSString *) = ^(ColorMode mode, NSString *title) {
        NSMenuItem *item  = [[NSMenuItem alloc] initWithTitle:title action:NULL keyEquivalent:@""];
        [item setTag:mode];
        [menu addItem:item];
    };
  
    addMenu( ColorMode_RGB_Percentage, NSLocalizedString(@"RGB, percentage", nil) );
  
    if (showsLegacy) {
        addMenu( ColorMode_RGB_Value_8,     NSLocalizedString(@"RGB, decimal, 8-bit",  nil) );
        addMenu( ColorMode_RGB_Value_16,    NSLocalizedString(@"RGB, decimal, 16-bit", nil) );
        addMenu( ColorMode_RGB_HexValue_8,  NSLocalizedString(@"RGB, hex, 8-bit",      nil) );
        addMenu( ColorMode_RGB_HexValue_16, NSLocalizedString(@"RGB, hex, 16-bit",     nil) );
    } else {
        addMenu( ColorMode_RGB_Value_8,     NSLocalizedString(@"RGB, decimal",         nil) );
        addMenu( ColorMode_RGB_HexValue_8,  NSLocalizedString(@"RGB, hex",             nil) );
    }
  
    [menu addItem:[NSMenuItem separatorItem]];
    addMenu( ColorMode_HSB, NSLocalizedString(@"HSB", nil) );
    addMenu( ColorMode_HSL, NSLocalizedString(@"HSL", nil) );

    if ([preferences showsLumaChromaColorSpaces]) {
        [menu addItem:[NSMenuItem separatorItem]];
        addMenu( ColorMode_YPbPr_601, NSLocalizedString(@"Y'PrPb ITU-R BT.601", nil) );
        addMenu( ColorMode_YPbPr_709, NSLocalizedString(@"Y'PrPb ITU-R BT.709", nil) );
        addMenu( ColorMode_YCbCr_601, NSLocalizedString(@"Y'CbCr ITU-R BT.601", nil) );
        addMenu( ColorMode_YCbCr_709, NSLocalizedString(@"Y'CbCr ITU-R BT.709", nil) );
    }

    [menu addItem:[NSMenuItem separatorItem]];

    if ([preferences showsAdditionalCIEColorSpaces]) {
        addMenu( ColorMode_CIE_1931,    NSLocalizedString(@"CIE 1931",    nil) );
        addMenu( ColorMode_CIE_1976,    NSLocalizedString(@"CIE 1976",    nil) );
        addMenu( ColorMode_CIE_Lab,     NSLocalizedString(@"CIE L*a*b*",  nil) );
        addMenu( ColorMode_Tristimulus, NSLocalizedString(@"Tristimulus", nil) );
    } else {
        addMenu( ColorMode_CIE_Lab,     NSLocalizedString(@"CIE L*a*b*",  nil) );
    }
    
    [[self convertToGenericRGBMenuItem]  setHidden:!showsLegacy];
    [[self convertToMainDisplayMenuItem] setHidden:!showsLegacy];
}


- (void) _updateHoldLabels
{
    ColorMode mode  = [self _currentColorMode];
    Color    *color = _color;

    NSString *hexString = nil;
    
    // Calculate hexString
    {
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
        if (_usesPoundPrefix) {
            hexFormat = _usesLowercaseHex ? @"#%02x%02x%02x" : @"#%02X%02X%02X";
        } else {
            hexFormat = _usesLowercaseHex ?  @"%02x%02x%02x" :  @"%02X%02X%02X";
        }

        hexString = [NSString stringWithFormat:hexFormat, r, g, b];
    }

    if (ColorModeIsRGB(mode)) {
        float f1, f2, f3;
        [color getHue:&f1 saturation:&f2 brightness:&f3];
    
        long h = lroundf(f1 * 360);
        long s = lroundf(f2 * 100);
        long b = lroundf(f3 * 100);

        while   (h > 360) h -= 360;
        while   (h < 0)   h += 360;
        if      (s > 100) s = 100;
        else if (s < 0)   s = 0;
        if      (b > 100) b = 100;
        else if (b < 0)   b = 0;

        NSString *hsbString = [NSString stringWithFormat:@"%ld%C, %ld%%, %ld%%", h, (unsigned short)0x00b0, s, b];

        [[self topHoldLabelButton]    setTitle:hsbString];
        [[self bottomHoldLabelButton] setTitle:hexString];

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

        [[self topHoldLabelButton]    setTitle:decimalString];
        [[self bottomHoldLabelButton] setTitle:hexString];
    }
}


- (void) _updatePopUpSelectionAndComponentLabels
{
    ColorMode colorMode = [self _currentColorMode];

    [[self colorModePopUp] selectItemWithTag:colorMode];

    NSArray *labels = ColorModeGetComponentLabels(colorMode);
    if ([labels count] == 3) {
        [[self label1] setStringValue:[labels objectAtIndex:0]];
        [[self label2] setStringValue:[labels objectAtIndex:1]];
        [[self label3] setStringValue:[labels objectAtIndex:2]];
    }
    
    [_miniWindowController updateColorMode:colorMode];
}


- (void) _updateSliders
{
    ColorMode colorMode = [self _currentColorMode];

    NSSlider *slider1   = [self slider1];
    NSSlider *slider2   = [self slider2];
    NSSlider *slider3   = [self slider3];
    Color    *color     = _color;

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


- (void) _updateTextFields
{
    Preferences *preferences = [Preferences sharedInstance];
    ColorMode colorMode = [self _currentColorMode];

    NSTextField *value1 = [self value1];
    NSTextField *value2 = [self value2];
    NSTextField *value3 = [self value3];

    NSColor *(^getColor)(BOOL) = ^(BOOL outOfRange) {
        if (outOfRange && [preferences highlightsOutOfRange]) {
            return [NSColor systemRedColor];
        }
        
        return [NSColor textColor];
    };

    NSString * __autoreleasing strings[3];
    BOOL outOfRange[3];
    [_color getComponentsForMode:colorMode options:_colorStringOptions outOfRange:outOfRange strings:strings];

    if (strings[0]) [value1 setStringValue:strings[0]];
    if (strings[1]) [value2 setStringValue:strings[1]];
    if (strings[2]) [value3 setStringValue:strings[2]];

    BOOL isEditable = (ColorModeIsRGB(colorMode) || ColorModeIsHue(colorMode)) && _isHoldingColor;

    if (isEditable) {
        NSColor *black = [NSColor textColor];

        [value1 setTextColor:black];
        [value2 setTextColor:black];
        [value3 setTextColor:black];

    } else {
        [value1 setTextColor:getColor(outOfRange[0])];
        [value2 setTextColor:getColor(outOfRange[1])];
        [value3 setTextColor:getColor(outOfRange[2])];
    }

    [value1 setEditable:isEditable];
    [value2 setEditable:isEditable];
    [value3 setEditable:isEditable];
    
    [_miniWindowController updateColor:_color options:_colorStringOptions];
}


- (void) _updateApertureTimer
{
    NSWindow *mainWindow  = [self window];
    NSWindow *colorWindow = [self colorWindow];
    NSWindow *miniWindow  = [_miniWindowController window];

    BOOL (^needsUpdates)(NSWindow *) = ^(NSWindow *window) {
        if (![window isVisible]) return NO;
    
        NSWindowOcclusionState occlusionState = [window occlusionState];
        return (BOOL)((occlusionState & NSWindowOcclusionStateVisible) > 0);
    };

    BOOL usesTimer = !_isHoldingColor && (
        _recorderController != nil ||
        needsUpdates(mainWindow)   ||
        needsUpdates(colorWindow)  ||
        needsUpdates(miniWindow)
    );

    [_aperture setUsesTimer:usesTimer];
}


- (void) aperture:(Aperture *)aperture didUpdateImage:(CGImageRef)image
{
    if (!_isHoldingColor) {
        float r1, g1, b1;
        float r2, g2, b2;
        
        [_color getRed:&r1 green:&g1 blue:&b1];
        [_aperture averageAndUpdateColor:_color];
        [_color getRed:&r2 green:&g2 blue:&b2];

        if ([_recorderController isRecording]) {
            NSString *text = [_color clipboardStringForMode:_colorMode options:_colorStringOptions];
            [_recorderController addSampleWithText:text];
        }
        
        if ((r1 != r2) || (g1 != g2) || (b1 != b2)) {
            [self _updateColorViews];
            [self _updateTextFields];
        }
    }

    PreviewView *previewView = [self previewView];
    [previewView setImage:image];
    [previewView setImageScale:[_aperture scaleFactor]];
    [previewView setOffset:[_aperture offset]];
    [previewView setApertureRect:[_aperture apertureRect]];
}


- (void) apertureDidUpdateColorProfile:(Aperture *)aperture
{
    [self _updateStatusText];
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    Preferences *preferences  = [Preferences sharedInstance];
    NSInteger    apertureSize = [preferences apertureSize];

    ResultView  *resultView      = [self resultView];
    ResultView  *colorResultView = [self colorResultView];
    PreviewView *previewView     = [self previewView];
    NSSlider    *apertureSlider  = [self apertureSizeSlider];

    _usesLowercaseHex     = [preferences usesLowercaseHex];
    _usesPoundPrefix      = [preferences usesPoundPrefix];
    _colorMode            = [preferences colorMode];
    _showMouseCoordinates = [preferences showMouseCoordinates];
    
    _colorStringOptions = 0;
    if (_usesLowercaseHex)             _colorStringOptions |= ColorStringUsesLowercaseHex;
    if (_usesPoundPrefix)              _colorStringOptions |= ColorStringUsesPoundPrefix;
    if ([preferences clipsOutOfRange]) _colorStringOptions |= ColorStringClipsOutOfRange;

    BOOL showsHoldLabels = [preferences showsHoldLabels];
    [[self topHoldLabelButton]    setHidden:!showsHoldLabels];
    [[self bottomHoldLabelButton] setHidden:!showsHoldLabels];

    BOOL showsLockGuides = [[Preferences sharedInstance] showsLockGuides];
    [[GuideController sharedInstance] setEnabled:showsLockGuides];

    [apertureSlider setIntegerValue:apertureSize];
    [previewView setShowsLocation:[preferences showMouseCoordinates]];
    [previewView setApertureOutline:[preferences apertureOutline]];
    [previewView setZoomLevel:[preferences zoomLevel]];

    [resultView setClickEnabled:[preferences clickInSwatchEnabled]];
    [resultView setDragEnabled: [preferences dragInSwatchEnabled]];
    [colorResultView setClickEnabled:[preferences clickInSwatchEnabled]];
    [colorResultView setDragEnabled: [preferences dragInSwatchEnabled]];

    [_aperture setZoomLevel:[preferences zoomLevel]];
    [_aperture setUpdatesContinuously:[preferences updatesContinuously]];
    [_aperture setApertureSize:apertureSize];

    ColorConversion colorConversion = [preferences colorConversion];
    ColorMode colorMode = [preferences colorMode];
    
    if (ColorModeIsXYZ(colorMode) || colorMode == ColorMode_CIE_Lab) {
        colorConversion = ColorConversionNone;
        [_profileButton setEnabled:NO];
    } else {
        [_profileButton setEnabled:YES];
    }

    [_aperture setColorConversion:colorConversion];

    NSMutableArray *shortcuts = [NSMutableArray array];
    if ([preferences showApplicationShortcut]) {
        [shortcuts addObject:[preferences showApplicationShortcut]];
    }
    if ([preferences holdColorShortcut]) {
        [shortcuts addObject:[preferences holdColorShortcut]];
    }
    if ([preferences lockPositionShortcut]) {
        [shortcuts addObject:[preferences lockPositionShortcut]];
    }
    if ([preferences nsColorSnippetShortcut]) {
        [shortcuts addObject:[preferences nsColorSnippetShortcut]];
    }
    if ([preferences uiColorSnippetShortcut]) {
        [shortcuts addObject:[preferences uiColorSnippetShortcut]];
    }
    if ([preferences hexColorSnippetShortcut]) {
        [shortcuts addObject:[preferences hexColorSnippetShortcut]];
    }
    if ([preferences rgbColorSnippetShortcut]) {
        [shortcuts addObject:[preferences rgbColorSnippetShortcut]];
    }
    if ([preferences rgbaColorSnippetShortcut]) {
        [shortcuts addObject:[preferences rgbaColorSnippetShortcut]];
    }

    if ([shortcuts count] || [ShortcutManager hasSharedInstance]) {
        [[ShortcutManager sharedInstance] addListener:self];
        [[ShortcutManager sharedInstance] setShortcuts:shortcuts];
    }

    if ([preferences floatWindow]) {
        [[self window] setLevel:NSFloatingWindowLevel];
    } else {
        [[self window] setLevel:NSNormalWindowLevel];
    }

    [self _updatePopUpMenuItems];
    [self _updatePopUpSelectionAndComponentLabels];
    [self _updateSliders];
    [self _updateHoldLabels];
    [self _updateTextFields];
    [self _updateStatusText];
    
    if (_isHoldingColor) {
        [self _animateSnapshotsIfNeeded];
    }
}


- (void) _handleWindowDidChangeOcclusionState:(NSNotification *)note
{
    [self _updateApertureTimer];
}


- (void) _updateStatusText
{
    // Update position status
    if (![[Preferences sharedInstance] showsLockGuides]) {
        NSMutableArray *status = [[NSMutableArray alloc] init];

        BOOL xLocked = [_cursor isXLocked];
        BOOL yLocked = [_cursor isYLocked];
        
        if (xLocked && yLocked) {
            [status addObject: NSLocalizedString(@"Locked Position", @"Status text: locked position")];
        } else if (xLocked) {
            [status addObject: NSLocalizedString(@"Locked X", @"Status text: locked x")];
        } else if (yLocked) {
            [status addObject: NSLocalizedString(@"Locked Y", @"Status text: locked y")];
        }

        [[self previewView] setStatusText:[status componentsJoinedByString:@", "]];
    } else {
        [[self previewView] setStatusText:nil];
    }

    // Update color profile status
    {
        NSString *shortLabel = [_aperture shortColorProfileLabel];
        NSString *longLabel  = [_aperture longColorProfileLabel];
        
        if (_colorMode == ColorMode_CIE_Lab) {
            shortLabel = [shortLabel stringByAppendingFormat:@"%@%@", GetArrowJoinerString(), NSLocalizedString(@"Lab", nil)];
            longLabel  = [longLabel  stringByAppendingFormat:@"%@%@", GetArrowJoinerString(), NSLocalizedString(@"Lab", nil)];
        } else if (ColorModeIsXYZ(_colorMode)) {
            shortLabel = [shortLabel stringByAppendingFormat:@"%@%@", GetArrowJoinerString(), NSLocalizedString(@"XYZ", nil)];
            longLabel  = [longLabel stringByAppendingFormat:@"%@%@",  GetArrowJoinerString(), NSLocalizedString(@"XYZ", nil)];
        }

        [[self profileButton] setTitle:longLabel];
        [[self profileButton] setShortTitle:shortLabel];
    }
}


- (NSImage *) _imageFromPreviewView
{
    [_aperture update];

    NSSize   size  = [[self previewView] bounds].size;
    NSImage *image = [[NSImage alloc] initWithSize:size];
    
    [image lockFocus];
    [[self previewView] drawRect:[[self previewView] bounds]];
    [image unlockFocus];
    
    return image;
}


- (NSEvent *) _handleLocalEvent:(NSEvent *)event
{
    if (![[self window] isKeyWindow]) {
        return event;
    }

    NSEventType type = [event type];

    if (type == NSEventTypeKeyDown) {
        NSUInteger modifierFlags = [event modifierFlags];

        id        firstResponder = [[self window] firstResponder];
        NSString *characters     = [event charactersIgnoringModifiers];
        unichar   c              = [characters length] ? [characters characterAtIndex:0] : 0; 
        BOOL      isShift        = (modifierFlags & NSEventModifierFlagShift)   > 0;
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
            if (firstResponder != [self window]) {
                [[self window] makeFirstResponder:[self window]];
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

            [_cursor movePositionByXDelta:xDelta yDelta:yDelta];

            return nil;
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


#pragma mark - Pasteboard / Dragging

- (id<NSPasteboardWriting>) _pasteboardWriterForColorAction:(ColorAction)actionTag
{
    Preferences *preferences = [Preferences sharedInstance];

    id<NSPasteboardWriting> result = nil;

    NSString *template      = nil;
    NSString *clipboardText = nil;

    if (actionTag == CopyColorAsColor) {
        result = [_color NSColor];

    } else if (actionTag == CopyColorAsText) {
        ColorMode mode = _colorMode;

        if (_isHoldingColor && [preferences usesDifferentColorSpaceInHoldColor] && ![preferences usesMainColorSpaceForCopyAsText]) {
            mode = [preferences holdColorMode];
        }
        
        clipboardText = [_color clipboardStringForMode:mode options:_colorStringOptions];
        
    } else if (actionTag == CopyColorAsImage) {
        NSRect   bounds = NSMakeRect(0, 0, 64.0, 64.0);
        NSImage *image = [[NSImage alloc] initWithSize:bounds.size];
        
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
        clipboardText = [_color codeSnippetForTemplate:template options:_colorStringOptions];
        
        if (!_usesPoundPrefix && [clipboardText hasPrefix:@"#"]) {
            clipboardText = [clipboardText substringFromIndex:1]; 
        }
    }
    
    if (clipboardText) {
        NSPasteboardItem *item = [[NSPasteboardItem alloc] initWithPasteboardPropertyList:clipboardText ofType:NSPasteboardTypeString];
        result = item;
    }

    return result;
}


- (NSDraggingImageComponent *) _draggingImageComponentForColor:(Color *)color action:(ColorAction)colorAction
{
    CGRect imageRect  = CGRectMake(0, 0, 48.0, 48.0);
    CGRect circleRect = CGRectInset(imageRect, 8.0, 8.0);
    
    NSImage *image = [[NSImage alloc] initWithSize:imageRect.size];
    
    [image lockFocus];
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    
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
        }
        
        CGContextRestoreGState(context);
    }

    [[NSColor whiteColor] set];
    [path setLineWidth:2.0];
    [path stroke];

    [image unlockFocus];
    

    NSString *key = NSDraggingImageComponentIconKey;
    NSDraggingImageComponent *component = [[NSDraggingImageComponent alloc] initWithKey:key];

    [component setContents:image];
    [component setFrame:imageRect];
    
    return component;
}


- (NSDraggingItem *) _draggingItemForColorAction:(ColorAction)colorAction cursorOffset:(NSPoint)location
{
    id<NSPasteboardWriting> pboardWriter = [self _pasteboardWriterForColorAction:colorAction];

    Color *colorCopy = [_color copy];

    NSDraggingItem *draggingItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pboardWriter];
    
    [draggingItem setDraggingFrame:[[self resultView] bounds]];

    [draggingItem setImageComponentsProvider: ^{
        NSDraggingImageComponent *component = [self _draggingImageComponentForColor:colorCopy action:colorAction];
        
        NSRect frame = [component frame];
        frame.origin = NSMakePoint(location.x - (frame.size.width / 2.0), location.y - (frame.size.height / 2.0));
        [component setFrame:frame];

        return [NSArray arrayWithObject:component];
    }];
    

    return draggingItem;
}


- (void) _writeString:(NSString *)string toPasteboard:(NSPasteboard *)pasteboard
{
    if (string) {
        NSPasteboardItem *item = [[NSPasteboardItem alloc] initWithPasteboardPropertyList:string ofType:NSPasteboardTypeString];

        [pasteboard clearContents];
        [pasteboard writeObjects:[NSArray arrayWithObject:item]];
    }
}


- (NSDragOperation) draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    return NSDragOperationGeneric | NSDragOperationCopy;
}


#pragma mark - Animation

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


- (void) _animateSnapshotsIfNeeded
{
    NSView *leftContainer   = [self leftContainer];
    NSView *middleContainer = [self middleContainer];
    NSView *rightContainer  = [self rightContainer];
    NSView *layerContainer  = _layerContainer;

    CALayer *leftSnapshot   = _leftSnapshot;
    CALayer *middleSnapshot = _middleSnapshot;
    CALayer *rightSnapshot  = _rightSnapshot;

    void (^setSnapshotsHidden)(BOOL) = ^(BOOL yn) {
        [leftContainer   setHidden:!yn];
        [middleContainer setHidden:!yn];
        [rightContainer  setHidden:!yn];
        [layerContainer  setHidden: yn];
    };
    
    void (^layout)(NSView *, CALayer *, CGFloat *) = ^(NSView *view, CALayer *layer, CGFloat *inOutX) {
        CGRect frame = [view frame];
        frame.origin.x = (*inOutX) + 6;

        [view  setFrame:frame];
        [layer setFrame:frame];

        *inOutX = NSMaxX(frame);
    };
    
    BOOL showSliders = _isHoldingColor && [[Preferences sharedInstance] showsHoldColorSliders];

    CGFloat scale = [_window backingScaleFactor];

    [leftSnapshot   setContents:GetSnapshotImageForView(leftContainer)];
    [middleSnapshot setContents:GetSnapshotImageForView(middleContainer)];
    [rightSnapshot  setContents:GetSnapshotImageForView(rightContainer)];

    [leftSnapshot   setContentsScale:scale];
    [middleSnapshot setContentsScale:scale];
    [rightSnapshot  setContentsScale:scale];

    setSnapshotsHidden(NO);

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [context setDuration:0.25];
        CGFloat xOffset  = showSliders ? -126.0 : 0.0;
        
        layout(leftContainer,   leftSnapshot,   &xOffset);
        layout(middleContainer, middleSnapshot, &xOffset);
        layout(rightContainer,  rightSnapshot,  &xOffset);

        [leftSnapshot  setOpacity:showSliders ? 0.0 : 1.0];
        [rightSnapshot setOpacity:showSliders ? 1.0 : 0.0];

    } completionHandler:^{
        setSnapshotsHidden(YES);
        [rightContainer setHidden:!_isHoldingColor];
    }];
}


- (id<CAAction>) actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    if (_isHoldingColor && [event isEqualToString:@"contents"]) {
        return (id<CAAction>)[NSNull null];
    }
    
    return nil;
}


#pragma mark - ResultViewDelegate

- (void) resultViewClicked:(ResultView *)view
{
    Preferences *preferences = [Preferences sharedInstance];

    if ([preferences clickInSwatchEnabled]) {
        NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSPasteboardNameGeneral];
        
        id<NSPasteboardWriting> pboardWriter = [self _pasteboardWriterForColorAction:[preferences clickInSwatchAction]];

        [pboard clearContents];
        [pboard writeObjects:[NSArray arrayWithObject:pboardWriter]];

        DoPopOutAnimation(view);
    }
}


- (void) resultView:(ResultView *)view dragInitiatedWithEvent:(NSEvent *)event
{
    Preferences *preferences = [Preferences sharedInstance];

    if ([preferences dragInSwatchEnabled]) {
        NSInteger action   = [preferences dragInSwatchAction];
        NSPoint   location = [event locationInWindow];

        location = [[self resultView] convertPoint:location fromView:nil];

        NSDraggingItem *item  = [self _draggingItemForColorAction:action cursorOffset:location];
        NSArray        *items = [NSArray arrayWithObject:item];

        [[self resultView] beginDraggingSessionWithItems:items event:event source:self];
    }
}


#pragma mark - Shortcuts

- (BOOL) performShortcut:(Shortcut *)shortcut
{
    Preferences *preferences = [Preferences sharedInstance];
    BOOL yn = NO;

    ColorAction colorAction = UnknownColorAction;

    if ([[preferences holdColorShortcut] isEqual:shortcut]) {
        [self holdColor:self];
        yn = YES;
    }
    
    if ([[preferences lockPositionShortcut] isEqual:shortcut]) {
        [self lockPosition:self];
        yn = YES;
    }
    
    if ([[preferences showApplicationShortcut] isEqual:shortcut]) {
        [NSApp activateIgnoringOtherApps:YES];
        [[self window] makeKeyAndOrderFront:self];
        yn = YES;
    }
    
    if ([[preferences nsColorSnippetShortcut] isEqual:shortcut]) {
        colorAction = CopyColorAsNSColorSnippet;
    } else if ([[preferences uiColorSnippetShortcut] isEqual:shortcut]) {
        colorAction = CopyColorAsUIColorSnippet;
    } else if ([[preferences hexColorSnippetShortcut] isEqual:shortcut]) {
        colorAction = CopyColorAsHexColorSnippet;
    } else if ([[preferences rgbColorSnippetShortcut] isEqual:shortcut]) {
        colorAction = CopyColorAsRGBColorSnippet;
    } else if ([[preferences rgbaColorSnippetShortcut] isEqual:shortcut]) {
        colorAction = CopyColorAsRGBAColorSnippet;
    }

    if (colorAction != UnknownColorAction) {
        [_aperture update];

        NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSPasteboardNameGeneral];
        
        id<NSPasteboardWriting> writer = [self _pasteboardWriterForColorAction:colorAction];
        [pboard clearContents];
        [pboard writeObjects:[NSArray arrayWithObject:writer]];

        DoPopOutAnimation([self resultView]);

        yn = YES;
    }

    return yn;
}


#pragma mark - IBActions

- (IBAction) changeColorMode:(id)sender
{
    NSInteger tag = [sender selectedTag];
    
    if ([[Preferences sharedInstance] usesDifferentColorSpaceInHoldColor] && _isHoldingColor) {
        [[Preferences sharedInstance] setHoldColorMode:tag];
    } else {
        [[Preferences sharedInstance] setColorMode:tag];
    }
}


- (IBAction) changeApertureOutline:(id)sender
{
    [[Preferences sharedInstance] setApertureOutline:[sender tag]];
}


- (IBAction) changeApertureSize:(id)sender
{
    [[Preferences sharedInstance] setApertureSize:[sender integerValue]];
}


- (IBAction) updateComponent:(id)sender
{
    ColorMode mode = [self _currentColorMode];

    BOOL isRGB = ColorModeIsRGB(mode);
    BOOL isHue = ColorModeIsHue(mode);

    ColorComponent component = ColorComponentNone;

    if (isRGB || isHue) {
        if ((sender == [self slider1]) || (sender == [self value1])) {
            component = isRGB ? ColorComponentRed :ColorComponentHue;

        } else if ((sender == [self slider2]) || (sender == [self value2])) {
            if (isRGB) {
                component = ColorComponentGreen;
            } else if (mode == ColorMode_HSB) {
                component = ColorComponentSaturationHSB;
            } else if (mode == ColorMode_HSL) {
                component = ColorComponentSaturationHSL;
            }

        } else if ((sender == [self slider3]) || (sender == [self value3])) {
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
    
        [_color setFloatValue:floatValue forComponent:component];
    }

    [self _updateColorViews];
    [self _updateSliders];
    [self _updateHoldLabels];
    [self _updateTextFields];
}


- (IBAction) showSnippets:(id)sender
{
    if (!_snippetsController) {
        _snippetsController = [[SnippetsController alloc] init];
    }
    
    [_snippetsController showWindow:self];
}


- (IBAction) showRecorder:(id)sender
{
    if (!_recorderController) {
        _recorderController = [[RecorderController alloc] init];
    }
    
    [_recorderController showWindow:self];
    [self _updateApertureTimer];
}


- (IBAction) toggleColorWindow:(id)sender
{
    NSWindow *colorWindow = [self colorWindow];
    BOOL      isVisible   = [colorWindow isVisible];

    if (isVisible) {
        [colorWindow orderOut:self];
    } else {
        [colorWindow makeKeyAndOrderFront:self];
    }
    
    [[Preferences sharedInstance] setShowsColorWindow:!isVisible];  
    [self _updateApertureTimer];
}


- (IBAction) toggleMiniWindow:(id)sender
{
    if (!_miniWindowController) {
        _miniWindowController = [[MiniWindowController alloc] init];
        [_miniWindowController updateColorMode:[self _currentColorMode]];
        [_miniWindowController updateColor:_color options:_colorStringOptions];
    }
    
    [_miniWindowController toggle];
    [self _updateApertureTimer];
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
    [[Preferences sharedInstance] setColorConversion:tag];
}


- (IBAction) writeTopLabelValueToPasteboard:(id)sender
{
    [self _writeString:[[self topHoldLabelButton] title] toPasteboard:[NSPasteboard generalPasteboard]];
    DoPopOutAnimation([self topHoldLabelButton]);
}


- (IBAction) writeBottomLabelValueToPasteboard:(id)sender
{
    [self _writeString:[[self bottomHoldLabelButton] title] toPasteboard:[NSPasteboard generalPasteboard]];
    DoPopOutAnimation([self bottomHoldLabelButton]);
}


- (IBAction) lockPosition:(id)sender
{
    BOOL xLocked = [_cursor isXLocked];
    BOOL yLocked = [_cursor isYLocked];
    
    if (!xLocked || !yLocked) {
        [_cursor setXLocked:YES yLocked:YES];
    } else {
        [_cursor setXLocked:NO yLocked:NO];
    }
    
    [self _updateStatusText];
    [[GuideController sharedInstance] update];
}


- (IBAction) lockX:(id)sender
{
    [_cursor setXLocked:![_cursor isXLocked]];
    [self _updateStatusText];
    [[GuideController sharedInstance] update];
}


- (IBAction) lockY:(id)sender
{
    [_cursor setYLocked:![_cursor isYLocked]];
    [self _updateStatusText];
    [[GuideController sharedInstance] update];
}


- (IBAction) toggleLockGuides:(id)sender
{
    Preferences *preferences = [Preferences sharedInstance];
    BOOL showsLockGuides = ![preferences showsLockGuides];
    [preferences setShowsLockGuides:showsLockGuides];
}


- (IBAction) updateMagnification:(id)sender
{
    NSInteger tag = [sender tag];
    [[Preferences sharedInstance] setZoomLevel:tag];
    [_aperture setZoomLevel:tag];
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
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSPasteboardNameGeneral];
    [self _addImage:image toPasteboard:pboard];
}


- (IBAction) saveImage:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    NSImage     *image     = [self _imageFromPreviewView];
    
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:(id)kUTTypeTIFF]];
    
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            [[image TIFFRepresentation] writeToURL:[savePanel URL] atomically:YES];
        }
    }];
}


- (IBAction) holdColor:(id)sender
{
    _isHoldingColor = !_isHoldingColor;

    [[self holdingLabel] setStringValue: NSLocalizedString(@"Holding Color", @"Status text: holding color")];

    [[self holdingLabel]  setHidden:!_isHoldingColor];
    [[self profileButton] setHidden:_isHoldingColor];

    // If coming from UI, we will have a sender.  Sender=nil for pasteTextAsColor:
//    if (sender) {
//        [self _updateScreenshot];
//    }

    [self _updatePopUpSelectionAndComponentLabels];
    [self _updateSliders];
    [self _updateTextFields];
    [self _updateHoldLabels];
    [self _updateApertureTimer];

    if ([[Preferences sharedInstance] showsHoldColorSliders]) {
        [self _animateSnapshotsIfNeeded];
    }
}


- (IBAction) pasteTextAsColor:(id)sender
{
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSPasteboardNameGeneral];
    NSString     *string = [pboard stringForType:NSPasteboardTypeString];

    Color *parsedColor = [Color colorWithString:string];
    if (parsedColor) {
        [_color setRed:[parsedColor red] green:[parsedColor green] blue:[parsedColor blue]];

        [self _updateColorViews];
        [self _updateTextFields];

        if (!_isHoldingColor) {
            [self holdColor:nil];
        } else {
            [self _updateSliders];
            [self _updateHoldLabels];
        }
        
    } else {
        NSBeep();
    }
}


- (IBAction) performColorActionForSender:(id)sender
{
    NSInteger tag = [sender tag];
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSPasteboardNameGeneral];
    
    id<NSPasteboardWriting> writer = [self _pasteboardWriterForColorAction:tag];
    
    [pboard clearContents];
    [pboard writeObjects:[NSArray arrayWithObject:writer]];
}


- (IBAction) sendFeedback:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:FeedbackURLString]];
}


- (IBAction) viewSite:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ProductSiteURLString]];
}


- (IBAction) viewPrivacyPolicy:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:PrivacyPolicyURLString]];
}


- (IBAction) learnAboutConversion:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ConversionsURLString]];
}


- (IBAction) viewOnAppStore:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:AppStoreURLString]];
}


@end
