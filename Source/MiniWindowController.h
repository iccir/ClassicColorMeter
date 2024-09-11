// (c) 2011-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>


@interface MiniWindowController : NSWindowController

- (void) toggle;

- (void) updateColorMode:(ColorMode)colorMode;
- (void) updateColor:(Color *)color options:(ColorStringOptions)options;

@end
