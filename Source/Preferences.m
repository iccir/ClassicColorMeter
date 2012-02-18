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

static NSString * const sColorModeKey               = @"ColorMode";
static NSString * const sHoldColorModeKey           = @"HoldColorMode";
static NSString * const sColorProfileTypeKey        = @"ColorProfileType";
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

static NSString * const sShowApplicationShortcutKey = @"ShowApplicationShortcut";
static NSString * const sHoldColorShortcutKey       = @"HoldColorShortcut";

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

static NSString * const sUsesDifferentColorSpaceInHoldColor = @"UsesDifferentColorSpaceInHoldColor";
static NSString * const sUsesMainColorSpaceForCopyAsText    = @"UsesMainColorSpaceForCopyAsText";


static NSString * const sDefaultNSColorSnippetTemplate   = @"[NSColor colorWithDeviceRed:(0x$RHEX / 255.0) green:(0x$GHEX / 255.0) blue:(0x$BHEX / 255.0) alpha:1.0]";
static NSString * const sDefaultUIColorSnippetTemplate   = @"[UIColor colorWithRed:(0x$RHEX / 255.0) green:(0x$GHEX / 255.0) blue:(0x$BHEX / 255.0) alpha:1.0]";
static NSString * const sDefaultHexColorSnippetTemplate  = @"#$RHEX$GHEX$BHEX";
static NSString * const sDefaultRGBColorSnippetTemplate  = @"rgb($RN255, $GN255, $BN255)";
static NSString * const sDefaultRGBAColorSnippetTemplate = @"rgba($RN255, $GN255, $BN255, 1.0)";


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
    i( sHoldColorModeKey,     ColorMode_HSB );
    i( sColorProfileTypeKey,  0 );
    i( sZoomLevelKey,         8 );
    i( sApertureSizeKey,      0 );
    i( sApertureColorKey,     3 );
    i( sSwatchClickActionKey, 0 );
    i( sSwatchDragActionKey,  0 );

    o( sCodeSnippetTemplateNSKey,   sDefaultNSColorSnippetTemplate   );
    o( sCodeSnippetTemplateUIKey,   sDefaultUIColorSnippetTemplate   );
    o( sCodeSnippetTemplateHexKey,  sDefaultHexColorSnippetTemplate  );
    o( sCodeSnippetTemplateRGBKey,  sDefaultRGBColorSnippetTemplate  );
    o( sCodeSnippetTemplateRGBAKey, sDefaultRGBAColorSnippetTemplate );
    
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

    b( sUsesDifferentColorSpaceInHoldColor, NO  );
    b( sUsesMainColorSpaceForCopyAsText,    YES );
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}


@interface Preferences ()

- (void) _load;
- (void) _save;

@end


@implementation Preferences

@synthesize colorMode           = _colorMode,
            holdColorMode       = _holdColorMode,
            colorProfileType    = _colorProfileType;
            
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

@synthesize showApplicationShortcut  = _showApplicationShortcut,
            holdColorShortcut        = _holdColorShortcut;


@synthesize updatesContinuously   = _updatesContinuously,
            floatWindow           = _floatWindow,
            showMouseCoordinates  = _showMouseCoordinates,
            clickInSwatchEnabled  = _clickInSwatchEnabled,
            dragInSwatchEnabled   = _dragInSwatchEnabled,
            arrowKeysEnabled      = _arrowKeysEnabled,
            usesLowercaseHex      = _usesLowercaseHex,
            showsHoldLabels       = _showsHoldLabels,
            showsHoldColorSliders = _showsHoldColorSliders,
            usesPoundPrefix       = _usesPoundPrefix;

