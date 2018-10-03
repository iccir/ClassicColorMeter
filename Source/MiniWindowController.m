//
//  PreferencesController.h
//  ColorMeter
//
//  Created by Ricci Adams on 2011-07-28.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "MiniWindowController.h"
#import "Preferences.h"

@interface MiniWindowController ()

@property (nonatomic, strong) IBOutlet NSVisualEffectView *miniEffectView;
@property (nonatomic, strong) IBOutlet NSView *miniMainView;

@property (nonatomic, strong) IBOutlet NSTextField *miniLabel1;
@property (nonatomic, strong) IBOutlet NSTextField *miniLabel2;
@property (nonatomic, strong) IBOutlet NSTextField *miniLabel3;

@property (nonatomic, strong) IBOutlet NSTextField *miniValue1;
@property (nonatomic, strong) IBOutlet NSTextField *miniValue2;
@property (nonatomic, strong) IBOutlet NSTextField *miniValue3;

@end


@implementation MiniWindowController {
    Color *_color;
    ColorMode _colorMode;
    ColorStringOptions _options;
}


- (id) initWithWindow:(NSWindow *)window
{
    if ((self = [super initWithWindow:window])) {
        _colorMode = -1;
    }
    
    return self;
}


- (NSString *) windowNibName
{
    return @"MiniWindow";
}


- (void) toggle
{
    if ([[self window] isVisible]) {
        [[self window] orderOut:nil];
        [[Preferences sharedInstance] setShowsMiniWindow:NO];
        
    } else {
        [[self window] orderFront:nil];
        [[Preferences sharedInstance] setShowsMiniWindow:YES];
    }
}


- (void) windowDidLoad
{
    [super windowDidLoad];
    
    [_miniMainView setFrame:[_miniEffectView bounds]];
    [_miniMainView setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];
    [_miniEffectView addSubview:_miniMainView];

    CGFloat  pointSize      = [[[self miniValue1] font] pointSize];
    NSFont  *monospacedFont = [NSFont monospacedDigitSystemFontOfSize:pointSize weight:NSFontWeightRegular];

    [[self miniValue1] setFont:monospacedFont];
    [[self miniValue2] setFont:monospacedFont];
    [[self miniValue3] setFont:monospacedFont];

    void (^setupMiniLabel)(NSTextField *) = ^(NSTextField *miniLabel) {
        [miniLabel setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
        [miniLabel setTextColor:[NSColor secondaryLabelColor]];
    };

    [[self window] setLevel:NSFloatingWindowLevel];

    setupMiniLabel([self miniLabel1]);
    setupMiniLabel([self miniLabel2]);
    setupMiniLabel([self miniLabel3]);
    
    [self _updateColorModeLabels];
}


- (void) _updateColorModeLabels
{
    NSArray *labels  = ColorModeGetComponentLabels(_colorMode);
    NSArray *longest = ColorModeGetLongestStrings(_colorMode);
    
    NSTextField *miniLabel1 = [self miniLabel1];
    NSTextField *miniLabel2 = [self miniLabel2];
    NSTextField *miniLabel3 = [self miniLabel3];

    NSTextField *miniValue1 = [self miniValue1];
    NSTextField *miniValue2 = [self miniValue2];
    NSTextField *miniValue3 = [self miniValue3];
    
    if (!miniLabel1) return;

    if ([labels count] == 3) {
        [miniLabel1 setStringValue:[labels objectAtIndex:0]];
        [miniLabel2 setStringValue:[labels objectAtIndex:1]];
        [miniLabel3 setStringValue:[labels objectAtIndex:2]];
    }
    
    if ([longest count] == 3) {
        [miniValue1 setStringValue:[longest objectAtIndex:0]];
        [miniValue2 setStringValue:[longest objectAtIndex:1]];
        [miniValue3 setStringValue:[longest objectAtIndex:2]];
    }
    
    CGFloat y = [miniLabel1 frame].origin.y;

    [miniLabel1 setFrame:NSMakeRect(8, y, 9999, 9999)];
    [miniLabel1 sizeToFit];

    [miniValue1 setFrame:NSMakeRect(NSMaxX([miniLabel1 frame]) + 4, y, 9999, 9999)];
    [miniValue1 sizeToFit];

    [miniLabel2 setFrame:NSMakeRect(NSMaxX([miniValue1 frame]) + 8, y, 9999, 9999)];
    [miniLabel2 sizeToFit];

    [miniValue2 setFrame:NSMakeRect(NSMaxX([miniLabel2 frame]) + 4, y, 9999, 9999)];
    [miniValue2 sizeToFit];

    [miniLabel3 setFrame:NSMakeRect(NSMaxX([miniValue2 frame]) + 8, y, 9999, 9999)];
    [miniLabel3 sizeToFit];

    [miniValue3 setFrame:NSMakeRect(NSMaxX([miniLabel3 frame]) + 4, y, 9999, 9999)];
    [miniValue3 sizeToFit];
    
    CGFloat maxX = NSMaxX([miniValue3 frame]) + 8;
    
    NSRect frame = [[self window] frame];
    frame.size.width = maxX;
    [[self window] setFrame:frame display:YES];
    
    [self _updateTextFields];
}


- (void) _updateTextFields
{
    NSString * __autoreleasing strings[3];
    [_color getComponentsForMode:_colorMode options:(_options | ColorStringForMiniWindow) outOfRange:NULL strings:strings];

    if (strings[0]) [[self miniValue1] setStringValue:strings[0]];
    if (strings[1]) [[self miniValue2] setStringValue:strings[1]];
    if (strings[2]) [[self miniValue3] setStringValue:strings[2]];
}


- (void) updateColorMode:(ColorMode)colorMode
{
    if (_colorMode != colorMode) {
        _colorMode = colorMode;
        [self _updateColorModeLabels];
    }
}


- (void) updateColor:(Color *)color options:(ColorStringOptions)options
{
    _color = color;
    _options = options;

    [self _updateTextFields];
}   


@end
