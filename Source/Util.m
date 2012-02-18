//
//  Util.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "Util.h"

#import <ApplicationServices/ApplicationServices.h>

BOOL ColorModeIsRGB(ColorMode mode)
{
    return (mode == ColorMode_RGB_Percentage) ||
           (mode == ColorMode_RGB_Value_8)    ||
           (mode == ColorMode_RGB_Value_16)   ||
           (mode == ColorMode_RGB_HexValue_8) ||
           (mode == ColorMode_RGB_HexValue_16);
}


BOOL ColorModeIsHue(ColorMode mode)
{
    return (mode == ColorMode_HSB) || (mode == ColorMode_HSL);
}


BOOL ColorModeIsXYZ(ColorMode mode)
{
    return (mode == ColorMode_CIE_1931) ||
           (mode == ColorMode_CIE_1976) ||
           (mode == ColorMode_Tristimulus);
}


static void sConvertColor(Color *inColor, CFStringRef profileName, float *outFloat0, float *outFloat1, float *outFloat2)
{
    ColorSyncProfileRef fromProfile = ColorSyncProfileCreateWithDisplayID(CGMainDisplayID());
    ColorSyncProfileRef toProfile   = ColorSyncProfileCreateWithName(profileName);
    
    NSDictionary *from = [[NSDictionary alloc] initWithObjectsAndKeys:
        (__bridge id)fromProfile,                         (__bridge id)kColorSyncProfile,
        (__bridge id)kColorSyncRenderingIntentPerceptual, (__bridge id)kColorSyncRenderingIntent,
        (__bridge id)kColorSyncTransformDeviceToPCS,      (__bridge id)kColorSyncTransformTag,
        nil];

    NSDictionary *to = [[NSDictionary alloc] initWithObjectsAndKeys:
        (__bridge id)toProfile,                           (__bridge id)kColorSyncProfile,
        (__bridge id)kColorSyncRenderingIntentPerceptual, (__bridge id)kColorSyncRenderingIntent,
        (__bridge id)kColorSyncTransformPCSToDevice,      (__bridge id)kColorSyncTransformTag,
        nil];
        
    NSArray      *profiles = [[NSArray alloc] initWithObjects:from, to, nil];
    NSDictionary *options  = [[NSDictionary alloc] initWithObjectsAndKeys:
        (__bridge id)kColorSyncBestQuality, (__bridge id)kColorSyncConvertQuality,
        nil]; 

    ColorSyncTransformRef transform = ColorSyncTransformCreate((__bridge CFArrayRef)profiles, (__bridge CFDictionaryRef)options);
    
    if (transform) {
        float input[3]  = { [inColor red], [inColor green], [inColor blue] };
        float output[3] = { 0.0, 0.0, 0.0 };

        ColorSyncTransformConvert(transform, 1, 1, &output[0], kColorSync32BitFloat, kColorSyncByteOrderDefault, 12, &input[0], kColorSync32BitFloat, kColorSyncByteOrderDefault, 12, NULL);

        *outFloat0 = output[0];
        *outFloat1 = output[1];
        *outFloat2 = output[2];
    
        CFRelease(transform);
    }

    if (fromProfile) CFRelease(fromProfile);
    if (toProfile)   CFRelease(toProfile);
}


