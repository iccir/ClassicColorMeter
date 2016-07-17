//
//  Util.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "Util.h"

#import <ApplicationServices/ApplicationServices.h>
#import <QuartzCore/QuartzCore.h>

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


NSArray *ColorModeGetLongestStrings(ColorMode mode)
{
    __block NSArray *result = nil;
    
    void (^f)(NSString *, NSString *, NSString *) = ^(NSString *s0, NSString *s1, NSString *s2) {
        result = [NSArray arrayWithObjects:s0, s1, s2, nil];
    };

    switch (mode) {
    case ColorMode_RGB_Percentage:
        f( @"99.9%", @"99.9%", @"99.9%"); 
        break;
    
    case ColorMode_RGB_Value_8:
        f( @"255", @"255", @"255"); 
        break;

    case ColorMode_RGB_Value_16:
        f( @"65535", @"65535", @"65535"); 
        break;

    case ColorMode_RGB_HexValue_8:
        f( @"CC", @"CC", @"CC"); 
        break;

    case ColorMode_RGB_HexValue_16:
        f( @"CCCC", @"CCCC", @"CCCC"); 
        break;

    case ColorMode_YPbPr_601:
    case ColorMode_YPbPr_709:
    case ColorMode_YCbCr_601:
    case ColorMode_YCbCr_709:
    case ColorMode_CIE_1931:
    case ColorMode_CIE_1976:
    case ColorMode_Tristimulus:
        f( @"-100.000", @"-100.000", @"-100.000" );
        break;

    case ColorMode_CIE_Lab:
        f( @"100.0", @"-86.2", @"-107.9" );
        break;
        
    case ColorMode_HSB:
    case ColorMode_HSL:
        f( @"360", @"100", @"100" );
        break;
    }

    return result;
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
            [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithCGContext:context flipped:YES]];

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


void DoPopOutAnimation(NSView *view)
{
    CGRect  bounds          = [view bounds];
    CGRect  boundsInBase    = [view convertRect:bounds toView:nil];
    CGRect  boundsInScreen  = [[view window] convertRectToScreen:boundsInBase];
    
    CGRect  fakeWindowFrame = boundsInScreen;
    fakeWindowFrame.origin.x -= (boundsInScreen.size.width  * 0.5);
    fakeWindowFrame.origin.y -= (boundsInScreen.size.height * 0.5);
    fakeWindowFrame.size.width  *= 2;
    fakeWindowFrame.size.height *= 2;

    NSWindow *fakeWindow  = [[NSWindow alloc] initWithContentRect:fakeWindowFrame styleMask:0 backing:NSBackingStoreBuffered defer:NO];
    NSView   *contentView = [fakeWindow contentView]; 

    [fakeWindow setOpaque:NO];
    [fakeWindow setBackgroundColor:[NSColor clearColor]];

    CALayer *snapshot = [CALayer layer];
    
    [snapshot setFrame:[contentView bounds]];
    [snapshot setTransform:CATransform3DMakeScale(0.5, 0.5, 1)];
    [snapshot setContents:GetSnapshotImageForView(view)];
    [snapshot setContentsScale:[[view window] backingScaleFactor]];
    [snapshot setMagnificationFilter:kCAFilterNearest];

    [contentView setWantsLayer:YES];
    [[contentView layer] addSublayer:snapshot];
    
    [[view window] addChildWindow:fakeWindow ordered:NSWindowAbove];
    [fakeWindow orderFront:nil];
    
    [CATransaction flush];
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.35];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    
    [CATransaction setCompletionBlock:^{
        [[view window] removeChildWindow:fakeWindow];
    }];

    [snapshot setTransform:CATransform3DMakeScale(0.8, 0.8, 1)];
    [snapshot setOpacity:0.0];

    [CATransaction commit];
}


