//
//  Color.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-31.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "Color.h"


@implementation Color {
    BOOL  _rawValid;
    float _rawRed;
    float _rawGreen;
    float _rawBlue;
}


+ (Color *) colorWithString:(NSString *)string
{
    return sGetColorFromParsedString(string);
}


- (id) copyWithZone:(NSZone *)zone
{
    Color *result = [[Color alloc] init];
    
    result->_red           = _red;
    result->_green         = _green;
    result->_blue          = _blue;
    result->_rawValid      = _rawValid;
    result->_rawRed        = _rawRed;
    result->_rawGreen      = _rawGreen;
    result->_rawBlue       = _rawBlue;
    result->_hue           = _hue;
    result->_saturationHSL = _saturationHSL;
    result->_saturationHSB = _saturationHSB;
    result->_brightness    = _brightness;
    result->_lightness     = _lightness;
    result->_colorSpace    = CGColorSpaceRetain(_colorSpace);

    return result;
}


- (void) dealloc
{
    CGColorSpaceRelease(_colorSpace);
    _colorSpace = NULL;
}


#pragma mark - Static Functions

static NSString *sGetHexString(NSString *format, long value)
{
    if (value >= 0) {
        return [NSString stringWithFormat:format, value];
    } else {
        return [NSString stringWithFormat:@"-%@", [NSString stringWithFormat:format, -value]];
    }
}


static inline float sClamp(float f, BOOL *didClamp)
{
    if (f > 1.0) {
        *didClamp = YES;
        return 1.0;
    } else if (f < 0.0) {
        *didClamp = YES;
        return 0.0;
    } else {
        *didClamp = NO;
        return f;
    }
}


static Color *sGetColorFromParsedString(NSString *stringToParse)
{
    if (!stringToParse) return nil;

    __block Color *color = nil;

    float (^scanHex)(NSString *, float) = ^(NSString *string, float maxValue) {
        const char *s = [string UTF8String];
        float result = s ? (strtol(s, NULL, 16) / maxValue) : 0.0;
        return result;
    };

    void (^withPattern)(NSString *, void(^)(NSArray *)) = ^(NSString *pattern, void (^callback)(NSArray *result)) {
        if (color) return;

        NSRegularExpression  *re     = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:NULL];
        NSTextCheckingResult *result = [re firstMatchInString:stringToParse options:0 range:NSMakeRange(0, [stringToParse length])];

        NSInteger numberOfRanges = [result numberOfRanges];
        if ([result numberOfRanges] > 1) {
            NSMutableArray *captureGroups = [NSMutableArray array];
            
            NSInteger i;
            for (i = 1; i < numberOfRanges; i++) {
                NSRange captureRange = [result rangeAtIndex:i];
                [captureGroups addObject:[stringToParse substringWithRange:captureRange]];
            }
            
            callback(captureGroups);
        }
    };

    withPattern(@"#([0-9a-f]{4})([0-9a-f]{4})([0-9a-f]{4})", ^(NSArray *result) {
        if ([result count] == 3) {
            color = [[Color alloc] init];
            
            [color setRed: scanHex([result objectAtIndex:0], 65535.0)
                    green: scanHex([result objectAtIndex:1], 65535.0)
                     blue: scanHex([result objectAtIndex:2], 65535.0)];
        }
    });
    
    withPattern(@"#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})", ^(NSArray *result) {
        if ([result count] == 3) {
            color = [[Color alloc] init];
            
            [color setRed: scanHex([result objectAtIndex:0], 255.0)
                    green: scanHex([result objectAtIndex:1], 255.0)
                     blue: scanHex([result objectAtIndex:2], 255.0)];
        }
    });

    withPattern(@"rgb\\s*\\(\\s*([0-9.]+)\\s*,\\s*([0-9.]+)\\s*,\\s*([0-9.]+)\\s*\\)", ^(NSArray *result) {
        if ([result count] == 3) {
            color = [[Color alloc] init];
            
            [color setRed: ([[result objectAtIndex:0] floatValue] / 255.0)
                    green: ([[result objectAtIndex:1] floatValue] / 255.0)
                     blue: ([[result objectAtIndex:2] floatValue] / 255.0)];
        }
    });

    withPattern(@"rgba\\s*\\(\\s*([0-9.]+)\\s*,\\s*([0-9.]+)\\s*,\\s*([0-9.]+)\\s*,\\s*([0-9.]+)\\s*\\)", ^(NSArray *result) {
        if ([result count] == 4) {
            color = [[Color alloc] init];
            
            [color setRed: ([[result objectAtIndex:0] floatValue] / 255.0)
                    green: ([[result objectAtIndex:1] floatValue] / 255.0)
                     blue: ([[result objectAtIndex:2] floatValue] / 255.0)];
        }
    });

    withPattern(@"([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})", ^(NSArray *result) {
        if ([result count] == 3) {
            color = [[Color alloc] init];
            
            [color setRed: scanHex([result objectAtIndex:0], 255.0)
                    green: scanHex([result objectAtIndex:1], 255.0)
                     blue: scanHex([result objectAtIndex:2], 255.0)];
        }
    });

    return color;
}


