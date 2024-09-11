// (c) 2012-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import "Aperture.h"
#import "MouseCursor.h"
#import "ScreenCapturer.h"


@interface Aperture () <MouseCursorListener>
@property (nonatomic) MouseCursor *cursor;
@property (nonatomic) NSTimer *timer;
@end


@implementation Aperture {
    ScreenCapturer        *_capturer;
    CFMutableDictionaryRef _displayToScaleFactorMap;
    ColorSyncTransformRef  _colorSyncTransform;
    CGColorSpaceRef        _targetColorSpace;
    ColorConversion        _colorConversion;
    NSTimeInterval         _lastUpdateTimeInterval;
    CGRect                 _screenBounds;
    CGRect                 _captureRect;
    BOOL                   _needsUpdateDueToMove;
    BOOL                   _needsUpdateDueToButton;
    BOOL                   _canHaveMixedScaleFactors;
    BOOL                   _hasMixedScaleFactors;
}


- (id) init
{
    if ((self = [super init])) {
        _zoomLevel = 1;

        _capturer = [[ScreenCapturer alloc] init];
        _cursor = [MouseCursor sharedInstance];
    
        [_cursor addListener:self];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleScreenColorSpaceDidChange:) name:NSScreenColorSpaceDidChangeNotification object:nil];
        
        [self _updateImage];
        [self _updateColorProfile];
        [self _updateTimer];
    }

    return self;
}


- (void) dealloc
{
    if (_displayToScaleFactorMap) {
        CFRelease(_displayToScaleFactorMap);
        _displayToScaleFactorMap = NULL;
    }

    if (_colorSyncTransform) {
        CFRelease(_colorSyncTransform);
        _colorSyncTransform = NULL;
    }

    if (_targetColorSpace) {
        CFRelease(_targetColorSpace);
        _targetColorSpace = NULL;
    }
}


#pragma mark - Private Methods

- (void) _updateTimer
{
    if (_usesTimer && !_timer) {
        _timer = [NSTimer timerWithTimeInterval:(1.0 / 30.0) target:self selector:@selector(_timerTick:) userInfo:nil repeats:YES];
        [_timer setTolerance:(1.0 / 30.0)];

        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];

    } else if (!_usesTimer && _timer) {
        [_timer invalidate];
        _timer = nil;
    }
}


- (void) _timerTick:(NSTimer *)timer
{
    NSTimeInterval now   = [NSDate timeIntervalSinceReferenceDate];
    BOOL needsUpdateTick = (now - _lastUpdateTimeInterval) > 0.5;
    
    if (_updatesContinuously) {
        [_capturer setMaxFPS:0];
    } else {
        [_capturer setMaxFPS:12];
    }

    if (_updatesContinuously || _needsUpdateDueToButton || needsUpdateTick) {
        [_capturer invalidate];
        _needsUpdateDueToButton = NO;
    }
    
    if (_updatesContinuously || _needsUpdateDueToMove || needsUpdateTick) {
        [self _updateOffsetAndCaptureRect];

        if (_canHaveMixedScaleFactors) {
            [self _updateScaleFactor];
            [self _updateAperture];
        }

        [self _updateImage];
        _lastUpdateTimeInterval = now;
    }
}


- (void) _updateImage
{
    CGWindowImageOption imageOption = kCGWindowImageDefault;
    
    if (_hasMixedScaleFactors) {
        if (_scaleFactor == 1.0) {
            imageOption |= kCGWindowImageNominalResolution;
        } else {
            imageOption |= kCGWindowImageBestResolution;
        }
    }

    CGImageRef newImage = [_capturer captureRect:_captureRect imageOption:imageOption];
    
    if (newImage) {
        CGImageRelease(_image);   
        _image = newImage;

        [_delegate aperture:self didUpdateImage:_image];

        _needsUpdateDueToButton = _needsUpdateDueToMove = NO;
    }
}


- (void) _updateScreenBounds
{
    CGFloat pointsToCapture = (120.0 / _zoomLevel) + (1 + 1); // Pad with 1 pixel on each side
    CGFloat captureOffset = floor(pointsToCapture / 2.0);

    _screenBounds = CGRectMake(-captureOffset, -captureOffset, pointsToCapture, pointsToCapture);
}


- (void) _updateOffsetAndCaptureRect
{
    CGPoint location = [_cursor location];
    CGPoint locationToUse = CGPointMake(floor(location.x), floor(location.y));
    
    _offset = CGPointMake(location.x - locationToUse.x, location.y - locationToUse.y);

    _captureRect = _screenBounds;
    _captureRect.origin.x += locationToUse.x;
    _captureRect.origin.y += locationToUse.y;
}


