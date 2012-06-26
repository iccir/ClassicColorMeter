//
//  ResultView.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "ResultView.h"
#import "Util.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat sDistanceForDrag = 10.0;

@interface ResultView ()
@property (nonatomic, assign) CGPoint mouseDownLocation;
@property (nonatomic, assign, getter=isInDrag) BOOL inDrag;
@end


@implementation ResultView

- (void) dealloc
{
    if (_colorSpace) {
        CFRelease(_colorSpace);
        _colorSpace = NULL;
    }
}


- (BOOL) isOpaque
{
    return YES;
}


- (void) mouseDown:(NSEvent *)theEvent
{
    _inDrag = NO;

    _mouseDownLocation = [theEvent locationInWindow];

    // If we don't need to track drags, do this now
    //
    if (!_dragEnabled) {
        [_delegate resultViewClicked:self];
    }
}


- (void) mouseUp:(NSEvent *)theEvent
{
    // If tracking drags, we don't call the delegate on mouseDown, so do it now
    //
    if (_dragEnabled && !_inDrag) {
        [_delegate resultViewClicked:self];
    }
}


- (void) mouseDragged:(NSEvent *)theEvent
{
    if (_dragEnabled && !_inDrag) {
        NSPoint location = [theEvent locationInWindow];
        float   deltaX   = location.x - _mouseDownLocation.x;
        float   deltaY   = location.y - _mouseDownLocation.y;
        float   distance = sqrt(pow(deltaX, 2) + pow(deltaY, 2));

        if (distance > sDistanceForDrag) {
            _inDrag = YES;
            [_delegate resultView:self dragInitiatedWithEvent:theEvent];
        }
    }
}


- (BOOL) mouseDownCanMoveWindow
{
    // This is cached by AppKit, so we can't generate it dynamically based on _clickEnabled/_dragEnabled :(
    return NO;
}


- (void) doPopOutAnimation
{
    CGRect  bounds          = [self bounds];
    CGRect  boundsInBase    = [self convertRect:bounds toView:nil];
    CGRect  boundsInScreen  = [[self window] convertRectToScreen:boundsInBase];

    CGFloat halfWidth       = boundsInBase.size.width  * 0.25;
    CGFloat halfHeight      = boundsInBase.size.height * 0.25;
    CGRect  fakeWindowFrame = CGRectInset(boundsInScreen, -halfWidth, -halfHeight);

    CGRect  startingFrame   = CGRectMake(halfWidth, halfHeight, bounds.size.width, bounds.size.height);
    CGRect  endingFrame     = CGRectMake(0, 0, fakeWindowFrame.size.width, fakeWindowFrame.size.height);
    
    NSWindow *fakeWindow  = [[NSWindow alloc] initWithContentRect:fakeWindowFrame styleMask:0 backing:0 defer:NO];
    NSView   *contentView = [fakeWindow contentView]; 

    [fakeWindow setOpaque:NO];
    [fakeWindow setBackgroundColor:[NSColor clearColor]];

    CALayer *snapshot = [CALayer layer];
    
    [snapshot setFrame:startingFrame];
    [snapshot setContents:GetSnapshotImageForView(self)];
    [snapshot setMagnificationFilter:kCAFilterNearest];

    [contentView setWantsLayer:YES];
    [[contentView layer] addSublayer:snapshot];
    
    [[self window] addChildWindow:fakeWindow ordered:NSWindowAbove];
    [fakeWindow orderFront:self];
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.35];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    
    [CATransaction setCompletionBlock:^{
        [[self window] removeChildWindow:fakeWindow];
    }];

    [snapshot setFrame:endingFrame];
    [snapshot setOpacity:0.0];

    [CATransaction commit];

}


- (void) drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);

    NSRect bounds = [self bounds];

    if (_colorSpace) {
        CGContextSetFillColorSpace(context, _colorSpace);
        CGContextSetStrokeColorSpace(context, _colorSpace);
    }

    CGFloat components[4] = { [_color red], [_color green], [_color blue], 1.0 };
    CGContextSetFillColor(context, components);
    CGContextFillRect(context, bounds);
    
    if (_drawsBorder) {
        CGContextSetGrayStrokeColor(context, 0.0, 0.5);
        CGContextStrokeRect(context, NSInsetRect(bounds, 0.5, 0.5));
    }

    CGContextRestoreGState(context);
}


- (void) setColorSpace:(CGColorSpaceRef)colorSpace
{
    if (_colorSpace != colorSpace) {
        CGColorSpaceRelease(_colorSpace);
        _colorSpace = colorSpace;
        CGColorSpaceRetain(_colorSpace);

        [self setNeedsDisplay:YES];
    }
}


- (void) setColor:(Color *)color
{
    if (_color != color) {
        _color = color;
        [self setNeedsDisplay:YES];
    }
}


- (void) setDrawsBorder:(BOOL)drawsBorder
{
    if (_drawsBorder != drawsBorder) {
        _drawsBorder = drawsBorder;
        [self setNeedsDisplay:YES];
    }
}


@end
