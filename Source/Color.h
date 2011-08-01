//
//  Color.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 7/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
    ColorComponentNone,

    ColorComponentRed,
    ColorComponentGreen,
    ColorComponentBlue,
    
    ColorComponentHue,
    ColorComponentSaturation,
    ColorComponentBrightness
};
typedef NSInteger ColorComponent;


@interface Color : NSObject <NSCopying>

- (void) setFloatValue:(float)value forComponent:(ColorComponent)component;
- (float) floatValueForComponent:(ColorComponent)component;

- (void) setRed:(float)red green:(float)green blue:(float)blue;
- (void) setHue:(float)hue saturation:(float)saturation brightness:(float)brightness;

//                                                 0.0          1.0
//                                                 ----------   ----------
@property (nonatomic, assign) float red;        // 0x00      -> 0xFF
@property (nonatomic, assign) float green;      // 0x00      -> 0xFF
@property (nonatomic, assign) float blue;       // 0x00      -> 0xFF
@property (nonatomic, assign) float hue;        // 0 degrees -> 360 degrees
@property (nonatomic, assign) float saturation; // 0%        -> 100%
@property (nonatomic, assign) float brightness; // 0%        -> 100%

@end
