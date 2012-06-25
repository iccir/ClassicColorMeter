//
//  Aperture.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2012-06-14.
//
//

#import "Aperture.h"
#import "MouseCursor.h"


@interface Aperture () <MouseCursorListener>
@property (nonatomic, strong) MouseCursor *cursor;
@property (nonatomic, strong) NSTimer *timer;
@end


@implementation Aperture {
    ColorSyncTransformRef _colorSyncTransform;
    ColorConversion _colorConversion;
    NSTimeInterval _lastUpdateTimeInterval;
    CGRect         _screenBounds;
}

- (id) init
{
    if ((self = [super init])) {
        _cursor = [MouseCursor sharedInstance];
    
        [_cursor addListener:self];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleScreenColorSpaceDidChange:) name:NSScreenColorSpaceDidChangeNotification object:nil];

        _timer = [NSTimer timerWithTimeInterval:(1.0 / 30.0) target:self selector:@selector(_timerTick:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
        
        _zoomLevel = 1;

        [self _updateImage];
        [self _updateColorProfile];
    }

    return self;
}


- (void) dealloc
{
    if (_colorSyncTransform) {
        CFRelease(_colorSyncTransform);
        _colorSyncTransform = NULL;
    }
}


#pragma mark -
#pragma mark Private Methods

- (void) _timerTick:(NSTimer *)timer
{
    NSTimeInterval now   = [NSDate timeIntervalSinceReferenceDate];
    BOOL needsUpdateTick = (now - _lastUpdateTimeInterval) > 0.5;
    
    if (_updatesContinuously || needsUpdateTick) {
        [self _updateImage];
        _lastUpdateTimeInterval = now;
    }
}


- (void) _updateImage
{
    CGPoint location = [_cursor location];
    CGPoint locationToUse = CGPointMake(floor(location.x), floor(location.y));
    
    _offset = CGPointMake(location.x - locationToUse.x, location.y - locationToUse.y);

    CGRect screenBounds = _screenBounds;
    screenBounds.origin.x += locationToUse.x;
    screenBounds.origin.y += locationToUse.y;

    CGImageRelease(_image);
    _image = CGWindowListCreateImage(screenBounds, kCGWindowListOptionAll, kCGNullWindowID, kCGWindowImageDefault);

    [_delegate aperture:self didUpdateImage:_image];
}


- (void) _updateAperture
{
    _scaleFactor = [_cursor displayScaleFactor];
    
    CGFloat pointsToCapture = (120.0 / _zoomLevel) + 50;
    CGFloat pointsToAverage = ((_apertureSize * 2) + 1) * (8.0 / (_zoomLevel * _scaleFactor));

    CGFloat captureOffset = floor(pointsToCapture / 2.0);
    CGFloat averageOffset = ((pointsToCapture - pointsToAverage) / 2.0);

    _screenBounds = CGRectMake(-captureOffset, -captureOffset, pointsToCapture, pointsToCapture);
    _apertureRect = CGRectMake( averageOffset,  averageOffset, pointsToAverage, pointsToAverage);

    [self _updateImage];
}


- (void) _updateColorProfile
{
    CGDirectDisplayID   displayID   = [_cursor displayID];
    CGDirectDisplayID   mainID      = CGMainDisplayID();
    ColorSyncProfileRef fromProfile = ColorSyncProfileCreateWithDisplayID(displayID);
    ColorSyncProfileRef toProfile   = NULL;

    if (_colorSyncTransform) {
        CFRelease(_colorSyncTransform);
        _colorSyncTransform = NULL;
    }

    if (_colorConversion == ColorConversionDisplayInSRGB) {
        toProfile = ColorSyncProfileCreateWithName(kColorSyncSRGBProfile);

    } else if (_colorConversion == ColorConversionDisplayInAdobeRGB) {
        toProfile = ColorSyncProfileCreateWithName(kColorSyncAdobeRGB1998Profile);

    } else if (_colorConversion == ColorConversionDisplayInGenericRGB) {
        toProfile = ColorSyncProfileCreateWithName(kColorSyncGenericRGBProfile);

    } else if ((displayID != mainID) && (_colorConversion == ColorConversionConvertToMainDisplay)) {
        toProfile = ColorSyncProfileCreateWithDisplayID(mainID);
    }
    
    // Create _colorSyncTransform
    if (toProfile) {
        NSMutableDictionary *fromDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
            (__bridge id)fromProfile,                         (__bridge id)kColorSyncProfile,
            (__bridge id)kColorSyncRenderingIntentPerceptual, (__bridge id)kColorSyncRenderingIntent,
            (__bridge id)kColorSyncTransformDeviceToPCS,      (__bridge id)kColorSyncTransformTag,
            nil];

        NSMutableDictionary *toDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
            (__bridge id)toProfile,                           (__bridge id)kColorSyncProfile,
            (__bridge id)kColorSyncRenderingIntentPerceptual, (__bridge id)kColorSyncRenderingIntent,
            (__bridge id)kColorSyncTransformPCSToDevice,      (__bridge id)kColorSyncTransformTag,
            nil];
            
        NSArray *profileSequence = [[NSArray alloc] initWithObjects:fromDictionary, toDictionary, nil];
        
        _colorSyncTransform = ColorSyncTransformCreate((__bridge CFArrayRef)profileSequence, NULL);
    }

    // Update profile name
    {
        NSString *name = CFBridgingRelease(ColorSyncProfileCopyDescriptionString(fromProfile));
        if (![name length]) name = NSLocalizedString(@"Display", @"");

        NSMutableArray *profiles = [NSMutableArray array];

        [profiles addObject:name];

        if (_colorConversion == ColorConversionDisplayInSRGB) {
            [profiles addObject:NSLocalizedString(@"sRGB", @"")];

        } else if (_colorConversion == ColorConversionDisplayInGenericRGB) {
            [profiles addObject:NSLocalizedString(@"Generic RGB", @"")];

        } else if (_colorConversion == ColorConversionDisplayInAdobeRGB) {
            [profiles addObject:NSLocalizedString(@"Adobe RGB", @"")];

        } else if (toProfile) {
            NSString *toName = CFBridgingRelease(ColorSyncProfileCopyDescriptionString(toProfile));
            if (![toName length]) toName = NSLocalizedString(@"Display", @"");

            [profiles addObject:toName];
        }

        _colorProfileLabel = [profiles componentsJoinedByString:GetArrowJoinerString()];
    }

    if (fromProfile) CFRelease(fromProfile);
    if (toProfile)   CFRelease(toProfile);

    [_delegate apertureDidUpdateColorProfile:self];
}


