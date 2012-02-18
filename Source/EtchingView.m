//
//  EtchingView.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "EtchingView.h"

@interface EtchingView ()
@end


@implementation EtchingView

@synthesize activeDarkOpacity    = _activeDarkOpacity,
            activeLightOpacity   = _activeLightOpacity,
            inactiveDarkOpacity  = _inactiveDarkOpacity,
            inactiveLightOpacity = _inactiveLightOpacity;


- (void) drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);

    BOOL active = [[self window] isKeyWindow];

    NSRect bounds = [self bounds];

    NSRect bottomRect = bounds;
    bottomRect.size.height /= 2.0;

    NSRect topRect = bottomRect;
    topRect.origin.y += topRect.size.height;

    CGContextSetGrayFillColor(context, 1.0, (active ? _activeLightOpacity : _inactiveLightOpacity));
    CGContextFillRect(context, bottomRect);

    CGContextSetGrayFillColor(context, 0.0, (active ? _activeDarkOpacity : _inactiveDarkOpacity));
    CGContextFillRect(context, topRect);
    
    CGContextRestoreGState(context);
}


- (void) setActiveLightOpacity:(CGFloat)lightOpacity
{
    if (_activeLightOpacity != lightOpacity) {
        _activeLightOpacity = lightOpacity;
        [self setNeedsDisplay:YES];
    }
}


- (void) setActiveDarkOpacity:(CGFloat)darkOpacity
{
    if (_activeDarkOpacity != darkOpacity) {
        _activeDarkOpacity = darkOpacity;
        [self setNeedsDisplay:YES];
    }
}


- (void) setInactiveLightOpacity:(CGFloat)lightOpacity
{
    if (_inactiveLightOpacity != lightOpacity) {
        _inactiveLightOpacity = lightOpacity;
        [self setNeedsDisplay:YES];
    }
}


- (void) setInactiveDarkOpacity:(CGFloat)darkOpacity
{
    if (_inactiveDarkOpacity != darkOpacity) {
        _inactiveDarkOpacity = darkOpacity;
        [self setNeedsDisplay:YES];
    }
}

@end
