//
//  Util.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "Util.h"

#import <ApplicationServices/ApplicationServices.h>


NSString * const ProductSiteURLString = @"http://iccir.com/projects/classic-color-meter";
NSString * const FeedbackURLString    = @"http://iccir.com/projects/classic-color-meter/feedback";
NSString * const ConversionsURLString = @"http://iccir.com/articles/osx-color-conversions";
NSString * const AppStoreURLString    = @"macappstore://itunes.apple.com/us/app/classic-color-meter/id451640037?mt=12";


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


NSString *ColorModeGetName(ColorMode mode)
{
    if (mode == ColorMode_RGB_Percentage) {
        return NSLocalizedString(@"RGB, percentage", nil);

    } else if (mode == ColorMode_RGB_Value_8) {
        return NSLocalizedString(@"RGB, decimal, 8-bit", nil);

    } else if (mode == ColorMode_RGB_Value_16) {
        return NSLocalizedString(@"RGB, decimal, 16-bit", nil);

    } else if (mode == ColorMode_RGB_HexValue_8) {
        return NSLocalizedString(@"RGB, hex, 8-bit", nil);

    } else if (mode == ColorMode_RGB_HexValue_16) {
        return NSLocalizedString(@"RGB, hex, 16-bit", nil);

    } else if (mode == ColorMode_YPbPr_601) {
        return NSLocalizedString(@"Y'PrPb ITU-R BT.601", nil);
    
    } else if (mode == ColorMode_YPbPr_709) {
        return NSLocalizedString(@"Y'PrPb ITU-R BT.709", nil);

    } else if (mode == ColorMode_YCbCr_601) {
        return NSLocalizedString(@"Y'CbCr ITU-R BT.601", nil);

    } else if (mode == ColorMode_YCbCr_709) {
        return NSLocalizedString(@"Y'CbCr ITU-R BT.709", nil);

    } else if (mode == ColorMode_CIE_1931) {
        return NSLocalizedString(@"CIE 1931", nil);

    } else if (mode == ColorMode_CIE_1976) {
        return NSLocalizedString(@"CIE 1976", nil);

    } else if (mode == ColorMode_CIE_Lab) {
        return NSLocalizedString(@"CIE L*a*b*", nil);

    } else if (mode == ColorMode_Tristimulus) {
        return NSLocalizedString(@"Tristimulus", nil);

    } else if (mode == ColorMode_HSB) {
        return NSLocalizedString(@"HSB", nil);

    } else if (mode == ColorMode_HSL) {
        return NSLocalizedString(@"HSL", nil);
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
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, width, colorSpace, 0 | kCGImageAlphaNone);
    
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


CGImageRef CreateImage(CGSize size, BOOL opaque, CGFloat scale, void (^callback)(CGContextRef))
{
    size_t width  = size.width * scale;
    size_t height = size.height * scale;

    CGImageRef      cgImage    = NULL;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    if (colorSpace && width > 0 && height > 0) {
        CGBitmapInfo bitmapInfo = 0 | (opaque ? kCGImageAlphaNoneSkipFirst : kCGImageAlphaPremultipliedFirst);
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, bitmapInfo);
    
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


NSString *GetArrowJoinerString()
{
    return [NSString stringWithFormat:@" %C ", (unsigned short)0x279D];
}

