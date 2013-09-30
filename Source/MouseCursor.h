//
//  MouseCursor.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2012-06-14.
//
//

#import <Foundation/Foundation.h>

@protocol MouseCursorListener;


@interface MouseCursor : NSObject

+ (id) sharedInstance;

// Allows sub-pixel positioning
- (void) movePositionByXDelta:(CGFloat)xDelta yDelta:(CGFloat)yDelta;

- (void) addListener:(id<MouseCursorListener>)listener;
- (void) removeListener:(id<MouseCursorListener>)listener;

- (void) update;

@property (nonatomic, assign) CGPoint location;

- (void) setXLocked:(BOOL)xLocked yLocked:(BOOL)yLocked;
@property (nonatomic, assign, getter=isXLocked) BOOL xLocked;
@property (nonatomic, assign, getter=isYLocked) BOOL yLocked;

- (CGWindowID) windowIDForSoftwareCursor;

// On a Retina display and in pixel selection mode
@property (nonatomic, assign) BOOL inRetinaPixelMode;

@property (nonatomic, assign, readonly) CGDirectDisplayID displayID;
@property (nonatomic, retain, readonly) NSScreen *screen;
@property (nonatomic, assign, readonly) CGFloat displayScaleFactor;

@property (nonatomic, assign, readonly) CGPoint unflippedLocation;
@property (nonatomic, assign, readonly) CGPoint realLocation;
@property (nonatomic, assign, readonly) CGPoint realUnflippedLocation;

@end


@protocol MouseCursorListener <NSObject>
- (void) mouseCursorMovedToLocation:(CGPoint)position;
- (void) mouseCursorMovedToDisplay:(CGDirectDisplayID)display;
@end
