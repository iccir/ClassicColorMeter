//
//  Preferences.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "Preferences.h"
#import "Shortcut.h"


NSString * const PreferencesDidChangeNotification = @"PreferencesDidChange";

static NSString * const sDefaultNSColorSnippetTemplate   = @"[NSColor colorWithSRGBRed:(0x$RHEX / 255.0) green:(0x$GHEX / 255.0) blue:(0x$BHEX / 255.0) alpha:1.0]";
static NSString * const sDefaultUIColorSnippetTemplate   = @"[UIColor colorWithRed:(0x$RHEX / 255.0) green:(0x$GHEX / 255.0) blue:(0x$BHEX / 255.0) alpha:1.0]";
static NSString * const sDefaultHexColorSnippetTemplate  = @"#$RHEX$GHEX$BHEX";
static NSString * const sDefaultRGBColorSnippetTemplate  = @"rgb($RN255, $GN255, $BN255)";
static NSString * const sDefaultRGBAColorSnippetTemplate = @"rgba($RN255, $GN255, $BN255, 1.0)";

static NSDictionary *sPropertyNameToDefaultKeyMap = nil;
static NSDictionary *sDefaultKeyToDefaultValueMap = nil;


static void sSetDefaultObject(id dictionary, NSString *key, id valueToSave)
{
    void (^saveObject)(NSObject *, NSString *) = ^(NSObject *o, NSString *k) {
        if (o) {
            [dictionary setObject:o forKey:k];
        } else {
            [dictionary removeObjectForKey:k];
        }
    };
    
    id defaultValue = [sDefaultKeyToDefaultValueMap objectForKey:key];

    if ([defaultValue isKindOfClass:[NSNumber class]] || [defaultValue isKindOfClass:[NSString class]]) {
        saveObject(valueToSave, key);

    } else if ([defaultValue isKindOfClass:[Shortcut class]]) {
        if (valueToSave == [Shortcut emptyShortcut]) {
            valueToSave = nil;
        }

        saveObject([valueToSave preferencesString], key);
    }
}



