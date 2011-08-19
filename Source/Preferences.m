//
//  Preferences.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "Preferences.h"

NSString * const PreferencesDidChangeNotification = @"PreferencesDidChange";

static NSString * const sColorModeKey               = @"ColorMode";
static NSString * const sHoldColorModeKey           = @"HoldColorMode";
static NSString * const sZoomLevelKey               = @"ZoomLevel";
static NSString * const sApertureSizeKey            = @"ApertureSize";
static NSString * const sApertureColorKey           = @"ApertureColor";
static NSString * const sSwatchClickActionKey       = @"SwatchClickAction";
static NSString * const sSwatchDragActionKey        = @"SwatchDragAction";

static NSString * const sCodeSnippetTemplateNSKey   = @"CodeSnippetTemplate_NSColor";
static NSString * const sCodeSnippetTemplateUIKey   = @"CodeSnippetTemplate_UIColor";
static NSString * const sCodeSnippetTemplateHexKey  = @"CodeSnippetTemplate_Hex";
static NSString * const sCodeSnippetTemplateRGBKey  = @"CodeSnippetTemplate_rgb";
static NSString * const sCodeSnippetTemplateRGBAKey = @"CodeSnippetTemplate_rgba";

static NSString * const sUpdatesContinuouslyKey     = @"UpdatesContinuously";
static NSString * const sFloatWindowKey             = @"FloatWindow";
static NSString * const sShowMouseCoordinatesKey    = @"ShowMouseCoordinates";
static NSString * const sSwatchClickEnabledKey      = @"SwatchClickEnabled";
static NSString * const sSwatchDragEnabledKey       = @"SwatchDragEnabled";
static NSString * const sArrowKeysEnabledKey        = @"ArrowKeysEnabled";
static NSString * const sUsesLowercaseHexKey        = @"UsesLowercaseHex";
static NSString * const sUsesPoundPrefixKey         = @"UsesPoundPrefixForHex";
static NSString * const sShowsHoldColorSlidersKey   = @"ShowsHoldColorSliders";
static NSString * const sShowsHoldLabelsKey         = @"ShowsHoldLabels";


@interface Preferences () {
    ColorMode            _colorMode;
    HoldColorMode        _holdColorMode;
    HoldColorSlidersType _holdColorSlidersType;

    NSInteger _zoomLevel;
    NSInteger _apertureSize;
    NSInteger _apertureColor;
    NSInteger _clickInSwatchAction;
    NSInteger _dragInSwatchAction;

    NSString *_nsColorSnippetTemplate;
    NSString *_uiColorSnippetTemplate;
    NSString *_hexColorSnippetTemplate;
    NSString *_rgbColorSnippetTemplate;
    NSString *_rgbaColorSnippetTemplate;
    
    BOOL _updatesContinuously;
    BOOL _floatWindow;
    BOOL _showMouseCoordinates;
    BOOL _clickInSwatchEnabled;
    BOOL _dragInSwatchEnabled;
    BOOL _arrowKeysEnabled;
    BOOL _usesLowercaseHex;
    BOOL _showsHoldLabels;
    BOOL _usesPoundPrefix;
}

- (void) _load;
- (void) _save;

@end


static void sRegisterDefaults(void)
{
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

    void (^i)(NSString *, NSInteger) = ^(NSString *key, NSInteger value) {
        NSNumber *number = [NSNumber numberWithInteger:value];
        [defaults setObject:number forKey:key];
    };

    void (^o)(NSString *, id) = ^(NSString *key, id object) {
        [defaults setObject:object forKey:key];
    };

    void (^b)(NSString *, BOOL) = ^(NSString *key, BOOL yn) {
        NSNumber *number = [NSNumber numberWithBool:yn];
        [defaults setObject:number forKey:key];
    };

    i( sColorModeKey,         0 );
    i( sZoomLevelKey,         8 );
    i( sApertureSizeKey,      0 );
    i( sApertureColorKey,     3 );
    i( sSwatchClickActionKey, 0 );
    i( sSwatchDragActionKey,  0 );

    o( sCodeSnippetTemplateNSKey,   @"[NSColor colorWithDeviceRed:(0x$RHEX / 255.0) green:(0x$GHEX / 255.0) blue:(0x$BHEX / 255.0) alpha:1.0]" );
    o( sCodeSnippetTemplateUIKey,   @"[UIColor colorWithRed:(0x$RHEX / 255.0) green:(0x$GHEX / 255.0) blue:(0x$BHEX / 255.0) alpha:1.0]");
    o( sCodeSnippetTemplateHexKey,  @"#$RHEX$GHEX$BHEX");
    o( sCodeSnippetTemplateRGBKey,  @"rgb($RN255, $GN255, $BN255)" );
    o( sCodeSnippetTemplateRGBAKey, @"rgba($RN255, $GN255, $BN255, 1.0)" );
    
    b( sUpdatesContinuouslyKey,   NO  );
    b( sFloatWindowKey,           NO  );
    b( sShowMouseCoordinatesKey,  NO  );
    b( sSwatchClickEnabledKey,    NO  );
    b( sSwatchDragEnabledKey,     NO  );
    b( sArrowKeysEnabledKey,      YES );
    b( sShowsHoldColorSlidersKey, YES );
    b( sShowsHoldLabelsKey,       YES );
    b( sUsesLowercaseHexKey,      NO  );
    b( sUsesPoundPrefixKey,       YES );
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}


