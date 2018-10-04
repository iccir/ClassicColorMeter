//
//  ScreenCapturer.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2018-10-02.
//

#import <Foundation/Foundation.h>


@interface ScreenCapturer : NSObject

- (CGImageRef) captureRect:(CGRect)captureRect imageOption:(CGWindowImageOption)imageOption CF_RETURNS_RETAINED;
- (void) invalidate;

@property (nonatomic) NSInteger maxFPS;

@end

