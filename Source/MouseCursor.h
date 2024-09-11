// (c) 2012-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>

@protocol MouseCursorListener;


@interface MouseCursor : NSObject

+ (id) sharedInstance;

// Allows sub-pixel positioning
- (void) movePositionByXDelta:(CGFloat)xDelta yDelta:(CGFloat)yDelta;

- (void) addListener:(id<MouseCursorListener>)listener;
- (void) removeListener:(id<MouseCursorListener>)listener;

- (void) update;

@property (nonatomic) CGPoint location;

- (void) setXLocked:(BOOL)xLocked yLocked:(BOOL)yLocked;
@property (nonatomic, getter=isXLocked) BOOL xLocked;
@property (nonatomic, getter=isYLocked) BOOL yLocked;

- (CGWindowID) windowIDForSoftwareCursor;

// On a Retina display and in pixel selection mode
@property (nonatomic) BOOL inRetinaPixelMode;

@property (nonatomic, readonly) CGDirectDisplayID displayID;
@property (nonatomic, readonly) NSScreen *screen;
@property (nonatomic, readonly) CGFloat displayScaleFactor;

@property (nonatomic, readonly) CGPoint unflippedLocation;
@property (nonatomic, readonly) CGPoint realLocation;
@property (nonatomic, readonly) CGPoint realUnflippedLocation;

@end


@protocol MouseCursorListener <NSObject>
- (void) mouseButtonsChanged;
- (void) mouseCursorMovedToLocation:(CGPoint)position;
- (void) mouseCursorMovedToDisplay:(CGDirectDisplayID)display;
@end
