// (c) 2012-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>

@interface GuideController : NSObject

+ (GuideController *) sharedInstance;

- (void) update;

@property (nonatomic, getter=isEnabled) BOOL enabled;

@end