@synthesize usesDifferentColorSpaceInHoldColor = _usesDifferentColorSpaceInHoldColor,
            usesMainColorSpaceForCopyAsText    = _usesMainColorSpaceForCopyAsText;


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
        [self addObserver:self forKeyPath:@"colorProfileType"         options:0 context:NULL];
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

        [self addObserver:self forKeyPath:@"showApplicationShortcut"  options:0 context:NULL];
        [self addObserver:self forKeyPath:@"holdColorShortcut"        options:0 context:NULL];

        [self addObserver:self forKeyPath:@"updatesContinuously"      options:0 context:NULL];
        [self addObserver:self forKeyPath:@"floatWindow"              options:0 context:NULL];
        [self addObserver:self forKeyPath:@"showMouseCoordinates"     options:0 context:NULL];
        [self addObserver:self forKeyPath:@"clickInSwatchEnabled"     options:0 context:NULL];
        [self addObserver:self forKeyPath:@"dragInSwatchEnabled"      options:0 context:NULL];
        [self addObserver:self forKeyPath:@"arrowKeysEnabled"         options:0 context:NULL];
        [self addObserver:self forKeyPath:@"usesLowercaseHex"         options:0 context:NULL];
        [self addObserver:self forKeyPath:@"showsHoldColorSliders"    options:0 context:NULL];
        [self addObserver:self forKeyPath:@"showsHoldLabels"          options:0 context:NULL];
        [self addObserver:self forKeyPath:@"usesPoundPrefix"          options:0 context:NULL];

        [self addObserver:self forKeyPath:@"usesDifferentColorSpaceInHoldColor" options:0 context:NULL];
        [self addObserver:self forKeyPath:@"usesMainColorSpaceForCopyAsText"    options:0 context:NULL];
    }

    return self;
}


- (void) _load
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSInteger (^loadInteger)(NSString *) = ^(NSString *key) {
        return [defaults integerForKey:key];
    };

    id (^loadObjectOfClass)(Class, NSString *) = ^(Class cls, NSString *key) {
        NSObject *o = [defaults objectForKey:key];
        return [o isKindOfClass:cls] ? o : nil;
    };

    NSString *(^loadString)(NSString *) = ^(NSString *key) {
        return loadObjectOfClass([NSString class], key);
    };

    Shortcut *(^loadShortcut)(NSString *) = ^(NSString *key) {
        NSString *preferencesString = [defaults objectForKey:key];
        Shortcut *shortcut          = nil;

        if ([preferencesString isKindOfClass:[NSString class]]) {
            shortcut = [Shortcut shortcutWithPreferencesString:preferencesString];
        }
        
        return shortcut;
    };

    BOOL (^loadBoolean)(NSString *) = ^(NSString *key) {
        return [defaults boolForKey:key];
    };

    _colorMode           = loadInteger( sColorModeKey         );
    _holdColorMode       = loadInteger( sHoldColorModeKey     );
    _colorProfileType    = loadInteger( sColorProfileTypeKey  );
    _zoomLevel           = loadInteger( sZoomLevelKey         );
    _apertureSize        = loadInteger( sApertureSizeKey      );
    _apertureColor       = loadInteger( sApertureColorKey     );
    _clickInSwatchAction = loadInteger( sSwatchClickActionKey );
    _dragInSwatchAction  = loadInteger( sSwatchDragActionKey  );

    _nsColorSnippetTemplate   = loadString( sCodeSnippetTemplateNSKey   );
    _uiColorSnippetTemplate   = loadString( sCodeSnippetTemplateUIKey   );
    _hexColorSnippetTemplate  = loadString( sCodeSnippetTemplateHexKey  );
    _rgbColorSnippetTemplate  = loadString( sCodeSnippetTemplateRGBKey  );
    _rgbaColorSnippetTemplate = loadString( sCodeSnippetTemplateRGBAKey );

    _showApplicationShortcut  = loadShortcut( sShowApplicationShortcutKey );
    _holdColorShortcut        = loadShortcut( sHoldColorShortcutKey       );

    _updatesContinuously   = loadBoolean( sUpdatesContinuouslyKey   );
    _floatWindow           = loadBoolean( sFloatWindowKey           );
    _showMouseCoordinates  = loadBoolean( sShowMouseCoordinatesKey  );
    _clickInSwatchEnabled  = loadBoolean( sSwatchClickEnabledKey    );
    _dragInSwatchEnabled   = loadBoolean( sSwatchDragEnabledKey     );
    _arrowKeysEnabled      = loadBoolean( sArrowKeysEnabledKey      );
    _showsHoldLabels       = loadBoolean( sShowsHoldLabelsKey       );
    _usesLowercaseHex      = loadBoolean( sUsesLowercaseHexKey      );
    _usesPoundPrefix       = loadBoolean( sUsesPoundPrefixKey       );
    _showsHoldColorSliders = loadBoolean( sShowsHoldColorSlidersKey );
                  
    _usesDifferentColorSpaceInHoldColor = loadBoolean( sUsesDifferentColorSpaceInHoldColor );
    _usesMainColorSpaceForCopyAsText    = loadBoolean( sUsesMainColorSpaceForCopyAsText    );
}


