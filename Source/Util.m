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


BOOL ColorModeIsHSB(ColorMode mode)
{
    return (mode == ColorMode_HSB);
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
        (id)fromProfile,                         (id)kColorSyncProfile,
        (id)kColorSyncRenderingIntentPerceptual, (id)kColorSyncRenderingIntent,
        (id)kColorSyncTransformDeviceToPCS,      (id)kColorSyncTransformTag,
        nil];

    NSDictionary *to = [[NSDictionary alloc] initWithObjectsAndKeys:
        (id)toProfile,                           (id)kColorSyncProfile,
        (id)kColorSyncRenderingIntentPerceptual, (id)kColorSyncRenderingIntent,
        (id)kColorSyncTransformPCSToDevice,      (id)kColorSyncTransformTag,
        nil];
        
    NSArray      *profiles = [[NSArray alloc] initWithObjects:from, to, nil];
    NSDictionary *options  = [[NSDictionary alloc] initWithObjectsAndKeys:
        (id)kColorSyncBestQuality, (id)kColorSyncConvertQuality,
        nil]; 

    ColorSyncTransformRef transform = ColorSyncTransformCreate((CFArrayRef)profiles, (CFDictionaryRef)options);
    
    if (transform) {
        float input[3]  = { [inColor red], [inColor green], [inColor blue] };
        float output[3] = { 0.0, 0.0, 0.0 };

        ColorSyncTransformConvert(transform, 1, 1, &output[0], kColorSync32BitFloat, kColorSyncByteOrderDefault, 12, &input[0], kColorSync32BitFloat, kColorSyncByteOrderDefault, 12, NULL);

        *outFloat0 = output[0];
        *outFloat1 = output[1];
        *outFloat2 = output[2];
    
        CFRelease(transform);
    }

    [profiles release];
    [options  release];
    [to       release];
    [from     release];

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
            color = [[[Color alloc] init] autorelease];
            
            [color setRed:   scanHex([result objectAtIndex:0], 65535.0)];
            [color setGreen: scanHex([result objectAtIndex:1], 65535.0)];
            [color setBlue:  scanHex([result objectAtIndex:2], 65535.0)];
        }
    });
    
    withPattern(@"#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})", ^(NSArray *result) {
        if ([result count] == 3) {
            color = [[[Color alloc] init] autorelease];
            
            [color setRed:   scanHex([result objectAtIndex:0], 255.0)];
            [color setGreen: scanHex([result objectAtIndex:1], 255.0)];
            [color setBlue:  scanHex([result objectAtIndex:2], 255.0)];
        }
    });

    withPattern(@"rgb\\s*\\(\\s*([0-9.]+)\\s*,\\s*([0-9.]+)\\s*,\\s*([0-9.]+)\\s*\\)", ^(NSArray *result) {
        if ([result count] == 3) {
            color = [[[Color alloc] init] autorelease];
            
            [color setRed:   ([[result objectAtIndex:0] floatValue] / 255.0)];
            [color setGreen: ([[result objectAtIndex:1] floatValue] / 255.0)];
            [color setBlue:  ([[result objectAtIndex:2] floatValue] / 255.0)];
        }
    });

    withPattern(@"rgba\\s*\\(\\s*([0-9.]+)\\s*,\\s*([0-9.]+)\\s*,\\s*([0-9.]+)\\s*,\\s*([0-9.]+)\\s*\\)", ^(NSArray *result) {
        if ([result count] == 4) {
            color = [[[Color alloc] init] autorelease];
            
            [color setRed:   ([[result objectAtIndex:0] floatValue] / 255.0)];
            [color setGreen: ([[result objectAtIndex:1] floatValue] / 255.0)];
            [color setBlue:  ([[result objectAtIndex:2] floatValue] / 255.0)];
        }
    });

    withPattern(@"([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})", ^(NSArray *result) {
        if ([result count] == 3) {
            color = [[[Color alloc] init] autorelease];
            
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
        CFIndex  length = CFStringGetLength((CFStringRef)string);
        unichar *buffer = length ? malloc(sizeof(unichar) * length) : NULL;
        if (!buffer) return result;

        CFStringGetCharacters((CFStringRef)string, CFRangeMake(0, length), buffer);
        
        for (CFIndex i = 0; i < length; i++) {
            unichar c = buffer[i];
        
            if (c == 'x' || c == 'X') {
                result = 0;

            } else if (ishexnumber(c)) {
                result *= 16;

                if (c >= 'a' && c <= 'f') {
                    result += (10 + (c - 'a'));
                } else if (c >= 'A' && c <= 'F') {
                    result += (c - 'A');
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
    } else if (mode == ColorMode_HSB && component == ColorComponentHue) {
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


void ColorModeMakeComponentStrings(ColorMode mode, Color *color, BOOL lowercaseHex, BOOL usesPoundPrefix, NSString **outValue1, NSString **outValue2, NSString **outValue3, NSString **outClipboard)
{
    NSString *value1    = nil;
    NSString *value2    = nil;
    NSString *value3    = nil;
    NSString *clipboard = nil;

    float red   = [color red];
    float green = [color green];
    float blue  = [color blue];

    if (mode == ColorMode_RGB_Percentage) {
        value1 = [NSString stringWithFormat:@"%0.1lf", red   * 100];
        value2 = [NSString stringWithFormat:@"%0.1lf", green * 100];
        value3 = [NSString stringWithFormat:@"%0.1lf", blue  * 100];

    } else if (mode == ColorMode_RGB_Value_8 || mode == ColorMode_RGB_HexValue_8) {
        NSString *format = @"%ld";
        
        if (mode == ColorMode_RGB_HexValue_8) {
            format = lowercaseHex ? @"%02lx" : @"%02lX";
        }
        
        value1 = [NSString stringWithFormat:format, lroundf(red   * 255)];
        value2 = [NSString stringWithFormat:format, lroundf(green * 255)];
        value3 = [NSString stringWithFormat:format, lroundf(blue  * 255)];

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

        value1 = [NSString stringWithFormat:format, lroundf(red   * 65535)];
        value2 = [NSString stringWithFormat:format, lroundf(green * 65535)];
        value3 = [NSString stringWithFormat:format, lroundf(blue  * 65535)];

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

    } else if (mode == ColorMode_HSB) {
        value1 = [NSString stringWithFormat:@"%ld", (long) ([color hue]        * 360)];
        value2 = [NSString stringWithFormat:@"%ld", (long) ([color saturation] * 100)];
        value3 = [NSString stringWithFormat:@"%ld", (long) ([color brightness] * 100)];
    }
    
    if (!clipboard) {
        clipboard = [NSString stringWithFormat:@"%@\t%@\t%@", value1, value2, value3];
    }

    if (outValue1)    { *outValue1    = value1;    }
    if (outValue2)    { *outValue2    = value2;    }
    if (outValue3)    { *outValue3    = value3;    }
    if (outClipboard) { *outClipboard = clipboard; }
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
    }

    return result;
}


extern NSString *GetCodeSnippetForColor(Color *color, BOOL lowercaseHex, NSString *inTemplate)
{
    NSMutableString *result = [[inTemplate mutableCopy] autorelease];

    void (^replaceHex)(NSString *, float) = ^(NSString *key, float component) {
        NSString *hexFormat = lowercaseHex ? @"%02x" : @"%02X";
        NSString *hexValue = [NSString stringWithFormat:hexFormat, (NSInteger)(component * 255.0)];
        [result replaceOccurrencesOfString:key withString:hexValue options:NSLiteralSearch range:NSMakeRange(0, [result length])];
    };
    
    void (^replaceNumber)(NSString *, float, float) = ^(NSString *key, float multiplier, float component) {
        NSRange range = [result rangeOfString:key];

        if (range.location != NSNotFound) {
            NSString *string = [NSString stringWithFormat: @"%ld", lroundf(multiplier * component)];
            
            if (string) {
                [result replaceOccurrencesOfString:key withString:string options:NSLiteralSearch range:NSMakeRange(0, [result length])];
            }
        }
    };
    
    void (^replaceFloat)(NSString *, float) = ^(NSString *key, float component) {
        NSRange range = [result rangeOfString:key];

        if (range.location != NSNotFound) {
            unichar number = [result characterAtIndex:(range.location + 7)];
            
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
    
    replaceFloat(@"$RFLOAT", red);
    replaceFloat(@"$GFLOAT", green);
    replaceFloat(@"$BFLOAT", blue);

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

    return [image autorelease];
}

