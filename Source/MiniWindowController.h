//
//  PreferencesController.h
//  ColorMeter
//
//  Created by Ricci Adams on 2011-07-28.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MiniWindowController : NSWindowController

- (void) toggle;

- (void) updateColorMode:(ColorMode)colorMode;
- (void) updateColor:(Color *)color options:(ColorStringOptions)options;

@end
