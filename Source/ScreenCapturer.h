// (c) 2018-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>


@interface ScreenCapturer : NSObject

+ (void) requestScreenCaptureAccess;
+ (BOOL) hasScreenCaptureAccess;

- (void) invalidate;
- (CGImageRef) captureRect:(CGRect)captureRect imageOption:(CGWindowImageOption)imageOption CF_RETURNS_RETAINED;

@property (nonatomic) NSInteger maxFPS;

@end

