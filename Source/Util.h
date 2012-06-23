//
//  Util.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Foundation/Foundation.h>

extern BOOL      ColorModeIsRGB(ColorMode mode);
extern BOOL      ColorModeIsHue(ColorMode mode);
extern BOOL      ColorModeIsXYZ(ColorMode mode);
extern NSString *ColorModeGetName(ColorMode mode);
extern NSArray  *ColorModeGetComponentLabels(ColorMode mode);

extern float ColorModeParseComponentString(ColorMode mode, ColorComponent component, NSString *string);

extern NSImage *GetSnapshotImageForView(NSView *view);

extern CGContextRef CreateBitmapContext(CGSize size, BOOL opaque, CGFloat scale);
extern CGImageRef   CreateImageMask(CGSize size, CGFloat scale, void (^callback)(CGContextRef));
extern CGImageRef   CreateImage(CGSize size, BOOL opaque, CGFloat scale, void (^callback)(CGContextRef));

extern NSString *GetArrowJoinerString(void);
