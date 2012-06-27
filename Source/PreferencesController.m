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

@synthesize generalPane    = o_generalPane,
            conversionPane = o_conversionPane,
            keyboardPane   = o_keyboardPane,
            
            toolbar        = o_toolbar,
            generalItem    = o_generalItem,
            conversionItem = o_conversionItem,
            keyboardItem   = o_keyboardItem,

            apertureColorPopUp    = o_apertureColorPopUp,

            clickInSwatchButton   = o_clickInSwatchButton,
            clickInSwatchPopUp    = o_clickInSwatchPopUp,

            dragInSwatchButton    = o_dragInSwatchButton,
            dragInSwatchPopUp     = o_dragInSwatchPopUp,
            
            useLowercaseHexButton = o_useLowercaseHexButton,
            usePoundPrefixButton  = o_usePoundPrefixButton,
            arrowKeysButton       = o_arrowKeysButton,
            showLockGuidesButton  = o_showLockGuidesButton,
            
            showsHoldColorSlidersButton              = o_showsHoldColorSlidersButton,
            usesDifferentColorSpaceInHoldColorButton = o_usesDifferentColorSpaceInHoldColorButton,
            usesMainColorSpaceForCopyAsTextButton    = o_usesMainColorSpaceForCopyAsTextButton,

            enableSystemClippedColorButton = o_enableSystemClippedColorButton,
            systemClippedColorWell         = o_systemClippedColorWell,
            useSystemClippedValueButton    = o_useSystemClippedValueButton,

            enableMyClippedColorButton     = o_enableMyClippedColorButton,
            myClippedColorWell             = o_myClippedColorWell,
            useMyClippedValueButton        = o_useMyClippedValueButton,
            
            showApplicationShortcutView  = o_showApplicationShortcutView,
            holdColorShortcutView        = o_holdColorShortcutView,
            lockPositionShortcutView     = o_lockPositionShortcutView,
            nsColorSnippetShortcutView   = o_nsColorSnippetShortcutView,
            uiColorSnippetShortcutView   = o_uiColorSnippetShortcutView,
            hexColorSnippetShortcutView  = o_hexColorSnippetShortcutView,
            rgbColorSnippetShortcutView  = o_rgbColorSnippetShortcutView,
            rgbaColorSnippetShortcutView = o_rgbaColorSnippetShortcutView;


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

    [o_showLockGuidesButton setTarget:nil];
    [o_showLockGuidesButton setAction:NULL];

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

    [o_lockPositionShortcutView setTarget:nil];
    [o_lockPositionShortcutView setAction:NULL];

    [o_nsColorSnippetShortcutView setTarget:nil];
    [o_nsColorSnippetShortcutView setAction:NULL];

    [o_uiColorSnippetShortcutView setTarget:nil];
    [o_uiColorSnippetShortcutView setAction:NULL];

    [o_hexColorSnippetShortcutView setTarget:nil];
    [o_hexColorSnippetShortcutView setAction:NULL];

    [o_rgbColorSnippetShortcutView setTarget:nil];
    [o_rgbColorSnippetShortcutView setAction:NULL];

    [o_rgbaColorSnippetShortcutView setTarget:nil];
    [o_rgbaColorSnippetShortcutView setAction:NULL];
}


- (NSString *) windowNibName
{
    return @"Preferences";
}


- (void ) windowDidLoad
{
    [self _handlePreferencesDidChange:nil];
    [self selectPane:0 animated:NO];
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    Preferences *preferences = [Preferences sharedInstance];

    BOOL clickInSwatchEnabled          = [preferences clickInSwatchEnabled];
    BOOL dragInSwatchEnabled           = [preferences dragInSwatchEnabled];
    BOOL highlightsMyClippedValues     = [preferences highlightsMyClippedValues];
    BOOL highlightsSystemClippedValues = [preferences highlightsSystemClippedValues];

    [o_apertureColorPopUp selectItemWithTag:[preferences apertureColor]];

    [o_clickInSwatchButton setState:clickInSwatchEnabled];
    [o_clickInSwatchPopUp  selectItemWithTag:[preferences clickInSwatchAction]];
    [o_clickInSwatchPopUp  setEnabled:clickInSwatchEnabled];

    [o_dragInSwatchButton  setState:dragInSwatchEnabled];
    [o_dragInSwatchPopUp   selectItemWithTag:[preferences dragInSwatchAction]];
    [o_dragInSwatchPopUp   setEnabled:dragInSwatchEnabled];

    [o_useLowercaseHexButton setState:[preferences usesLowercaseHex]];
    [o_usePoundPrefixButton  setState:[preferences usesPoundPrefix]];
    [o_arrowKeysButton       setState:[preferences arrowKeysEnabled]];
    [o_showLockGuidesButton  setState:[preferences showsLockGuides]];

    [o_showsHoldColorSlidersButton              setState:[preferences showsHoldColorSliders]];

    [o_enableSystemClippedColorButton setState: highlightsSystemClippedValues];
    [o_systemClippedColorWell       setEnabled: highlightsSystemClippedValues];
    [o_systemClippedColorWell         setColor: [preferences colorForSystemClippedValues]];
    [o_useSystemClippedValueButton    setState: [preferences usesSystemClippedValues]];

    [o_enableMyClippedColorButton setState: highlightsMyClippedValues];
    [o_myClippedColorWell       setEnabled: highlightsMyClippedValues];
    [o_myClippedColorWell         setColor: [preferences colorForMyClippedValues]];
    [o_useMyClippedValueButton    setState: ![preferences usesMyClippedValues]];

    BOOL usesDifferentColorSpaceInHoldColor = [preferences usesDifferentColorSpaceInHoldColor];

    [o_usesDifferentColorSpaceInHoldColorButton setState:usesDifferentColorSpaceInHoldColor];
    [o_usesMainColorSpaceForCopyAsTextButton setEnabled:usesDifferentColorSpaceInHoldColor];
    [o_usesMainColorSpaceForCopyAsTextButton setState:[preferences usesMainColorSpaceForCopyAsText]];

    [o_showApplicationShortcutView  setShortcut:[preferences showApplicationShortcut]];
    [o_holdColorShortcutView        setShortcut:[preferences holdColorShortcut]];
    [o_lockPositionShortcutView     setShortcut:[preferences lockPositionShortcut]];
    [o_nsColorSnippetShortcutView   setShortcut:[preferences nsColorSnippetShortcut]];
    [o_uiColorSnippetShortcutView   setShortcut:[preferences uiColorSnippetShortcut]];
    [o_hexColorSnippetShortcutView  setShortcut:[preferences hexColorSnippetShortcut]];
    [o_rgbColorSnippetShortcutView  setShortcut:[preferences rgbColorSnippetShortcut]];
    [o_rgbaColorSnippetShortcutView setShortcut:[preferences rgbaColorSnippetShortcut]];
}

