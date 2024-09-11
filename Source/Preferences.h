// (c) 2011-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>

extern NSString * const PreferencesDidChangeNotification;

@class Shortcut;

@interface Preferences : NSObject

+ (id) sharedInstance;

@property (nonatomic, readonly) NSString *latestBuildString;

- (void) migrateIfNeeded;
- (void) restoreCodeSnippets;

@property (nonatomic) ColorMode colorMode;
@property (nonatomic) ColorMode holdColorMode;
@property (nonatomic) ColorConversion colorConversion;

@property (nonatomic) NSInteger zoomLevel;
@property (nonatomic) NSInteger apertureSize;
@property (nonatomic) ApertureOutline apertureOutline;
@property (nonatomic) NSInteger clickInSwatchAction;
@property (nonatomic) NSInteger dragInSwatchAction;

@property (nonatomic) NSString *nsColorSnippetTemplate;
@property (nonatomic) NSString *uiColorSnippetTemplate;
@property (nonatomic) NSString *hexColorSnippetTemplate;
@property (nonatomic) NSString *rgbColorSnippetTemplate;
@property (nonatomic) NSString *rgbaColorSnippetTemplate;

@property (nonatomic) BOOL     highlightsOutOfRange;
@property (nonatomic) BOOL     clipsOutOfRange;

@property (nonatomic) Shortcut *showApplicationShortcut;
@property (nonatomic) Shortcut *holdColorShortcut;
@property (nonatomic) Shortcut *lockPositionShortcut;

@property (nonatomic) Shortcut *nsColorSnippetShortcut;
@property (nonatomic) Shortcut *uiColorSnippetShortcut;
@property (nonatomic) Shortcut *hexColorSnippetShortcut;
@property (nonatomic) Shortcut *rgbColorSnippetShortcut;
@property (nonatomic) Shortcut *rgbaColorSnippetShortcut;

@property (nonatomic) BOOL updatesContinuously;
@property (nonatomic) BOOL floatWindow;
@property (nonatomic) BOOL showMouseCoordinates;
@property (nonatomic) BOOL clickInSwatchEnabled;
@property (nonatomic) BOOL dragInSwatchEnabled;
@property (nonatomic) BOOL arrowKeysEnabled;
@property (nonatomic) BOOL usesLowercaseHex;
@property (nonatomic) BOOL showsHoldColorSliders;
@property (nonatomic) BOOL usesPoundPrefix;
@property (nonatomic) BOOL showsHoldLabels;
@property (nonatomic) BOOL showsLockGuides;
@property (nonatomic) BOOL usesDifferentColorSpaceInHoldColor;
@property (nonatomic) BOOL usesMainColorSpaceForCopyAsText;

@property (nonatomic) BOOL showsLegacyColorSpaces;
@property (nonatomic) BOOL showsLumaChromaColorSpaces;
@property (nonatomic) BOOL showsAdditionalCIEColorSpaces;

@property (nonatomic) BOOL showsColorWindow;
@property (nonatomic) BOOL showsMiniWindow;

@end
