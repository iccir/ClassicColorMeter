//
//  PreferencesController.h
//  ColorMeter
//
//  Created by Ricci Adams on 2011-07-28.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "PreferencesController.h"

#import "Preferences.h"

@interface PreferencesController () {
    NSPopUpButton *oApertureColorPopUp;

    NSButton      *oClickInSwatchButton;
    NSPopUpButton *oClickInSwatchPopUp;

    NSButton      *oDragInSwatchButton;
    NSPopUpButton *oDragInSwatchPopUp;

    NSButton      *oUseLowercaseHexButton;
    NSButton      *oArrowKeysButton;
    NSButton      *oShowSliderButton;
}

- (void) _handlePreferencesDidChange:(NSNotification *)note;

@end


@implementation PreferencesController

- (id) initWithWindow:(NSWindow *)window
{
    if ((self = [super initWithWindow:window])) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handlePreferencesDidChange:) name:PreferencesDidChangeNotification        object:nil];
    }
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [oApertureColorPopUp    setTarget:nil];  [oApertureColorPopUp    setAction:NULL];
    [oClickInSwatchButton   setTarget:nil];  [oClickInSwatchButton   setAction:NULL];
    [oClickInSwatchPopUp    setTarget:nil];  [oClickInSwatchPopUp    setAction:NULL];
    [oDragInSwatchButton    setTarget:nil];  [oDragInSwatchButton    setAction:NULL];
    [oDragInSwatchPopUp     setTarget:nil];  [oDragInSwatchPopUp     setAction:NULL];
    [oUseLowercaseHexButton setTarget:nil];  [oUseLowercaseHexButton setAction:NULL];
    [oArrowKeysButton       setTarget:nil];  [oArrowKeysButton       setAction:NULL];
    [oShowSliderButton      setTarget:nil];  [oShowSliderButton      setAction:NULL];

    [self setApertureColorPopUp:nil];
    [self setClickInSwatchButton:nil];
    [self setClickInSwatchPopUp:nil];
    [self setDragInSwatchButton:nil];
    [self setDragInSwatchPopUp:nil];
    [self setUseLowercaseHexButton:nil];
    [self setArrowKeysButton:nil];
    [self setShowSliderButton:nil];

    [super dealloc];
}


- (NSString *) windowNibName
{
    return @"Preferences";
}


- (void ) windowDidLoad
{
    [self _handlePreferencesDidChange:nil];
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    Preferences *preferences = [Preferences sharedInstance];

    [oApertureColorPopUp selectItemWithTag:[preferences apertureColor]];

    BOOL clickInSwatchEnabled = [preferences clickInSwatchEnabled];
    [oClickInSwatchButton setState:clickInSwatchEnabled];
    [oClickInSwatchPopUp  selectItemWithTag:[preferences clickInSwatchAction]];
    [oClickInSwatchPopUp  setEnabled:clickInSwatchEnabled];

    BOOL dragInSwatchEnabled = [preferences dragInSwatchEnabled];
    [oDragInSwatchButton  setState:dragInSwatchEnabled];
    [oDragInSwatchPopUp   selectItemWithTag:[preferences dragInSwatchAction]];
    [oDragInSwatchPopUp   setEnabled:dragInSwatchEnabled];

    [oUseLowercaseHexButton setState:[preferences usesLowercaseHex]];
    [oArrowKeysButton       setState:[preferences arrowKeysEnabled]];
    [oShowSliderButton      setState:[preferences showsHoldColorSliders]];
}


- (void) updatePreferences:(id)sender
{
    Preferences *preferences = [Preferences sharedInstance];

    if (sender == oApertureColorPopUp) {
        [preferences setApertureColor:[sender selectedTag]];

    } else if (sender == oClickInSwatchButton) {
        [preferences setClickInSwatchEnabled:([sender state] == NSOnState)];

    } else if (sender == oClickInSwatchPopUp) {
        [preferences setClickInSwatchAction:[sender selectedTag]];
    
    } else if (sender == oDragInSwatchButton) {
        [preferences setDragInSwatchEnabled:([sender state] == NSOnState)];

    } else if (sender == oDragInSwatchPopUp) {
        [preferences setDragInSwatchAction:[sender selectedTag]];

    } else if (sender == oUseLowercaseHexButton) {
        [preferences setUsesLowercaseHex:([sender state] == NSOnState)];
    
    } else if (sender == oArrowKeysButton) {
        [preferences setArrowKeysEnabled:([sender state] == NSOnState)];

    } else if (sender == oShowSliderButton) {
        [preferences setShowsHoldColorSliders:([sender state] == NSOnState)];
    }
}


@synthesize apertureColorPopUp    = oApertureColorPopUp,

            clickInSwatchButton   = oClickInSwatchButton,
            clickInSwatchPopUp    = oClickInSwatchPopUp,

            dragInSwatchButton    = oDragInSwatchButton,
            dragInSwatchPopUp     = oDragInSwatchPopUp,
            
            useLowercaseHexButton = oUseLowercaseHexButton,
            arrowKeysButton       = oArrowKeysButton,
            showSliderButton      = oShowSliderButton;

@end