static void sConvertColor(Color *inColor, CFStringRef profileName, float *outFloat0, float *outFloat1, float *outFloat2)
{
    ColorSyncProfileRef fromProfile = ColorSyncProfileCreateWithDisplayID(CGMainDisplayID());
    ColorSyncProfileRef toProfile   = ColorSyncProfileCreateWithName(profileName);
    
    NSDictionary *from = [[NSDictionary alloc] initWithObjectsAndKeys:
        (__bridge id)fromProfile,                       (__bridge id)kColorSyncProfile,
        (__bridge id)kColorSyncRenderingIntentRelative, (__bridge id)kColorSyncRenderingIntent,
        (__bridge id)kColorSyncTransformDeviceToPCS,    (__bridge id)kColorSyncTransformTag,
        nil];

    NSDictionary *to = [[NSDictionary alloc] initWithObjectsAndKeys:
        (__bridge id)toProfile,                         (__bridge id)kColorSyncProfile,
        (__bridge id)kColorSyncRenderingIntentRelative, (__bridge id)kColorSyncRenderingIntent,
        (__bridge id)kColorSyncTransformPCSToDevice,    (__bridge id)kColorSyncTransformTag,
        nil];
        
    NSArray      *profiles = [[NSArray alloc] initWithObjects:from, to, nil];
    NSDictionary *options  = [[NSDictionary alloc] initWithObjectsAndKeys:
        (__bridge id)kColorSyncBestQuality, (__bridge id)kColorSyncConvertQuality,
        nil]; 

    ColorSyncTransformRef transform = ColorSyncTransformCreate((__bridge CFArrayRef)profiles, (__bridge CFDictionaryRef)options);
    
    if (transform) {
        float red, green, blue;
        [inColor getRed:&red green:&green blue:&blue];
        
        float input[3]  = { red, green, blue };
        float output[3] = { 0.0, 0.0, 0.0 };

        if (!ColorSyncTransformConvert(transform, 1, 1, &output[0], kColorSync32BitFloat, kColorSyncByteOrderDefault, 12, &input[0], kColorSync32BitFloat, kColorSyncByteOrderDefault, 12, NULL)) {
            NSLog(@"ColorSyncTransformConvert failed");
        }

        *outFloat0 = output[0];
        *outFloat1 = output[1];
        *outFloat2 = output[2];
    
        CFRelease(transform);
    }

    if (fromProfile) CFRelease(fromProfile);
    if (toProfile)   CFRelease(toProfile);
}


