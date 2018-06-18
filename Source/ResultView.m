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
@property (nonatomic) CGPoint mouseDownLocation;
@property (nonatomic, getter=isInDrag) BOOL inDrag;
@end


@implementation ResultView

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


- (void) drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    CGContextSaveGState(context);

    NSRect bounds = [self bounds];

    CGColorSpaceRef colorSpace = [_color colorSpace];
    
    if (colorSpace) {
        CGContextSetFillColorSpace(context, colorSpace);
        CGContextSetStrokeColorSpace(context, colorSpace);
    }

    CGFloat components[4] = { [_color red], [_color green], [_color blue], 1.0 };
    CGContextSetFillColor(context, components);
    CGContextFillRect(context, bounds);
    
    if (_drawsBorder) {
        CGContextSetGrayStrokeColor(context, 0.0, 0.33);

        if ([[self window] backingScaleFactor] > 1) {
            CGRect strokeRect = NSInsetRect(bounds, 0.25, 0.25);
            CGContextSetLineWidth(context, 0.5);
            CGContextStrokeRect(context, strokeRect);
        } else {
            CGRect strokeRect = NSInsetRect(bounds, 0.5, 0.5);
            CGContextSetLineWidth(context, 0.25);
            CGContextStrokeRect(context, strokeRect);
        }
    }

    CGContextRestoreGState(context);
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