@implementation Preferences

+ (id) sharedInstance
{
    static Preferences *sSharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sRegisterDefaults();
    
        sSharedInstance = [[Preferences alloc] init];
        [sSharedInstance _load];
    });
    
    return sSharedInstance;
}


- (id) init
{
    if ((self = [super init])) {
        [self _load];
        
        [self addObserver:self forKeyPath:@"colorMode"                options:0 context:NULL];
        [self addObserver:self forKeyPath:@"holdColorMode"            options:0 context:NULL];
        [self addObserver:self forKeyPath:@"holdColorSlidersType"     options:0 context:NULL];

        [self addObserver:self forKeyPath:@"zoomLevel"                options:0 context:NULL];
        [self addObserver:self forKeyPath:@"apertureSize"             options:0 context:NULL];
        [self addObserver:self forKeyPath:@"apertureColor"            options:0 context:NULL];
        [self addObserver:self forKeyPath:@"clickInSwatchAction"      options:0 context:NULL];
        [self addObserver:self forKeyPath:@"dragInSwatchAction"       options:0 context:NULL];

        [self addObserver:self forKeyPath:@"nsColorSnippetTemplate"   options:0 context:NULL];
        [self addObserver:self forKeyPath:@"uiColorSnippetTemplate"   options:0 context:NULL];
        [self addObserver:self forKeyPath:@"hexColorSnippetTemplate"  options:0 context:NULL];
        [self addObserver:self forKeyPath:@"rgbColorSnippetTemplate"  options:0 context:NULL];
        [self addObserver:self forKeyPath:@"rgbaColorSnippetTemplate" options:0 context:NULL];

        [self addObserver:self forKeyPath:@"updatesContinuously"      options:0 context:NULL];
        [self addObserver:self forKeyPath:@"floatWindow"              options:0 context:NULL];
        [self addObserver:self forKeyPath:@"showMouseCoordinates"     options:0 context:NULL];
        [self addObserver:self forKeyPath:@"clickInSwatchEnabled"     options:0 context:NULL];
        [self addObserver:self forKeyPath:@"dragInSwatchEnabled"      options:0 context:NULL];
        [self addObserver:self forKeyPath:@"arrowKeysEnabled"         options:0 context:NULL];
        [self addObserver:self forKeyPath:@"usesLowercaseHex"         options:0 context:NULL];
        [self addObserver:self forKeyPath:@"showsHoldLabels"          options:0 context:NULL];
        [self addObserver:self forKeyPath:@"usesPoundPrefix"          options:0 context:NULL];
    }

    return self;
}


- (void) _load
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    _colorMode                = [defaults integerForKey:sColorModeKey];
    _holdColorMode            = [defaults integerForKey:sHoldColorModeKey];
    _holdColorSlidersType     = [defaults integerForKey:sShowsHoldColorSlidersKey];

    _zoomLevel                = [defaults integerForKey:sZoomLevelKey];
    _apertureSize             = [defaults integerForKey:sApertureSizeKey];
    _apertureColor            = [defaults integerForKey:sApertureColorKey];
    _clickInSwatchAction      = [defaults integerForKey:sSwatchClickActionKey];
    _dragInSwatchAction       = [defaults integerForKey:sSwatchDragActionKey];

    _nsColorSnippetTemplate   = [defaults objectForKey:sCodeSnippetTemplateNSKey];
    _uiColorSnippetTemplate   = [defaults objectForKey:sCodeSnippetTemplateUIKey];
    _hexColorSnippetTemplate  = [defaults objectForKey:sCodeSnippetTemplateHexKey];
    _rgbColorSnippetTemplate  = [defaults objectForKey:sCodeSnippetTemplateRGBKey];
    _rgbaColorSnippetTemplate = [defaults objectForKey:sCodeSnippetTemplateRGBAKey];

    _updatesContinuously      = [defaults boolForKey:sUpdatesContinuouslyKey];
    _floatWindow              = [defaults boolForKey:sFloatWindowKey];
    _showMouseCoordinates     = [defaults boolForKey:sShowMouseCoordinatesKey];
    _clickInSwatchEnabled     = [defaults boolForKey:sSwatchClickEnabledKey];
    _dragInSwatchEnabled      = [defaults boolForKey:sSwatchDragEnabledKey];
    _arrowKeysEnabled         = [defaults boolForKey:sArrowKeysEnabledKey];
    _showsHoldLabels          = [defaults boolForKey:sShowsHoldLabelsKey];
    _usesLowercaseHex         = [defaults boolForKey:sUsesLowercaseHexKey];
    _usesPoundPrefix          = [defaults boolForKey:sUsesPoundPrefixKey];
}