static NSString *sApplyFilter(NSString *inString)
{
    NSUInteger length = [inString length];
    unichar buffer[10];
        
    if (length < 10 && length > 3) {
        [inString getCharacters:buffer range:NSMakeRange(0, length)];
        
        if (buffer[0] == '-' &&
            buffer[1] == '0' &&
            buffer[2] == '.' &&
            buffer[3] == '0')
        {
            BOOL allZero = YES;
            
            for (NSInteger i = 3; i < length; i++) {
                allZero = allZero && (buffer[i] == '0');
                if (!allZero) break;
            }

            if (allZero) {
                return [inString substringFromIndex:1];
            }
        }
    }
    
    return inString;
}


static void sMakeStrings(
    Color *color,
    ColorMode mode,
    ColorStringOptions options,
    NSString * __autoreleasing *outClipboard,
    NSString * __autoreleasing outString[3],
    BOOL outOfRange[3]
)
{
    NSString *value1    = nil;
    NSString *value2    = nil;
    NSString *value3    = nil;
    NSString *clipboard = nil;

    float red, green, blue;
    [color getRed:&red green:&green blue:&blue];

    BOOL lowercaseHex    = (options & ColorStringUsesLowercaseHex) > 0;
    BOOL usesPoundPrefix = (options & ColorStringUsesPoundPrefix)  > 0;
    BOOL clips           = (options & ColorStringClipsOutOfRange)  > 0;
    BOOL forMiniWindow   = (options & ColorStringForMiniWindow)    > 0;
    
    BOOL outOfRange1 = NO;
    BOOL outOfRange2 = NO;
    BOOL outOfRange3 = NO;

    if (mode == ColorMode_RGB_Percentage) {
        red   *= 100;
        green *= 100;
        blue  *= 100;

        // Clip if needed
        {
            if      (red   >= 100.0499) { if (clips) { red   = 100.0; } outOfRange1 = YES; }
            else if (red   <=  -0.0499) { if (clips) { red   =   0.0; } outOfRange1 = YES; }

            if      (green >= 100.0499) { if (clips) { green = 100.0; } outOfRange2 = YES; }
            else if (green <=  -0.0499) { if (clips) { green =   0.0; } outOfRange2 = YES; }

            if      (blue  >= 100.0499) { if (clips) { blue  = 100.0; } outOfRange3 = YES; }
            else if (blue  <=  -0.0499) { if (clips) { blue  =   0.0; } outOfRange3 = YES; }
        }

        value1 = [NSString stringWithFormat:@"%0.1lf", red];
        value2 = [NSString stringWithFormat:@"%0.1lf", green];
        value3 = [NSString stringWithFormat:@"%0.1lf", blue];

    } else if (mode == ColorMode_RGB_Value_8 || mode == ColorMode_RGB_HexValue_8) {
        long redLong   = lroundf(red   * 255);
        long greenLong = lroundf(green * 255);
        long blueLong  = lroundf(blue  * 255);

        long redClipped, greenClipped, blueClipped;
        
        {
            if      (redLong   > 255) { redClipped   = 255; outOfRange1 = YES; }
            else if (redLong   < 0)   { redClipped   = 0;   outOfRange1 = YES; }
            else                      { redClipped   = redLong; }

            if      (greenLong > 255) { greenClipped = 255; outOfRange2 = YES; }
            else if (greenLong < 0)   { greenClipped = 0;   outOfRange2 = YES; }
            else                      { greenClipped = greenLong; }

            if      (blueLong  > 255) { blueClipped  = 255; outOfRange3 = YES; }
            else if (blueLong  < 0)   { blueClipped  = 0;   outOfRange3 = YES; }
            else                      { blueClipped  = blueLong; }
        }
        
        if (mode == ColorMode_RGB_Value_8) {
            value1 = [NSString stringWithFormat:@"%ld", (clips ? redClipped   : redLong)  ];
            value2 = [NSString stringWithFormat:@"%ld", (clips ? greenClipped : greenLong)];
            value3 = [NSString stringWithFormat:@"%ld", (clips ? blueClipped  : blueLong) ];
        } else {
            NSString *format = lowercaseHex ? @"%02lx" : @"%02lX";

            value1 = sGetHexString(format, clips ? redClipped   : redLong);
            value2 = sGetHexString(format, clips ? greenClipped : greenLong);
            value3 = sGetHexString(format, clips ? blueClipped  : blueLong);
        }

        if (mode == ColorMode_RGB_HexValue_8) {
            if (lowercaseHex) {
                clipboard = [NSString stringWithFormat:@"%s%02lx%02lx%02lx", (usesPoundPrefix ? "#" : ""), redClipped, greenClipped, blueClipped];
            } else {
                clipboard = [NSString stringWithFormat:@"%s%02lX%02lX%02lX", (usesPoundPrefix ? "#" : ""), redClipped, greenClipped, blueClipped];
            }
        }

    } else if (mode == ColorMode_RGB_Value_16 || mode == ColorMode_RGB_HexValue_16) {
        long redLong   = lroundf(red   * 65535);
        long greenLong = lroundf(green * 65535);
        long blueLong  = lroundf(blue  * 65535);
        
        {
            if      (redLong   > 65535) { if (clips) { redLong   = 65535; } outOfRange1 = YES; }
            else if (redLong   < 0)     { if (clips) { redLong   = 0;     } outOfRange1 = YES; }

            if      (greenLong > 65535) { if (clips) { greenLong = 65535; } outOfRange2 = YES; }
            else if (greenLong < 0)     { if (clips) { greenLong = 0;     } outOfRange2 = YES; }

            if      (blueLong  > 65535) { if (clips) { blueLong  = 65535; } outOfRange3 = YES; }
            else if (blueLong  < 0)     { if (clips) { blueLong  = 0;     } outOfRange3 = YES; }
        }

        if (mode == ColorMode_RGB_Value_16) {
            value1 = [NSString stringWithFormat:@"%ld", redLong];
            value2 = [NSString stringWithFormat:@"%ld", greenLong];
            value3 = [NSString stringWithFormat:@"%ld", blueLong];

        } else {
            NSString *format = lowercaseHex ? @"%04lx" : @"%04lX";

            value1 = sGetHexString(format, redLong);
            value2 = sGetHexString(format, greenLong);
            value3 = sGetHexString(format, blueLong);
        }

    } else if (mode >= ColorMode_YPbPr_601 && mode <= ColorMode_YCbCr_709) {
        BOOL is601     = (mode == ColorMode_YPbPr_601 || mode == ColorMode_YCbCr_601);
        BOOL isDigital = (mode == ColorMode_YCbCr_601 || mode == ColorMode_YCbCr_709);

        double kr = is601 ? 0.299 : 0.2126;
        double kb = is601 ? 0.114 : 0.0722;

        double y  = (kr * red) + ((1 - (kr + kb)) * green) + (kb * blue);
        double pb = 0.5 * ((blue - y) / (1 - kb));
        double pr = 0.5 * ((red  - y) / (1 - kr));
        
        if (isDigital) {
            value1 = [NSString stringWithFormat:@"%ld", (long)(16  + round(y  * 219.0))];
            value2 = [NSString stringWithFormat:@"%ld", (long)(128 + round(pb * 224.0))];
            value3 = [NSString stringWithFormat:@"%ld", (long)(128 + round(pr * 224.0))];

        } else {
            value1 = [NSString stringWithFormat:@"%0.03lf", y];
            value2 = [NSString stringWithFormat:@"%0.03lf", pb];
            value3 = [NSString stringWithFormat:@"%0.03lf", pr];
        }

    } else if (ColorModeIsXYZ(mode)) {
        float x = 0.0;
        float y = 0.0;
        float z = 0.0;
        sConvertColor(color, kColorSyncGenericXYZProfile, &x, &y, &z);

        if (mode == ColorMode_CIE_1931) {
            float divisor = x + y + z;

            value1    = [NSString stringWithFormat:@"%0.03lf", (divisor == 0.0) ? 0.0 : (x / divisor)];
            value2    = [NSString stringWithFormat:@"%0.03lf", (divisor == 0.0) ? 0.0 : (y / divisor)];
            value3    = [NSString stringWithFormat:@"%0.03lf", (y * 100)];
        
        } else if (mode == ColorMode_CIE_1976) {
            float divisor = (x + (15 * y) + (3 * z));

            value1    = [NSString stringWithFormat:@"%0.03lf", (divisor == 0.0) ? 0.0 : ((4 * x) / divisor)];
            value2    = [NSString stringWithFormat:@"%0.03lf", (divisor == 0.0) ? 0.0 : ((9 * y) / divisor)];
            value3    = [NSString stringWithFormat:@"%0.03lf", (y * 100)];
        
        } else if (mode == ColorMode_Tristimulus) {
            value1    = [NSString stringWithFormat:@"%0.03lf", x * 100];
            value2    = [NSString stringWithFormat:@"%0.03lf", y * 100];
            value3    = [NSString stringWithFormat:@"%0.03lf", z * 100];
        }
        
    } else if (mode == ColorMode_CIE_Lab) {
        float l = 0.0;
        float a = 0.0;
        float b = 0.0;
        sConvertColor(color, kColorSyncGenericLabProfile, &l, &a, &b);

        NSString *format = forMiniWindow ? @"%0.01lf" : @"%0.03lf";
        
        value1 = [NSString stringWithFormat:format, (l * 100.0)];
        value2 = [NSString stringWithFormat:format, (a * 256.0) - 128.0];
        value3 = [NSString stringWithFormat:format, (b * 256.0) - 128.0];

    } else if ((mode == ColorMode_HSB) || (mode == ColorMode_HSL)) {
        float f1, f2, f3;
        if (mode == ColorMode_HSB) {
            [color getHue:&f1 saturation:&f2 brightness:&f3];
        } else {
            [color getHue:&f1 saturation:&f2 lightness:&f3];
        }
        
        long h  = lround(f1 * 360);
        long s  = lround(f2 * 100);
        long bl = lround(f3 * 100);

        while (h > 360) { h -= 360; }
        while (h < 0)   { h += 360; }

        if      (s > 100) { if (clips) { s = 100; } outOfRange2 = YES; }
        else if (s < 0)   { if (clips) { s = 0;   } outOfRange2 = YES; }

        if      (bl > 100) { if (clips) { bl = 100; } outOfRange3 = YES; }
        else if (bl < 0)   { if (clips) { bl = 0;   } outOfRange3 = YES; }

        value1 = [NSString stringWithFormat:@"%ld", h];
        value2 = [NSString stringWithFormat:@"%ld", s];
        value3 = [NSString stringWithFormat:@"%ld", bl];
    }
        
    value1 = sApplyFilter(value1);
    value2 = sApplyFilter(value2);
    value3 = sApplyFilter(value3);
    
    if (!clipboard) {
        clipboard = [NSString stringWithFormat:@"%@\t%@\t%@", value1, value2, value3];
    }   

    if (outString) {
        outString[0] = value1;
        outString[1] = value2;
        outString[2] = value3;
    }

    if (outOfRange) {
        outOfRange[0] = outOfRange1;
        outOfRange[1] = outOfRange2;
        outOfRange[2] = outOfRange3;
    }

    if (outClipboard) {
        *outClipboard = clipboard;
    }
}


