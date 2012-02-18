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

@interface ResultView () {
    CGPoint m_mouseDownLocation;
    BOOL    m_isInDrag;
}

@end


@implementation ResultView

@synthesize color        = m_color,
            delegate     = m_delegate,
            clickEnabled = m_clickEnabled,
            dragEnabled  = m_dragEnabled;


- (BOOL) isOpaque
{
    return YES;
}


- (void) mouseDown:(NSEvent *)theEvent
{
    m_isInDrag = NO;

    m_mouseDownLocation = [theEvent locationInWindow];

    // If we don't need to track drags, do this now
    //
    if (!m_dragEnabled) {
        [m_delegate resultViewClicked:self];
    }
}


- (void) mouseUp:(NSEvent *)theEvent
{
    // If tracking drags, we don't call the delegate on mouseDown, so do it now
    //
    if (m_dragEnabled && !m_isInDrag) {
        [m_delegate resultViewClicked:self];
    }
}


- (void) mouseDragged:(NSEvent *)theEvent
{
    if (m_dragEnabled && !m_isInDrag) {
        NSPoint location = [theEvent locationInWindow];
        float   deltaX   = location.x - m_mouseDownLocation.x;
        float   deltaY   = location.y - m_mouseDownLocation.y;
        float   distance = sqrt(pow(deltaX, 2) + pow(deltaY, 2));

        if (distance > sDistanceForDrag) {
            m_isInDrag = YES;
            [m_delegate resultView:self dragInitiatedWithEvent:theEvent];
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

    CGContextSetRGBFillColor(context, [m_color red], [m_color green], [m_color blue], 1.0);
    CGContextFillRect(context, bounds);
    
    CGContextSetGrayStrokeColor(context, 0.0, 0.5);
    CGContextStrokeRect(context, NSInsetRect(bounds, 0.5, 0.5));

    CGContextRestoreGState(context);
}


- (void) setColor:(Color *)color
{
    if (m_color != color) {
        m_color = color;
        [self setNeedsDisplay:YES];
    }
}


@end
