// (c) 2011-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import "RecessedButton.h"
#import "Util.h"
#import <QuartzCore/QuartzCore.h>

@interface RecessedButtonCell ()
@property (nonatomic) NSRect arrowRect;
@property (nonatomic) BOOL drawsArrow;
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
    BOOL drawArrow = (_arrowRect.size.width > 0) && _drawsArrow;
    
    CGSize titleSize = [title size];
    if (titleSize.width > (frame.size.width - 16)) {
        NSString *shortTitle = [(id)[self controlView] shortTitle];
        
        if (shortTitle) {
            NSMutableAttributedString *mutableTitle = [title mutableCopy];
            [[mutableTitle mutableString] setString:shortTitle];
            title = mutableTitle;
        }
    }
    
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    
    CGContextSaveGState(context);

    CGContextSetAllowsFontSmoothing(context, YES);
    CGContextSetShouldSmoothFonts(context, YES);

    NSRect rect = [super drawTitle:title withFrame:frame inView:controlView];
    
    if (drawArrow) {
        [sGetArrowPath(_arrowRect) fill];
        _arrowRect = CGRectZero;
    }
    
    CGContextRestoreGState(context);

    return rect;
}

@end


@implementation RecessedButton

- (void) awakeFromNib
{
    if (![self target] && ![self action]) {
        [self setTarget:self];
        [self setAction:@selector(_showPopUpMenu:)];

        if ([[self cell] isKindOfClass:[RecessedButtonCell class]]) {
            [(RecessedButtonCell *)[self cell] setDrawsArrow:YES];
        }
    }
}


- (void) _showPopUpMenu:(id)sender
{
    NSMenu *menu   = [self menu];
    NSRect  bounds = [self bounds];

    [menu setMinimumWidth:bounds.size.width];
    [menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(0, 22) inView:self];
}


- (void) setShortTitle:(NSString *)shortTitle
{
    if (_shortTitle != shortTitle) {
        _shortTitle = shortTitle;
        [self setNeedsDisplay:YES];
    }
}

@end
