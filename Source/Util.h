// (c) 2011-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>

extern NSString * const ProductSiteURLString;
extern NSString * const LegacySpacesURLString;
extern NSString * const PrivacyPolicyURLString;
extern NSString * const ConversionsURLString;
extern NSString * const FeedbackURLString;
extern NSString * const AppStoreURLString;

extern NSString  *GetAppBuildString(void);
extern NSUInteger GetCombinedBuildNumber(NSString *string);

extern BOOL ColorModeIsRGB(ColorMode mode);
extern BOOL ColorModeIsHue(ColorMode mode);
extern BOOL ColorModeIsXYZ(ColorMode mode);
extern BOOL ColorModeIsLumaChroma(ColorMode mode);
extern BOOL ColorModeIsLegacy(ColorMode mode);

extern NSArray *ColorModeGetComponentLabels(ColorMode mode);
extern NSArray *ColorModeGetLongestStrings(ColorMode mode);

extern float ColorModeParseComponentString(ColorMode mode, ColorComponent component, NSString *string);

extern NSImage *GetSnapshotImageForView(NSView *view);

extern CGContextRef CreateBitmapContext(CGSize size, BOOL opaque, CGFloat scale);
extern CGImageRef   CreateImage(CGSize size, BOOL opaque, CGFloat scale, void (^callback)(CGContextRef));

extern NSString *GetArrowJoinerString(void);

extern void DoPopOutAnimation(NSView *view);

extern BOOL IsAppearanceDarkAqua(NSView *view);