extern void GetAverageColor(CGImageRef image, CGRect apertureRect, float *outRed, float *outGreen, float *outBlue)
{
    CFDataRef data = NULL;

    // 1) Check the CGBitmapInfo of the image.  We need it to be kCGBitmapByteOrder32Little with
    //    non-float-components and in RGB_ or _RGB;
    //
    CGBitmapInfo      bitmapInfo = CGImageGetBitmapInfo(image);
    CGImageAlphaInfo  alphaInfo  = bitmapInfo & kCGBitmapAlphaInfoMask;
    NSInteger         orderInfo  = bitmapInfo & kCGBitmapByteOrderMask;

    size_t bytesPerRow = CGImageGetBytesPerRow(image);

    BOOL isOrderOK = (orderInfo == kCGBitmapByteOrder32Little);
    BOOL isAlphaOK = NO;

    if (alphaInfo == kCGImageAlphaLast || alphaInfo == kCGImageAlphaNoneSkipLast) {
        alphaInfo = kCGImageAlphaLast;
        isAlphaOK = YES;
    } else if (alphaInfo == kCGImageAlphaFirst || alphaInfo == kCGImageAlphaNoneSkipFirst) {
        alphaInfo = kCGImageAlphaFirst;
        isAlphaOK = YES;
    }


    // 2) If the order and alpha are both ok, we can do a fast path with CGImageGetDataProvider()
    //    Else, convert it to  kCGImageAlphaNoneSkipLast+kCGBitmapByteOrder32Little
    //
    if (isOrderOK && isAlphaOK) {
        CGDataProviderRef provider = CGImageGetDataProvider(image);
        data = CGDataProviderCopyData(provider);
        
    } else {
        size_t       width      = CGImageGetWidth(image);
        size_t       height     = CGImageGetHeight(image);
        CGBitmapInfo bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Little;

        CGColorSpaceRef space   = CGColorSpaceCreateDeviceRGB();
        CGContextRef    context = space ? CGBitmapContextCreate(NULL, width, height, 8, 4 * width, space, bitmapInfo) : NULL;

        if (context) {
            CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);

            const void *bytes = CGBitmapContextGetData(context);
            data = CFDataCreate(NULL, bytes, 4 * width * height);

            bytesPerRow = CGBitmapContextGetBytesPerRow(context);
            alphaInfo   = kCGImageAlphaLast;
        }
        
        CGColorSpaceRelease(space);
        CGContextRelease(context);
    }
    
    UInt8 *buffer = data ? (UInt8 *)CFDataGetBytePtr(data) : NULL;
    NSInteger totalSamples = apertureRect.size.width * apertureRect.size.height; 
    
    if (buffer && (totalSamples > 0)) {
        NSUInteger r = 0;
        NSUInteger g = 0;
        NSUInteger b = 0;

        NSInteger minY = CGRectGetMinY(apertureRect);
        NSInteger maxY = CGRectGetMaxY(apertureRect);
        NSInteger minX = CGRectGetMinX(apertureRect);
        NSInteger maxX = CGRectGetMaxX(apertureRect);

        for (NSInteger y = minY; y < maxY; y++) {
            UInt8 *ptr    = buffer + (y * bytesPerRow) + (4 * minX);
            UInt8 *maxPtr = buffer + (y * bytesPerRow) + (4 * maxX);

            if (alphaInfo == kCGImageAlphaLast) {
                while (ptr < maxPtr) {
                    //   ptr[0]
                    b += ptr[1];
                    g += ptr[2];
                    r += ptr[3];

                    ptr += 4;
                }

            } else if (alphaInfo == kCGImageAlphaFirst) {
                while (ptr < maxPtr) {
                    b += ptr[0];
                    g += ptr[1];
                    r += ptr[2];
                    //   ptr[3]

                    ptr += 4;
                }
            }
        }

        *outRed   = ((r / totalSamples) / 255.0);
        *outGreen = ((g / totalSamples) / 255.0);
        *outBlue  = ((b / totalSamples) / 255.0);
    }
    
    if (data) {
        CFRelease(data);
    }
}


