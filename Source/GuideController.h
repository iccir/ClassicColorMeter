//
//  GuideView.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2012-06-18.
//
//

#import <Foundation/Foundation.h>

@interface GuideController : NSObject

+ (GuideController *) sharedInstance;

- (void) update;

@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

@end
