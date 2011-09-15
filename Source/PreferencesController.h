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

@property (nonatomic, retain) IBOutlet NSPopUpButton *apertureColorPopUp;

@property (nonatomic, retain) IBOutlet NSButton      *clickInSwatchButton;
@property (nonatomic, retain) IBOutlet NSPopUpButton *clickInSwatchPopUp;

@property (nonatomic, retain) IBOutlet NSButton      *dragInSwatchButton;
@property (nonatomic, retain) IBOutlet NSPopUpButton *dragInSwatchPopUp;

@property (nonatomic, retain) IBOutlet NSButton      *useLowercaseHexButton;
@property (nonatomic, retain) IBOutlet NSButton      *usePoundPrefixButton;
@property (nonatomic, retain) IBOutlet NSButton      *arrowKeysButton;

@property (nonatomic, retain) IBOutlet NSButton      *showsHoldColorSlidersButton;
@property (nonatomic, retain) IBOutlet NSButton      *usesDifferentColorSpaceInHoldColorButton;
@property (nonatomic, retain) IBOutlet NSButton      *usesMainColorSpaceForCopyAsTextButton;

@property (nonatomic, retain) IBOutlet ShortcutView  *showApplicationShortcutView;
@property (nonatomic, retain) IBOutlet ShortcutView  *holdColorShortcutView;

@end
