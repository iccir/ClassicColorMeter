//
//  Types.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
    ApertureColorBlack,
    ApertureColorGrey,
    ApertureColorWhite,
    ApertureColorBlackAndWhite
};
typedef NSInteger ApertureColor;


enum {
    ColorMode_RGB_Percentage,

    ColorMode_RGB_Value_8,
    ColorMode_RGB_Value_16,

    ColorMode_RGB_HexValue_8,
    ColorMode_RGB_HexValue_16,

    ColorMode_YPbPr_601,
    ColorMode_YPbPr_709,
    ColorMode_YCbCr_601,
    ColorMode_YCbCr_709,

    ColorMode_CIE_1931,
    ColorMode_CIE_1976,
    ColorMode_CIE_Lab,
    ColorMode_Tristimulus,
    
    ColorMode_HSB
};
typedef NSInteger ColorMode;


