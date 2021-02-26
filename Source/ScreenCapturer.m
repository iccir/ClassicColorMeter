//
//  ScreenCapturer.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2018-10-02.
//

#import "ScreenCapturer.h"


@implementation ScreenCapturer {
    BOOL _didPermissionCheck;

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


#pragma mark - Permissions

static NSInteger sGetPermissionDialogCount(void)
{
    CFArrayRef list = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, 0);
    NSInteger count = 0;

    if (list) {
        for (NSInteger i = 0; i < CFArrayGetCount(list); i++) {
            CFDictionaryRef dictionary = CFArrayGetValueAtIndex(list, i);

            NSString *processName = (__bridge NSString *) CFDictionaryGetValue(dictionary, kCGWindowOwnerName);

            if ([processName containsString:@"universalAccess"]) {
                count++;
            }
        }

        CFRelease(list);
    }
    
    return count;
}


static BOOL sIsScreenCaptureBlocked(void)
{
    CFArrayRef list = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, 0);
    BOOL result = NO;

    if (list) {
        for (NSInteger i = 0; i < CFArrayGetCount(list); i++) {
            CFDictionaryRef dictionary = CFArrayGetValueAtIndex(list, i);

            NSNumber *sharingType = (__bridge NSNumber *) CFDictionaryGetValue(dictionary, kCGWindowSharingState);
            NSNumber *windowLevel = (__bridge NSNumber *) CFDictionaryGetValue(dictionary, kCGWindowLayer);
            NSString *processName = (__bridge NSString *) CFDictionaryGetValue(dictionary, kCGWindowOwnerName);

            if ([processName isEqualToString:@"Dock"]) {
                if ([windowLevel integerValue] == kCGDockWindowLevel) {
                    if ([sharingType integerValue] == kCGWindowSharingNone) {
                        result = YES;
                    }
                    
                    break;
                }
            }
        }
    
        CFRelease(list);
    }

    return result;
}


static void sShowPermissionDialog(void)
{
    NSAlert *alert = [[NSAlert alloc] init];
    
    NSString *informativeText = [@[
        NSLocalizedString(@"This permission is necessary for Classic Color Meter to see raw pixel data and calculate color information.", nil),
        NSLocalizedString(@"This application does not transmit information over a network.", nil),
        NSLocalizedString(@"Grant access to this application in Security & Privacy preferences, located in System Preferences.", nil)
    ] componentsJoinedByString:@"\n\n"];
    
    [alert setMessageText:NSLocalizedString(@"Classic Color Meter needs permission to record this computer's screen.", nil)];
    [alert setInformativeText:informativeText];

    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Open System Preferences", nil)];
    
    if ([alert runModal] == NSAlertSecondButtonReturn) {
        NSURL *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"];
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}


static void sCheckScreenCapturePermission(void)
{
    if (!sIsScreenCaptureBlocked()) return;

    NSInteger initialCount = sGetPermissionDialogCount();

    // Trigger screen capture
    CGImageRef image = CGWindowListCreateImage(CGRectInfinite, kCGWindowListOptionAll, 0, kCGWindowImageDefault);
    CGImageRelease(image);

    // Wait 250ms and check count again
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(250 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        if (sGetPermissionDialogCount() <= initialCount) {
            sShowPermissionDialog();
        }
    });
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    BOOL needsAirplayWorkaround = CGCursorIsDrawnInFramebuffer();
#pragma clang diagnostic pop

    if (!_didPermissionCheck) {
        if (@available(macOS 11, *)) {
            if (!CGPreflightScreenCaptureAccess()) {
                sShowPermissionDialog();
            }
            
        } else if (@available(macOS 10.15, *)) {
            sCheckScreenCapturePermission();
        }

        _didPermissionCheck = YES;
    }

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
