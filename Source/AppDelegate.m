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
#import "ColorCalculator.h"
#import "EtchingView.h"
#import "Preferences.h"
#import "PreviewView.h"
#import "ResultView.h"

static NSString * const sFeedbackURL = @"http://iccir.com/feedback/ClassicColorMeter";

@class PreviewView;

@interface AppDelegate () {
    NSWindow      *oWindow;
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

    Preferences   *_preferences;

    NSTimer       *_timer;
    NSPoint        _lastMouseLocation;
    NSTimeInterval _lastMouseTimeInterval;
    CGFloat        _screenZeroHeight;

    CGFloat        _lockedX;
    CGFloat        _lockedY;
    
    CGRect         _screenBounds;
    CGRect         _apertureRect;
    
    BOOL           _isHoldingColor;
    Color          _color;
    
    // Cached prefs
    ColorMode      _colorMode;
    NSInteger      _zoomLevel;
    NSInteger      _updatesContinuously;
    NSInteger      _showMouseCoordinates;
}

- (void) _updateStatusText;
- (void) _handlePreferencesDidChange:(NSNotification *)note;
- (void) _handleScreenColorSpaceDidChange:(NSNotification *)note;

@end


@implementation AppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _preferences = [[Preferences sharedInstance] retain];

    _lockedX               = NAN;
    _lockedY               = NAN;
    _lastMouseLocation     = NSMakePoint(NAN, NAN);
    _lastMouseTimeInterval = NAN;
    _zoomLevel             = 1.0;

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
        NSString   *title = ColorCalculatorGetName(mode);
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
    addMenu( ColorMode_YPbPr_601   );
    addMenu( ColorMode_YPbPr_709   );
    addMenu( ColorMode_YCbCr_601   );
    addMenu( ColorMode_YCbCr_709   );
    [menu addItem:[NSMenuItem separatorItem]];
    addMenu( ColorMode_CIE_1931    );
    addMenu( ColorMode_CIE_1976    );
    addMenu( ColorMode_CIE_Lab     );
    addMenu( ColorMode_Tristimulus );
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handlePreferencesDidChange:)      name:PreferencesDidChangeNotification        object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleScreenColorSpaceDidChange:) name:NSScreenColorSpaceDidChangeNotification object:nil];
    
    [self applicationDidChangeScreenParameters:nil];
    [self _updateStatusText];
    [self _handlePreferencesDidChange:nil];
    [self _handleScreenColorSpaceDidChange:nil];
}


- (void) dealloc
{
    [_preferences release];  _preferences = nil;
    [_timer       release];  _timer       = nil;

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

    if (action == @selector(changeApertureColor:)) {
        [menuItem setState:([menuItem tag] == [_preferences apertureColor])];
    
    } else if (action == @selector(lockPosition:)) {
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
        [menuItem setState:[_preferences floatWindow]];
    }

    return YES;
}


- (void) windowWillClose:(NSNotification *)note
{
    if ([note object] == oWindow) {
        [NSApp terminate:self];
    }
}


#pragma mark -
#pragma mark Private Methods

