//
//  ColorCalculator.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Foundation/Foundation.h>

extern void ColorCalculatorGetCIE1931Color(     uint32_t inDisplay, Color *inColor, float *outX, float *outY, float *outFL);
extern void ColorCalculatorGetCIE1976Color(     uint32_t inDisplay, Color *inColor, float *outU, float *outV, float *outFL);
extern void ColorCalculatorGetLabColor(         uint32_t inDisplay, Color *inColor, float *outL, float *outA, float *outB);
extern void ColorCalculatorGetTristimulusColor( uint32_t inDisplay, Color *inColor, float *outX, float *outY, float *outZ);

extern void ColorCalculatorGetAverageColor(CGImageRef image, CGRect apertureRect, Color *outColor); 
extern void ColorCalculatorCalculate(uint32_t inDisplay, ColorMode mode, Color *color, NSString **outLabel1, NSString **outLabel2, NSString **outLabel3, NSString **outClipboard);

extern NSString *ColorCalculatorGetName(ColorMode mode);
extern NSArray  *ColorCalculatorGetComponentLabels(ColorMode mode);


