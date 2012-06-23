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
#import "EtchingView.h"
#import "GuideController.h"
#import "MouseCursor.h"
#import "Preferences.h"
#import "PreferencesController.h"
#import "PreviewView.h"
#import "RecessedButton.h"
#import "ResultView.h"
#import "Shortcut.h"
#import "ShortcutManager.h"
#import "SnippetsController.h"
#import "Util.h"


typedef enum : NSInteger {
    CopyColorAsColor            = 0,

    CopyColorAsText             = 1,
    CopyColorAsImage            = 2,

    CopyColorAsNSColorSnippet   = 3,
    CopyColorAsUIColorSnippet   = 4,
    CopyColorAsHexColorSnippet  = 5,
    CopyColorAsRGBColorSnippet  = 6,
    CopyColorAsRGBAColorSnippet = 7
} ColorAction;


static NSString * const sFeedbackURL = @"http://iccir.com/feedback/ClassicColorMeter";

@class PreviewView;

@interface AppDelegate () <ApertureDelegate> {
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

    MouseCursor           *_cursor;
    Aperture              *_aperture;

    BOOL           _isHoldingColor;
    Color         *_color;
    
    // Cached prefs
    ColorMode        _colorMode;
    NSInteger        _showMouseCoordinates;
    BOOL             _usesLowercaseHex;
    BOOL             _usesPoundPrefix;
}

@end


@implementation AppDelegate

@synthesize window                = o_window,
            leftContainer         = o_leftContainer,
            middleContainer       = o_middleContainer,
            rightContainer        = o_rightContainer,
            colorModePopUp        = o_colorModePopUp,
            previewView           = o_previewView,
            resultView            = o_resultView,
            apertureSizeLabel     = o_apertureSizeLabel,
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
            slider3               = o_slider3,
            colorWindow           = o_colorWindow,
            colorResultView       = o_colorResultView;


- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _cursor   = [MouseCursor sharedInstance];
    _color    = [[Color alloc] init];
    _aperture = [[Aperture alloc] init];
    
    [_aperture setDelegate:self];

    [(ColorSliderCell *)[o_slider1 cell] setColor:_color];
    [(ColorSliderCell *)[o_slider2 cell] setColor:_color];
    [(ColorSliderCell *)[o_slider3 cell] setColor:_color];
    [o_resultView setColor:_color];
    [o_colorResultView setColor:_color];
    
    [o_resultView setDelegate:self];
    [o_colorResultView setDelegate:self];
    
    [o_rightContainer setHidden:YES];

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
    
    NSRect frame = [o_window frame];
    frame.size.width = 316;
    [o_window setFrame:frame display:NO animate:NO];

    [o_window setContentBorderThickness:0.0 forEdge:NSMinYEdge];
    [o_window setContentBorderThickness:172.0 forEdge:NSMaxYEdge];
    [o_window setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
    [o_window setAutorecalculatesContentBorderThickness:NO forEdge:NSMaxYEdge];

    [[o_apertureSizeLabel cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [[o_holdingLabel      cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [[o_label1            cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [[o_label2            cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [[o_label3            cell] setBackgroundStyle:NSBackgroundStyleRaised];

    [self _setupHoldAnimation];

    [self _handlePreferencesDidChange:nil];
    
    [_aperture update];
    
    [o_resultView setDrawsBorder:YES];
    
    [o_window makeKeyAndOrderFront:self];
    [o_window selectPreviousKeyView:self];
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

        NSInteger state = NSOffState;

        if (xLocked && yLocked) {
            state = NSOnState;
        } else if (xLocked || yLocked) {
            state = NSMixedState;
        }

        [menuItem setState:state];
    
    } else if (action == @selector(lockX:)) {
        [menuItem setState:[_cursor isXLocked]];

    } else if (action == @selector(lockY:)) {
        [menuItem setState:[_cursor isYLocked]];
        
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

    } else if (action == @selector(showSnippets:)) {
        NSUInteger flags     = [NSEvent modifierFlags];
        NSUInteger mask      = NSControlKeyMask | NSCommandKeyMask | NSAlternateKeyMask;
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
    [o_resultView setNeedsDisplay:YES];
    [o_colorResultView setNeedsDisplay:YES];
    [o_slider1 setNeedsDisplay:YES];
    [o_slider2 setNeedsDisplay:YES];
    [o_slider3 setNeedsDisplay:YES];
}

- (void) _updateHoldLabels
{
    ColorMode mode      = [self _currentColorMode];
    BOOL      lowercase = _usesLowercaseHex;
    Color    *color     = _color;

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
        while   (h < 0)   h += 360;
        if      (s > 100) s = 100;
        else if (s < 0)   s = 0;
        if      (b > 100) b = 100;
        else if (b < 0)   b = 0;

        NSString *hsbString = [NSString stringWithFormat:@"%ld%C, %ld%%, %ld%%", h, (unsigned short)0x00b0, s, b];

        [o_topHoldLabelButton    setTitle:hsbString];
        [o_bottomHoldLabelButton setTitle:hexString];

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

        [o_topHoldLabelButton    setTitle:decimalString];
        [o_bottomHoldLabelButton setTitle:hexString];
    }
}


- (void) _updatePopUpAndComponentLabels
{
    ColorMode colorMode = [self _currentColorMode];

    [o_colorModePopUp selectItemWithTag:colorMode];

    NSArray *labels = ColorModeGetComponentLabels(colorMode);
    if ([labels count] == 3) {
        [o_label1 setStringValue:[labels objectAtIndex:0]];
        [o_label2 setStringValue:[labels objectAtIndex:1]];
        [o_label3 setStringValue:[labels objectAtIndex:2]];
    }
}


- (void) _updateSliders
{
    ColorMode colorMode = [self _currentColorMode];

    NSSlider *slider1   = o_slider1;
    NSSlider *slider2   = o_slider2;
    NSSlider *slider3   = o_slider3;
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
    ColorMode colorMode = [self _currentColorMode];

    NSString * __autoreleasing strings[3];
    NSColor  * __autoreleasing colors[3];

    [_color getComponentsForMode:colorMode options:[self _colorStringOptions] strings:strings colors:colors];

    if (strings[0]) [o_value1 setStringValue:strings[0]];
    if (strings[1]) [o_value2 setStringValue:strings[1]];
    if (strings[2]) [o_value3 setStringValue:strings[2]];
    
    static NSColor *sRedColor = nil;
    static NSColor *sBlackColor = nil;
    
    if (!sRedColor) {
        sRedColor   = [NSColor redColor];
        sBlackColor = [NSColor blackColor];
    }

    BOOL isEditable = (ColorModeIsRGB(colorMode) || ColorModeIsHue(colorMode)) && _isHoldingColor;

    if (isEditable) {
        NSColor *black = [NSColor blackColor];

        [o_value1 setTextColor:black];
        [o_value2 setTextColor:black];
        [o_value3 setTextColor:black];

    } else {
        [o_value1 setTextColor:colors[0]];
        [o_value2 setTextColor:colors[1]];
        [o_value3 setTextColor:colors[2]];
    }

    [o_value1 setEditable:isEditable];
    [o_value2 setEditable:isEditable];
    [o_value3 setEditable:isEditable];
}


- (void) aperture:(Aperture *)aperture didUpdateImage:(CGImageRef)image
{
    if (!_isHoldingColor) {
        [_aperture averageAndUpdateColor:_color];

        [self _updateColorViews];
        [self _updateTextFields];
    }

    [o_previewView setImage:image];
    [o_previewView setOffset:[_aperture offset]];
    [o_previewView setImageScale:[_aperture scaleFactor]];
    [o_previewView setApertureRect:[_aperture apertureRect]];
}


- (void) apertureDidUpdateColorProfile:(Aperture *)aperture
{
    [self _updateStatusText];
}


#pragma mark -
#pragma mark Private Methods

- (ColorStringOptions) _colorStringOptions
{
    ColorStringOptions options = 0;
    if (_usesLowercaseHex) options |= ColorStringUsesLowercaseHex;
    if (_usesPoundPrefix)  options |= ColorStringUsesPoundPrefix;
        
    return options;
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    Preferences *preferences  = [Preferences sharedInstance];
    NSInteger    apertureSize = [preferences apertureSize];

    _usesLowercaseHex     = [preferences usesLowercaseHex];
    _usesPoundPrefix      = [preferences usesPoundPrefix];
    _colorMode            = [preferences colorMode];
    _showMouseCoordinates = [preferences showMouseCoordinates];

    BOOL showsHoldLabels = [preferences showsHoldLabels];
    [o_topHoldLabelButton    setHidden:!showsHoldLabels];
    [o_bottomHoldLabelButton setHidden:!showsHoldLabels];

    BOOL showsLockGuides = [[Preferences sharedInstance] showsLockGuides];
    [[GuideController sharedInstance] setEnabled:showsLockGuides];

    [o_apertureSizeSlider setIntegerValue:apertureSize];
    [o_previewView setShowsLocation:[preferences showMouseCoordinates]];
    [o_previewView setApertureColor:[preferences apertureColor]];
    [o_previewView setZoomLevel:[preferences zoomLevel]];

    [o_resultView setClickEnabled:[preferences clickInSwatchEnabled]];
    [o_resultView setDragEnabled: [preferences dragInSwatchEnabled]];
    [o_colorResultView setClickEnabled:[preferences clickInSwatchEnabled]];
    [o_colorResultView setDragEnabled: [preferences dragInSwatchEnabled]];

    [_aperture setZoomLevel:[preferences zoomLevel]];
    [_aperture setUpdatesContinuously:[preferences updatesContinuously]];
    [_aperture setApertureSize:apertureSize];
    [_aperture setColorConversion:[preferences colorConversion]];

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
        [o_window setLevel:NSFloatingWindowLevel];
    } else {
        [o_window setLevel:NSNormalWindowLevel];
    }

    [self _updatePopUpAndComponentLabels];
    [self _updateSliders];
    [self _updateHoldLabels];
    [self _updateTextFields];
    [self _updateStatusText];
    
    if (_isHoldingColor) {
        [self _animateSnapshotsIfNeeded];
    }
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

        [o_previewView setStatusText:[status componentsJoinedByString:@", "]];
    } else {
        [o_previewView setStatusText:nil];
    }

    // Update color profile status
    {
        NSString *label = [_aperture colorProfileLabel];
        
        if (_colorMode == ColorMode_CIE_Lab) {
            label = [label stringByAppendingFormat:@"%@%@", GetArrowJoinerString(), NSLocalizedString(@"Lab", nil)];
        } else if (ColorModeIsXYZ(_colorMode)) {
            label = [label stringByAppendingFormat:@"%@%@", GetArrowJoinerString(), NSLocalizedString(@"XYZ", nil)];
        }

        [o_profileButton setTitle:label];
    }
}


- (NSImage *) _imageFromPreviewView
{
    NSSize   size  = [o_previewView bounds].size;
    NSImage *image = [[NSImage alloc] initWithSize:size];
    
    [image lockFocus];
    [o_previewView drawRect:[o_previewView bounds]];
    [image unlockFocus];
    
    return image;
}


- (NSEvent *) _handleLocalEvent:(NSEvent *)event
{
    if (![o_window isKeyWindow]) {
        return event;
    }

    NSEventType type = [event type];

    if (type == NSKeyDown) {
        NSUInteger modifierFlags = [event modifierFlags];

        id        firstResponder = [o_window firstResponder];
        NSString *characters     = [event charactersIgnoringModifiers];
        unichar   c              = [characters length] ? [characters characterAtIndex:0] : 0; 
        BOOL      isShift        = (modifierFlags & NSShiftKeyMask)   > 0;
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


#pragma mark -
#pragma mark Pasteboard / Dragging

- (id<NSPasteboardWriting>) _pasteboardWriterForColorAction:(ColorAction)actionTag
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
        
        clipboardText = [_color clipboardStringForMode:mode options:[self _colorStringOptions]];
        
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
        clipboardText = [_color codeSnippetForTemplate:template options:[self _colorStringOptions]];
        
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
        [o_leftContainer   setHidden:!yn];
        [o_middleContainer setHidden:!yn];
        [o_rightContainer  setHidden:!yn];
        [_layerContainer   setHidden: yn];
    };
    
    void (^layout)(NSView *, CALayer *, CGFloat *) = ^(NSView *view, CALayer *layer, CGFloat *inOutX) {
        CGRect frame = [view frame];
        frame.origin.x = (*inOutX) + 6;

        [view  setFrame:frame];
        [layer setFrame:frame];

        *inOutX = NSMaxX(frame);
    };
    
    BOOL showSliders = _isHoldingColor && [[Preferences sharedInstance] showsHoldColorSliders];
    CGFloat xOffset  = showSliders ? -126.0 : 0.0;

    NSDisableScreenUpdates();
    {
        setSnapshotsHidden(NO);

        [CATransaction setAnimationDuration:0.3];
        [CATransaction setCompletionBlock:^{
            NSDisableScreenUpdates();

            setSnapshotsHidden(YES);
            [o_rightContainer setHidden:!_isHoldingColor];
            [o_window displayIfNeeded];

            NSEnableScreenUpdates();
        }];

        [_leftSnapshot   setContents:GetSnapshotImageForView(o_leftContainer)];
        [_middleSnapshot setContents:GetSnapshotImageForView(o_middleContainer)];
        [_rightSnapshot  setContents:GetSnapshotImageForView(o_rightContainer)];

        layout(o_leftContainer,   _leftSnapshot,   &xOffset);
        layout(o_middleContainer, _middleSnapshot, &xOffset);
        layout(o_rightContainer,  _rightSnapshot,  &xOffset);

        [_leftSnapshot  setOpacity:showSliders ? 0.0 : 1.0];
        [_rightSnapshot setOpacity:showSliders ? 1.0 : 0.0];

        [o_window displayIfNeeded];
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
        
        [view doPopOutAnimation];
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

    ColorAction colorAction = -1;

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
        [o_window makeKeyAndOrderFront:self];
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

    if (colorAction != -1) {
        NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
        
        id<NSPasteboardWriting> writer = [self _pasteboardWriterForColorAction:colorAction];
        [pboard clearContents];
        [pboard writeObjects:[NSArray arrayWithObject:writer]];

        [o_resultView doPopOutAnimation];

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
    ColorMode mode = [self _currentColorMode];

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
    [self _writeString:[o_topHoldLabelButton title] toPasteboard:[NSPasteboard generalPasteboard]];
    [o_topHoldLabelButton doPopOutAnimation];
}


- (IBAction) writeBottomLabelValueToPasteboard:(id)sender
{
    [self _writeString:[o_bottomHoldLabelButton title] toPasteboard:[NSPasteboard generalPasteboard]];
    [o_bottomHoldLabelButton doPopOutAnimation];
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


- (IBAction) updateMagnification:(id)sender
{
    NSInteger tag = [sender tag];
    [[Preferences sharedInstance] setZoomLevel:[sender tag]];
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


- (IBAction) showColorWindow:(id)sender
{
    [o_colorWindow makeKeyAndOrderFront:self];
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
    _isHoldingColor = !_isHoldingColor;

    [o_holdingLabel setHidden:!_isHoldingColor];
    [o_holdingLabel setStringValue: NSLocalizedString(@"Holding Color", @"Status text: holding color")];
    [o_profileButton setHidden:_isHoldingColor];

    // If coming from UI, we will have a sender.  Sender=nil for pasteTextAsColor:
//    if (sender) {
//        [self _updateScreenshot];
//    }

    [self _updatePopUpAndComponentLabels];
    [self _updateSliders];
    [self _updateTextFields];
    [self _updateHoldLabels];

    if ([[Preferences sharedInstance] showsHoldColorSliders]) {
        [self _animateSnapshotsIfNeeded];
    }
}


- (IBAction) pasteTextAsColor:(id)sender
{
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    NSString     *string = [pboard stringForType:NSPasteboardTypeString];

    Color *parsedColor = [Color colorWithString:string];
    if (parsedColor) {
        [_color setRed:[parsedColor red] green:[parsedColor green] blue:[parsedColor blue]];

        [self _updateColorViews];
        [self _updateTextFields];

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

@end
