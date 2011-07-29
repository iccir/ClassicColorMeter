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

@property (retain) IBOutlet NSPopUpButton *apertureColorPopUp;
@property (retain) IBOutlet NSPopUpButton *hexCasePopUp;
@property (retain) IBOutlet NSButton      *arrowKeysButton;
@property (retain) IBOutlet NSButton      *showSliderButton;

@end