Color *GetColorFromParsedString(NSString *stringToParse)
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
            
            [color setRed:   scanHex([result objectAtIndex:0], 65535.0)];
            [color setGreen: scanHex([result objectAtIndex:1], 65535.0)];
            [color setBlue:  scanHex([result objectAtIndex:2], 65535.0)];
        }
    });
    
    withPattern(@"#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})", ^(NSArray *result) {
        if ([result count] == 3) {
            color = [[Color alloc] init];
            
            [color setRed:   scanHex([result objectAtIndex:0], 255.0)];
            [color setGreen: scanHex([result objectAtIndex:1], 255.0)];
            [color setBlue:  scanHex([result objectAtIndex:2], 255.0)];
        }
    });

    withPattern(@"rgb\\s*\\(\\s*([0-9.]+)\\s*,\\s*([0-9.]+)\\s*,\\s*([0-9.]+)\\s*\\)", ^(NSArray *result) {
        if ([result count] == 3) {
            color = [[Color alloc] init];
            
            [color setRed:   ([[result objectAtIndex:0] floatValue] / 255.0)];
            [color setGreen: ([[result objectAtIndex:1] floatValue] / 255.0)];
            [color setBlue:  ([[result objectAtIndex:2] floatValue] / 255.0)];
        }
    });

    withPattern(@"rgba\\s*\\(\\s*([0-9.]+)\\s*,\\s*([0-9.]+)\\s*,\\s*([0-9.]+)\\s*,\\s*([0-9.]+)\\s*\\)", ^(NSArray *result) {
        if ([result count] == 4) {
            color = [[Color alloc] init];
            
            [color setRed:   ([[result objectAtIndex:0] floatValue] / 255.0)];
            [color setGreen: ([[result objectAtIndex:1] floatValue] / 255.0)];
            [color setBlue:  ([[result objectAtIndex:2] floatValue] / 255.0)];
        }
    });

    withPattern(@"([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})", ^(NSArray *result) {
        if ([result count] == 3) {
            color = [[Color alloc] init];
            
            [color setRed:   scanHex([result objectAtIndex:0], 255.0)];
            [color setGreen: scanHex([result objectAtIndex:1], 255.0)];
            [color setBlue:  scanHex([result objectAtIndex:2], 255.0)];
        }
    });

    return color;
}


float ColorModeParseComponentString(ColorMode mode, ColorComponent component, NSString *string)
{
    float result = 0.0;

    if (mode == ColorMode_RGB_HexValue_8 || mode == ColorMode_RGB_HexValue_16) {
        CFIndex  length = CFStringGetLength((__bridge CFStringRef)string);
        unichar *buffer = length ? malloc(sizeof(unichar) * length) : NULL;
        if (!buffer) return result;

        CFStringGetCharacters((__bridge CFStringRef)string, CFRangeMake(0, length), buffer);
        
        for (CFIndex i = 0; i < length; i++) {
            unichar c = buffer[i];
        
            if (c == 'x' || c == 'X') {
                result = 0;

            } else if (ishexnumber(c)) {
                result *= 16;

                if (c >= 'a' && c <= 'f') {
                    result += (10 + (c - 'a'));
                } else if (c >= 'A' && c <= 'F') {
                    result += (10 + (c - 'A'));
                } else if (c >= '0' && c <= '9') {
                    result += (c - '0');
                }
            }
        
        }
        
        free(buffer);

    } else {
        result = [string floatValue];
    }

    if (mode == ColorMode_RGB_Value_16 || mode == ColorMode_RGB_HexValue_16) {
        result /= 65535.0;
    } else if (mode == ColorMode_RGB_Value_8 || mode == ColorMode_RGB_HexValue_8) {
        result /= 255.0;
    } else if (ColorModeIsHue(mode) && component == ColorComponentHue) {
        result /= 360.0;
    } else {
        result /= 100.0;
    }

    if (result < 0.0) {
        result = 0.0;
    } else if (result > 1.0) {
        result = 1.0;
    }
    
    return result;
}