static void sBuildMaps(void)
{
    NSMutableDictionary *propertyNameToDefaultKeyMap  = [NSMutableDictionary dictionary];
    NSMutableDictionary *defaultKeyToDefaultValueMap = [NSMutableDictionary dictionary];

    void (^o)(NSString *, NSString *, id) = ^(NSString *propertyName, NSString *defaultKey, id defaultValue) {
        [propertyNameToDefaultKeyMap setObject:defaultKey   forKey:propertyName];
        [defaultKeyToDefaultValueMap setObject:defaultValue forKey:defaultKey];
    };

    o( @"colorMode",           @"ColorMode",         @( ColorMode_RGB_HexValue_8)      );
    o( @"holdColorMode",       @"HoldColorMode",     @( ColorMode_HSB)                 );
    o( @"colorConversion",     @"ColorProfileType",  @( ColorConversionDisplayInSRGB ) );

    o( @"zoomLevel",           @"ZoomLevel",         @( 8 )                            );
    o( @"apertureSize",        @"ApertureSize",      @( 0 )                            );
    o( @"apertureOutline",     @"ApertureOutline",   @( ApertureOutlineBlackAndWhite ) );
    o( @"clickInSwatchAction", @"SwatchClickAction", @( 0 )                            );
    o( @"dragInSwatchAction",  @"SwatchDragAction",  @( 0 )                            );

    o( @"nsColorSnippetTemplate",   @"CodeSnippetTemplate_NSColor", sDefaultNSColorSnippetTemplate   );
    o( @"uiColorSnippetTemplate",   @"CodeSnippetTemplate_UIColor", sDefaultUIColorSnippetTemplate   );
    o( @"hexColorSnippetTemplate",  @"CodeSnippetTemplate_Hex",     sDefaultHexColorSnippetTemplate  );
    o( @"rgbColorSnippetTemplate",  @"CodeSnippetTemplate_rgb",     sDefaultRGBColorSnippetTemplate  );
    o( @"rgbaColorSnippetTemplate", @"CodeSnippetTemplate_rgba",    sDefaultRGBAColorSnippetTemplate );
    
    o( @"highlightsOutOfRange",     @"HighlightsMyClippedValues",   @YES );
    o( @"clipsOutOfRange",          @"UsesMyClippedValues",         @YES );

    o( @"showApplicationShortcut",  @"ShowApplicationShortcut",     [Shortcut emptyShortcut] );
    o( @"holdColorShortcut",        @"HoldColorShortcut",           [Shortcut emptyShortcut] );
    o( @"lockPositionShortcut",     @"LockPositionShortcut",        [Shortcut emptyShortcut] );
    o( @"nsColorSnippetShortcut",   @"SnippetNSColorShortcut",      [Shortcut emptyShortcut] );
    o( @"uiColorSnippetShortcut",   @"SnippetUIColorShortcut",      [Shortcut emptyShortcut] );
    o( @"hexColorSnippetShortcut",  @"SnippetHexColorShortcut",     [Shortcut emptyShortcut] );
    o( @"rgbColorSnippetShortcut",  @"SnippetRGBColorShortcut",     [Shortcut emptyShortcut] );
    o( @"rgbaColorSnippetShortcut", @"SnippetRGBAColorShortcut",    [Shortcut emptyShortcut] );

    o( @"updatesContinuously",      @"UpdatesContinuously",         @NO  );
    o( @"floatWindow",              @"FloatWindow",                 @NO  );
    o( @"showMouseCoordinates",     @"ShowMouseCoordinates",        @NO  );
    o( @"clickInSwatchEnabled",     @"SwatchClickEnabled",          @NO  );
    o( @"dragInSwatchEnabled",      @"SwatchDragEnabled",           @NO  );
    o( @"arrowKeysEnabled",         @"ArrowKeysEnabled",            @YES );
    o( @"showsHoldColorSliders",    @"ShowsHoldColorSliders",       @YES );
    o( @"showsHoldLabels",          @"ShowsHoldLabels",             @YES );
    o( @"showsLockGuides",          @"ShowsLockGuides",             @YES );
    o( @"usesLowercaseHex",         @"UsesLowercaseHex",            @NO  );
    o( @"usesPoundPrefix",          @"UsesPoundPrefixForHex",       @YES );
  
    o( @"usesDifferentColorSpaceInHoldColor", @"UsesDifferentColorSpaceInHoldColor", @NO  );
    o( @"usesMainColorSpaceForCopyAsText",    @"UsesMainColorSpaceForCopyAsText",    @YES );

    o( @"showsLegacyColorSpaces",             @"ShowsLegacyColorSpaces",             @NO );
    o( @"showsLumaChromaColorSpaces",         @"ShowsLumaChromaColorSpaces",         @NO );
    o( @"showsAdditionalCIEColorSpaces",      @"ShowsAdditionalCIEColorSpaces",      @NO );

    o( @"showsMiniWindow",  @"ShowsMiniWindow",  @NO );
    o( @"showsColorWindow", @"ShowsColorWindow", @NO );

    sPropertyNameToDefaultKeyMap = propertyNameToDefaultKeyMap;
    sDefaultKeyToDefaultValueMap = defaultKeyToDefaultValueMap;
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    for (NSString *key in sDefaultKeyToDefaultValueMap) {
        id value = [sDefaultKeyToDefaultValueMap objectForKey:key];
        sSetDefaultObject(dictionary, key, value);
    }
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
}


@implementation Preferences {
    NSUInteger _migrationFromBuild;
    BOOL _didMigrate;
}


+ (id) sharedInstance
{
    static Preferences *sSharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sBuildMaps();
        sSharedInstance = [[Preferences alloc] init];
    });
    
    return sSharedInstance;
}


- (id) init
{
    if ((self = [super init])) {
        [self _loadAndObserve];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        NSString *currentBuildString = GetAppBuildString();
        NSString *latestBuildString  = [defaults objectForKey:@"LatestBuild"];

        NSUInteger currentBuild = GetCombinedBuildNumber(currentBuildString);
        NSUInteger latestBuild  = GetCombinedBuildNumber(latestBuildString);

        if (currentBuild > latestBuild) {
            _migrationFromBuild = latestBuild;
            [defaults setObject:currentBuildString forKey:@"LatestBuild"];
            latestBuildString = currentBuildString;
        }

        [defaults setObject:currentBuildString forKey:@"LastBuild"];

        _latestBuildString = latestBuildString;
    }

    return self;
}