#pragma mark - Private

- (void) _didChangeRGB
{
    float r = _red;
    float g = _green;
    float b = _blue;

    float maxRGB = fmaxf(fmaxf(r, g), b);
    float minRGB = fminf(fminf(r, g), b);
    float delta  = maxRGB - minRGB;

    _hue           = 0.0;
    _saturationHSB = 0.0;
    _saturationHSL = 0.0;
    _brightness    = maxRGB;
    _lightness     = (minRGB + maxRGB) * 0.5;

    if (maxRGB != 0.0) {
        _saturationHSB = delta / maxRGB;
    }
    
    // Override previous value for now
    float divisor =  (1 - fabsf((2 * _lightness) - 1));
    if (divisor != 0) {
        _saturationHSL = delta / divisor;
    }

    if (_saturationHSB != 0.0) {
        if (maxRGB == r) {
            _hue = 0 + ((g - b) / delta);
        } else if (maxRGB == g) {
            _hue = 2 + ((b - r) / delta);
        } else if (maxRGB == b) {
            _hue = 4 + ((r - g) / delta);
        }
    }
    
    while (_hue < 0.0) {
        _hue += 6.0;
    }
    
    _hue /= 6.0;
}


- (void) _didChangeHSB
{
    float hue        = _hue;
    float saturation = _saturationHSB;
    float brightness = _brightness;
    
    float r = 0.0;
    float g = 0.0;
    float b = 0.0;

    if (saturation == 0.0) {
        r = g = b = brightness;

    } else {
        if (hue >= 1.0) hue -= 1.0;

        float sectorAsFloat = hue * 6;
        int   sectorAsInt   = (int)(sectorAsFloat);

        float f = sectorAsFloat - sectorAsInt;			// factorial part of h
        float p = brightness * ( 1 - saturation );
        float q = brightness * ( 1 - saturation * f );
        float t = brightness * ( 1 - saturation * ( 1 - f ) );
        float v = brightness;

        switch (sectorAsInt) {
        case 0:
            r = v;
            g = t;
            b = p;
            break;

        case 1:
            r = q;
            g = v;
            b = p;
            break;

        case 2:
            r = p;
            g = v;
            b = t;
            break;

        case 3:
            r = p;
            g = q;
            b = v;
            break;

        case 4:
            r = t;
            g = p;
            b = v;
            break;

        case 5:
            r = v;
            g = p;
            b = q;
            break;
        }
    }

    _rawValid = NO;
    _red   = r;
    _green = g;
    _blue  = b;
}


