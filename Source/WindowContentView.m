// (c) 2018-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import "WindowContentView.h"

@implementation WindowContentView

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleWindowMainChanged:) name:NSWindowDidBecomeMainNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleWindowMainChanged:) name:NSWindowDidResignMainNotification object:nil];
}


- (BOOL) isOpaque
{
    return YES;
}


- (void) _handleWindowMainChanged:(NSNotification *)note
{
    NSWindow *window = [self window];

    if (window && [[note object] isEqual:window]) {
        [self setNeedsDisplay:YES];
    }
}


- (void) drawRect:(NSRect)dirtyRect
{
    [[NSColor redColor] set];
    
    BOOL isDarkAqua = IsAppearanceDarkAqua(self);
    BOOL isMain = [[self window] isMainWindow];
    
    if (isMain) {
        CGFloat startWhite = isDarkAqua ? 0.25 : 0.95;
        CGFloat endWhite   = isDarkAqua ? 0.20 : 0.85;
                
        [[[NSGradient alloc] initWithColors:@[
            [NSColor colorWithWhite:startWhite alpha:1.0],
            [NSColor colorWithWhite:endWhite   alpha:1.0],
        ]] drawInRect:[self bounds] angle:-90];

    } else {
        CGFloat white = isDarkAqua ? 0.18 : 0.965;
        [[NSColor colorWithWhite:white alpha:1.0] set];
        NSRectFill([self bounds]);
    }
}


@end
