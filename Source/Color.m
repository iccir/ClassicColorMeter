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
    float m_saturation;
    float m_brightness;
}

@end


@implementation Color

static void sDidChangeHSB(Color *self)
{
    float hue        = self->m_hue;
    float saturation = self->m_saturation;
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


static void sDidChangeRGB(Color *self)
{
    float r = self->m_red;
    float g = self->m_green;
    float b = self->m_blue;
    
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
    
    self->m_hue        = hue;
    self->m_saturation = saturation;
    self->m_brightness = brightness;
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
    
    } else if (component == ColorComponentSaturation) {
        m_saturation = value;
        sDidChangeHSB(self);
    
    } else if (component == ColorComponentBrightness) {
        m_brightness = value;
        sDidChangeHSB(self);
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
    
    } else if (component == ColorComponentSaturation) {
        return m_saturation;
    
    } else if (component == ColorComponentBrightness) {
        return m_brightness;

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
    if ( m_hue        != hue        )  m_hue        = hue;
    if ( m_saturation != saturation )  m_saturation = saturation;
    if ( m_brightness != brightness )  m_brightness = brightness;
    
    sDidChangeHSB(self);
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


- (void) setSaturation:(float)saturation
{
    if (m_saturation != saturation) {
        m_saturation = saturation;
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

@synthesize red        = m_red,
            green      = m_green,
            blue       = m_blue,

            hue        = m_hue,
            saturation = m_saturation,
            brightness = m_brightness;

@end
