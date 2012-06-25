//
//  MouseCursor.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2012-06-14.
//
//

#import "MouseCursor.h"

@implementation MouseCursor {
    NSTimer *_timer;
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
        _globalMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSMouseMovedMask handler:^(NSEvent *event) {
            [self _handleMouseMoved];
        }];

        _localMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSMouseMovedMask handler:^(NSEvent *event) {
            [self _handleMouseMoved];
            return event;
        }];
        
        _listeners = CFBridgingRelease(CFArrayCreateMutable(NULL, 0, NULL));

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleDidChangeScreenParameters:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
        [self _handleDidChangeScreenParameters:nil];
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


- (void) _handleDidChangeScreenParameters:(NSNotification *)note
{
    NSArray  *screensArray = [NSScreen screens];
    NSScreen *screenZero   = [screensArray count] ? [screensArray objectAtIndex:0] : nil;

    _screenZeroHeight = screenZero ? [screenZero frame].size.height : 0.0;
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