- (void) _didChangeHSL
{
    float (^convertHue)(float, float, float) = ^(float p, float q, float t) {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < (1.0 / 6.0)) return (float)(p + (q - p) * 6.0 * t);
        if (t < (1.0 / 2.0)) return q;
        if (t < (2.0 / 3.0)) return (float)(p + (q - p) * ((2.0 / 3.0) - t) * 6.0);
        return p;
    };

    float hue        = _hue;
    float saturation = _saturationHSL;
    float lightness  = _lightness;

    float r = 0.0;
    float g = 0.0;
    float b = 0.0;

    if (saturation == 0.0) {
        r = g = b = lightness;

    } else {
        float q;
        if (lightness < 0.5) {
            q = lightness * (1 + saturation);
        } else {
            q = (lightness + saturation) - (lightness * saturation);
        }
         
        float p = (2 * lightness) - q;

        r = convertHue(p, q, hue + (1.0 / 3.0));
        g = convertHue(p, q, hue              );
        b = convertHue(p, q, hue - (1.0 / 3.0));
    }

    _rawValid = NO;
    _red   = r;
    _green = g;
    _blue  = b;
}


#pragma mark - Public Methods

- (void) getComponentsForMode: (ColorMode) mode
                      options: (ColorStringOptions) options
                   outOfRange: (BOOL[3]) outOfRange
                      strings: (NSString * __autoreleasing [3]) strings
{
    sMakeStrings(self, mode, options, NULL, strings, outOfRange);
}


