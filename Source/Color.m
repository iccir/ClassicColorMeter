//
//  Color.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 7/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Color.h"

@interface Color () {
    float _red;
    float _green;
    float _blue;

    float _hue;
    float _saturation;
    float _brightness;
}

@end


@implementation Color

static void sDidChangeHSB(Color *self)
{
    float hue        = self->_hue;
    float saturation = self->_saturation;
    float brightness = self->_brightness;

    float r = 0.0;
    float g = 0.0;
    float b = 0.0;

    if (saturation == 0.0) {
        r = g = b = brightness;

    } else {
        if (hue > 1.0) hue -= 1.0;

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

    self->_red   = r;
    self->_green = g;
    self->_blue  = b;
}


static void sDidChangeRGB(Color *self)
{
    float r = self->_red;
    float g = self->_green;
    float b = self->_blue;
    
    float maxRGB = fmaxf(fmaxf(r, g), b);
    float minRGB = fminf(fminf(r, g), b);
    float delta  = maxRGB - minRGB;

    float hue        = 0.0;
    float saturation = 0.0;
    float brightness = maxRGB;

    if (maxRGB != 0.0) {
        saturation = delta / maxRGB;
    }

    if (saturation != 0.0) {
        if (maxRGB == r) {
            hue = 0 + ((g - b) / delta);
        } else if (maxRGB == g) {
            hue = 2 + ((b - r) / delta);
        } else if (maxRGB == b) {
            hue = 4 + ((r - g) / delta);
        }
    }
    
    while (hue < 0.0) {
        hue += 6.0;
    }
    
    hue /= 6.0;
    
    self->_hue        = hue;
    self->_saturation = saturation;
    self->_brightness = brightness;
}


- (id) copyWithZone:(NSZone *)zone
{
    return NSCopyObject(self, 0, zone);
}


#pragma mark -
#pragma mark Public Methods

- (void) setFloatValue:(float)value forComponent:(ColorComponent)component
{
    if (component == ColorComponentRed) {
        _red = value;
        sDidChangeRGB(self);

    } else if (component == ColorComponentGreen) {
        _green = value;
        sDidChangeRGB(self);
    
    } else if (component == ColorComponentBlue) {
        _blue = value;
        sDidChangeRGB(self);
    
    } else if (component == ColorComponentHue) {
        _hue = value;
        sDidChangeHSB(self);
    
    } else if (component == ColorComponentSaturation) {
        _saturation = value;
        sDidChangeHSB(self);
    
    } else if (component == ColorComponentBrightness) {
        _brightness = value;
        sDidChangeHSB(self);
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
    
    } else if (component == ColorComponentSaturation) {
        return _saturation;
    
    } else if (component == ColorComponentBrightness) {
        return _brightness;

    } else {
        return 0.0;
    }
}


- (void) setRed:(float)red green:(float)green blue:(float)blue
{
    if ( _red   != red   )  _red   = red;
    if ( _green != green )  _green = green;
    if ( _blue  != blue  )  _blue  = blue;
    
    sDidChangeRGB(self);
}


- (void) setHue:(float)hue saturation:(float)saturation brightness:(float)brightness
{
    if ( _hue        != hue        )  _hue        = hue;
    if ( _saturation != saturation )  _saturation = saturation;
    if ( _brightness != brightness )  _brightness = brightness;
    
    sDidChangeHSB(self);
}


#pragma mark -
#pragma mark Accessors

- (void) setRed:(float)red
{
    if (_red != red) {
        _red = red;
        sDidChangeRGB(self);
    }
}


- (void) setGreen:(float)green
{
    if (_green != green) {
        _green = green;
        sDidChangeRGB(self);
    }
}


- (void) setBlue:(float)blue
{
    if (_blue != blue) {
        _blue = blue;
        sDidChangeRGB(self);
    }
}


- (void) setHue:(float)hue
{
    if (_hue != hue) {
        _hue = hue;
        sDidChangeHSB(self);
    }
}


- (void) setSaturation:(float)saturation
{
    if (_saturation != saturation) {
        _saturation = saturation;
        sDidChangeHSB(self);
    }
}


- (void) setBrightness:(float)brightness
{
    if (_brightness != brightness) {
        _brightness = brightness;
        sDidChangeHSB(self);
    }
}

@synthesize red        = _red,
            green      = _green,
            blue       = _blue,

            hue        = _hue,
            saturation = _saturation,
            brightness = _brightness;

@end
