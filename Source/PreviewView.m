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
@end


@implementation PreviewView {
    NSTextField *_topLabelField;
    NSTextField *_bottomLabelField;
}


- (void) awakeFromNib
{
    [[MouseCursor sharedInstance] addListener:self];

    NSTextField *(^makeLabel)() = ^{
        NSTextField *label = [NSTextField labelWithString:@""];

        [label setFont:[NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightMedium]];
        [label setAlignment:NSTextAlignmentCenter];
        [label setTextColor:[NSColor whiteColor]];

        [label setBackgroundColor:[NSColor colorWithWhite:0 alpha:0.5]];
        [label setDrawsBackground:YES];

        [label setHidden:YES];

        [self addSubview:label];

        return label;
    };

    _topLabelField    = makeLabel();
    _bottomLabelField = makeLabel();
    
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


- (void) layout
{
    // Do not call super
    
    CGRect  bounds = [self bounds];
    CGFloat onePixel = 1.0 / [[self window] backingScaleFactor];

    // Layout bottom label
    {
        CGRect bottomFrame = bounds;
        bottomFrame.size.height = 18;
        bottomFrame = CGRectInset(bottomFrame, onePixel, onePixel);

        [_bottomLabelField setFrame:bottomFrame];
    }

    // Layout top label
    {
        CGRect topFrame = bounds;
        topFrame.size.height = 16;
        topFrame.origin.y = bounds.size.height - topFrame.size.height;
        topFrame = CGRectInset(topFrame, onePixel, onePixel);

        [_topLabelField setFrame:topFrame];
    }
}


- (void) drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    CGContextSaveGState(context);
 
    NSRect bounds = [self bounds];
    CGRect zoomedBounds = bounds;

    [[NSColor colorWithWhite:0.25 alpha:1.0] set];
    NSRectFill(bounds); 
       
    CGFloat scale = [[self window] backingScaleFactor];
    CGFloat onePixel  = 1.0 / scale;

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

        if (_apertureOutline == ApertureOutlineBlack) {
            CGContextSetGrayStrokeColor(context, 0.0, 0.75);

        } else if (_apertureOutline == ApertureOutlineGrey) {
            CGContextSetGrayStrokeColor(context, 0.5, 0.8);

        } else if (_apertureOutline == ApertureOutlineWhite) {
            CGContextSetGrayStrokeColor(context, 1.0, 0.8);

        } else if (_apertureOutline == ApertureOutlineBlackAndWhite) {
            CGRect innerRect = CGRectInset(apertureRect, 1.5, 1.5);
            CGContextSetGrayStrokeColor(context, 1.0, 0.66);
            CGContextStrokeRect(context, innerRect);

            CGContextSetGrayStrokeColor(context, 0.0, 0.75);
        }

        CGContextStrokeRect(context, CGRectInset(apertureRect, 0.5, 0.5));
    }

    CGFloat borderAlpha = IsAppearanceDarkAqua(self) ? 0.5 : 0.33;
    [[NSColor colorWithWhite:0 alpha:borderAlpha] set];

    CGRect strokeRect = NSInsetRect(bounds, onePixel / 2.0, onePixel / 2.0);
    CGContextSetLineWidth(context, onePixel);
    CGContextStrokeRect(context, strokeRect);
    
    CGContextRestoreGState(context);
}


- (BOOL) canBecomeKeyView
{
    return YES;
}


#pragma mark - Private Methods

- (void) _updateBottomLabel
{
    NSString *locationString;

    if (_showsLocation) {
        MouseCursor *cursor = [MouseCursor sharedInstance];
        CGPoint location = [cursor location];

        if ([cursor inRetinaPixelMode]) {
            locationString = [[NSString alloc] initWithFormat:@"%.1lf, %.1lf", (double)location.x, (double)location.y];
        } else {
            locationString = [[NSString alloc] initWithFormat:@"%ld, %ld", (long)location.x, (long)location.y];
        }
    }

    [_bottomLabelField setHidden:([locationString length] == 0)];
    [_bottomLabelField setStringValue:locationString ? locationString : @""];
}


#pragma mark - Mouse Cursor

- (void) mouseCursorMovedToLocation:(CGPoint)position
{
    if (_showsLocation) {
        [self _updateBottomLabel];
    }
}


- (void) mouseButtonsChanged
{
    // No implementation
}


- (void) mouseCursorMovedToDisplay:(CGDirectDisplayID)display
{
    // No implementation
}


#pragma mark - Accessors

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


- (void) setApertureOutline:(ApertureOutline)apertureOutline
{
    if (_apertureOutline != apertureOutline) {
        _apertureOutline = apertureOutline;
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
        [self _updateBottomLabel];
    }
}


- (void) setStatusText:(NSString *)statusText
{
    if (_statusText != statusText) {
        _statusText = statusText;
        
        [_topLabelField setHidden:[_statusText length] == 0];
        [_topLabelField setStringValue:_statusText ? _statusText : @""];
    }
}


@end