- (void) _updateScaleFactor
{
    _scaleFactor = [_cursor displayScaleFactor];
    _hasMixedScaleFactors = NO;

    uint32_t count = 0;
    CGError  err   = kCGErrorSuccess;
    CGDirectDisplayID *displays = NULL;

    err = CGGetOnlineDisplayList(0, NULL, &count);
    if (!err && (count > 1)) {
        displays = alloca(sizeof(CGDirectDisplayID) * count);
        err = CGGetDisplaysWithRect(_captureRect, count, displays, &count);
    }

    if (!err && (count > 1)) {
        NSInteger existingScaleFactor = -1;
        for (NSInteger i = 0; i < count; i++) {
            NSInteger display     = displays[i];
            NSInteger scaleFactor = (NSInteger) CFDictionaryGetValue(_displayToScaleFactorMap, (const void *)display);

            if (existingScaleFactor < 0) {
                existingScaleFactor = scaleFactor;

            } else if (scaleFactor != existingScaleFactor) {
                _hasMixedScaleFactors = YES;
                break;
            }
        }
    }
}


- (void) _updateAperture
{
    CGFloat pointsToAverage = ((_apertureSize * 2) + 1) * (8.0 / (_zoomLevel * _scaleFactor));
    CGFloat averageOffset   = ((_screenBounds.size.width - pointsToAverage) / 2.0);

    _apertureRect = CGRectMake( averageOffset,  averageOffset, pointsToAverage, pointsToAverage);
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

    if (_targetColorSpace) {
        CFRelease(_targetColorSpace);
        _targetColorSpace = NULL;
    }

    if (_colorConversion == ColorConversionDisplayInSRGB) {
        toProfile = ColorSyncProfileCreateWithName(kColorSyncSRGBProfile);
        _targetColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);

    } else if (_colorConversion == ColorConversionDisplayInAdobeRGB) {
        toProfile = ColorSyncProfileCreateWithName(kColorSyncAdobeRGB1998Profile);
        _targetColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceAdobeRGB1998);

    } else if (_colorConversion == ColorConversionDisplayInGenericRGB) {
        toProfile = ColorSyncProfileCreateWithName(kColorSyncGenericRGBProfile);
        _targetColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);

    } else if (_colorConversion == ColorConversionDisplayInP3) {
        toProfile = ColorSyncProfileCreateWithName(CFSTR("com.apple.ColorSync.DisplayP3"));
        _targetColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);

    } else if (_colorConversion == ColorConversionDisplayInROMMRGB) {
        toProfile = ColorSyncProfileCreateWithName(CFSTR("com.apple.ColorSync.ROMMRGB"));
        _targetColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceROMMRGB);

    } else if ((displayID != mainID) && (_colorConversion == ColorConversionConvertToMainDisplay)) {
        toProfile = ColorSyncProfileCreateWithDisplayID(mainID);
        _targetColorSpace = CGColorSpaceCreateWithPlatformColorSpace(toProfile);
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
        NSString *displayString    = NSLocalizedString(@"Display",     nil);
        NSString *sRGBString       = NSLocalizedString(@"sRGB",        nil);
        NSString *sP3String        = NSLocalizedString(@"Display P3",  nil);
        NSString *genericRGBString = NSLocalizedString(@"Generic RGB", nil);
        NSString *adobeRGBString   = NSLocalizedString(@"Adobe RGB",   nil);
        NSString *rommRGBString    = NSLocalizedString(@"ROMM RGB",    nil);
        NSString *mainString       = NSLocalizedString(@"Main",        nil);
    
        NSString *fromName = CFBridgingRelease(ColorSyncProfileCopyDescriptionString(fromProfile));
        if (![fromName length]) fromName = displayString;

        NSMutableArray *shortProfiles = [NSMutableArray array];
        NSMutableArray *longProfiles  = [NSMutableArray array];

        [shortProfiles addObject:displayString];
        [longProfiles  addObject:fromName];

        if (_colorConversion == ColorConversionDisplayInSRGB) {
            [shortProfiles addObject:sRGBString];
            [longProfiles  addObject:sRGBString];

        } else if (_colorConversion == ColorConversionDisplayInP3) {
            [shortProfiles addObject:sP3String];
            [longProfiles  addObject:sP3String];

        } else if (_colorConversion == ColorConversionDisplayInGenericRGB) {
            [shortProfiles addObject:genericRGBString];
            [longProfiles  addObject:genericRGBString];

        } else if (_colorConversion == ColorConversionDisplayInAdobeRGB) {
            [shortProfiles addObject:adobeRGBString];
            [longProfiles  addObject:adobeRGBString];

        } else if (_colorConversion == ColorConversionDisplayInROMMRGB) {
            [shortProfiles addObject:rommRGBString];
            [longProfiles  addObject:rommRGBString];

        } else if (toProfile) {
            NSString *toName = CFBridgingRelease(ColorSyncProfileCopyDescriptionString(toProfile));
            if (![toName length]) toName = mainString;

            [shortProfiles addObject:mainString];
            [longProfiles  addObject:toName];
        }

        _shortColorProfileLabel = [shortProfiles componentsJoinedByString:GetArrowJoinerString()];
        _longColorProfileLabel  = [longProfiles  componentsJoinedByString:GetArrowJoinerString()];
    }

    if (fromProfile) CFRelease(fromProfile);
    if (toProfile)   CFRelease(toProfile);

    [_delegate apertureDidUpdateColorProfile:self];
}


