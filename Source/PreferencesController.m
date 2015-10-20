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


- (IBAction) selectPane:(id)sender;
- (IBAction) updatePreferences:(id)sender;
- (IBAction) learnAboutConversion:(id)sender;

@property (nonatomic, strong) IBOutlet NSView *generalPane;
@property (nonatomic, strong) IBOutlet NSView *conversionPane;
@property (nonatomic, strong) IBOutlet NSView *keyboardPane;

@property (nonatomic, weak) IBOutlet NSToolbar *toolbar;
@property (nonatomic, weak) IBOutlet NSToolbarItem *generalItem;
@property (nonatomic, weak) IBOutlet NSToolbarItem *conversionItem;
@property (nonatomic, weak) IBOutlet NSToolbarItem *keyboardItem;

@property (nonatomic, weak) IBOutlet NSPopUpButton *apertureColorPopUp;

@property (nonatomic, weak) IBOutlet NSButton      *clickInSwatchButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *clickInSwatchPopUp;

@property (nonatomic, weak) IBOutlet NSButton      *dragInSwatchButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *dragInSwatchPopUp;

@property (nonatomic, weak) IBOutlet NSButton      *useLowercaseHexButton;
@property (nonatomic, weak) IBOutlet NSButton      *usePoundPrefixButton;
@property (nonatomic, weak) IBOutlet NSButton      *arrowKeysButton;
@property (nonatomic, weak) IBOutlet NSButton      *showLockGuidesButton;

@property (nonatomic, weak) IBOutlet NSButton      *showsHoldColorSlidersButton;
@property (nonatomic, weak) IBOutlet NSButton      *usesDifferentColorSpaceInHoldColorButton;
@property (nonatomic, weak) IBOutlet NSButton      *usesMainColorSpaceForCopyAsTextButton;

@property (nonatomic, weak) IBOutlet NSButton      *enableSystemClippedColorButton;
@property (nonatomic, weak) IBOutlet NSColorWell   *systemClippedColorWell;
@property (nonatomic, weak) IBOutlet NSButton      *useSystemClippedValueButton;

@property (nonatomic, weak) IBOutlet NSButton      *enableMyClippedColorButton;
@property (nonatomic, weak) IBOutlet NSColorWell   *myClippedColorWell;
@property (nonatomic, weak) IBOutlet NSButton      *useMyClippedValueButton;

@property (nonatomic, weak) IBOutlet NSButton      *restoreDisplayInSRGBButton;

@property (nonatomic, weak) IBOutlet ShortcutView  *showApplicationShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView  *holdColorShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView  *lockPositionShortcutView;

