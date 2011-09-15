//
//  PreferencesController.h
//  ColorMeter
//
//  Created by Ricci Adams on 2011-07-28.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "PreferencesController.h"

#import "Preferences.h"
#import "ShortcutView.h"

@interface PreferencesController () {
    NSPopUpButton *oApertureColorPopUp;
    NSPopUpButton *oHoldSlidersPopUp;

    NSButton      *oClickInSwatchButton;
    NSPopUpButton *oClickInSwatchPopUp;

    NSButton      *oDragInSwatchButton;
    NSPopUpButton *oDragInSwatchPopUp;

    NSButton      *oUseLowercaseHexButton;
    NSButton      *oUsePoundPrefixButton;
    NSButton      *oArrowKeysButton;
    NSButton      *oShowsHoldColorSlidersButton;
    NSButton      *oUsesDifferentColorSpaceInHoldColorButton;
    NSButton      *oUsesMainColorSpaceForCopyAsTextButton;
    
    ShortcutView  *oShowApplicationShortcutView;
    ShortcutView  *oHoldColorShortcutView;
}

- (void) _handlePreferencesDidChange:(NSNotification *)note;

@end


@implementation PreferencesController

- (id) initWithWindow:(NSWindow *)window
{
    if ((self = [super initWithWindow:window])) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handlePreferencesDidChange:) name:PreferencesDidChangeNotification object:nil];
    }
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [oApertureColorPopUp setTarget:nil];
    [oApertureColorPopUp setAction:NULL];
    [oApertureColorPopUp release];
    oApertureColorPopUp = nil;

    [oClickInSwatchButton setTarget:nil];
    [oClickInSwatchButton setAction:NULL];
    [oClickInSwatchButton release];
    oClickInSwatchButton = nil;

    [oClickInSwatchPopUp setTarget:nil];
    [oClickInSwatchPopUp setAction:NULL];
    [oClickInSwatchPopUp release];
    oClickInSwatchPopUp = nil;

    [oDragInSwatchButton setTarget:nil];
    [oDragInSwatchButton setAction:NULL];
    [oDragInSwatchButton release];
    oDragInSwatchButton = nil;

    [oDragInSwatchPopUp setTarget:nil];
    [oDragInSwatchPopUp setAction:NULL];
    [oDragInSwatchPopUp release];
    oDragInSwatchPopUp = nil;

    [oUseLowercaseHexButton setTarget:nil];
    [oUseLowercaseHexButton setAction:NULL];
    [oUseLowercaseHexButton release];
    oUseLowercaseHexButton = nil;

    [oArrowKeysButton setTarget:nil];
    [oArrowKeysButton setAction:NULL];
    [oArrowKeysButton release];
    oArrowKeysButton = nil;

    [oUsePoundPrefixButton setTarget:nil];
    [oUsePoundPrefixButton setAction:NULL];
    [oUsePoundPrefixButton release];
    oUsePoundPrefixButton  = nil;

    [oShowsHoldColorSlidersButton setTarget:nil];
    [oShowsHoldColorSlidersButton setAction:NULL];
    [oShowsHoldColorSlidersButton release];
    oShowsHoldColorSlidersButton = nil;

    [oUsesDifferentColorSpaceInHoldColorButton setTarget:nil];
    [oUsesDifferentColorSpaceInHoldColorButton setAction:NULL];
    [oUsesDifferentColorSpaceInHoldColorButton release];
    oUsesDifferentColorSpaceInHoldColorButton = nil;

    [oUsesMainColorSpaceForCopyAsTextButton setTarget:nil];
    [oUsesMainColorSpaceForCopyAsTextButton setAction:NULL];
    [oUsesMainColorSpaceForCopyAsTextButton release];
    oUsesMainColorSpaceForCopyAsTextButton = nil;

    [oShowApplicationShortcutView setTarget:nil];
    [oShowApplicationShortcutView setAction:NULL];
    [oShowApplicationShortcutView release];
    oShowApplicationShortcutView = nil;

    [oHoldColorShortcutView setTarget:nil];
    [oHoldColorShortcutView setAction:NULL];
    [oHoldColorShortcutView release];
    oHoldColorShortcutView = nil;

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
    [oUsePoundPrefixButton  setState:[preferences usesPoundPrefix]];
    [oArrowKeysButton       setState:[preferences arrowKeysEnabled]];

    [oShowsHoldColorSlidersButton              setState:[preferences showsHoldColorSliders]];

    BOOL usesDifferentColorSpaceInHoldColor = [preferences usesDifferentColorSpaceInHoldColor];

    [oUsesDifferentColorSpaceInHoldColorButton setState:usesDifferentColorSpaceInHoldColor];
    [oUsesMainColorSpaceForCopyAsTextButton setEnabled:usesDifferentColorSpaceInHoldColor];
    [oUsesMainColorSpaceForCopyAsTextButton setState:[preferences usesMainColorSpaceForCopyAsText]];

    [oShowApplicationShortcutView setShortcut:[preferences showApplicationShortcut]];
    [oHoldColorShortcutView setShortcut:[preferences holdColorShortcut]];
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

    } else if (sender == oUsePoundPrefixButton) {
        [preferences setUsesPoundPrefix:([sender state] == NSOnState)];

    } else if (sender == oArrowKeysButton) {
        [preferences setArrowKeysEnabled:([sender state] == NSOnState)];

    } else if (sender == oShowsHoldColorSlidersButton) {
        [preferences setShowsHoldColorSliders:([sender state] == NSOnState)];

    } else if (sender == oUsesDifferentColorSpaceInHoldColorButton) {
        [preferences setUsesDifferentColorSpaceInHoldColor:([sender state] == NSOnState)];

    } else if (sender == oUsesMainColorSpaceForCopyAsTextButton) {
        [preferences setUsesMainColorSpaceForCopyAsText:([sender state] == NSOnState)];

    } else if (sender == oShowApplicationShortcutView) {
        [preferences setShowApplicationShortcut:[oShowApplicationShortcutView shortcut]];
    
    } else if (sender == oHoldColorShortcutView) {
        [preferences setHoldColorShortcut:[oHoldColorShortcutView shortcut]];
    }
}


@synthesize apertureColorPopUp    = oApertureColorPopUp,

            clickInSwatchButton   = oClickInSwatchButton,
            clickInSwatchPopUp    = oClickInSwatchPopUp,

            dragInSwatchButton    = oDragInSwatchButton,
            dragInSwatchPopUp     = oDragInSwatchPopUp,
            
            useLowercaseHexButton = oUseLowercaseHexButton,
            usePoundPrefixButton  = oUsePoundPrefixButton,
            arrowKeysButton       = oArrowKeysButton,
            
            showsHoldColorSlidersButton              = oShowsHoldColorSlidersButton,
            usesDifferentColorSpaceInHoldColorButton = oUsesDifferentColorSpaceInHoldColorButton,
            usesMainColorSpaceForCopyAsTextButton    = oUsesMainColorSpaceForCopyAsTextButton,
            
            showApplicationShortcutView  = oShowApplicationShortcutView,
            holdColorShortcutView        = oHoldColorShortcutView;

@end