static void sMakeStrings(
    ColorMode mode,
    Color *color,
    BOOL lowercaseHex,
    BOOL usesPoundPrefix,
    NSString **outClipboard,
    NSString **outValue1,
    NSString **outValue2,
    NSString **outValue3,
    BOOL     *outClipped1,
    BOOL     *outClipped2,
    BOOL     *outClipped3 
)
{
    NSString *value1    = nil;
    NSString *value2    = nil;
    NSString *value3    = nil;
    NSString *clipboard = nil;

    float red   = [color red];
    float green = [color green];
    float blue  = [color blue];
    
    BOOL clipped1 = NO;
    BOOL clipped2 = NO;
    BOOL clipped3 = NO;

    if (mode == ColorMode_RGB_Percentage) {
        red   *= 100;
        green *= 100;
        blue  *= 100;

        {
            if      (red   >= 100.0499) { red   = 100.0; clipped1 = YES; }
            else if (red   <=  -0.0499) { red   =   0.0; clipped1 = YES; }

            if      (green >= 100.0499) { green = 100.0; clipped2 = YES; }
            else if (green <=  -0.0499) { green =   0.0; clipped2 = YES; }

            if      (blue  >= 100.0499) { blue  = 100.0; clipped3 = YES; }
            else if (blue  <=  -0.0499) { blue  =   0.0; clipped3 = YES; }
        }

        value1 = [NSString stringWithFormat:@"%0.1lf", red];
        value2 = [NSString stringWithFormat:@"%0.1lf", green];
        value3 = [NSString stringWithFormat:@"%0.1lf", blue];

    } else if (mode == ColorMode_RGB_Value_8 || mode == ColorMode_RGB_HexValue_8) {
        NSString *format = @"%ld";
        
        if (mode == ColorMode_RGB_HexValue_8) {
            format = lowercaseHex ? @"%02lx" : @"%02lX";
        }
        
        long redLong   = lroundf(red   * 255);
        long greenLong = lroundf(green * 255);
        long blueLong  = lroundf(blue  * 255);
        
        {
            if      (redLong   > 255) { redLong   = 255; clipped1 = YES; }
            else if (redLong   < 0)   { redLong   = 0;   clipped1 = YES; }

            if      (greenLong > 255) { greenLong = 255; clipped2 = YES; }
            else if (greenLong < 0)   { greenLong = 0;   clipped2 = YES; }

            if      (blueLong  > 255) { blueLong  = 255; clipped3 = YES; }
            else if (blueLong  < 0)   { blueLong  = 0;   clipped3 = YES; }
        }
        
        value1 = [NSString stringWithFormat:format, redLong];
        value2 = [NSString stringWithFormat:format, greenLong];
        value3 = [NSString stringWithFormat:format, blueLong];

        if (mode == ColorMode_RGB_HexValue_8) { 
            if (usesPoundPrefix) {
                clipboard = [NSString stringWithFormat:@"#%@%@%@", value1, value2, value3];
            } else {
                clipboard = [NSString stringWithFormat: @"%@%@%@", value1, value2, value3];
            }
        }

    } else if (mode == ColorMode_RGB_Value_16 || mode == ColorMode_RGB_HexValue_16) {
        NSString *format = @"%ld";
        
        if (mode == ColorMode_RGB_HexValue_16) {
            format = lowercaseHex ? @"%04lx" : @"%04lX";
        }

        long redLong   = lroundf(red   * 65535);
        long greenLong = lroundf(green * 65535);
        long blueLong  = lroundf(blue  * 65535);
        
        {
            if      (redLong   > 65535) { redLong   = 65535; clipped1 = YES; }
            else if (redLong   < 0)     { redLong   = 0;     clipped1 = YES; }

            if      (greenLong > 65535) { greenLong = 65535; clipped2 = YES; }
            else if (greenLong < 0)     { greenLong = 0;     clipped2 = YES; }

            if      (blueLong  > 65535) { blueLong  = 65535; clipped3 = YES; }
            else if (blueLong  < 0)     { blueLong  = 0;     clipped3 = YES; }
        }

        value1 = [NSString stringWithFormat:format, redLong];
        value2 = [NSString stringWithFormat:format, greenLong];
        value3 = [NSString stringWithFormat:format, blueLong];

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
        
        value1    = [NSString stringWithFormat:@"%0.03lf", (l * 100.0)];
        value2    = [NSString stringWithFormat:@"%0.03lf", (a * 256.0) - 128.0];
        value3    = [NSString stringWithFormat:@"%0.03lf", (b * 256.0) - 128.0];

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

        if      (s > 100) { s = 100; clipped2 = YES; }
        else if (s < 0)   { s = 0;   clipped2 = YES; }

        if      (bl > 100) { bl = 100; clipped3 = YES; }
        else if (bl < 0)   { bl = 0;   clipped3 = YES; }

        value1 = [NSString stringWithFormat:@"%ld", h];
        value2 = [NSString stringWithFormat:@"%ld", s];
        value3 = [NSString stringWithFormat:@"%ld", bl];
    }
    
    if (!clipboard) {
        clipboard = [NSString stringWithFormat:@"%@\t%@\t%@", value1, value2, value3];
    }

    if (outValue1)    { *outValue1    = value1;    }
    if (outValue2)    { *outValue2    = value2;    }
    if (outValue3)    { *outValue3    = value3;    }
    if (outClipped1)  { *outClipped1  = clipped1;  }
    if (outClipped2)  { *outClipped2  = clipped2;  }
    if (outClipped3)  { *outClipped3  = clipped3;  }
    if (outClipboard) { *outClipboard = clipboard; }
}