@property (nonatomic, weak) IBOutlet ShortcutView  *nsColorSnippetShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView  *uiColorSnippetShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView  *hexColorSnippetShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView  *rgbColorSnippetShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView  *rgbaColorSnippetShortcutView;


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

    [_apertureColorPopUp setTarget:nil];
    [_apertureColorPopUp setAction:NULL];

    [_clickInSwatchButton setTarget:nil];
    [_clickInSwatchButton setAction:NULL];

    [_clickInSwatchPopUp setTarget:nil];
    [_clickInSwatchPopUp setAction:NULL];

    [_dragInSwatchButton setTarget:nil];
    [_dragInSwatchButton setAction:NULL];

    [_dragInSwatchPopUp setTarget:nil];
    [_dragInSwatchPopUp setAction:NULL];

    [_useLowercaseHexButton setTarget:nil];
    [_useLowercaseHexButton setAction:NULL];

    [_arrowKeysButton setTarget:nil];
    [_arrowKeysButton setAction:NULL];

    [_showLockGuidesButton setTarget:nil];
    [_showLockGuidesButton setAction:NULL];

    [_usePoundPrefixButton setTarget:nil];
    [_usePoundPrefixButton setAction:NULL];

    [_showsHoldColorSlidersButton setTarget:nil];
    [_showsHoldColorSlidersButton setAction:NULL];

    [_usesDifferentColorSpaceInHoldColorButton setTarget:nil];
    [_usesDifferentColorSpaceInHoldColorButton setAction:NULL];

    [_usesMainColorSpaceForCopyAsTextButton setTarget:nil];
    [_usesMainColorSpaceForCopyAsTextButton setAction:NULL];

    [_showApplicationShortcutView setTarget:nil];
    [_showApplicationShortcutView setAction:NULL];

    [_holdColorShortcutView setTarget:nil];
    [_holdColorShortcutView setAction:NULL];

    [_lockPositionShortcutView setTarget:nil];
    [_lockPositionShortcutView setAction:NULL];

    [_nsColorSnippetShortcutView setTarget:nil];
    [_nsColorSnippetShortcutView setAction:NULL];

    [_uiColorSnippetShortcutView setTarget:nil];
    [_uiColorSnippetShortcutView setAction:NULL];

    [_hexColorSnippetShortcutView setTarget:nil];
    [_hexColorSnippetShortcutView setAction:NULL];

    [_rgbColorSnippetShortcutView setTarget:nil];
    [_rgbColorSnippetShortcutView setAction:NULL];

    [_rgbaColorSnippetShortcutView setTarget:nil];
    [_rgbaColorSnippetShortcutView setAction:NULL];
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

    [_apertureColorPopUp selectItemWithTag:[preferences apertureColor]];

    [_clickInSwatchButton setState:clickInSwatchEnabled];
    [_clickInSwatchPopUp  selectItemWithTag:[preferences clickInSwatchAction]];
    [_clickInSwatchPopUp  setEnabled:clickInSwatchEnabled];

    [_dragInSwatchButton  setState:dragInSwatchEnabled];
    [_dragInSwatchPopUp   selectItemWithTag:[preferences dragInSwatchAction]];
    [_dragInSwatchPopUp   setEnabled:dragInSwatchEnabled];

    [_useLowercaseHexButton setState:[preferences usesLowercaseHex]];
    [_usePoundPrefixButton  setState:[preferences usesPoundPrefix]];
    [_arrowKeysButton       setState:[preferences arrowKeysEnabled]];
    [_showLockGuidesButton  setState:[preferences showsLockGuides]];

    [_showsHoldColorSlidersButton              setState:[preferences showsHoldColorSliders]];

    [_enableSystemClippedColorButton setState: highlightsSystemClippedValues];
    [_systemClippedColorWell       setEnabled: highlightsSystemClippedValues];
    [_systemClippedColorWell         setColor: [preferences colorForSystemClippedValues]];
    [_useSystemClippedValueButton    setState: [preferences usesSystemClippedValues]];

    [_enableMyClippedColorButton setState: highlightsMyClippedValues];
    [_myClippedColorWell       setEnabled: highlightsMyClippedValues];
    [_myClippedColorWell         setColor: [preferences colorForMyClippedValues]];
    [_useMyClippedValueButton    setState: ![preferences usesMyClippedValues]];

    BOOL usesDifferentColorSpaceInHoldColor = [preferences usesDifferentColorSpaceInHoldColor];

    [_usesDifferentColorSpaceInHoldColorButton setState:usesDifferentColorSpaceInHoldColor];
    [_usesMainColorSpaceForCopyAsTextButton setEnabled:usesDifferentColorSpaceInHoldColor];
    [_usesMainColorSpaceForCopyAsTextButton setState:[preferences usesMainColorSpaceForCopyAsText]];

    [_showApplicationShortcutView  setShortcut:[preferences showApplicationShortcut]];
    [_holdColorShortcutView        setShortcut:[preferences holdColorShortcut]];
    [_lockPositionShortcutView     setShortcut:[preferences lockPositionShortcut]];
    [_nsColorSnippetShortcutView   setShortcut:[preferences nsColorSnippetShortcut]];
    [_uiColorSnippetShortcutView   setShortcut:[preferences uiColorSnippetShortcut]];
    [_hexColorSnippetShortcutView  setShortcut:[preferences hexColorSnippetShortcut]];
    [_rgbColorSnippetShortcutView  setShortcut:[preferences rgbColorSnippetShortcut]];
    [_rgbaColorSnippetShortcutView setShortcut:[preferences rgbaColorSnippetShortcut]];
    
    [_restoreDisplayInSRGBButton setEnabled:([preferences colorConversion] != ColorConversionDisplayInSRGB)];
}


