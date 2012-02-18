//
//  Color.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-31.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "Color.h"

@interface Color () {
    float m_red;
    float m_green;
    float m_blue;

    float m_hue;
    float m_saturationHSL;
    float m_saturationHSB;
    float m_brightness;
    float m_lightness;
}

@end


@implementation Color

static void sDidChangeHSB(Color *self)
{
    float hue        = self->m_hue;
    float saturation = self->m_saturationHSB;
    float brightness = self->m_brightness;

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

    self->m_red   = r;
    self->m_green = g;
    self->m_blue  = b;
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
    float hue        = self->m_hue;
    float saturation = self->m_saturationHSL;
    float lightness  = self->m_lightness;

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

    self->m_red   = r;
    self->m_green = g;
    self->m_blue  = b;
}


static void sDidChangeRGB(Color *self)
{
    float r = self->m_red;
    float g = self->m_green;
    float b = self->m_blue;
    
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
    
    self->m_hue           = hue;
    self->m_saturationHSB = saturationHSB;
    self->m_brightness    = brightness;
    self->m_saturationHSL = saturationHSL;
    self->m_lightness     = lightness;
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
        m_red = value;
        sDidChangeRGB(self);

    } else if (component == ColorComponentGreen) {
        m_green = value;
        sDidChangeRGB(self);
    
    } else if (component == ColorComponentBlue) {
        m_blue = value;
        sDidChangeRGB(self);
    
    } else if (component == ColorComponentHue) {
        m_hue = value;
        sDidChangeHSB(self);
    
    } else if (component == ColorComponentSaturationHSB) {
        m_saturationHSB = value;
        sDidChangeHSB(self);

    } else if (component == ColorComponentBrightness) {
        m_brightness = value;
        sDidChangeHSB(self);

    } else if (component == ColorComponentSaturationHSL) {
        m_saturationHSL = value;
        sDidChangeHSL(self);

    } else if (component == ColorComponentLightness) {
        m_lightness = value;
        sDidChangeHSL(self);
    }
}


- (float) floatValueForComponent:(ColorComponent)component
{
    if (component == ColorComponentRed) {
        return m_red;

    } else if (component == ColorComponentGreen) {
        return m_green;
    
    } else if (component == ColorComponentBlue) {
        return m_blue;
    
    } else if (component == ColorComponentHue) {
        return m_hue;
    
    } else if (component == ColorComponentSaturationHSB) {
        return m_saturationHSB;
    
    } else if (component == ColorComponentBrightness) {
        return m_brightness;

    } else if (component == ColorComponentSaturationHSL) {
        return m_saturationHSL;

    } else if (component == ColorComponentLightness) {
        return m_lightness;

    } else {
        return 0.0;
    }
}


- (void) setRed:(float)red green:(float)green blue:(float)blue
{
    if ( m_red   != red   )  m_red   = red;
    if ( m_green != green )  m_green = green;
    if ( m_blue  != blue  )  m_blue  = blue;
    
    sDidChangeRGB(self);
}


- (void) setHue:(float)hue saturation:(float)saturation brightness:(float)brightness
{
    if ( m_hue           != hue        )  m_hue           = hue;
    if ( m_saturationHSB != saturation )  m_saturationHSB = saturation;
    if ( m_brightness    != brightness )  m_brightness    = brightness;
    
    sDidChangeHSB(self);
}


- (void) setHue:(float)hue saturation:(float)saturation lightness:(float)lightness
{
    if ( m_hue           != hue        )  m_hue           = hue;
    if ( m_saturationHSL != saturation )  m_saturationHSL = saturation;
    if ( m_lightness     != lightness  )  m_lightness     = lightness;
    
    sDidChangeHSL(self);
}


- (void) getRed:(float *)outR green:(float *)outG blue:(float *)outB
{
    if (outR)  *outR = m_red;
    if (outG)  *outG = m_green;
    if (outB)  *outB = m_blue;
}


- (void) getHue:(float *)outH saturation:(float *)outS brightness:(float *)outB
{
    if (outH)  *outH = m_hue;
    if (outS)  *outS = m_saturationHSB;
    if (outB)  *outB = m_brightness;
}


- (void) getHue:(float *)outH saturation:(float *)outS lightness:(float *)outL
{
    if (outH)  *outH = m_hue;
    if (outS)  *outS = m_saturationHSL;
    if (outL)  *outL = m_lightness;
}


#pragma mark -
#pragma mark Accessors

- (NSColor *) NSColor
{
    return [NSColor colorWithDeviceRed:m_red green:m_green blue:m_blue alpha:1.0];
}


- (void) setRed:(float)red
{
    if (m_red != red) {
        m_red = red;
        sDidChangeRGB(self);
    }
}


- (void) setGreen:(float)green
{
    if (m_green != green) {
        m_green = green;
        sDidChangeRGB(self);
    }
}


- (void) setBlue:(float)blue
{
    if (m_blue != blue) {
        m_blue = blue;
        sDidChangeRGB(self);
    }
}


- (void) setHue:(float)hue
{
    if (m_hue != hue) {
        m_hue = hue;
        sDidChangeHSB(self);
    }
}


- (void) setSaturationHSB:(float)saturation
{
    if (m_saturationHSB != saturation) {
        m_saturationHSB = saturation;
        sDidChangeHSB(self);
    }
}


- (void) setBrightness:(float)brightness
{
    if (m_brightness != brightness) {
        m_brightness = brightness;
        sDidChangeHSB(self);
    }
}


- (void) setSaturationHSL:(float)saturation
{
    if (m_saturationHSL != saturation) {
        m_saturationHSL = saturation;
        sDidChangeHSL(self);
    }
}


- (void) setLightness:(float)lightness
{
    if (m_lightness != lightness) {
        m_lightness = lightness;
        sDidChangeHSL(self);
    }
}

@synthesize red           = m_red,
            green         = m_green,
            blue          = m_blue,
            hue           = m_hue,
            saturationHSB = m_saturationHSB,
            brightness    = m_brightness,
            saturationHSL = m_saturationHSL,
            lightness     = m_lightness;

@end
