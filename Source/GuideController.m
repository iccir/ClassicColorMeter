//
//  GuideView.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2012-06-18.
//
//

#import "GuideController.h"

#import "MouseCursor.h"
#import <QuartzCore/QuartzCore.h>

@interface GuideController () <MouseCursorListener>
@end


@implementation GuideController {
    MouseCursor *_cursor;

    NSWindow    *_horizontalWindow;
    NSImageView *_horizontalView;

    NSWindow    *_verticalWindow;
    NSImageView *_verticalView;
}


+ (GuideController *) sharedInstance
{
    static id sSharedInstance = nil;
    if (!sSharedInstance) sSharedInstance= [[self alloc] init];
    return sSharedInstance;
}


- (id) init
{
    if ((self = [super init])) {
         _cursor = [MouseCursor sharedInstance];
        [_cursor addListener:self];

         void (^makeWindowAndView)(NSWindow **, NSImageView **) = ^(NSWindow **outWindow, NSImageView **outView) {
            NSWindow *window = [[NSWindow alloc] initWithContentRect:NSZeroRect styleMask:0 backing:NSBackingStoreBuffered defer:NO];
            
            NSImageView *view = [[NSImageView alloc] initWithFrame:NSZeroRect];

            [window setOpaque:NO];
            [window setBackgroundColor:[NSColor clearColor]];
            [window setLevel:kCGMaximumWindowLevel];
            [window setSharingType:NSWindowSharingNone];
            [window setAnimationBehavior:NSWindowAnimationBehaviorNone];
            [window setIgnoresMouseEvents:YES];

            [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
            [view setImageScaling:NSImageScaleAxesIndependently];
            [[window contentView] addSubview:view];
            
            *outWindow = window;
            *outView   = view;
        };

        {
            NSWindow *horizontalWindow;
            NSImageView *horizontalView;

            makeWindowAndView(&horizontalWindow, &horizontalView);

            _horizontalWindow = horizontalWindow;
            _horizontalView   = horizontalView;
        }

        {
            NSWindow *verticalWindow;
            NSImageView *verticalView;

            makeWindowAndView(&verticalWindow, &verticalView);

            _verticalWindow = verticalWindow;
            _verticalView   = verticalView;
        }
    }
    
    return self;
}


- (void) dealloc
{
    [[MouseCursor sharedInstance] removeListener:self];
}


- (void) _updateContents
{
    CGFloat scale = [_cursor displayScaleFactor];
    
    NSImage *(^makeImage)(BOOL) = ^(BOOL rotate) {
        CGImageRef cgImage = CreateImage(CGSizeMake(3, 3), NO, scale, ^(CGContextRef context) {
            if (rotate) {
                CGContextTranslateCTM(context, 1.5, 1.5);
                CGContextRotateCTM(context, -M_PI / 2.0);
                CGContextTranslateCTM(context, -1.5, -1.5);
            }

            CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
            CGFloat black[4] = { 0.0, 0.0, 0.0, 0.66 };
            CGFloat white[4] = { 1.0, 1.0, 1.0, 0.25 };
            
            CGFloat thickness = 1.0 / scale;
            
            CGContextSetFillColorSpace(context, space);

            CGContextSetFillColor(context, black);
            CGContextFillRect(context, CGRectMake(0, 1, 3, thickness));
            
            CGContextSetFillColor(context, white);
            CGContextFillRect(context, CGRectMake(0, 1 - thickness, 3, thickness));
            CGContextFillRect(context, CGRectMake(0, 1 + thickness, 3, thickness));
            
            CGColorSpaceRelease(space);
        });

        return [[NSImage alloc] initWithCGImage:cgImage size:CGSizeMake(3, 3)];
    };


    NSImage *horizontalImage = makeImage(NO);
    NSImage *verticalImage   = makeImage(YES);

    [_horizontalView setImage:horizontalImage];
    [_verticalView   setImage:verticalImage];
}


- (void) _updateLocation
{
    NSScreen *screen = [_cursor screen];
    NSRect screenFrame = [screen frame];
    
    CGPoint location = [_cursor unflippedLocation];

    if ([_cursor isYLocked]) {
        [_horizontalWindow orderFront:self];

        CGFloat remainder = fmod(location.y, 1.0);
        location.y -= remainder;

        [_horizontalView   setFrameOrigin:CGPointMake(0, remainder)];
        [_horizontalWindow setFrame:CGRectMake(screenFrame.origin.x, location.y - 1.0, screenFrame.size.width, 3.0) display:YES];
    }

    if ([_cursor isXLocked]) {
        [_verticalWindow orderFront:self];
        
        CGFloat remainder = fmod(location.x, 1.0);
        location.x -= remainder;

        [_verticalView   setFrameOrigin:CGPointMake(remainder, 0)];
        [_verticalWindow setFrame:CGRectMake(location.x - 1.0, screenFrame.origin.y, 3.0, screenFrame.size.height) display:YES];
    }
}


- (void) update
{
    [self _updateLocation];
    [self _updateContents];
    
    if ([_cursor isYLocked]) {
        [_horizontalWindow display];
    } else {
        [_horizontalWindow orderOut:self];
    }

    if ([_cursor isXLocked]) {
        [_verticalWindow display];
    } else {
        [_verticalWindow orderOut:self];
    }
}


- (void) mouseCursorMovedToLocation:(CGPoint)position
{
    [self _updateLocation];
}


- (void) mouseCursorMovedToDisplay:(CGDirectDisplayID)display
{
    [self _updateLocation];
    [self _updateContents];
}


- (id<CAAction>) actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    return (id)[NSNull null];
}


- (void) setEnabled:(BOOL)enabled
{
    if (_enabled != enabled) {
        _enabled = enabled;
        [self update];
    }
}


@end