- (NSString *) clipboardStringForMode:(ColorMode)mode options:(ColorStringOptions)options
{
    NSString *result;
    sMakeStrings(self, mode, options, &result, NULL, NULL);
    return result;
}


- (NSString *) codeSnippetForTemplate:(NSString *)template options:(ColorStringOptions)options
{
    NSMutableString *result = [template mutableCopy];

    BOOL lowercaseHex = (options & ColorStringUsesLowercaseHex) > 0;

    void (^replaceHex)(NSString *, float) = ^(NSString *key, float component) {
        if (component > 1.0) component = 1.0;
        if (component < 0.0) component = 0.0;

        NSString *hexFormat = lowercaseHex ? @"%02x" : @"%02X";
        NSString *hexValue = [NSString stringWithFormat:hexFormat, (NSInteger)(component * 255.0)];
        [result replaceOccurrencesOfString:key withString:hexValue options:NSLiteralSearch range:NSMakeRange(0, [result length])];
    };
    
    void (^replaceNumber)(NSString *, float, float) = ^(NSString *key, float multiplier, float component) {
        NSRange range = [result rangeOfString:key];

        if (range.location != NSNotFound) {
            if (component > 1.0) component = 1.0;
            if (component < 0.0) component = 0.0;

            NSString *string = [NSString stringWithFormat: @"%ld", lroundf(multiplier * component)];
            
            if (string) {
                [result replaceOccurrencesOfString:key withString:string options:NSLiteralSearch range:NSMakeRange(0, [result length])];
            }
        }
    };
    
    void (^replaceFloat)(NSString *, float) = ^(NSString *key, float component) {
        NSRange range = [result rangeOfString:key];

        if (range.location != NSNotFound) {
            if (component > 1.0) component = 1.0;
            if (component < 0.0) component = 0.0;

            unichar number = [result characterAtIndex:(range.location + 3)];
            
            NSString *keyWithNumber = [NSString stringWithFormat:@"%@%C", key, number];
            NSString *format = [NSString stringWithFormat: @"%%.%Cf", number];
            NSString *string = [NSString stringWithFormat: format, component];
            
            if (string) {
                [result replaceOccurrencesOfString:keyWithNumber withString:string options:NSLiteralSearch range:NSMakeRange(0, [result length])];
            }
        }
    };

    BOOL didClamp;
    float red   = sClamp(_red,   &didClamp);
    float green = sClamp(_green, &didClamp);
    float blue  = sClamp(_blue,  &didClamp);

    replaceHex(@"$RHEX", red);
    replaceHex(@"$GHEX", green);
    replaceHex(@"$BHEX", blue);

    replaceNumber(@"$RN255", 255, red);
    replaceNumber(@"$GN255", 255, green);
    replaceNumber(@"$BN255", 255, blue);
    
    replaceFloat(@"$RF", red);
    replaceFloat(@"$GF", green);
    replaceFloat(@"$BF", blue);

    [result replaceOccurrencesOfString:@"$$" withString:@"$" options:NSLiteralSearch range:NSMakeRange(0, [result length])];

    return result;
}


