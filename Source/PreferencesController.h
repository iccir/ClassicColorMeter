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

- (IBAction) updatePreferences:(id)sender;

@property (nonatomic, strong) IBOutlet NSPopUpButton *apertureColorPopUp;

@property (nonatomic, strong) IBOutlet NSButton      *clickInSwatchButton;
@property (nonatomic, strong) IBOutlet NSPopUpButton *clickInSwatchPopUp;

@property (nonatomic, strong) IBOutlet NSButton      *dragInSwatchButton;
@property (nonatomic, strong) IBOutlet NSPopUpButton *dragInSwatchPopUp;

@property (nonatomic, strong) IBOutlet NSButton      *useLowercaseHexButton;
@property (nonatomic, strong) IBOutlet NSButton      *usePoundPrefixButton;
@property (nonatomic, strong) IBOutlet NSButton      *arrowKeysButton;

@property (nonatomic, strong) IBOutlet NSButton      *showsHoldColorSlidersButton;
@property (nonatomic, strong) IBOutlet NSButton      *usesDifferentColorSpaceInHoldColorButton;
@property (nonatomic, strong) IBOutlet NSButton      *usesMainColorSpaceForCopyAsTextButton;

@property (nonatomic, strong) IBOutlet ShortcutView  *showApplicationShortcutView;
@property (nonatomic, strong) IBOutlet ShortcutView  *holdColorShortcutView;

@end
