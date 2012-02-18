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

extern void ColorModeMakeClipboardString(
    ColorMode mode,
    Color *color,
    BOOL lowercaseHex,
    BOOL usesPoundPrefix,
    NSString **outClipboard
);

extern void ColorModeMakeComponentStrings(
    ColorMode mode,
    Color *color,
    BOOL lowercaseHex,
    BOOL usesPoundPrefix,
    NSString **outLabel1,
    NSString **outLabel2,
    NSString **outLabel3,
    BOOL *isLabel1Clipped,
    BOOL *isLabel2Clipped,
    BOOL *isLabel3Clipped 
);

extern float ColorModeParseComponentString(ColorMode mode, ColorComponent component, NSString *string);

extern void GetAverageColor(CGImageRef image, CGRect apertureRect, float *outRed, float *outGreen, float *outBlue);

extern Color *GetColorFromParsedString(NSString *string);

extern NSString *GetCodeSnippetForColor(Color *color, BOOL lowercaseHex, NSString *inTemplate);


extern NSImage *GetSnapshotImageForView(NSView *view);


extern CGContextRef CreateBitmapContext(CGSize size, BOOL opaque, CGFloat scale);
extern CGImageRef   CreateImageMask(CGSize size, CGFloat scale, void (^callback)(CGContextRef));
