//
//  PreferencesController.h
//  ColorMeter
//
//  Created by Ricci Adams on 7/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PreferencesController : NSWindowController

- (IBAction) updatePreferences:(id)sender;

@property (nonatomic, retain) IBOutlet NSPopUpButton *apertureColorPopUp;
@property (nonatomic, retain) IBOutlet NSPopUpButton *hexCasePopUp;
@property (nonatomic, retain) IBOutlet NSButton      *arrowKeysButton;
@property (nonatomic, retain) IBOutlet NSButton      *showSliderButton;

@end
