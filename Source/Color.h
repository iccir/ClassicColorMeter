//
//  Color.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-31.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
    ColorComponentNone,

    ColorComponentRed,
    ColorComponentGreen,
    ColorComponentBlue,
    
    ColorComponentHue,
    ColorComponentSaturationHSB,
    ColorComponentBrightness,
    
    ColorComponentSaturationHSL,
    ColorComponentLightness
};
typedef NSInteger ColorComponent;


@interface Color : NSObject <NSCopying>

- (void) setFloatValue:(float)value forComponent:(ColorComponent)component;
- (float) floatValueForComponent:(ColorComponent)component;

- (void) setRed:(float)red green:(float)green blue:(float)blue;
- (void) setHue:(float)hue saturation:(float)saturation brightness:(float)brightness;
- (void) setHue:(float)hue saturation:(float)saturation lightness:(float)lightness;

- (void) getRed:(float *)outRed green:(float *)outGreen blue:(float *)outBlue;
- (void) getHue:(float *)outHue saturation:(float *)outSaturation brightness:(float *)outBrightness;
- (void) getHue:(float *)outHue saturation:(float *)outSaturation lightness:(float *)outLightness;

//                                                   0.0          1.0
//                                                   ----------   ----------
@property (nonatomic, assign) float red;           // 0x00      -> 0xFF
@property (nonatomic, assign) float green;         // 0x00      -> 0xFF
@property (nonatomic, assign) float blue;          // 0x00      -> 0xFF

@property (nonatomic, assign) float hue;           // 0 degrees -> 360 degrees
@property (nonatomic, assign) float saturationHSB; // 0%        -> 100%
@property (nonatomic, assign) float brightness;    // 0%        -> 100%

@property (nonatomic, assign) float saturationHSL; // 0%        -> 100%
@property (nonatomic, assign) float lightness;     // 0%        -> 100%

@property (nonatomic, copy, readonly) NSColor *NSColor;

@end
