//
//  ScreenCapturer.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2018-10-02.
//

#import "ScreenCapturer.h"


static CGWindowID sGetWindowIDForSoftwareCursor()
{
    CFArrayRef descriptionList = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);
    CGWindowID result         = kCGNullWindowID;
    CGWindowID resultWithName = kCGNullWindowID;

    CFIndex count = CFArrayGetCount(descriptionList);
    for (CFIndex i = 0; i < count; i++) {
        NSDictionary *description = (__bridge NSDictionary *)CFArrayGetValueAtIndex(descriptionList, i);

        CGWindowLevel cursorLevel = CGWindowLevelForKey(kCGCursorWindowLevelKey);
        CGWindowLevel windowLevel = [[description objectForKey:(id)kCGWindowLayer] intValue];
        
        if (cursorLevel == windowLevel) {
            NSString *name = [description objectForKey:(id)kCGWindowName];

            if ([name isEqualToString:@"Cursor"]) {
                result = [[description objectForKey:(id)kCGWindowNumber] intValue];
                break;
            } else {
                result = [[description objectForKey:(id)kCGWindowNumber] intValue];
            }
        }
    }
    
    CFRelease(descriptionList);
    
    return resultWithName ? resultWithName : result;
}


@implementation ScreenCapturer {
    CGRect _lastCaptureRect;
    CGWindowImageOption _lastImageOptions;
    CGImageRef _lastCaptureImage;
    CGFloat _lastCaptureScale;
    
    NSTimeInterval _lastTimeInterval;
}


- (void) dealloc
{
    [self invalidate];
}


- (void) _doCaptureWithCaptureRect:(CGRect)captureRect imageOptions:(CGWindowImageOption)imageOption
{
    CGImageRelease(_lastCaptureImage);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    BOOL needsAirplayWorkaround = CGCursorIsDrawnInFramebuffer();
#pragma clang diagnostic pop

    if (needsAirplayWorkaround) {
        CGWindowID cursorWindowID = sGetWindowIDForSoftwareCursor();
        
        if (cursorWindowID != kCGNullWindowID) {
            _lastCaptureImage = CGWindowListCreateImage(captureRect, kCGWindowListOptionOnScreenBelowWindow, cursorWindowID, imageOption);
        } else {
            _lastCaptureImage = CGWindowListCreateImage(captureRect, kCGWindowListOptionAll, kCGNullWindowID, imageOption);
        }
        
    } else {
        _lastCaptureImage = CGWindowListCreateImage(captureRect, kCGWindowListOptionAll, kCGNullWindowID, imageOption);
    }
    
    _lastCaptureScale = CGImageGetWidth(_lastCaptureImage) / captureRect.size.width;
    _lastCaptureRect  = captureRect;
    _lastImageOptions = imageOption;
}


- (void) invalidate
{
    CGImageRelease(_lastCaptureImage);
    _lastCaptureImage = NULL;

    _lastCaptureRect  = CGRectZero;
    _lastImageOptions = 0;
    
    _lastTimeInterval = 0;
}


- (CGImageRef) captureRect:(CGRect)captureRect imageOption:(CGWindowImageOption)imageOption
{
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    
    if (!CGRectContainsRect(_lastCaptureRect, captureRect) || (imageOption != _lastImageOptions)) {
        if (_maxFPS && ((now - _lastTimeInterval) < (1.0 / (double)_maxFPS))) {
            return NULL;
        }

        CGFloat expansionLength = (captureRect.size.width < 62) ?
            captureRect.size.width * 2:
            0;

        CGRect expandedRect = CGRectInset(captureRect, -expansionLength, -expansionLength);
        [self _doCaptureWithCaptureRect:expandedRect imageOptions:imageOption];
        
        _lastTimeInterval = now;
    }

    CGRect croppedRect = CGRectMake(
        (captureRect.origin.x - _lastCaptureRect.origin.x) * _lastCaptureScale,
        (captureRect.origin.y - _lastCaptureRect.origin.y) * _lastCaptureScale,
        captureRect.size.width  * _lastCaptureScale,
        captureRect.size.height * _lastCaptureScale
    );

    return CGImageCreateWithImageInRect(_lastCaptureImage, croppedRect);
}


@end
