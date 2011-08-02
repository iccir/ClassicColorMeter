//
//  PreferencesController.h
//  ColorMeter
//
//  Created by Ricci Adams on 2011-07-28.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PreferencesController : NSWindowController

- (IBAction) updatePreferences:(id)sender;

@property (nonatomic, retain) IBOutlet NSPopUpButton *apertureColorPopUp;

@property (nonatomic, retain) IBOutlet NSButton      *clickInSwatchButton;
@property (nonatomic, retain) IBOutlet NSPopUpButton *clickInSwatchPopUp;

@property (nonatomic, retain) IBOutlet NSButton      *dragInSwatchButton;
@property (nonatomic, retain) IBOutlet NSPopUpButton *dragInSwatchPopUp;

@property (nonatomic, retain) IBOutlet NSButton      *useLowercaseHexButton;
@property (nonatomic, retain) IBOutlet NSButton      *arrowKeysButton;
@property (nonatomic, retain) IBOutlet NSButton      *showSliderButton;

@end