- (void) _save
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults]; 

    [defaults setInteger:_colorMode             forKey:sColorModeKey];
    [defaults setInteger:_holdColorMode         forKey:sHoldColorModeKey];
    [defaults setInteger:_holdColorSlidersType  forKey:sShowsHoldColorSlidersKey];

    [defaults setInteger:_zoomLevel             forKey:sZoomLevelKey];
    [defaults setInteger:_apertureSize          forKey:sApertureSizeKey];
    [defaults setInteger:_apertureColor         forKey:sApertureColorKey];
    [defaults setInteger:_clickInSwatchAction   forKey:sSwatchClickActionKey];
    [defaults setInteger:_dragInSwatchAction    forKey:sSwatchDragActionKey];

    [defaults setObject:_nsColorSnippetTemplate   forKey:sCodeSnippetTemplateNSKey];
    [defaults setObject:_uiColorSnippetTemplate   forKey:sCodeSnippetTemplateUIKey];
    [defaults setObject:_hexColorSnippetTemplate  forKey:sCodeSnippetTemplateHexKey];
    [defaults setObject:_rgbColorSnippetTemplate  forKey:sCodeSnippetTemplateRGBKey];
    [defaults setObject:_rgbaColorSnippetTemplate forKey:sCodeSnippetTemplateRGBAKey];
    
    [defaults setBool:_updatesContinuously   forKey:sUpdatesContinuouslyKey];
    [defaults setBool:_floatWindow           forKey:sFloatWindowKey];
    [defaults setBool:_showMouseCoordinates  forKey:sShowMouseCoordinatesKey];
    [defaults setBool:_clickInSwatchEnabled  forKey:sSwatchClickEnabledKey];
    [defaults setBool:_dragInSwatchEnabled   forKey:sSwatchDragEnabledKey];
    [defaults setBool:_arrowKeysEnabled      forKey:sArrowKeysEnabledKey];
    [defaults setBool:_usesLowercaseHex      forKey:sUsesLowercaseHexKey];
    [defaults setBool:_usesPoundPrefix       forKey:sUsesPoundPrefixKey];
    [defaults setBool:_showsHoldLabels       forKey:sShowsHoldLabelsKey];
    
    [defaults synchronize];
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PreferencesDidChangeNotification object:self];
        [self _save];
    }
}


@synthesize colorMode            = _colorMode,
            holdColorMode        = _holdColorMode,
            holdColorSlidersType = _holdColorSlidersType;
            
@synthesize zoomLevel           = _zoomLevel,
            apertureSize        = _apertureSize,
            apertureColor       = _apertureColor,
            clickInSwatchAction = _clickInSwatchAction,
            dragInSwatchAction  = _dragInSwatchAction;

@synthesize nsColorSnippetTemplate   = _nsColorSnippetTemplate,
            uiColorSnippetTemplate   = _uiColorSnippetTemplate,
            hexColorSnippetTemplate  = _hexColorSnippetTemplate,
            rgbColorSnippetTemplate  = _rgbColorSnippetTemplate,
            rgbaColorSnippetTemplate = _rgbaColorSnippetTemplate;

@synthesize updatesContinuously   = _updatesContinuously,
            floatWindow           = _floatWindow,
            showMouseCoordinates  = _showMouseCoordinates,
            clickInSwatchEnabled  = _clickInSwatchEnabled,
            dragInSwatchEnabled   = _dragInSwatchEnabled,
            arrowKeysEnabled      = _arrowKeysEnabled,
            usesLowercaseHex      = _usesLowercaseHex,
            showsHoldLabels       = _showsHoldLabels,
            usesPoundPrefix       = _usesPoundPrefix;

@end
