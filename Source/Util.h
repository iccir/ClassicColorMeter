//
//  Util.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

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

extern NSArray *ColorModeGetComponentLabels(ColorMode mode);
extern NSArray *ColorModeGetLongestStrings(ColorMode mode);

extern float ColorModeParseComponentString(ColorMode mode, ColorComponent component, NSString *string);

extern NSImage *GetSnapshotImageForView(NSView *view);

extern CGContextRef CreateBitmapContext(CGSize size, BOOL opaque, CGFloat scale);
extern CGImageRef   CreateImage(CGSize size, BOOL opaque, CGFloat scale, void (^callback)(CGContextRef));

extern NSString *GetArrowJoinerString(void);

extern void DoPopOutAnimation(NSView *view);

extern BOOL IsAppearanceDarkAqua(NSView *view);
