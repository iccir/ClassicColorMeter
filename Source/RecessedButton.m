//
//  RecessedButton.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 9/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "RecessedButton.h"
#import "Util.h"

@interface RecessedButtonCell () 
@property (nonatomic, assign) NSRect arrowRect;
@end


static NSBezierPath *sGetArrowPath(CGRect rect)
{
    NSBezierPath *path = [NSBezierPath bezierPath];

    [path moveToPoint:NSMakePoint(NSMinX(rect), NSMinY(rect))];
    [path lineToPoint:NSMakePoint(NSMaxX(rect), NSMinY(rect))];
    [path lineToPoint:NSMakePoint(NSMidX(rect), NSMaxY(rect))];
    [path lineToPoint:NSMakePoint(NSMinX(rect), NSMinY(rect))];
    [path closePath];
    
    return path;
}


@implementation RecessedButtonCell

@synthesize arrowRect = _arrowRect;


- (void) drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
    [super drawBezelWithFrame:frame inView:controlView];

    _arrowRect = frame;
    _arrowRect.size     = NSMakeSize(7, 5);
    _arrowRect.origin.x = NSMaxX(frame) - 14.0;
    _arrowRect.origin.y = floor(NSMidY(frame) - (_arrowRect.size.height / 2.0));
}

- (NSRect) drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView*)controlView
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    BOOL drawArrow = (_arrowRect.size.width > 0);
    
    if (drawArrow) {
        CGContextSaveGState(context);
        
        CGImageRef cgImage = CreateImageMask(frame.size, 1, ^(CGContextRef context) {
            CGRect bounds = frame;
            bounds.origin = CGPointZero;

            CGFloat startLocation = (frame.size.width - 17.0) / frame.size.width;
            CGFloat endLocation   = (frame.size.width - 11.0) / frame.size.width;
            
            NSGradient *g = [[NSGradient alloc] initWithColorsAndLocations:
                [NSColor whiteColor], 0.0,
                [NSColor whiteColor], startLocation,
                [NSColor darkGrayColor], endLocation,
                nil];
                
            [g drawInRect:bounds angle:0];
        });
        
        CGContextClipToMask(context, frame, cgImage);        
        
        CGImageRelease(cgImage);
    }
    
    NSRect rect = [super drawTitle:title withFrame:frame inView:controlView];
    
    if (drawArrow) {
        CGContextRestoreGState(context);
        CGContextSaveGState(context);

        NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowOffset:NSMakeSize(0, -1)];
        [shadow setShadowBlurRadius:1.0];
        [shadow set];

        NSBezierPath *path = sGetArrowPath(_arrowRect);
        [[NSColor whiteColor] set];
        [path fill];
        
        CGContextRestoreGState(context);    
        
        _arrowRect = CGRectZero;
    }
    
    return rect;
}

@end


@implementation RecessedButton

- (id) initWithCoder:(NSCoder *)coder
{
    if ((self = [super initWithCoder:coder])) {
        if (![self target] && ![self action]) {
            [self setTarget:self];
            [self setAction:@selector(_showPopUpMenu:)];
        }
    }

    return self;
}


- (void) _showPopUpMenu:(id)sender
{
    NSMenu *menu   = [self menu];
    NSRect  bounds = [self bounds];

    [menu setMinimumWidth:bounds.size.width];
    [menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(0, 22) inView:self];
}

@end
