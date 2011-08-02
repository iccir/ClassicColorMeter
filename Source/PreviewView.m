//
//  PreviewView.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "PreviewView.h"

@interface PreviewView () {
    NSDictionary *_attributes;
    CGImageRef    _image;

    NSInteger     _zoomLevel;
    ApertureColor _apertureColor;
    NSInteger     _apertureSize;
    NSPoint       _mouseLocation;
    BOOL          _showsLocation;
}

@end

@implementation PreviewView

- (void) dealloc
{
    [_attributes release];
    CGImageRelease(_image);

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
    
    if (_image) {
        CGContextSetInterpolationQuality(context, kCGInterpolationNone);

        CGFloat size         = (CGImageGetWidth(_image) * _zoomLevel);
        CGFloat origin       = round((bounds.size.width - size) / 2.0);
        CGRect  zoomedBounds = CGRectMake(origin, origin, size, size);
        
        CGContextDrawImage(context, zoomedBounds, _image);
    }

    if (_showsLocation) {
        if (!_attributes) {
            NSFont *font = [NSFont boldSystemFontOfSize:12.0];

            _attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                font, NSFontAttributeName,
                [NSColor whiteColor], NSForegroundColorAttributeName,
                nil];
        }
    
        NSString *locationString = [[NSString alloc] initWithFormat:@"%ld, %ld", (long)_mouseLocation.x, (long)_mouseLocation.y];

        CGRect textRect = [locationString boundingRectWithSize:NSMakeSize(INFINITY, INFINITY) options:0 attributes:_attributes];

        {
            CGRect boxRect  = CGRectMake(1.0, 1.0, bounds.size.width - 2.0, textRect.size.height);
            
            CGContextSetGrayFillColor(context, 0.0, 0.5);
            CGContextFillRect(context, boxRect);
        }

        textRect.origin.x = (bounds.size.width - textRect.size.width) - 2.0;
        textRect.origin.y = 4.0;
        [locationString drawWithRect:textRect options:0 attributes:_attributes];
        
        [locationString release];
    }

    // Draw aperture
    {
        CGFloat size   = (_apertureSize * 16) + 10;
        CGFloat origin = round((bounds.size.width - size) / 2.0);;

        // Special case for max aperture size
        if (size >= bounds.size.width) {
            size   = 118;
            origin = 1;
        }
        
        CGRect apertureRect = CGRectMake(origin, origin, size, size);
        
        if (_apertureSize >= 0 && _apertureSize < 8) {
            if (_apertureColor == ApertureColorBlack) {
                CGContextSetGrayStrokeColor(context, 0.0, 0.75);

            } else if (_apertureColor == ApertureColorGrey) {
                CGContextSetGrayStrokeColor(context, 0.5, 0.8);

            } else if (_apertureColor == ApertureColorWhite) {
                CGContextSetGrayStrokeColor(context, 1.0, 0.8);

            } else if (_apertureColor == ApertureColorBlackAndWhite) {
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
    if (_zoomLevel != zoomLevel) {
        _zoomLevel = zoomLevel;
        [self setNeedsDisplay:YES];
    }
}


- (void) setApertureSize:(NSInteger)apertureSize
{
    if (_apertureSize != apertureSize) {
        _apertureSize = apertureSize;
        [self setNeedsDisplay:YES];
    }
}


- (void) setApertureColor:(ApertureColor)apertureColor
{
    if (_apertureColor != apertureColor) {
        _apertureColor = apertureColor;
        [self setNeedsDisplay:YES];
    }
}


- (void) setImage:(CGImageRef)image
{
    if (_image != image) {
        CGImageRelease(_image);
        _image = CGImageRetain(image);

        [self setNeedsDisplay:YES];
    }
}


- (void) setMouseLocation:(NSPoint)mouseLocation
{
    _mouseLocation = mouseLocation;
    [self setNeedsDisplay:YES];
}

@synthesize zoomLevel     = _zoomLevel,
            apertureSize  = _apertureSize,
            apertureColor = _apertureColor,
            image         = _image,
            mouseLocation = _mouseLocation,
            showsLocation = _showsLocation;
@end