void ColorModeMakeClipboardString(
    ColorMode mode,
    Color *color,
    BOOL lowercaseHex,
    BOOL usesPoundPrefix,
    NSString **outClipboard
) {
    sMakeStrings(
        mode, color, lowercaseHex, usesPoundPrefix,
        outClipboard,
        NULL, NULL, NULL,
        NULL, NULL, NULL
    );
}


void ColorModeMakeComponentStrings(
    ColorMode mode,
    Color *color,
    BOOL lowercaseHex,
    BOOL usesPoundPrefix,
    NSString **outLabel1,
    NSString **outLabel2,
    NSString **outLabel3,
    BOOL *outClipped1,
    BOOL *outClipped2,
    BOOL *outClipped3 
) {
    sMakeStrings(
        mode, color, lowercaseHex, usesPoundPrefix,
        NULL,
        outLabel1, outLabel2, outLabel3,
        outClipped1, outClipped2, outClipped3
    );
}


NSString *ColorModeGetName(ColorMode mode)
{
    if (mode == ColorMode_RGB_Percentage) {
        return NSLocalizedString(@"RGB as percentage", @"RGB %");

    } else if (mode == ColorMode_RGB_Value_8) {
        return NSLocalizedString(@"RGB as actual value, 8-bit", @"RGB, actual value, 8-bit");

    } else if (mode == ColorMode_RGB_Value_16) {
        return NSLocalizedString(@"RGB as actual value, 16-bit", @"RGB, actual value, 16-bit");

    } else if (mode == ColorMode_RGB_HexValue_8) {
        return NSLocalizedString(@"RGB as hex value, 8-bit", @"RGB, hex, 8-bit");

    } else if (mode == ColorMode_RGB_HexValue_16) {
        return NSLocalizedString(@"RGB as hex value, 16-bit", @"RGB, hex, 16-bit");

    } else if (mode == ColorMode_YPbPr_601) {
        return NSLocalizedString(@"Y'PrPb ITU-R BT.601", @"Y'PrPb 601");
    
    } else if (mode == ColorMode_YPbPr_709) {
        return NSLocalizedString(@"Y'PrPb ITU-R BT.709", @"Y'PrPb 709");

    } else if (mode == ColorMode_YCbCr_601) {
        return NSLocalizedString(@"Y'CbCr ITU-R BT.601", @"Y'CbCr 601");

    } else if (mode == ColorMode_YCbCr_709) {
        return NSLocalizedString(@"Y'CbCr ITU-R BT.709", @"Y'CbCr 709");

    } else if (mode == ColorMode_CIE_1931) {
        return NSLocalizedString(@"CIE 1931", @"CIE 1931");

    } else if (mode == ColorMode_CIE_1976) {
        return NSLocalizedString(@"CIE 1976", @"CIE 1976");

    } else if (mode == ColorMode_CIE_Lab) {
        return NSLocalizedString(@"CIE L*a*b*", @"CIE L*a*b*");

    } else if (mode == ColorMode_Tristimulus) {
        return NSLocalizedString(@"Tristimulus", @"Tristimulus");

    } else if (mode == ColorMode_HSB) {
        return NSLocalizedString(@"HSB", @"HSB");

    } else if (mode == ColorMode_HSL) {
        return NSLocalizedString(@"HSL", @"HSL");
    }

    return @"";
}


