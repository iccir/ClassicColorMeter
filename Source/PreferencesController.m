//
//  PreferencesController.m
//  ColorMeter
//
//  Created by Ricci Adams on 7/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PreferencesController.h"

#import "Preferences.h"

@interface PreferencesController () {
    NSPopUpButton *oApertureColorPopUp;
    NSPopUpButton *oHexCasePopUp;
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

    [oApertureColorPopUp setTarget:nil];  [oApertureColorPopUp setAction:NULL];
    [oHexCasePopUp       setTarget:nil];  [oHexCasePopUp       setAction:NULL];
    [oArrowKeysButton    setTarget:nil];  [oArrowKeysButton    setAction:NULL];
    [oShowSliderButton   setTarget:nil];  [oShowSliderButton   setAction:NULL];

    [self setApertureColorPopUp:nil];
    [self setHexCasePopUp:nil];
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
    [oHexCasePopUp       selectItemWithTag:[preferences usesLowercaseHex]];
    [oArrowKeysButton    setState:[preferences arrowKeysEnabled]];
    [oShowSliderButton   setState:[preferences showsHoldColorSliders]];
}


- (void) updatePreferences:(id)sender
{
    Preferences *preferences = [Preferences sharedInstance];

    if (sender == oApertureColorPopUp) {
        [preferences setApertureColor:[oApertureColorPopUp selectedTag]];

    } else if (sender == oHexCasePopUp) {
        [preferences setUsesLowercaseHex:[oHexCasePopUp selectedTag]];

    } else if (sender == oArrowKeysButton) {
        [preferences setArrowKeysEnabled:([oArrowKeysButton state] == NSOnState)];

    } else if (sender == oShowSliderButton) {
        [preferences setShowsHoldColorSliders:([oShowSliderButton state] == NSOnState)];
    }
}


@synthesize apertureColorPopUp = oApertureColorPopUp,
            hexCasePopUp       = oHexCasePopUp,
            arrowKeysButton    = oArrowKeysButton,
            showSliderButton   = oShowSliderButton;

@end
