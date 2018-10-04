//
//  ColorSliderCell.m
//  ColorMeter
//
//  Created by Ricci Adams on 2011-07-29.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "ColorSliderCell.h"
#import <AppKit/AppKit.h>


@implementation ColorSliderCell

#pragma mark - Drawing

- (void) _drawColorBackgroundInRect:(CGRect)inRect context:(CGContextRef)context
{
    CGRect  rect = inRect;
    CGFloat maxX = NSMaxX(inRect);

    ColorComponent component = _component;

    rect.size.width = 1.0;
    
    if (component != ColorComponentNone) {
        Color *color = [_color copy];

        CGColorSpaceRef colorSpace = [color colorSpace];
        if (colorSpace) {
            CGContextSetFillColorSpace(context, colorSpace);
        }
    
        while (rect.origin.x <= maxX) {
            float percent = (rect.origin.x - inRect.origin.x) / inRect.size.width;

            [color setFloatValue:percent forComponent:component];

            float r, g, b;
            [color getRed:&r green:&g blue:&b];
            
            CGFloat components[4] = { r, g, b, 1.0 };
            CGContextSetFillColor(context, components);
            CGContextFillRect(context, rect);
            rect.origin.x += 1.0;
        }
    }
}


- (void) drawBarInside:(NSRect)aRect flipped:(BOOL)flipped
{
//    static CGFloat const sXInset = 3;
//    static CGFloat const sYInset = 5;

    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];

    CGFloat xRadius   = aRect.size.width  / 2.0;
    CGFloat yRadius   = aRect.size.height / 2.0;
    CGFloat minRadius = MIN(xRadius, yRadius);
    
    CGContextSaveGState(context);

    NSBezierPath *barPath = [NSBezierPath bezierPathWithRoundedRect:aRect xRadius:minRadius yRadius:minRadius];

    NSColor *foregroundColor = [NSColor textColor];

    CGContextSetStrokeColorWithColor(context, [[foregroundColor colorWithAlphaComponent:0.35] CGColor]);

    [barPath addClip];
    
    [self _drawColorBackgroundInRect:aRect context:context];

    [barPath stroke];


    CGContextRestoreGState(context);
}


- (void) drawKnob:(NSRect)rect
{
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];

    if ([self isEnabled]) {
        if (IsAppearanceDarkAqua([self controlView])) {
            rect = CGRectInset(rect, 3, 3);

            [[_color NSColor] set];

            CGContextSaveGState(context);

            NSShadow *shadow = [[NSShadow alloc] init];
            
            [shadow setShadowBlurRadius:1];
            [shadow setShadowColor:[NSColor colorWithWhite:0.0 alpha:0.5]];
            [shadow setShadowOffset:NSMakeSize(0, -0.5)];
            [shadow set];

            NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:rect];
            [path fill];

            CGContextRestoreGState(context);

            [path addClip];

            CGContextSetStrokeColorWithColor(context, [[[NSColor textColor] colorWithAlphaComponent:0.35] CGColor]);
            [path setLineWidth:2];
            [path stroke];

        } else {
            [super drawKnob:rect];
        }
    }
}


#pragma mark - Accessors

- (void) setComponent:(ColorComponent)component
{
    if (component != _component) {
        _component = component;
        [[self controlView] setNeedsDisplay:YES];
    }
}

@end