- (void) setFloatValue:(float)value forComponent:(ColorComponent)component
{
    if (component == ColorComponentRed) {
        _rawValid = NO;
        _red = value;

        [self _didChangeRGB];

    } else if (component == ColorComponentGreen) {
        _rawValid = NO;
        _green = value;

        [self _didChangeRGB];
    
    } else if (component == ColorComponentBlue) {
        _rawValid = NO;
        _blue  = value;

        [self _didChangeRGB];
    
    } else if (component == ColorComponentHue) {
        _hue = value;
        [self _didChangeHSB];
    
    } else if (component == ColorComponentSaturationHSB) {
        _saturationHSB = value;
        [self _didChangeHSB];

    } else if (component == ColorComponentBrightness) {
        _brightness = value;
        [self _didChangeHSB];

    } else if (component == ColorComponentSaturationHSL) {
        _saturationHSL = value;
        [self _didChangeHSL];

    } else if (component == ColorComponentLightness) {
        _lightness = value;
        [self _didChangeHSL];
    }
}


- (float) floatValueForComponent:(ColorComponent)component
{
    if (component == ColorComponentRed) {
        return _red;

    } else if (component == ColorComponentGreen) {
        return _green;
    
    } else if (component == ColorComponentBlue) {
        return _blue;
    
    } else if (component == ColorComponentHue) {
        return _hue;
    
    } else if (component == ColorComponentSaturationHSB) {
        return _saturationHSB;
    
    } else if (component == ColorComponentBrightness) {
        return _brightness;

    } else if (component == ColorComponentSaturationHSL) {
        return _saturationHSL;

    } else if (component == ColorComponentLightness) {
        return _lightness;

    } else {
        return 0.0;
    }
}


