// (c) 2011-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import "PreviewView.h"
#import "MouseCursor.h"


@interface PreviewView () <MouseCursorListener>
@end


@implementation PreviewView {
    NSTextField *_topLabelField;
    NSTextField *_bottomLabelField;
    NSTextField *_errorLabelField;
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
    _errorLabelField  = makeLabel();
    
    [_errorLabelField setFont:[NSFont monospacedDigitSystemFontOfSize:11.0 weight:NSFontWeightSemibold]];
    [_errorLabelField setBackgroundColor:[NSColor colorWithWhite:0 alpha:0.75]];
    [_errorLabelField setLineBreakMode:NSLineBreakByWordWrapping];
    [_errorLabelField setMaximumNumberOfLines:0];
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

    // Layout error label
    {
        CGRect insetBounds = CGRectInset(bounds, onePixel, onePixel);

        NSSize size = [_errorLabelField sizeThatFits:insetBounds.size];
    
        NSRect frame = insetBounds;
        frame.size = size;
        frame.origin.x = onePixel + ((frame.size.width - size.width) / 2.0);
        frame.size.height += 1;
        frame.size.width = insetBounds.size.width;
        
        [_errorLabelField setFrame:frame];
    }

    // Layout bottom label
    {
        CGRect frame = bounds;
        frame.size.height = 18;
        
        frame = CGRectInset(frame, onePixel, onePixel);

        [_bottomLabelField setFrame:frame];
    }

    // Layout top label
    {
        CGRect frame = bounds;
        frame.size.height = 18;
        frame.origin.y = bounds.size.height - frame.size.height;
        frame = CGRectInset(frame, onePixel, onePixel);

        [_topLabelField setFrame:frame];
    }
}


- (void) drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    CGContextSaveGState(context);
 
    NSRect bounds = [self bounds];
    CGRect zoomedBounds = bounds;
    
    NSRectClip(bounds);

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


- (void) _updateErrorLabel
{
    NSString *stringValue = _errorText;

    [_errorLabelField setHidden:([stringValue length] == 0)];
    [_errorLabelField setStringValue:stringValue ? stringValue : @""];
}


- (void) _updateTopLabel
{
    NSString *stringValue;

    if ([_errorText length] == 0) {
        stringValue = _statusText;
    }

    [_topLabelField setHidden:[stringValue length] == 0];
    [_topLabelField setStringValue:stringValue ? stringValue : @""];
}


- (void) _updateBottomLabel
{
    NSString *stringValue;

    if (_showsLocation && ([_errorText length] == 0)) {
        MouseCursor *cursor = [MouseCursor sharedInstance];
        CGPoint location = [cursor location];

        if ([cursor inRetinaPixelMode]) {
            stringValue = [[NSString alloc] initWithFormat:@"%.1lf, %.1lf", (double)location.x, (double)location.y];
        } else {
            stringValue = [[NSString alloc] initWithFormat:@"%ld, %ld", (long)location.x, (long)location.y];
        }
    }

    [_bottomLabelField setHidden:([stringValue length] == 0)];
    [_bottomLabelField setStringValue:stringValue ? stringValue : @""];
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




- (void) setErrorText:(NSString *)errorText
{
    if (_errorText != errorText) {
        _errorText = errorText;

        [self _updateErrorLabel];
        [self _updateTopLabel];
        [self _updateBottomLabel];

        [self setNeedsLayout:YES];
    }
}


- (void) setStatusText:(NSString *)statusText
{
    if (_statusText != statusText) {
        _statusText = statusText;
        [self _updateTopLabel];
    }
}


@end
