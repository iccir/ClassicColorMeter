//
//  Color.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-31.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "Color.h"

@interface Color ()
@end


@implementation Color

@synthesize red           = _red,
            green         = _green,
            blue          = _blue,
            hue           = _hue,
            saturationHSB = _saturationHSB,
            brightness    = _brightness,
            saturationHSL = _saturationHSL,
            lightness     = _lightness;


static void sDidChangeHSB(Color *self)
{
    float hue        = self->_hue;
    float saturation = self->_saturationHSB;
    float brightness = self->_brightness;

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

    self->_red   = r;
    self->_green = g;
    self->_blue  = b;
}


static float sHueToRGB(float p, float q, float t)
{
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < (1.0 / 6.0)) return p + (q - p) * 6.0 * t;
    if (t < (1.0 / 2.0)) return q;
    if (t < (2.0 / 3.0)) return p + (q - p) * ((2.0 / 3.0) - t) * 6.0;
    return p;
}


static void sDidChangeHSL(Color *self)
{
    float hue        = self->_hue;
    float saturation = self->_saturationHSL;
    float lightness  = self->_lightness;

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

        r = sHueToRGB(p, q, hue + (1.0 / 3.0));
        g = sHueToRGB(p, q, hue              );
        b = sHueToRGB(p, q, hue - (1.0 / 3.0));
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

    float hue           = 0.0;
    float saturationHSB = 0.0;
    float saturationHSL = 0.0;
    float brightness    = maxRGB;
    float lightness     = (minRGB + maxRGB) * 0.5;

    if (maxRGB != 0.0) {
        saturationHSB = delta / maxRGB;
    }
    
    // Override previous value for now
    float divisor =  (1 - fabsf((2 * lightness) - 1));
    if (divisor != 0) {
        saturationHSL = delta / divisor;
    }

    if (saturationHSB != 0.0) {
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
    
    self->_hue           = hue;
    self->_saturationHSB = saturationHSB;
    self->_brightness    = brightness;
    self->_saturationHSL = saturationHSL;
    self->_lightness     = lightness;
}


- (id) copyWithZone:(NSZone *)zone
{
    Color *result = [[Color alloc] init];
    
    result->_red           = _red;
    result->_green         = _green;
    result->_blue          = _blue;
    result->_hue           = _hue;
    result->_saturationHSL = _saturationHSL;
    result->_saturationHSB = _saturationHSB;
    result->_brightness    = _brightness;
    result->_lightness     = _lightness;

    return result;
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
    
    } else if (component == ColorComponentSaturationHSB) {
        _saturationHSB = value;
        sDidChangeHSB(self);

    } else if (component == ColorComponentBrightness) {
        _brightness = value;
        sDidChangeHSB(self);

    } else if (component == ColorComponentSaturationHSL) {
        _saturationHSL = value;
        sDidChangeHSL(self);

    } else if (component == ColorComponentLightness) {
        _lightness = value;
        sDidChangeHSL(self);
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


- (void) setRed:(float)red green:(float)green blue:(float)blue
{
    if ( _red   != red   )  _red   = red;
    if ( _green != green )  _green = green;
    if ( _blue  != blue  )  _blue  = blue;
    
    sDidChangeRGB(self);
}


- (void) setHue:(float)hue saturation:(float)saturation brightness:(float)brightness
{
    if ( _hue           != hue        )  _hue           = hue;
    if ( _saturationHSB != saturation )  _saturationHSB = saturation;
    if ( _brightness    != brightness )  _brightness    = brightness;
    
    sDidChangeHSB(self);
}


- (void) setHue:(float)hue saturation:(float)saturation lightness:(float)lightness
{
    if ( _hue           != hue        )  _hue           = hue;
    if ( _saturationHSL != saturation )  _saturationHSL = saturation;
    if ( _lightness     != lightness  )  _lightness     = lightness;
    
    sDidChangeHSL(self);
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


#pragma mark -
#pragma mark Accessors

- (NSColor *) NSColor
{
    return [NSColor colorWithDeviceRed:_red green:_green blue:_blue alpha:1.0];
}


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


- (void) setSaturationHSB:(float)saturation
{
    if (_saturationHSB != saturation) {
        _saturationHSB = saturation;
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


- (void) setSaturationHSL:(float)saturation
{
    if (_saturationHSL != saturation) {
        _saturationHSL = saturation;
        sDidChangeHSL(self);
    }
}


- (void) setLightness:(float)lightness
{
    if (_lightness != lightness) {
        _lightness = lightness;
        sDidChangeHSL(self);
    }
}

@end
