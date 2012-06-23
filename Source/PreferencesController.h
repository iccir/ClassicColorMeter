//
//  PreferencesController.h
//  ColorMeter
//
//  Created by Ricci Adams on 2011-07-28.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ShortcutView;

@interface PreferencesController : NSWindowController

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

@property (nonatomic, weak) IBOutlet ShortcutView  *showApplicationShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView  *holdColorShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView  *lockPositionShortcutView;

@property (nonatomic, weak) IBOutlet ShortcutView  *nsColorSnippetShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView  *uiColorSnippetShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView  *hexColorSnippetShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView  *rgbColorSnippetShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView  *rgbaColorSnippetShortcutView;

@end
