//
//  ColorCalculator.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "ColorCalculator.h"

#import <ApplicationServices/ApplicationServices.h>

static void sConvertColor(uint32_t displayID, CFStringRef profileName, Color *inColor, Color *outColor)
{
    ColorSyncProfileRef fromProfile = ColorSyncProfileCreateWithDisplayID(displayID);
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
        float input[3]  = { inColor->red, inColor->green, inColor->blue };
        float output[3] = { 0.0, 0.0, 0.0 };

        ColorSyncTransformConvert(transform, 1, 1, &output[0], kColorSync32BitFloat, kColorSyncByteOrderDefault, 12, &input[0], kColorSync32BitFloat, kColorSyncByteOrderDefault, 12, NULL);

        outColor->red   = output[0];
        outColor->green = output[1];
        outColor->blue  = output[2];
    
        CFRelease(transform);
    }

    [profiles release];
    [options  release];
    [to       release];
    [from     release];

    if (fromProfile) CFRelease(fromProfile);
    if (toProfile)   CFRelease(toProfile);
}


void ColorCalculatorGetCIE1931Color(uint32_t inDisplay, Color *inColor, float *outX, float *outY, float *outFL)
{
    Color fakeColor;
    sConvertColor(inDisplay, kColorSyncGenericXYZProfile, inColor, &fakeColor);

    float X = fakeColor.red;
    float Y = fakeColor.green;
    float Z = fakeColor.blue;

    float divisor = X + Y + Z;

    *outX  = (divisor == 0.0) ? 0.0 : (X / divisor);
    *outY  = (divisor == 0.0) ? 0.0 : (Y / divisor);
    *outFL = (Y * 100);
}


void ColorCalculatorGetCIE1976Color(uint32_t inDisplay, Color *inColor, float *outU, float *outV, float *outFL)
{   
    Color fakeColor;
    sConvertColor(inDisplay, kColorSyncGenericXYZProfile, inColor, &fakeColor);

    float X = fakeColor.red;
    float Y = fakeColor.green;
    float Z = fakeColor.blue;

    float divisor = (X + (15 * Y) + (3 * Z));

    *outU = (divisor == 0.0) ? 0.0 : ((4 * X) / divisor);
    *outV = (divisor == 0.0) ? 0.0 : ((9 * Y) / divisor);
    *outFL = (Y * 100);
}


void ColorCalculatorGetLabColor(uint32_t inDisplay, Color *inColor, float *outL, float *outA, float *outB)
{   
    Color fakeColor;
    sConvertColor(inDisplay, kColorSyncGenericLabProfile, inColor, &fakeColor);
    
    *outL = (fakeColor.red   * 100.0);
    *outA = (fakeColor.green * 256.0) - 128.0;
    *outB = (fakeColor.blue  * 256.0) - 128.0;
}


void ColorCalculatorGetTristimulusColor(uint32_t inDisplay, Color *inColor, float *outX, float *outY, float *outZ)
{   
    Color fakeColor;
    sConvertColor(inDisplay, kColorSyncGenericXYZProfile, inColor, &fakeColor);
    
    *outX = (fakeColor.red   * 100.0);
    *outY = (fakeColor.green * 100.0);
    *outZ = (fakeColor.blue  * 100.0);
}


extern void ColorCalculatorGetAverageColor(CGImageRef image, CGRect apertureRect, Color *outColor)
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
    
    if (buffer) {
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

        NSInteger totalSamples = apertureRect.size.width * apertureRect.size.height; 
        outColor->red   = ((r / totalSamples) / 255.0);
        outColor->green = ((g / totalSamples) / 255.0);
        outColor->blue  = ((b / totalSamples) / 255.0);
    }
    
    if (data) {
        CFRelease(data);
    }
}