- (void) selectPane:(NSInteger)tag animated:(BOOL)animated
{
    NSToolbarItem *item;
    NSView *pane;
    NSString *title;

    if (tag == 2) {
        item = _keyboardItem;
        pane = _keyboardPane;
        title = NSLocalizedString(@"Keyboard", nil);

    } else if (tag == 1) {
        item = _conversionItem;
        pane = _conversionPane;
        title = NSLocalizedString(@"Conversion", nil);

    } else {
        item = _generalItem;
        pane = _generalPane;
        title = NSLocalizedString(@"General", nil);
    }
    
    [_toolbar setSelectedItemIdentifier:[item itemIdentifier]];
    
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

    if (sender == _apertureColorPopUp) {
        [preferences setApertureColor:[sender selectedTag]];

    } else if (sender == _clickInSwatchButton) {
        [preferences setClickInSwatchEnabled:([sender state] == NSOnState)];

    } else if (sender == _clickInSwatchPopUp) {
        [preferences setClickInSwatchAction:[sender selectedTag]];
    
    } else if (sender == _dragInSwatchButton) {
        [preferences setDragInSwatchEnabled:([sender state] == NSOnState)];

    } else if (sender == _dragInSwatchPopUp) {
        [preferences setDragInSwatchAction:[sender selectedTag]];

    } else if (sender == _useLowercaseHexButton) {
        [preferences setUsesLowercaseHex:([sender state] == NSOnState)];

    } else if (sender == _usePoundPrefixButton) {
        [preferences setUsesPoundPrefix:([sender state] == NSOnState)];

    } else if (sender == _arrowKeysButton) {
        [preferences setArrowKeysEnabled:([sender state] == NSOnState)];

    } else if (sender == _showLockGuidesButton) {
        [preferences setShowsLockGuides:([sender state] == NSOnState)];

    } else if (sender == _showsHoldColorSlidersButton) {
        [preferences setShowsHoldColorSliders:([sender state] == NSOnState)];

    } else if (sender == _usesDifferentColorSpaceInHoldColorButton) {
        [preferences setUsesDifferentColorSpaceInHoldColor:([sender state] == NSOnState)];

    } else if (sender == _usesMainColorSpaceForCopyAsTextButton) {
        [preferences setUsesMainColorSpaceForCopyAsText:([sender state] == NSOnState)];

    } else if (sender == _showApplicationShortcutView) {
        [preferences setShowApplicationShortcut:[sender shortcut]];
    
    } else if (sender == _holdColorShortcutView) {
        [preferences setHoldColorShortcut:[sender shortcut]];

    } else if (sender == _lockPositionShortcutView) {
        [preferences setLockPositionShortcut:[sender shortcut]];

    } else if (sender == _nsColorSnippetShortcutView) {
        [preferences setNsColorSnippetShortcut:[sender shortcut]];
    
    } else if (sender == _uiColorSnippetShortcutView) {
        [preferences setUiColorSnippetShortcut:[sender shortcut]];

    } else if (sender == _hexColorSnippetShortcutView) {
        [preferences setHexColorSnippetShortcut:[sender shortcut]];

    } else if (sender == _rgbColorSnippetShortcutView) {
        [preferences setRgbColorSnippetShortcut:[sender shortcut]];

    } else if (sender == _rgbaColorSnippetShortcutView) {
        [preferences setRgbaColorSnippetShortcut:[sender shortcut]];

    } else if (sender == _enableSystemClippedColorButton) {
        [preferences setHighlightsSystemClippedValues:([sender state] == NSOnState)];

    } else if (sender == _systemClippedColorWell) {
        [preferences setColorForSystemClippedValues:[sender color]];

    } else if (sender == _useSystemClippedValueButton) {
        [preferences setUsesSystemClippedValues:([sender state] == NSOnState)];

    } else if (sender == _enableMyClippedColorButton) {
        [preferences setHighlightsMyClippedValues:([sender state] == NSOnState)];

    } else if (sender == _myClippedColorWell) {
        [preferences setColorForMyClippedValues:[sender color]];

    } else if (sender == _useMyClippedValueButton) {
        [preferences setUsesMyClippedValues:([sender state] != NSOnState)];
    }
}


- (IBAction) restoreDefaultSRGBMode:(id)sender
{
    [[Preferences sharedInstance] setColorConversion:ColorConversionDisplayInSRGB];
}


- (IBAction) learnAboutConversion:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ConversionsURLString]];
}


@end