#pragma mark - Callbacks

- (void) mouseCursorMovedToLocation:(CGPoint)position
{
    _needsUpdateDueToMove = YES;
}


- (void) mouseButtonsChanged
{
    _needsUpdateDueToButton = YES;
}


- (void) mouseCursorMovedToDisplay:(CGDirectDisplayID)display
{
    [self _updateColorProfile];
    [self _updateScaleFactor];
    [self _updateOffsetAndCaptureRect];
    [self _updateImage];
}


- (void) _handleScreenColorSpaceDidChange:(NSNotification *)note
{
    [self _updateColorProfile];
}


#pragma mark - Public Methods

- (void) update
{
    if (!_displayToScaleFactorMap) {
        _displayToScaleFactorMap = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
    }

    _canHaveMixedScaleFactors = NO;
    CFDictionaryRemoveAllValues(_displayToScaleFactorMap);

    NSInteger existingScaleFactor = -1;

    for (NSScreen *screen in [NSScreen screens]) {
        NSInteger screenNumber = [[[screen deviceDescription] objectForKey:@"NSScreenNumber"] integerValue];
        NSInteger scaleFactor  = (NSInteger)[screen backingScaleFactor];
        
        if (existingScaleFactor < 0) {
            existingScaleFactor = scaleFactor;
        } else if (scaleFactor != existingScaleFactor) {
            _canHaveMixedScaleFactors = YES;
        }
        
        CFDictionarySetValue(_displayToScaleFactorMap, (void *)screenNumber, (void *)scaleFactor);
    }

    [self _updateScreenBounds];
    [self _updateOffsetAndCaptureRect];
    [self _updateScaleFactor];
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
        size_t       width        = CGImageGetWidth(_image);
        size_t       height       = CGImageGetHeight(_image);
        CGBitmapInfo toBitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Little;

        CGColorSpaceRef space   = CGImageGetColorSpace(_image);
        CGContextRef    context = space ? CGBitmapContextCreate(NULL, width, height, 8, 4 * width, space, toBitmapInfo) : NULL;

        if (context) {
            CGContextDrawImage(context, CGRectMake(0, 0, width, height), _image);

            const void *bytes = CGBitmapContextGetData(context);
            data = CFDataCreate(NULL, bytes, 4 * width * height);

            bytesPerRow = CGBitmapContextGetBytesPerRow(context);
            alphaInfo   = kCGImageAlphaLast;
        }
        
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

        [color setRawRed: ((totalR / totalSamples) / 255.0)
                rawGreen: ((totalG / totalSamples) / 255.0)
                 rawBlue: ((totalB / totalSamples) / 255.0)
               transform: _colorSyncTransform
              colorSpace: _targetColorSpace ? _targetColorSpace : CGImageGetColorSpace(_image)];
    }


    if (data) {
        CFRelease(data);
    }
}



#pragma mark - Accessors

- (void) setApertureSize:(NSInteger)apertureSize
{
    if (_apertureSize != apertureSize) {
        _apertureSize = apertureSize;
        
        [_capturer invalidate];

        [self _updateAperture];
        [self _updateImage];
    }
}


- (void) setZoomLevel:(NSInteger)zoomLevel
{
    if (zoomLevel < 1) {
        zoomLevel = 1;
    }

    if (_zoomLevel != zoomLevel) {
        _zoomLevel = zoomLevel;
        
        [_capturer invalidate];

        [self _updateScreenBounds];
        [self _updateOffsetAndCaptureRect];
        [self _updateAperture];
        [self _updateImage];
    }
}


- (void) setColorConversion:(ColorConversion)colorConversion
{
    if (_colorConversion != colorConversion) {
        _colorConversion = colorConversion;
        [self _updateColorProfile];
    }
}


- (void) setUsesTimer:(BOOL)usesTimer
{
    if (_usesTimer != usesTimer) {
        _usesTimer = usesTimer;
        [self _updateTimer];
    }
}


@end