void ColorCalculatorCalculate(uint32_t inDisplay, ColorMode mode, Color *color, NSString **outValue1, NSString **outValue2, NSString **outValue3, NSString **outClipboard)
{
    NSString *value1    = nil;
    NSString *value2    = nil;
    NSString *value3    = nil;
    NSString *clipboard = nil;

    float red   = color->red;
    float green = color->green;
    float blue  = color->blue;

    if (mode == ColorMode_RGB_Percentage) {
        double r = red   * 100;
        double g = green * 100;
        double b = blue  * 100;

        value1    = [NSString stringWithFormat:@"%0.1lf", r];
        value2    = [NSString stringWithFormat:@"%0.1lf", g];
        value3    = [NSString stringWithFormat:@"%0.1lf", b];
        clipboard = [NSString stringWithFormat:@"%0.1lf\t%0.1lf\t%0.1lf", r, g, b];

    } else if (mode == ColorMode_RGB_Value_8 ||
               mode == ColorMode_RGB_HexValue_8)
    {
        long r = (red   * 255);
        long g = (green * 255);
        long b = (blue  * 255);
        
        if (mode == ColorMode_RGB_HexValue_8) {
            value1    = [NSString stringWithFormat:@"%02lX", r];
            value2    = [NSString stringWithFormat:@"%02lX", g];
            value3    = [NSString stringWithFormat:@"%02lX", b];
            clipboard = [NSString stringWithFormat:@"#%02lX%02lX%02lX", r, g, b];

        } else {
            value1 = [NSString stringWithFormat:@"%ld", r];
            value2 = [NSString stringWithFormat:@"%ld", g];
            value3 = [NSString stringWithFormat:@"%ld", b];
            clipboard = [NSString stringWithFormat:@"%ld\t%ld\t%ld", r, g, b];
        }

    } else if (mode == ColorMode_RGB_Value_16 ||
               mode == ColorMode_RGB_HexValue_16)
    {
        long r = (long)(red   * 65535);
        long g = (long)(green * 65535);
        long b = (long)(blue  * 65535);

        if (mode == ColorMode_RGB_Value_16) {
            value1    = [NSString stringWithFormat:@"%04lX", r];
            value2    = [NSString stringWithFormat:@"%04lX", g];
            value3    = [NSString stringWithFormat:@"%04lX", b];
            clipboard = [NSString stringWithFormat:@"#%04lX%04lX%04lX", r, g, b];

        } else {
            value1    = [NSString stringWithFormat:@"%ld", r];
            value2    = [NSString stringWithFormat:@"%ld", g];
            value3    = [NSString stringWithFormat:@"%ld", b];
            clipboard = [NSString stringWithFormat:@"%ld\t%ld\t%ld", r, g, b];
        }

    } else if (mode == ColorMode_YPbPr_601 ||
               mode == ColorMode_YPbPr_709 ||
               mode == ColorMode_YCbCr_601 ||
               mode == ColorMode_YCbCr_709)
    {
        BOOL is601     = (mode == ColorMode_YPbPr_601 || mode == ColorMode_YCbCr_601);
        BOOL isDigital = (mode == ColorMode_YCbCr_601 || mode == ColorMode_YCbCr_709);

        double kr = is601 ? 0.299 : 0.2126;
        double kb = is601 ? 0.114 : 0.0722;

        double y  = (kr * red) + ((1 - (kr + kb)) * green) + (kb * blue);
        double pb = 0.5 * ((blue - y) / (1 - kb));
        double pr = 0.5 * ((red  - y) / (1 - kr));
        
        if (isDigital) {
            long yAsLong  = 16  + round(y  * 219.0);
            long pbAsLong = 128 + round(pb * 224.0);
            long prAsLong = 128 + round(pr * 224.0);
        
            value1    = [NSString stringWithFormat:@"%ld", yAsLong];
            value2    = [NSString stringWithFormat:@"%ld", pbAsLong];
            value3    = [NSString stringWithFormat:@"%ld", prAsLong];
            clipboard = [NSString stringWithFormat:@"%ld\t%ld\t%ld", yAsLong, pbAsLong, prAsLong];

        } else {
            value1    = [NSString stringWithFormat:@"%0.03lf", y];
            value2    = [NSString stringWithFormat:@"%0.03lf", pb];
            value3    = [NSString stringWithFormat:@"%0.03lf", pr];
            clipboard = [NSString stringWithFormat:@"%0.03lf\t%0.03lf\t%0.03lf", value1, value2, value3];
        }
    } else if (mode == ColorMode_CIE_1931) {
        float x, y, fl;
        ColorCalculatorGetCIE1931Color(inDisplay, color, &x, &y, &fl);

        value1    = [NSString stringWithFormat:@"%0.03lf", x];
        value2    = [NSString stringWithFormat:@"%0.03lf", y];
        value3    = [NSString stringWithFormat:@"%0.03lf", fl];
        clipboard = [NSString stringWithFormat:@"%0.03lf\t%0.03lf\t%0.03lf", x, y, fl];
        
    } else if (mode == ColorMode_CIE_1976) {
        float u, v, fl;
        ColorCalculatorGetCIE1976Color(inDisplay, color, &u, &v, &fl);

        value1    = [NSString stringWithFormat:@"%0.03lf", u];
        value2    = [NSString stringWithFormat:@"%0.03lf", v];
        value3    = [NSString stringWithFormat:@"%0.03lf", fl];
        clipboard = [NSString stringWithFormat:@"%0.03lf\t%0.03lf\t%0.03lf", u, v, fl];

    } else if (mode == ColorMode_CIE_Lab) {
        float l, a, b;
        ColorCalculatorGetLabColor(inDisplay, color, &l, &a, &b);
        
        value1    = [NSString stringWithFormat:@"%0.03lf", l];
        value2    = [NSString stringWithFormat:@"%0.03lf", a];
        value3    = [NSString stringWithFormat:@"%0.03lf", b];
        clipboard = [NSString stringWithFormat:@"%0.03lf\t%0.03lf\t%0.03lf", l, a, b];

    } else if (mode == ColorMode_Tristimulus) {
        float x, y, z;
        ColorCalculatorGetTristimulusColor(inDisplay, color, &x, &y, &z);
        
        value1    = [NSString stringWithFormat:@"%0.03lf", x];
        value2    = [NSString stringWithFormat:@"%0.03lf", y];
        value3    = [NSString stringWithFormat:@"%0.03lf", z];
        clipboard = [NSString stringWithFormat:@"%0.03lf\t%0.03lf\t%0.03lf", x, y, z];
    }
    
    *outValue1    = value1;
    *outValue2    = value2;
    *outValue3    = value3;
    *outClipboard = clipboard;
}


NSString *ColorCalculatorGetName(ColorMode mode)
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
    }

    return @"";
}


NSArray *ColorCalculatorGetComponentLabels(ColorMode mode)
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
    }

    return result;
}

