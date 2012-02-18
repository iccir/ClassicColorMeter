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

@interface PreferencesController ()
- (void) _handlePreferencesDidChange:(NSNotification *)note;
@end


@implementation PreferencesController

@synthesize apertureColorPopUp    = o_apertureColorPopUp,

            clickInSwatchButton   = o_clickInSwatchButton,
            clickInSwatchPopUp    = o_clickInSwatchPopUp,

            dragInSwatchButton    = o_dragInSwatchButton,
            dragInSwatchPopUp     = o_dragInSwatchPopUp,
            
            useLowercaseHexButton = o_useLowercaseHexButton,
            usePoundPrefixButton  = o_usePoundPrefixButton,
            arrowKeysButton       = o_arrowKeysButton,
            
            showsHoldColorSlidersButton              = o_showsHoldColorSlidersButton,
            usesDifferentColorSpaceInHoldColorButton = o_usesDifferentColorSpaceInHoldColorButton,
            usesMainColorSpaceForCopyAsTextButton    = o_usesMainColorSpaceForCopyAsTextButton,
            
            showApplicationShortcutView  = o_showApplicationShortcutView,
            holdColorShortcutView        = o_holdColorShortcutView;


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

    [o_apertureColorPopUp setTarget:nil];
    [o_apertureColorPopUp setAction:NULL];

    [o_clickInSwatchButton setTarget:nil];
    [o_clickInSwatchButton setAction:NULL];

    [o_clickInSwatchPopUp setTarget:nil];
    [o_clickInSwatchPopUp setAction:NULL];

    [o_dragInSwatchButton setTarget:nil];
    [o_dragInSwatchButton setAction:NULL];

    [o_dragInSwatchPopUp setTarget:nil];
    [o_dragInSwatchPopUp setAction:NULL];

    [o_useLowercaseHexButton setTarget:nil];
    [o_useLowercaseHexButton setAction:NULL];

    [o_arrowKeysButton setTarget:nil];
    [o_arrowKeysButton setAction:NULL];

    [o_usePoundPrefixButton setTarget:nil];
    [o_usePoundPrefixButton setAction:NULL];

    [o_showsHoldColorSlidersButton setTarget:nil];
    [o_showsHoldColorSlidersButton setAction:NULL];

    [o_usesDifferentColorSpaceInHoldColorButton setTarget:nil];
    [o_usesDifferentColorSpaceInHoldColorButton setAction:NULL];

    [o_usesMainColorSpaceForCopyAsTextButton setTarget:nil];
    [o_usesMainColorSpaceForCopyAsTextButton setAction:NULL];

    [o_showApplicationShortcutView setTarget:nil];
    [o_showApplicationShortcutView setAction:NULL];

    [o_holdColorShortcutView setTarget:nil];
    [o_holdColorShortcutView setAction:NULL];
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

    [o_apertureColorPopUp selectItemWithTag:[preferences apertureColor]];

    BOOL clickInSwatchEnabled = [preferences clickInSwatchEnabled];
    [o_clickInSwatchButton setState:clickInSwatchEnabled];
    [o_clickInSwatchPopUp  selectItemWithTag:[preferences clickInSwatchAction]];
    [o_clickInSwatchPopUp  setEnabled:clickInSwatchEnabled];

    BOOL dragInSwatchEnabled = [preferences dragInSwatchEnabled];
    [o_dragInSwatchButton  setState:dragInSwatchEnabled];
    [o_dragInSwatchPopUp   selectItemWithTag:[preferences dragInSwatchAction]];
    [o_dragInSwatchPopUp   setEnabled:dragInSwatchEnabled];

    [o_useLowercaseHexButton setState:[preferences usesLowercaseHex]];
    [o_usePoundPrefixButton  setState:[preferences usesPoundPrefix]];
    [o_arrowKeysButton       setState:[preferences arrowKeysEnabled]];

    [o_showsHoldColorSlidersButton              setState:[preferences showsHoldColorSliders]];

    BOOL usesDifferentColorSpaceInHoldColor = [preferences usesDifferentColorSpaceInHoldColor];

    [o_usesDifferentColorSpaceInHoldColorButton setState:usesDifferentColorSpaceInHoldColor];
    [o_usesMainColorSpaceForCopyAsTextButton setEnabled:usesDifferentColorSpaceInHoldColor];
    [o_usesMainColorSpaceForCopyAsTextButton setState:[preferences usesMainColorSpaceForCopyAsText]];

    [o_showApplicationShortcutView setShortcut:[preferences showApplicationShortcut]];
    [o_holdColorShortcutView setShortcut:[preferences holdColorShortcut]];
}


- (void) updatePreferences:(id)sender
{
    Preferences *preferences = [Preferences sharedInstance];

    if (sender == o_apertureColorPopUp) {
        [preferences setApertureColor:[sender selectedTag]];

    } else if (sender == o_clickInSwatchButton) {
        [preferences setClickInSwatchEnabled:([sender state] == NSOnState)];

    } else if (sender == o_clickInSwatchPopUp) {
        [preferences setClickInSwatchAction:[sender selectedTag]];
    
    } else if (sender == o_dragInSwatchButton) {
        [preferences setDragInSwatchEnabled:([sender state] == NSOnState)];

    } else if (sender == o_dragInSwatchPopUp) {
        [preferences setDragInSwatchAction:[sender selectedTag]];

    } else if (sender == o_useLowercaseHexButton) {
        [preferences setUsesLowercaseHex:([sender state] == NSOnState)];

    } else if (sender == o_usePoundPrefixButton) {
        [preferences setUsesPoundPrefix:([sender state] == NSOnState)];

    } else if (sender == o_arrowKeysButton) {
        [preferences setArrowKeysEnabled:([sender state] == NSOnState)];

    } else if (sender == o_showsHoldColorSlidersButton) {
        [preferences setShowsHoldColorSliders:([sender state] == NSOnState)];

    } else if (sender == o_usesDifferentColorSpaceInHoldColorButton) {
        [preferences setUsesDifferentColorSpaceInHoldColor:([sender state] == NSOnState)];

    } else if (sender == o_usesMainColorSpaceForCopyAsTextButton) {
        [preferences setUsesMainColorSpaceForCopyAsText:([sender state] == NSOnState)];

    } else if (sender == o_showApplicationShortcutView) {
        [preferences setShowApplicationShortcut:[o_showApplicationShortcutView shortcut]];
    
    } else if (sender == o_holdColorShortcutView) {
        [preferences setHoldColorShortcut:[o_holdColorShortcutView shortcut]];
    }
}

@end
