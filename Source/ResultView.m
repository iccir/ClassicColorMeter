//
//  ResultView.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "ResultView.h"

@interface ResultView () {
    Color _color;
}

@end


@implementation ResultView

- (void) drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);

    NSRect bounds = [self bounds];

    CGContextSetRGBFillColor(context, _color.red, _color.green, _color.blue, 1.0);
    CGContextFillRect(context, bounds);
    
    CGContextSetGrayStrokeColor(context, 0.0, 0.5);
    CGContextStrokeRect(context, NSInsetRect(bounds, 0.5, 0.5));

    CGContextRestoreGState(context);
}


- (void) setColor:(Color)color
{
    _color = color;
    [self setNeedsDisplay:YES];
}

@synthesize color = _color;

@end