- (void) _save
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults]; 

    void (^saveInteger)(NSInteger, NSString *) = ^(NSInteger i, NSString *key) {
        [defaults setInteger:i forKey:key];
    };

    void (^saveObject)(NSObject *, NSString *) = ^(NSObject *o, NSString *key) {
        if (o) {
            [defaults setObject:o forKey:key];
        } else {
            [defaults removeObjectForKey:key];
        }
    };

    void (^saveShortcut)(Shortcut *, NSString *) = ^(Shortcut *s, NSString *key) {
        saveObject([s preferencesString], key);
    };

    void (^saveBoolean)(BOOL, NSString *) = ^(BOOL yn, NSString *key) {
        [defaults setBool:yn forKey:key];
    };

    saveInteger( _colorMode,                sColorModeKey               );
    saveInteger( _holdColorMode,            sHoldColorModeKey           );
    saveInteger( _colorProfileType,         sColorProfileTypeKey        );

    saveInteger( _zoomLevel,                sZoomLevelKey               );
    saveInteger( _apertureSize,             sApertureSizeKey            );
    saveInteger( _apertureColor,            sApertureColorKey           );
    saveInteger( _clickInSwatchAction,      sSwatchClickActionKey       );
    saveInteger( _dragInSwatchAction,       sSwatchDragActionKey        );

    saveObject( _nsColorSnippetTemplate,    sCodeSnippetTemplateNSKey   );
    saveObject( _uiColorSnippetTemplate,    sCodeSnippetTemplateUIKey   );
    saveObject( _hexColorSnippetTemplate,   sCodeSnippetTemplateHexKey  );
    saveObject( _rgbColorSnippetTemplate,   sCodeSnippetTemplateRGBKey  );
    saveObject( _rgbaColorSnippetTemplate,  sCodeSnippetTemplateRGBAKey );
    
    saveShortcut( _showApplicationShortcut, sShowApplicationShortcutKey );
    saveShortcut( _holdColorShortcut,       sHoldColorShortcutKey       );
    
    saveBoolean( _updatesContinuously,      sUpdatesContinuouslyKey     );
    saveBoolean( _floatWindow,              sFloatWindowKey             );
    saveBoolean( _showMouseCoordinates,     sShowMouseCoordinatesKey    );
    saveBoolean( _clickInSwatchEnabled,     sSwatchClickEnabledKey      );
    saveBoolean( _dragInSwatchEnabled,      sSwatchDragEnabledKey       );
    saveBoolean( _arrowKeysEnabled,         sArrowKeysEnabledKey        );
    saveBoolean( _usesLowercaseHex,         sUsesLowercaseHexKey        );
    saveBoolean( _usesPoundPrefix,          sUsesPoundPrefixKey         );
    saveBoolean( _showsHoldLabels,          sShowsHoldLabelsKey         );
    saveBoolean( _showsHoldColorSliders,    sShowsHoldColorSlidersKey   );

    saveBoolean( _usesDifferentColorSpaceInHoldColor, sUsesDifferentColorSpaceInHoldColor );
    saveBoolean( _usesMainColorSpaceForCopyAsText,    sUsesMainColorSpaceForCopyAsText    );

    [defaults synchronize];
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self) {
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
