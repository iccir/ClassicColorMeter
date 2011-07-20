//
//  BackgroundView.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "BackgroundView.h"

@implementation BackgroundView {
    NSGradient *_activeGradient;
    NSGradient *_inactiveGradient;
    BOOL        _active;
}


- (void) dealloc
{
    [_activeGradient   release];
    [_inactiveGradient release];
    
    [super dealloc];
}


- (void) drawRect:(NSRect)dirtyRect
{
    NSGradient *gradient = nil;

    if ([[self window] isKeyWindow]) {
        if (!_activeGradient) {
            NSColor *start = [NSColor colorWithDeviceWhite:222/255.0 alpha:1.0];
            NSColor *end   = [NSColor colorWithDeviceWhite:180/255.0 alpha:1.0];
            
            _activeGradient = [[NSGradient alloc] initWithStartingColor:start endingColor:end];
        } 
        
        gradient = _activeGradient;

    } else {
        if (!_inactiveGradient) {
            NSColor *start = [NSColor colorWithDeviceWhite:244/255.0 alpha:1.0];
            NSColor *end   = [NSColor colorWithDeviceWhite:222/255.0 alpha:1.0];
            
            _inactiveGradient = [[NSGradient alloc] initWithStartingColor:start endingColor:end];
        }
        
        gradient = _inactiveGradient;
    }

    [gradient drawInRect:[self bounds] angle:-90];
}

@end