- (void) _updateScreenshot
{
    CGPoint locationToUse = _lastMouseLocation;
    
    if (!isnan(_lockedX)) locationToUse.x = _lockedX;
    if (!isnan(_lockedY)) locationToUse.y = _lockedY;

    CGPoint convertedPoint  = CGPointMake(locationToUse.x, _screenZeroHeight - locationToUse.y);

    CGRect screenBounds = _screenBounds;
    screenBounds.origin.x += convertedPoint.x;
    screenBounds.origin.y += convertedPoint.y;
    CGImageRef screenShot = CGWindowListCreateImage(screenBounds, kCGWindowListOptionAll, kCGNullWindowID, kCGWindowImageDefault);
    
    if (!_isHoldingColor) {
        ColorCalculatorGetAverageColor(screenShot, _apertureRect, &_color);
    }

    [oResultView setColor:_color];
    
    NSString *value1    = nil;
    NSString *value2    = nil;
    NSString *value3    = nil;
    NSString *clipboard = nil;
    ColorCalculatorCalculate(CGMainDisplayID(), _colorMode, &_color, &value1, &value2, &value3, &clipboard);

    if (value1) [oValue1 setStringValue:value1];
    if (value2) [oValue2 setStringValue:value2];
    if (value3) [oValue3 setStringValue:value3];

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
    BOOL needsUpdateTick  = (now - _lastMouseTimeInterval > 0.5);

    if (didMouseMove) {
        _lastMouseLocation     = mouseLocation;
        _lastMouseTimeInterval = now;
    }
    
    if (_updatesContinuously || didMouseMove || needsUpdateTick) {
        [self _updateScreenshot];
    }
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    NSInteger apertureSize = [_preferences apertureSize];

    _colorMode            = [_preferences colorMode];
    _zoomLevel            = [_preferences zoomLevel];
    _updatesContinuously  = [_preferences updatesContinuously];
    _showMouseCoordinates = [_preferences showMouseCoordinates];

    [oApertureSizeSlider setIntegerValue:apertureSize];
    [oColorModePopUp selectItemWithTag:[_preferences colorMode]];
    [oPreviewView setShowsLocation:[_preferences showMouseCoordinates]];
    [oPreviewView setApertureSize:apertureSize];
    [oPreviewView setApertureColor:[_preferences apertureColor]];

    if ([_preferences floatWindow]) {
        [oWindow setLevel:NSFloatingWindowLevel];
    } else {
        [oWindow setLevel:NSNormalWindowLevel];
    }

    NSArray *labels = ColorCalculatorGetComponentLabels(_colorMode);
    if ([labels count] == 3) {
        [oLabel1 setStringValue:[labels objectAtIndex:0]];
        [oLabel2 setStringValue:[labels objectAtIndex:1]];
        [oLabel3 setStringValue:[labels objectAtIndex:2]];
    }

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


- (void) _copyImageToClipboard:(NSImage *)image
{
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];

    [pboard clearContents];
    [pboard addTypes:[NSArray arrayWithObjects:NSPasteboardTypeTIFF, nil] owner:nil];
    [pboard setData:[image TIFFRepresentation] forType:NSPasteboardTypeTIFF];
}


#pragma mark -
#pragma mark IBActions

- (IBAction) changeColorMode:(id)sender
{
    NSInteger tag = [sender selectedTag];
    [_preferences setColorMode:tag];
}


- (IBAction) changeApertureSize:(id)sender
{
    [_preferences setApertureSize:[sender integerValue]];
}


- (IBAction) changeApertureColor:(id)sender
{
    [_preferences setApertureColor:[sender tag]];
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
    [_preferences setZoomLevel:[sender tag]];
    _zoomLevel = tag;

    [self _updateScreenshot];
}


- (IBAction) toggleContinuous:(id)sender
{
    BOOL updatesContinuously = ![_preferences updatesContinuously];
    [_preferences setUpdatesContinuously:updatesContinuously];
}


- (IBAction) toggleMouseLocation:(id)sender
{
    BOOL showMouseCoordinates = ![_preferences showMouseCoordinates];
    [_preferences setShowMouseCoordinates:showMouseCoordinates];
}


- (IBAction) toggleFloatWindow:(id)sender
{
    BOOL floatWindow = ![_preferences floatWindow];
    [_preferences setFloatWindow:floatWindow];
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
}


- (IBAction) copyColorAsText:(id)sender
{
    NSString *unused1, *unused2, *unused3;
    NSString *clipboard = nil;

    ColorCalculatorCalculate(CGMainDisplayID(), _colorMode, &_color, &unused1, &unused2, &unused3, &clipboard);

    if (clipboard) {
        NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
        [pboard clearContents];
        [pboard addTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:nil];
        [pboard setString:clipboard forType:NSPasteboardTypeString];
    }
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


- (IBAction) sendFeedback:(id)sender
{
    NSURL *url = [NSURL URLWithString:sFeedbackURL];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


#pragma mark -
#pragma mark Accessors

@synthesize window             = oWindow,
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
            value3             = oValue3;

@end