NSArray *ColorModeGetComponentLabels(ColorMode mode)
{
    __block NSArray *result = nil;
    
    void (^f)(NSString *, NSString *, NSString *) = ^(NSString *s0, NSString *s1, NSString *s2) {
        result = [NSArray arrayWithObjects:s0, s1, s2, nil];
    };

    switch (mode) {
    case ColorMode_RGB_Percentage:
        f( @"R%", @"G%", @"B%"); 
        break;
    
    case ColorMode_RGB_Value_8:
    case ColorMode_RGB_Value_16:
    case ColorMode_RGB_HexValue_8:
    case ColorMode_RGB_HexValue_16:
        f( @"R", @"G", @"B"); 
        break;

    case ColorMode_YPbPr_601:
    case ColorMode_YPbPr_709:
        f( @"Y'", @"Pb", @"Pr");
        break;

    case ColorMode_YCbCr_601:
    case ColorMode_YCbCr_709:
        f( @"Y'", @"Pb", @"Pr");
        break;

    case ColorMode_CIE_1931:
        f( @"x", @"y", @"fL" );
        break;

    case ColorMode_CIE_1976:
        f( @"u'", @"v'", @"fL" );
        break;

    case ColorMode_CIE_Lab:
        f( @"L*", @"a*", @"b*" );
        break;

    case ColorMode_Tristimulus:
        f( @"X", @"Y", @"Z" );
        break;
        
    case ColorMode_HSB:
        f( @"H", @"S", @"B" );
        break;

    case ColorMode_HSL:
        f( @"H", @"S", @"L" );
        break;
    }

    return result;
}


extern NSString *GetCodeSnippetForColor(Color *color, BOOL lowercaseHex, NSString *inTemplate)
{
    NSMutableString *result = [inTemplate mutableCopy];

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

    float red   = [color red];
    float green = [color green];
    float blue  = [color blue];

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


NSImage *GetSnapshotImageForView(NSView *view)
{
    NSRect   bounds = [view bounds];
    NSImage *image  = [[NSImage alloc] initWithSize:bounds.size];

    [image lockFocus];
    [view displayRectIgnoringOpacity:[view bounds] inContext:[NSGraphicsContext currentContext]];
    [image unlockFocus];

    return image;
}


CGContextRef CreateBitmapContext(CGSize size, BOOL opaque, CGFloat scale)
{
    size_t width  = size.width  * scale;
    size_t height = size.height * scale;

    CGContextRef result = NULL;
    
    if (width > 0 && height > 0) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

        if (colorSpace) {
            CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Little;
            bitmapInfo |= (opaque ? kCGImageAlphaNoneSkipFirst : kCGImageAlphaPremultipliedFirst);

            result = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, bitmapInfo);
        
            if (result) {
                CGContextTranslateCTM(result, 0, height);
                CGContextScaleCTM(result, scale, -scale);
            }
        }

        CGColorSpaceRelease(colorSpace);
    }

    
    return result;
}


CGImageRef CreateImageMask(CGSize size, CGFloat scale, void (^callback)(CGContextRef))
{
    size_t width  = size.width * scale;
    size_t height = size.height * scale;

    CGImageRef      cgImage    = NULL;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();

    if (colorSpace && width > 0 && height > 0) {
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, width, colorSpace, kCGImageAlphaNone);
    
        if (context) {
            CGContextTranslateCTM(context, 0, height);
            CGContextScaleCTM(context, scale, -scale);

            NSGraphicsContext *savedContext = [NSGraphicsContext currentContext];
            [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:YES]];

            callback(context);
            
            [NSGraphicsContext setCurrentContext:savedContext];

            cgImage = CGBitmapContextCreateImage(context);
            CFRelease(context);
        }
    }

    CGColorSpaceRelease(colorSpace);

    return cgImage;
}

