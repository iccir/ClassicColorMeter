//
//  PreviewView.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "PreviewView.h"

@interface PreviewView () {
    NSDictionary *m_attributes;
    CGImageRef    m_image;

    NSInteger     m_zoomLevel;
    ApertureColor m_apertureColor;
    NSInteger     m_apertureSize;
    NSPoint       m_mouseLocation;
    BOOL          m_showsLocation;
}

@end

@implementation PreviewView

- (void) dealloc
{
    [m_attributes release];
    CGImageRelease(m_image);

    [super dealloc];
}


- (BOOL) isOpaque
{
    return YES;
}


- (void) drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    
    NSRect bounds = [self bounds];
    
    if (m_image) {
        CGContextSetInterpolationQuality(context, kCGInterpolationNone);

        CGFloat size         = (CGImageGetWidth(m_image) * m_zoomLevel);
        CGFloat origin       = round((bounds.size.width - size) / 2.0);
        CGRect  zoomedBounds = CGRectMake(origin, origin, size, size);
        
        CGContextDrawImage(context, zoomedBounds, m_image);
    }

    if (m_showsLocation) {
        if (!m_attributes) {
            NSFont *font = [NSFont boldSystemFontOfSize:12.0];

            m_attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                font, NSFontAttributeName,
                [NSColor whiteColor], NSForegroundColorAttributeName,
                nil];
        }
    
        NSString *locationString = [[NSString alloc] initWithFormat:@"%ld, %ld", (long)m_mouseLocation.x, (long)m_mouseLocation.y];

        CGRect textRect = [locationString boundingRectWithSize:NSMakeSize(INFINITY, INFINITY) options:0 attributes:m_attributes];

        {
            CGRect boxRect  = CGRectMake(1.0, 1.0, bounds.size.width - 2.0, textRect.size.height);
            
            CGContextSetGrayFillColor(context, 0.0, 0.5);
            CGContextFillRect(context, boxRect);
        }

        textRect.origin.x = (bounds.size.width - textRect.size.width) - 2.0;
        textRect.origin.y = 4.0;
        [locationString drawWithRect:textRect options:0 attributes:m_attributes];
        
        [locationString release];
    }

    // Draw aperture
    {
        CGFloat size   = (m_apertureSize * 16) + 10;
        CGFloat origin = round((bounds.size.width - size) / 2.0);;

        // Special case for max aperture size
        if (size >= bounds.size.width) {
            size   = 118;
            origin = 1;
        }
        
        CGRect apertureRect = CGRectMake(origin, origin, size, size);
        
        if (m_apertureSize >= 0 && m_apertureSize < 8) {
            if (m_apertureColor == ApertureColorBlack) {
                CGContextSetGrayStrokeColor(context, 0.0, 0.75);

            } else if (m_apertureColor == ApertureColorGrey) {
                CGContextSetGrayStrokeColor(context, 0.5, 0.8);

            } else if (m_apertureColor == ApertureColorWhite) {
                CGContextSetGrayStrokeColor(context, 1.0, 0.8);

            } else if (m_apertureColor == ApertureColorBlackAndWhite) {
                CGRect innerRect = CGRectInset(apertureRect, 1.5, 1.5);
                CGContextSetGrayStrokeColor(context, 1.0, 0.66);
                CGContextStrokeRect(context, innerRect);

                CGContextSetGrayStrokeColor(context, 0.0, 0.75);
            }

            CGContextStrokeRect(context, CGRectInset(apertureRect, 0.5, 0.5));
        }
    }
    
    CGRect strokeRect = NSInsetRect(bounds, 0.5, 0.5);
    CGContextSetGrayStrokeColor(context, 0.0, 0.5);
    CGContextStrokeRect(context, strokeRect);

    CGContextRestoreGState(context);
}


#pragma mark -
#pragma mark Accessors

- (void) setZoomLevel:(NSInteger)zoomLevel
{
    if (m_zoomLevel != zoomLevel) {
        m_zoomLevel = zoomLevel;
        [self setNeedsDisplay:YES];
    }
}


- (void) setApertureSize:(NSInteger)apertureSize
{
    if (m_apertureSize != apertureSize) {
        m_apertureSize = apertureSize;
        [self setNeedsDisplay:YES];
    }
}


- (void) setApertureColor:(ApertureColor)apertureColor
{
    if (m_apertureColor != apertureColor) {
        m_apertureColor = apertureColor;
        [self setNeedsDisplay:YES];
    }
}


- (void) setImage:(CGImageRef)image
{
    if (m_image != image) {
        CGImageRelease(m_image);
        m_image = CGImageRetain(image);

        [self setNeedsDisplay:YES];
    }
}


- (void) setMouseLocation:(NSPoint)mouseLocation
{
    m_mouseLocation = mouseLocation;
    [self setNeedsDisplay:YES];
}

@synthesize zoomLevel     = m_zoomLevel,
            apertureSize  = m_apertureSize,
            apertureColor = m_apertureColor,
            image         = m_image,
            mouseLocation = m_mouseLocation,
            showsLocation = m_showsLocation;
@end
