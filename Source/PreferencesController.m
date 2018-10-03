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

@property (nonatomic, strong) IBOutlet NSView *generalPane;
@property (nonatomic, strong) IBOutlet NSView *keyboardPane;
@property (nonatomic, strong) IBOutlet NSView *advancedPane;

@property (nonatomic, weak) IBOutlet NSToolbar     *toolbar;
@property (nonatomic, weak) IBOutlet NSToolbarItem *generalItem;
@property (nonatomic, weak) IBOutlet NSToolbarItem *keyboardItem;
@property (nonatomic, weak) IBOutlet NSToolbarItem *advancedItem;

@property (nonatomic, weak) IBOutlet ShortcutView  *showApplicationShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView  *holdColorShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView  *lockPositionShortcutView;

@property (nonatomic, weak) IBOutlet ShortcutView  *nsColorSnippetShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView  *uiColorSnippetShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView  *hexColorSnippetShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView  *rgbColorSnippetShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView  *rgbaColorSnippetShortcutView;

@property (atomic, strong) Preferences *preferences;

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
    [self setPreferences:[Preferences sharedInstance]];
    [self _handlePreferencesDidChange:nil];
    [self selectPane:0 animated:NO];
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    Preferences *preferences = [Preferences sharedInstance];

    [_showApplicationShortcutView  setShortcut:[preferences showApplicationShortcut]];
    [_holdColorShortcutView        setShortcut:[preferences holdColorShortcut]];
    [_lockPositionShortcutView     setShortcut:[preferences lockPositionShortcut]];
    [_nsColorSnippetShortcutView   setShortcut:[preferences nsColorSnippetShortcut]];
    [_uiColorSnippetShortcutView   setShortcut:[preferences uiColorSnippetShortcut]];
    [_hexColorSnippetShortcutView  setShortcut:[preferences hexColorSnippetShortcut]];
    [_rgbColorSnippetShortcutView  setShortcut:[preferences rgbColorSnippetShortcut]];
    [_rgbaColorSnippetShortcutView setShortcut:[preferences rgbaColorSnippetShortcut]];
}


- (void) selectPane:(NSInteger)tag animated:(BOOL)animated
{
    NSToolbarItem *item;
    NSView *pane;
    NSString *title;

    if (tag == 2) {
        item = _advancedItem;
        pane = _advancedPane;
        title = NSLocalizedString(@"Advanced", nil);
        
    } else if (tag == 1) {
        item = _keyboardItem;
        pane = _keyboardPane;
        title = NSLocalizedString(@"Keyboard", nil);

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

    if (sender == _showApplicationShortcutView) {
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
    }
}


- (IBAction) learnAboutLegacySpaces:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:LegacySpacesURLString]];
}


@end