#pragma mark -
#pragma mark Callbacks

- (void) mouseCursorMovedToLocation:(CGPoint)position
{
    [self _updateImage];
}


- (void) mouseCursorMovedToDisplay:(CGDirectDisplayID)display
{
    [self _updateColorProfile];
    [self _updateAperture];
}


- (void) _handleScreenColorSpaceDidChange:(NSNotification *)note
{
    [self _updateColorProfile];
}


#pragma mark -
#pragma mark Public Methods

- (void) update
{
    [self _updateAperture];
    [self _updateColorProfile];
    [self _updateImage];
}


- (void) averageAndUpdateColor:(Color *)color
{
    CFDataRef data = NULL;

    // 1) Check the CGBitmapInfo of the image.  We need it to be kCGBitmapByteOrder32Little with
    //    non-float-components and in RGB_ or _RGB;
    //
    CGBitmapInfo      bitmapInfo = CGImageGetBitmapInfo(_image);
    CGImageAlphaInfo  alphaInfo  = bitmapInfo & kCGBitmapAlphaInfoMask;
    NSInteger         orderInfo  = bitmapInfo & kCGBitmapByteOrderMask;

    size_t bytesPerRow = CGImageGetBytesPerRow(_image);

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
        CGDataProviderRef provider = CGImageGetDataProvider(_image);
        data = CGDataProviderCopyData(provider);
        
    } else {
        size_t       width      = CGImageGetWidth(_image);
        size_t       height     = CGImageGetHeight(_image);
        CGBitmapInfo bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Little;

        CGColorSpaceRef space   = CGColorSpaceCreateDeviceRGB();
        CGContextRef    context = space ? CGBitmapContextCreate(NULL, width, height, 8, 4 * width, space, bitmapInfo) : NULL;

        if (context) {
            CGContextDrawImage(context, CGRectMake(0, 0, width, height), _image);

            const void *bytes = CGBitmapContextGetData(context);
            data = CFDataCreate(NULL, bytes, 4 * width * height);

            bytesPerRow = CGBitmapContextGetBytesPerRow(context);
            alphaInfo   = kCGImageAlphaLast;
        }
        
        CGColorSpaceRelease(space);
        CGContextRelease(context);
    }
    
    UInt8 *buffer = data ? (UInt8 *)CFDataGetBytePtr(data) : NULL;
    NSInteger totalSamples = _apertureRect.size.width * _apertureRect.size.height * _scaleFactor * _scaleFactor;
    
    if (buffer && (totalSamples > 0)) {
        NSUInteger totalR = 0;
        NSUInteger totalG = 0;
        NSUInteger totalB = 0;

        NSInteger minY = (CGRectGetMinY(_apertureRect) + _offset.y) * _scaleFactor;
        NSInteger maxY = (CGRectGetMaxY(_apertureRect) + _offset.y) * _scaleFactor;
        NSInteger minX = (CGRectGetMinX(_apertureRect) + _offset.x) * _scaleFactor;
        NSInteger maxX = (CGRectGetMaxX(_apertureRect) + _offset.x) * _scaleFactor;

        for (NSInteger y = minY; y < maxY; y++) {
            UInt8 *ptr    = buffer + (y * bytesPerRow) + (4 * minX);
            UInt8 *maxPtr = buffer + (y * bytesPerRow) + (4 * maxX);

            if (alphaInfo == kCGImageAlphaLast) {
                while (ptr < maxPtr) {
                    //   ptr[0]
                    totalB += ptr[1];
                    totalG += ptr[2];
                    totalR += ptr[3];

                    ptr += 4;
                }

            } else if (alphaInfo == kCGImageAlphaFirst) {
                while (ptr < maxPtr) {
                    totalB += ptr[0];
                    totalG += ptr[1];
                    totalR += ptr[2];
                    //   ptr[3]

                    ptr += 4;
                }
            }
        }

        [color setRed: ((totalR / totalSamples) / 255.0)
                green: ((totalG / totalSamples) / 255.0)
                 blue: ((totalB / totalSamples) / 255.0)
            transform: _colorSyncTransform];
    }


    if (data) {
        CFRelease(data);
    }
}



#pragma mark -
#pragma mark Accessors

- (void) setApertureSize:(NSInteger)apertureSize
{
    if (_apertureSize != apertureSize) {
        _apertureSize = apertureSize;
        [self _updateAperture];
    }
}


- (void) setZoomLevel:(NSInteger)zoomLevel
{
    if (zoomLevel < 1) {
        zoomLevel = 1;
    }

    if (_zoomLevel != zoomLevel) {
        _zoomLevel = zoomLevel;
        [self _updateAperture];
    }
}


- (void) setColorConversion:(ColorConversion)colorConversion
{
    if (_colorConversion != colorConversion) {
        _colorConversion = colorConversion;
        [self _updateColorProfile];
    }
}


@end
