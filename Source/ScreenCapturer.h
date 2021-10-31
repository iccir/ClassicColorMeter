//
//  ScreenCapturer.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2018-10-02.
//

#import <Foundation/Foundation.h>


@interface ScreenCapturer : NSObject

+ (void) requestScreenCaptureAccess;
+ (BOOL) hasScreenCaptureAccess;

- (void) invalidate;
- (CGImageRef) captureRect:(CGRect)captureRect imageOption:(CGWindowImageOption)imageOption CF_RETURNS_RETAINED;

@property (nonatomic) NSInteger maxFPS;

@end