- (void) setRawRed: (float) rawRed
          rawGreen: (float) rawGreen
           rawBlue: (float) rawBlue 
         transform: (ColorSyncTransformRef) transform
        colorSpace: (CGColorSpaceRef) colorSpace
{
    float src[3];
    float dst[3];

    _rawValid = NO;
    _rawRed   = _red   = src[0] = rawRed;
    _rawGreen = _green = src[1] = rawGreen;
    _rawBlue  = _blue  = src[2] = rawBlue;
    
    if (_colorSpace != colorSpace) {
        CGColorSpaceRelease(_colorSpace);
        _colorSpace = CGColorSpaceRetain(colorSpace);
    }

    static CFDictionaryRef useExtendedRange = NULL;
    if (!useExtendedRange) {
        extern NSString *kColorSyncConvertUseExtendedRange;

        useExtendedRange = CFBridgingRetain(@{
            kColorSyncConvertUseExtendedRange: @YES
        });
    }

    if (transform && ColorSyncTransformConvert(transform, 1, 1,
        &dst, kColorSync32BitFloat, 0, 12,
        &src, kColorSync32BitFloat, 0, 12,
        useExtendedRange)
    ) {
        _rawValid = YES;
        _red   = dst[0];
        _green = dst[1];
        _blue  = dst[2];
    }
    
    [self _didChangeRGB];
}


- (void) setRed:(float)red green:(float)green blue:(float)blue
{
    _rawValid = NO;

    _red   = red;
    _green = green;
    _blue  = blue;

    [self _didChangeRGB];
}


- (void) setHue:(float)hue saturation:(float)saturation brightness:(float)brightness
{
    if ( _hue           != hue        )  _hue           = hue;
    if ( _saturationHSB != saturation )  _saturationHSB = saturation;
    if ( _brightness    != brightness )  _brightness    = brightness;
    
    [self _didChangeHSB];
}


- (void) setHue:(float)hue saturation:(float)saturation lightness:(float)lightness
{
    if ( _hue           != hue        )  _hue           = hue;
    if ( _saturationHSL != saturation )  _saturationHSL = saturation;
    if ( _lightness     != lightness  )  _lightness     = lightness;
    
    [self _didChangeHSL];
}


- (void) getRed:(float *)outR green:(float *)outG blue:(float *)outB
{
    if (outR)  *outR = _red;
    if (outG)  *outG = _green;
    if (outB)  *outB = _blue;
}


- (void) getHue:(float *)outH saturation:(float *)outS brightness:(float *)outB
{
    if (outH)  *outH = _hue;
    if (outS)  *outS = _saturationHSB;
    if (outB)  *outB = _brightness;
}


- (void) getHue:(float *)outH saturation:(float *)outS lightness:(float *)outL
{
    if (outH)  *outH = _hue;
    if (outS)  *outS = _saturationHSL;
    if (outL)  *outL = _lightness;
}


#pragma mark - Accessors

- (NSColor *) NSColor
{
    return [NSColor colorWithDeviceRed:_red green:_green blue:_blue alpha:1.0];
}

@end
