//
//  RecessedButton.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 9/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface RecessedButtonCell : NSButtonCell
@end


@interface RecessedButton : NSButton
- (void) doPopOutAnimation;
@end
