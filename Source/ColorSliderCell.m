//
//  ColorSliderCell.m
//  ColorMeter
//
//  Created by Ricci Adams on 2011-07-29.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "ColorSliderCell.h"
#import <AppKit/AppKit.h>

@interface ColorSliderCell () {
    ColorComponent _component;
    Color *_color;
}

@end



@implementation ColorSliderCell

- (void) dealloc
{
    [_color release];
    [super dealloc];
}


#pragma mark -
#pragma mark Drawing

static void sDrawColorBackground(ColorSliderCell *self, CGContextRef context, NSRect inRect)
{
    CGRect   rect     = inRect;
    CGFloat  maxX     = NSMaxX(inRect);

    ColorComponent component = self->_component;

    rect.size.width = 1.0;
    
    if (component != ColorComponentNone) {
        Color *color = [self->_color copy];
    
        while (rect.origin.x <= maxX) {
            float percent = (rect.origin.x - inRect.origin.x) / inRect.size.width;

            [color setFloatValue:percent forComponent:component];

            CGContextSetRGBFillColor(context, [color red], [color green], [color blue], 1.0);
            CGContextFillRect(context, rect);
            rect.origin.x += 1.0;
        }

        [color release];
    }
}


- (void) drawBarInside:(NSRect)aRect flipped:(BOOL)flipped
{
    static CGFloat const sXInset = 3;
    static CGFloat const sYInset = 5;

    NSImage *leftCap  = [NSImage imageNamed:@"slider_cover_leftcap"];
    NSImage *center   = [NSImage imageNamed:@"slider_cover_center"];
    NSImage *rightCap = [NSImage imageNamed:@"slider_cover_rightcap"];

    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

    CGFloat xRadius   = ((aRect.size.width  / 2.0) - sXInset);
    CGFloat yRadius   = ((aRect.size.height / 2.0) - sYInset);
    CGFloat minRadius = MIN(xRadius, yRadius);
    
    CGRect barRect = CGRectInset(aRect, sXInset, sYInset);
    CGRect shadowRect = barRect;
    shadowRect.origin.y += 1.5;

    CGRect coverRect = barRect;
    coverRect.size.height = [center size].height;

    CGContextSaveGState(context);
    {
        NSBezierPath *eraserPath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(barRect, -1, 2) xRadius:minRadius yRadius:minRadius];
        BOOL isKey = [[[self controlView] window] isKeyWindow];
        [[NSColor colorWithDeviceWhite:(isKey ? 0.8 : 0.9) alpha:1.0] set];
        [eraserPath fill];

        CGContextSaveGState(context);
        {
            NSBezierPath *barPath = [NSBezierPath bezierPathWithRoundedRect:barRect xRadius:minRadius yRadius:minRadius];
            [barPath addClip];
            sDrawColorBackground(self, context, aRect);
        }
        CGContextRestoreGState(context);

        NSDrawThreePartImage(coverRect, leftCap, center, rightCap, NO, NSCompositeSourceOver, 1.0, YES);
    }
    CGContextRestoreGState(context);
}

- (void) drawKnob:(NSRect)rect
{
    if ([self isEnabled]) {
        [super drawKnob:rect];
    }
}


#pragma mark -
#pragma mark Accessors

- (void) setComponent:(ColorComponent)component
{
    if (component != _component) {
        _component = component;
        [[self controlView] setNeedsDisplay:YES];
    }
}

@synthesize component = _component,
            color     = _color;

@end
