// (c) 2011-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ColorComponent) {
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


typedef NS_OPTIONS(NSUInteger, ColorStringOptions) {
    ColorStringUsesLowercaseHex = 1 << 0,
    ColorStringUsesPoundPrefix  = 1 << 1,
    ColorStringClipsOutOfRange  = 1 << 2,
    ColorStringForMiniWindow    = 1 << 4
};


@class ColorTransform;

@interface Color : NSObject <NSCopying>

+ (Color *) colorWithString:(NSString *)string;

- (void) getComponentsForMode: (ColorMode) mode
                      options: (ColorStringOptions) options
                   outOfRange: (BOOL[3]) outOfRange
                      strings: (NSString * __autoreleasing [3]) strings;

- (NSString *) clipboardStringForMode: (ColorMode) mode
                              options: (ColorStringOptions) options;

- (NSString *) codeSnippetForTemplate:(NSString *)template options:(ColorStringOptions)options;

- (void) setFloatValue:(float)value forComponent:(ColorComponent)component;
- (float) floatValueForComponent:(ColorComponent)component;

- (void) setRawRed: (float) red
          rawGreen: (float) green
           rawBlue: (float) blue 
         transform: (ColorSyncTransformRef) transform
        colorSpace: (CGColorSpaceRef) colorSpace;

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
@property (nonatomic, readonly) CGColorSpaceRef colorSpace;

@end
