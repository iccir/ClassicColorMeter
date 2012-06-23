//
//  Color.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-31.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSInteger {
    ColorComponentNone,

    ColorComponentRed,
    ColorComponentGreen,
    ColorComponentBlue,
    
    ColorComponentHue,
    ColorComponentSaturationHSB,
    ColorComponentBrightness,
    
    ColorComponentSaturationHSL,
    ColorComponentLightness
} ColorComponent;


enum {
    ColorStringUsesLowercaseHex = 1 << 0,
    ColorStringUsesPoundPrefix  = 1 << 1
};
typedef NSUInteger ColorStringOptions;


@interface Color : NSObject <NSCopying>

+ (Color *) colorWithString:(NSString *)string;

- (void) getComponentsForMode: (ColorMode) mode
                      options: (ColorStringOptions) options
                      strings: (NSString * __autoreleasing [3]) strings
                       colors: (NSColor  * __autoreleasing [3]) colors;

- (NSString *) clipboardStringForMode: (ColorMode) mode
                              options: (ColorStringOptions) options;

- (NSString *) codeSnippetForTemplate:(NSString *)template options:(ColorStringOptions)options;

- (void) setFloatValue:(float)value forComponent:(ColorComponent)component;
- (float) floatValueForComponent:(ColorComponent)component;

- (void) setRed:(float)red green:(float)green blue:(float)blue transform:(ColorSyncTransformRef)profile;

- (void) setRed:(float)red green:(float)green blue:(float)blue;
- (void) setHue:(float)hue saturation:(float)saturation brightness:(float)brightness;
- (void) setHue:(float)hue saturation:(float)saturation lightness:(float)lightness;

- (void) getRed:(float *)outRed green:(float *)outGreen blue:(float *)outBlue;
- (void) getHue:(float *)outHue saturation:(float *)outSaturation brightness:(float *)outBrightness;
- (void) getHue:(float *)outHue saturation:(float *)outSaturation lightness:(float *)outLightness;

//                                                   0.0          1.0
//                                                   ----------   ----------
@property (nonatomic, readonly) float red;           // 0x00      -> 0xFF
@property (nonatomic, readonly) float green;         // 0x00      -> 0xFF
@property (nonatomic, readonly) float blue;          // 0x00      -> 0xFF

@property (nonatomic, readonly) float hue;           // 0 degrees -> 360 degrees
@property (nonatomic, readonly) float saturationHSB; // 0%        -> 100%
@property (nonatomic, readonly) float brightness;    // 0%        -> 100%

@property (nonatomic, readonly) float saturationHSL; // 0%        -> 100%
@property (nonatomic, readonly) float lightness;     // 0%        -> 100%

@property (nonatomic, copy, readonly) NSColor *NSColor;

@end
