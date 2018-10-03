//
//  MouseCursor.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2012-06-14.
//
//

#import "MouseCursor.h"

@implementation MouseCursor {
    NSMutableArray *_listeners;
    CGFloat _screenZeroHeight;
    id _globalMonitor;
    id _localMonitor;
}

+ (id) sharedInstance
{
    static id sSharedInstance = nil;
    if (!sSharedInstance) sSharedInstance = [[MouseCursor alloc] init];
    return sSharedInstance;
}


- (id) init
{
    if ((self = [super init])) {
        NSEventMask globalMask =
            NSEventMaskMouseMoved |
            NSEventMaskLeftMouseDown  | NSEventMaskLeftMouseUp |
            NSEventMaskRightMouseDown | NSEventMaskRightMouseUp;

        _globalMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:globalMask handler:^(NSEvent *event) {
            if ([event type] == NSEventTypeMouseMoved) {
                [self _handleMouseMoved];
            } else {
                [self _handleMouseButton];
            }
        }];

        _localMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskMouseMoved handler:^(NSEvent *event) {
            [self _handleMouseMoved];
            return event;
        }];
        
        _listeners = CFBridgingRelease(CFArrayCreateMutable(NULL, 0, NULL));

        [self update];
        [self _handleMouseMoved];
        
    }
    
    return self;
}


- (void) _updateDisplay
{
    CGDirectDisplayID displayID = _displayID;
    uint32_t matchingDisplayCount;
    CGGetDisplaysWithPoint(_location, 1, &displayID, &matchingDisplayCount);

    if (_displayID != displayID) {
        _displayID = displayID;
        _screen    = nil;
        _displayScaleFactor = 1.0;

        for (NSScreen *screen in [NSScreen screens]) {
            NSInteger screenNumber = [[[screen deviceDescription] objectForKey:@"NSScreenNumber"] integerValue];

            if (_displayID == screenNumber) {
                _screen = screen;
                _displayScaleFactor = [screen backingScaleFactor];
                break;
            }
        }
        
        for (id<MouseCursorListener> listener in _listeners) {
            [listener mouseCursorMovedToDisplay:_displayID];
        }
    }
}


- (void) _handleMouseButton
{
    for (id<MouseCursorListener> listener in _listeners) {
        [listener mouseButtonsChanged];
    }
}


- (void) _handleMouseMoved
{
    _inRetinaPixelMode = NO;

    CGPoint realUnflippedLocation = [NSEvent mouseLocation];
    
    if (_xLocked) {
        realUnflippedLocation.x = _realUnflippedLocation.x;
    } else {
        realUnflippedLocation.x = floor(realUnflippedLocation.x);
    }

    if (_yLocked) {
        realUnflippedLocation.y = (_realUnflippedLocation.y + 1.0);
    } else {
        realUnflippedLocation.y = ceil(realUnflippedLocation.y);
    }

    CGPoint realLocation = CGPointMake(realUnflippedLocation.x, _screenZeroHeight - realUnflippedLocation.y);
    
    if (!CGPointEqualToPoint(_realLocation, realLocation)) {
        realUnflippedLocation.y -= 1.0;

        _location = _realLocation = realLocation;
        _unflippedLocation = _realUnflippedLocation = realUnflippedLocation;

        [self _updateDisplay];

        for (id<MouseCursorListener> listener in _listeners) {
            [listener mouseCursorMovedToLocation:_location];
        }
    }
}


- (void) update
{
    [self _updateDisplay];

    NSArray  *screensArray = [NSScreen screens];
    NSScreen *screenZero   = [screensArray count] ? [screensArray objectAtIndex:0] : nil;

    _screenZeroHeight = screenZero ? [screenZero frame].size.height : 0.0;
}


- (CGWindowID) windowIDForSoftwareCursor
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

- (void) movePositionByXDelta:(CGFloat)xDelta yDelta:(CGFloat)yDelta
{
    if (_displayScaleFactor != 1.0) {
        xDelta /= _displayScaleFactor;
        yDelta /= _displayScaleFactor;
        _inRetinaPixelMode = YES;
    }

    _location.x += xDelta;
    _location.y -= yDelta;
    _unflippedLocation.x += xDelta;
    _unflippedLocation.y += yDelta;
    
    CGPoint flooredPosition     = CGPointMake(floor(_location.x),     floor(_location.y));
    CGPoint flooredRealPosition = CGPointMake(floor(_realLocation.x), floor(_realLocation.y));
    
    if (!CGPointEqualToPoint(flooredPosition, flooredRealPosition)) {
        CGWarpMouseCursorPosition(_location);
    }

    [self _updateDisplay];

    for (id<MouseCursorListener> listener in _listeners) {
        [listener mouseCursorMovedToLocation:_location];
    }
}


- (void) addListener:(id<MouseCursorListener>)listener
{
    if (![_listeners containsObject:listener]) {
        [_listeners addObject:listener];
    }
}


- (void) removeListener:(id<MouseCursorListener>)listener
{
    [_listeners removeObject:listener];
}


- (void) setXLocked:(BOOL)xLocked yLocked:(BOOL)yLocked
{
    if ((_xLocked != xLocked) || (_yLocked != yLocked)) {
        _xLocked = xLocked;
        _yLocked = yLocked;

        [self _handleMouseMoved];
    }
}


- (void) setXLocked:(BOOL)xLocked
{
    if (_xLocked != xLocked) {
        _xLocked = xLocked;
        [self _handleMouseMoved];
    }
}


- (void) setYLocked:(BOOL)yLocked
{
    if (_yLocked != yLocked) {
        _yLocked = yLocked;
        [self _handleMouseMoved];
    }
}


@end
