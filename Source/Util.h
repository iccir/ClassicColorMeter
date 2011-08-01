//
//  ColorCalculator.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Foundation/Foundation.h>

extern BOOL      ColorModeIsRGB(ColorMode mode);
extern BOOL      ColorModeIsHSB(ColorMode mode);
extern BOOL      ColorModeIsXYZ(ColorMode mode);
extern NSString *ColorModeGetName(ColorMode mode);
extern NSArray  *ColorModeGetComponentLabels(ColorMode mode);

extern void ColorModeMakeComponentStrings(
    ColorMode mode,
    Color *color,
    BOOL lowercaseHex,
    NSString **outLabel1,
    NSString **outLabel2,
    NSString **outLabel3,
    NSString **outClipboard
);

extern float ColorModeParseComponentString(ColorMode mode, ColorComponent component, NSString *string);

extern void GetAverageColor(CGImageRef image, CGRect apertureRect, float *outRed, float *outGreen, float *outBlue);

extern NSString *GetCodeSnippetForColor(Color *color, BOOL lowercaseHex, NSString *inTemplate);
