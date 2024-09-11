// (c) 2018-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import "ScreenCapturer.h"


@implementation ScreenCapturer {
    CGRect _lastCaptureRect;
    CGWindowImageOption _lastImageOptions;
    CGImageRef _lastCaptureImage;
    CGFloat _lastCaptureScale;
    
    NSTimeInterval _lastTimeInterval;

    CGWindowID _softwareCursorWindowID;
    NSTimeInterval _softwareCursorCheckTime;
}


+ (void) requestScreenCaptureAccess
{
    if (@available(macOS 11.0, *)) {
        CGRequestScreenCaptureAccess();
        
    } else {
        CGImageRef image = CGWindowListCreateImage(CGRectInfinite, kCGWindowListOptionAll, kCGNullWindowID, kCGWindowImageDefault);
        CGImageRelease(image);
    }
}


+ (BOOL) hasScreenCaptureAccess
{
    if (@available(macOS 11.0, *)) {
        return CGPreflightScreenCaptureAccess();

    } else if (@available(macOS 10.15, *)) {
        static dispatch_once_t onceToken = 0;
        static BOOL result;
        
        dispatch_once(&onceToken, ^{
            result = YES;
        
            CFArrayRef list = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, 0);

            if (list) {
                for (NSInteger i = 0; i < CFArrayGetCount(list); i++) {
                    CFDictionaryRef dictionary = CFArrayGetValueAtIndex(list, i);

                    NSNumber *sharingType = (__bridge NSNumber *) CFDictionaryGetValue(dictionary, kCGWindowSharingState);
                    NSNumber *windowLevel = (__bridge NSNumber *) CFDictionaryGetValue(dictionary, kCGWindowLayer);
                    NSString *processName = (__bridge NSString *) CFDictionaryGetValue(dictionary, kCGWindowOwnerName);

                    if ([processName isEqualToString:@"Dock"]) {
                        if ([windowLevel integerValue] == kCGDockWindowLevel) {
                            if ([sharingType integerValue] == kCGWindowSharingNone) {
                                result = NO;
                            }
                            
                            break;
                        }
                    }
                }
            }

            CFRelease(list);
        });
        
        return result;

    } else {
        return YES;
    }
}


- (void) dealloc
{
    [self invalidate];
}


#pragma mark - Capture

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


- (void) invalidate
{
    CGImageRelease(_lastCaptureImage);
    _lastCaptureImage = NULL;

    _lastCaptureRect  = CGRectZero;
    _lastImageOptions = 0;
    
    _lastTimeInterval = 0;
}


- (void) _doCaptureWithCaptureRect:(CGRect)captureRect imageOptions:(CGWindowImageOption)imageOption
{
    CGImageRelease(_lastCaptureImage);

    if (![ScreenCapturer hasScreenCaptureAccess]) {
        CFArrayRef desktopWindowArray = (__bridge CFArrayRef) @[ ];
    
        _lastCaptureImage = CGWindowListCreateImageFromArray(captureRect, desktopWindowArray, imageOption);
        
    } else  {
        CGWindowID cursorWindowID = _softwareCursorWindowID;

        if (cursorWindowID != kCGNullWindowID) {
            _lastCaptureImage = CGWindowListCreateImage(captureRect, kCGWindowListOptionOnScreenBelowWindow, cursorWindowID, imageOption);
        } else {
            _lastCaptureImage = CGWindowListCreateImage(captureRect, kCGWindowListOptionAll, kCGNullWindowID, imageOption);
        }
    }
    
    _lastCaptureScale = CGImageGetWidth(_lastCaptureImage) / captureRect.size.width;
    _lastCaptureRect  = captureRect;
    _lastImageOptions = imageOption;
}


- (CGImageRef) captureRect:(CGRect)captureRect imageOption:(CGWindowImageOption)imageOption
{
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];

    if ((now - _softwareCursorCheckTime) > 1.0) {
        _softwareCursorWindowID = sGetWindowIDForSoftwareCursor();
        _softwareCursorCheckTime = now;
    }
    
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