- (void) migrateIfNeeded
{
    NSUInteger fromBuild = _migrationFromBuild;

    // If fromBuild is 0, this is either the first launch under the new
    // migration system or a fresh installation of the app. In either case,
    // do nothing
    //
    if (!fromBuild || _didMigrate) return;

    // Migrate to version 200
    if (fromBuild < GetCombinedBuildNumber(@"200")) {
        [self setShowsLegacyColorSpaces:YES];
        [self setShowsLumaChromaColorSpaces:YES];
        [self setShowsAdditionalCIEColorSpaces:YES];
    }

    _didMigrate = YES;
}


- (void) _loadAndObserve
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    for (NSString *propertyName in sPropertyNameToDefaultKeyMap) {
        id defaultKey   = [sPropertyNameToDefaultKeyMap objectForKey:propertyName];
        id defaultValue = [sDefaultKeyToDefaultValueMap objectForKey:defaultKey];

        if ([defaultValue isKindOfClass:[NSNumber class]]) {
            [self setValue:@([userDefaults integerForKey:defaultKey]) forKey:propertyName];

        } else if ([defaultValue isKindOfClass:[NSString class]]) {
            NSString *string = [userDefaults stringForKey:defaultKey];
            if (string) [self setValue:string forKey:propertyName];
        
        } else if ([defaultValue isKindOfClass:[Shortcut class]]) {
            NSString *preferencesString = [userDefaults objectForKey:defaultKey];
            Shortcut *shortcut = nil;

            if ([preferencesString isKindOfClass:[NSString class]]) {
                shortcut = [Shortcut shortcutWithPreferencesString:preferencesString];
            }
            
            if (shortcut == [Shortcut emptyShortcut]) {
                shortcut = nil;
            }
            
            [self setValue:shortcut forKey:propertyName];
        }

        [self addObserver:self forKeyPath:propertyName options:0 context:NULL];
    }
}


- (void) _save
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    for (NSString *propertyName in sPropertyNameToDefaultKeyMap) {
        id defaultKey = [sPropertyNameToDefaultKeyMap objectForKey:propertyName];
 
        sSetDefaultObject(userDefaults, defaultKey, [self valueForKey:propertyName]);
    }
}


- (void) _fixColorModes
{
    ColorMode colorMode     = [self colorMode];
    ColorMode holdColorMode = [self holdColorMode];

    BOOL showsLegacyColorSpaces        = [self showsLegacyColorSpaces];
    BOOL showsLumaChromaColorSpaces    = [self showsLumaChromaColorSpaces];
    BOOL showsAdditionalCIEColorSpaces = [self showsAdditionalCIEColorSpaces];

    BOOL (^fixMode)(ColorMode *) = ^(ColorMode *mode) {
        BOOL result = NO;

        if ((!showsLegacyColorSpaces        && ColorModeIsLegacy(colorMode))     ||
            (!showsLumaChromaColorSpaces    && ColorModeIsLumaChroma(colorMode)) ||
            (!showsAdditionalCIEColorSpaces && ColorModeIsXYZ(colorMode))
        ) {
            *mode = ColorMode_RGB_Percentage;
            result = YES;
        }

        return result;
    };
    
    if (fixMode(&colorMode)) {
        [self setColorMode:colorMode];
    }

    if (fixMode(&holdColorMode)) {
        [self setHoldColorMode:holdColorMode];
    }
    
    if (!showsLegacyColorSpaces) {
        ColorConversion colorConversion = [self colorConversion];

        if (colorConversion == ColorConversionDisplayInGenericRGB ||
            colorConversion == ColorConversionConvertToMainDisplay
        ) {
            [self setColorConversion:ColorConversionNone];
        }
    }
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self) {
        [self _fixColorModes];
        [[NSNotificationCenter defaultCenter] postNotificationName:PreferencesDidChangeNotification object:self];
        [self _save];
    }
}


- (void) restoreCodeSnippets
{
    [self setNsColorSnippetTemplate:   sDefaultNSColorSnippetTemplate];
    [self setUiColorSnippetTemplate:   sDefaultUIColorSnippetTemplate];
    [self setHexColorSnippetTemplate:  sDefaultHexColorSnippetTemplate];
    [self setRgbColorSnippetTemplate:  sDefaultRGBColorSnippetTemplate];
    [self setRgbaColorSnippetTemplate: sDefaultRGBAColorSnippetTemplate];
}

    
@end
