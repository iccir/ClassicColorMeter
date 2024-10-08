// (c) 2011-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ApertureOutline) {
    ApertureOutlineBlack,
    ApertureOutlineGrey,
    ApertureOutlineWhite,
    ApertureOutlineBlackAndWhite
};


typedef NS_ENUM(NSInteger, ColorConversion) {
    ColorConversionNone = 0,

    ColorConversionDisplayInSRGB         = 1,
    ColorConversionDisplayInGenericRGB   = 2,
    ColorConversionDisplayInAdobeRGB     = 3,
    ColorConversionConvertToMainDisplay  = 4,
    ColorConversionDisplayInP3           = 5,
    ColorConversionDisplayInROMMRGB      = 6
};


typedef NS_ENUM(NSInteger, ColorMode) {
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
    
    ColorMode_HSB,
    ColorMode_HSL
};