- (void) selectPane:(NSInteger)tag animated:(BOOL)animated
{
    NSToolbarItem *item;
    NSView *pane;
    NSString *title;

    if (tag == 2) {
        item = o_keyboardItem;
        pane = o_keyboardPane;
        title = NSLocalizedString(@"Keyboard", nil);

    } else if (tag == 1) {
        item = o_conversionItem;
        pane = o_conversionPane;
        title = NSLocalizedString(@"Conversion", nil);

    } else {
        item = o_generalItem;
        pane = o_generalPane;
        title = NSLocalizedString(@"General", nil);
    }
    
    [o_toolbar setSelectedItemIdentifier:[item itemIdentifier]];
    
    NSWindow *window = [self window];
    NSView *contentView = [window contentView];
    for (NSView *view in [contentView subviews]) {
        [view removeFromSuperview];
    }

    NSRect paneFrame = [pane frame];
    NSRect windowFrame = [window frame];
    NSRect newFrame = [window frameRectForContentRect:paneFrame];
    
    newFrame.origin = windowFrame.origin;
    newFrame.origin.y += (windowFrame.size.height - newFrame.size.height);

    [window setFrame:newFrame display:YES animate:animated];
    [window setTitle:title];

    [contentView addSubview:pane];
}


- (IBAction) selectPane:(id)sender
{
    [self selectPane:[sender tag] animated:YES];
}


- (IBAction) updatePreferences:(id)sender
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

    } else if (sender == o_showLockGuidesButton) {
        [preferences setShowsLockGuides:([sender state] == NSOnState)];

    } else if (sender == o_showsHoldColorSlidersButton) {
        [preferences setShowsHoldColorSliders:([sender state] == NSOnState)];

    } else if (sender == o_usesDifferentColorSpaceInHoldColorButton) {
        [preferences setUsesDifferentColorSpaceInHoldColor:([sender state] == NSOnState)];

    } else if (sender == o_usesMainColorSpaceForCopyAsTextButton) {
        [preferences setUsesMainColorSpaceForCopyAsText:([sender state] == NSOnState)];

    } else if (sender == o_showApplicationShortcutView) {
        [preferences setShowApplicationShortcut:[sender shortcut]];
    
    } else if (sender == o_holdColorShortcutView) {
        [preferences setHoldColorShortcut:[sender shortcut]];

    } else if (sender == o_lockPositionShortcutView) {
        [preferences setLockPositionShortcut:[sender shortcut]];

    } else if (sender == o_nsColorSnippetShortcutView) {
        [preferences setNsColorSnippetShortcut:[sender shortcut]];
    
    } else if (sender == o_uiColorSnippetShortcutView) {
        [preferences setUiColorSnippetShortcut:[sender shortcut]];

    } else if (sender == o_hexColorSnippetShortcutView) {
        [preferences setHexColorSnippetShortcut:[sender shortcut]];

    } else if (sender == o_rgbColorSnippetShortcutView) {
        [preferences setRgbColorSnippetShortcut:[sender shortcut]];

    } else if (sender == o_rgbaColorSnippetShortcutView) {
        [preferences setRgbaColorSnippetShortcut:[sender shortcut]];

    } else if (sender == o_enableSystemClippedColorButton) {
        [preferences setHighlightsSystemClippedValues:([sender state] == NSOnState)];

    } else if (sender == o_systemClippedColorWell) {
        [preferences setColorForSystemClippedValues:[sender color]];

    } else if (sender == o_useSystemClippedValueButton) {
        [preferences setUsesSystemClippedValues:([sender state] == NSOnState)];

    } else if (sender == o_enableMyClippedColorButton) {
        [preferences setHighlightsMyClippedValues:([sender state] == NSOnState)];

    } else if (sender == o_myClippedColorWell) {
        [preferences setColorForMyClippedValues:[sender color]];

    } else if (sender == o_useMyClippedValueButton) {
        [preferences setUsesMyClippedValues:([sender state] != NSOnState)];
    }
}


- (IBAction) learnAboutConversion:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ConversionsURLString]];
}


@end
