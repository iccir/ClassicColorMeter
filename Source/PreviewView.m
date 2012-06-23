//
//  PreviewView.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "PreviewView.h"
#import "MouseCursor.h"


@interface PreviewView () <MouseCursorListener>
@property (nonatomic, strong) NSDictionary *attributes;
@end


@implementation PreviewView

- (void) awakeFromNib
{
    [[MouseCursor sharedInstance] addListener:self];
}


- (void) dealloc
{
    [[MouseCursor sharedInstance] removeListener:self];

    CGImageRelease(_image);
	_image = NULL;
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
    CGRect zoomedBounds = bounds;

    if (_image) {
        CGContextSetInterpolationQuality(context, kCGInterpolationNone);

        CGFloat size   = ((CGImageGetWidth(_image) / _imageScale) * _zoomLevel);
        CGFloat origin = round((bounds.size.width - size) / 2.0);
        
        zoomedBounds = CGRectMake(origin, origin, size, size);
        
        CGFloat zoomTweak = 0.0;
        if (_imageScale > 1) {
            zoomTweak = (_zoomLevel / (_imageScale * _imageScale));
        }
           
        CGRect zoomedImageBounds = zoomedBounds;
        zoomedImageBounds.origin.x -= (_offset.x * _zoomLevel) - zoomTweak;
        zoomedImageBounds.origin.y += (_offset.y * _zoomLevel) - zoomTweak;
        
        CGContextDrawImage(context, zoomedImageBounds, _image);
    }

    if (!_attributes && (_showsLocation || [_statusText length])) {
        NSFont *font = [NSFont boldSystemFontOfSize:12.0];

        _attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
            font, NSFontAttributeName,
            [NSColor whiteColor], NSForegroundColorAttributeName,
            nil];
    }

    if (_showsLocation) {
        MouseCursor *cursor = [MouseCursor sharedInstance];
        CGPoint location = [cursor location];

        NSString *locationString;
        if ([cursor inRetinaPixelMode]) {
            locationString = [[NSString alloc] initWithFormat:@"%.1lf, %.1lf", (double)location.x, (double)location.y];
        } else {
            locationString = [[NSString alloc] initWithFormat:@"%ld, %ld", (long)location.x, (long)location.y];
        }

        CGRect textRect = [locationString boundingRectWithSize:NSMakeSize(INFINITY, INFINITY) options:0 attributes:_attributes];

        {
            CGRect boxRect  = CGRectMake(1.0, 1.0, bounds.size.width - 2.0, textRect.size.height);
            
            CGContextSetGrayFillColor(context, 0.0, 0.5);
            CGContextFillRect(context, boxRect);
        }

        textRect.origin.x = (bounds.size.width - textRect.size.width) - 2.0;
        textRect.origin.y = 4.0;
        [locationString drawWithRect:textRect options:0 attributes:_attributes];
    }


    if ([_statusText length]) {
        CGRect textRect = [_statusText boundingRectWithSize:NSMakeSize(INFINITY, INFINITY) options:0 attributes:_attributes];

        {
            CGRect boxRect  = CGRectMake(1.0, (bounds.size.height - textRect.size.height) - 1.0, bounds.size.width - 2.0, textRect.size.height);
            
            CGContextSetGrayFillColor(context, 0.0, 0.5);
            CGContextFillRect(context, boxRect);
        }

        textRect.origin.x = (bounds.size.width - textRect.size.width) - 2.0;
        textRect.origin.y = (bounds.size.height - textRect.size.height) + 3;
        [_statusText drawWithRect:textRect options:0 attributes:_attributes];
    }


    // Draw aperture
    {
        CGAffineTransform transform = CGAffineTransformMakeScale(_zoomLevel, _zoomLevel);
        CGRect apertureRect = CGRectApplyAffineTransform(_apertureRect, transform);

        if (apertureRect.size.width < bounds.size.width) {
            apertureRect = CGRectInset(apertureRect, -1, -1);
        } else {
            apertureRect = CGRectInset(apertureRect, 1, 1);
        }
        

        apertureRect.origin.x += zoomedBounds.origin.x;
        apertureRect.origin.y += zoomedBounds.origin.y;

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

    CGRect strokeRect = NSInsetRect(bounds, 0.5, 0.5);
    CGContextSetGrayStrokeColor(context, 0.0, 0.5);
    CGContextStrokeRect(context, strokeRect);

    CGContextRestoreGState(context);
}


- (BOOL) canBecomeKeyView
{
    return YES;
}


#pragma mark -
#pragma mark Mouse Cursor

- (void) mouseCursorMovedToLocation:(CGPoint)position
{
    if (_showsLocation) {
        [self setNeedsDisplay:YES];
    }
}


- (void) mouseCursorMovedToDisplay:(CGDirectDisplayID)display
{
}


#pragma mark -
#pragma mark Accessors

- (void) setZoomLevel:(NSInteger)zoomLevel
{
    if (zoomLevel < 1) {
        zoomLevel = 1;
    }

    if (_zoomLevel != zoomLevel) {
        _zoomLevel = zoomLevel;
        [self setNeedsDisplay:YES];
    }
}


- (void) setOffset:(CGPoint)offset
{
    if (!CGPointEqualToPoint(_offset, offset)) {
        _offset = offset;
        [self setNeedsDisplay:YES];
    }
}


- (void) setImageScale:(CGFloat)imageScale
{
    if (_imageScale != imageScale) {
        _imageScale = imageScale;
        [self setNeedsDisplay:YES];
    }
}


- (void) setApertureRect:(CGRect)apertureRect
{
    if (!CGRectEqualToRect(_apertureRect, apertureRect)) {
        _apertureRect = apertureRect;
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


- (void) setShowsLocation:(BOOL)showsLocation
{
    if (_showsLocation != showsLocation) {
        _showsLocation = showsLocation;
        [self setNeedsDisplay:YES];
    }
}


- (void) setStatusText:(NSString *)statusText
{
    if (_statusText != statusText) {
        _statusText = statusText;
        [self setNeedsDisplay:YES];
    }
}


@end
