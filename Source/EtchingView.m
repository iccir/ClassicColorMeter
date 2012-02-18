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

@synthesize activeDarkOpacity    = m_activeDarkOpacity,
            activeLightOpacity   = m_activeLightOpacity,
            inactiveDarkOpacity  = m_inactiveDarkOpacity,
            inactiveLightOpacity = m_inactiveLightOpacity;


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

    CGContextSetGrayFillColor(context, 1.0, (active ? m_activeLightOpacity : m_inactiveLightOpacity));
    CGContextFillRect(context, bottomRect);

    CGContextSetGrayFillColor(context, 0.0, (active ? m_activeDarkOpacity : m_inactiveDarkOpacity));
    CGContextFillRect(context, topRect);
    
    CGContextRestoreGState(context);
}


- (void) setActiveLightOpacity:(CGFloat)lightOpacity
{
    if (m_activeLightOpacity != lightOpacity) {
        m_activeLightOpacity = lightOpacity;
        [self setNeedsDisplay:YES];
    }
}


- (void) setActiveDarkOpacity:(CGFloat)darkOpacity
{
    if (m_activeDarkOpacity != darkOpacity) {
        m_activeDarkOpacity = darkOpacity;
        [self setNeedsDisplay:YES];
    }
}


- (void) setInactiveLightOpacity:(CGFloat)lightOpacity
{
    if (m_inactiveLightOpacity != lightOpacity) {
        m_inactiveLightOpacity = lightOpacity;
        [self setNeedsDisplay:YES];
    }
}


- (void) setInactiveDarkOpacity:(CGFloat)darkOpacity
{
    if (m_inactiveDarkOpacity != darkOpacity) {
        m_inactiveDarkOpacity = darkOpacity;
        [self setNeedsDisplay:YES];
    }
}

@end
