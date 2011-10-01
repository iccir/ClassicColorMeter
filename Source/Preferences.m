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


@interface Preferences () {
    ColorMode        m_colorMode;
    ColorMode        m_holdColorMode;
    ColorProfileType m_colorProfileType;

    NSInteger m_zoomLevel;
    NSInteger m_apertureSize;
    NSInteger m_apertureColor;
    NSInteger m_clickInSwatchAction;
    NSInteger m_dragInSwatchAction;

    NSString *m_nsColorSnippetTemplate;
    NSString *m_uiColorSnippetTemplate;
    NSString *m_hexColorSnippetTemplate;
    NSString *m_rgbColorSnippetTemplate;
    NSString *m_rgbaColorSnippetTemplate;
    
    Shortcut *m_showApplicationShortcut;
    Shortcut *m_holdColorShortcut;
    
    BOOL m_updatesContinuously;
    BOOL m_floatWindow;
    BOOL m_showMouseCoordinates;
    BOOL m_clickInSwatchEnabled;
    BOOL m_dragInSwatchEnabled;
    BOOL m_arrowKeysEnabled;
    BOOL m_showsHoldColorSliders;
    BOOL m_usesLowercaseHex;
    BOOL m_showsHoldLabels;
    BOOL m_usesPoundPrefix;
    
    BOOL m_usesDifferentColorSpaceInHoldColor;
    BOOL m_usesMainColorSpaceForCopyAsText;
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


- (void) dealloc
{
    [m_nsColorSnippetTemplate   release];  m_nsColorSnippetTemplate   = nil;
    [m_uiColorSnippetTemplate   release];  m_uiColorSnippetTemplate   = nil;
    [m_hexColorSnippetTemplate  release];  m_hexColorSnippetTemplate  = nil;
    [m_rgbColorSnippetTemplate  release];  m_rgbColorSnippetTemplate  = nil;
    [m_rgbaColorSnippetTemplate release];  m_rgbaColorSnippetTemplate = nil;

    [m_showApplicationShortcut  release];  m_showApplicationShortcut  = nil;
    [m_holdColorShortcut        release];  m_holdColorShortcut        = nil;

    [super dealloc];
}


- (void) _load
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    void (^loadInteger)(NSInteger *, NSString *) = ^(NSInteger *iPtr, NSString *key) {
        NSInteger i = [defaults integerForKey:key];
        if (iPtr) *iPtr = i;
    };

    void (^loadObjectOfClass)(NSObject **, Class, NSString *) = ^(NSObject **oPtr, Class cls, NSString *key) {
        NSObject *o = [defaults objectForKey:key];
        
        if (oPtr && [o isKindOfClass:cls]) {
            [*oPtr release];
            *oPtr = [o retain];
        }
    };

    void (^loadString)(NSString **, NSString *) = ^(NSString **sPtr, NSString *key) {
        loadObjectOfClass(sPtr, [NSString class], key);
    };

    void (^loadShortcut)(Shortcut **, NSString *) = ^(Shortcut **sPtr, NSString *key) {
        NSString *preferencesString = [defaults objectForKey:key];
        Shortcut *shortcut          = nil;

        if ([preferencesString isKindOfClass:[NSString class]]) {
            shortcut = [Shortcut shortcutWithPreferencesString:preferencesString];
        }
        
        if (sPtr) {
            [*sPtr release];
            *sPtr = [shortcut retain];
        }
    };

    void (^loadBoolean)(BOOL *, NSString *) = ^(BOOL *bPtr, NSString *key) {
        BOOL yn = [defaults boolForKey:key];
        if (bPtr) *bPtr = yn;
    };

    loadInteger(  &m_colorMode,                sColorModeKey               );
    loadInteger(  &m_holdColorMode,            sHoldColorModeKey           );
    loadInteger(  &m_colorProfileType,         sColorProfileTypeKey        );
    loadInteger(  &m_zoomLevel,                sZoomLevelKey               );
    loadInteger(  &m_apertureSize,             sApertureSizeKey            );
    loadInteger(  &m_apertureColor,            sApertureColorKey           );
    loadInteger(  &m_clickInSwatchAction,      sSwatchClickActionKey       );
    loadInteger(  &m_dragInSwatchAction,       sSwatchDragActionKey        );

    loadString(   &m_nsColorSnippetTemplate,   sCodeSnippetTemplateNSKey   );
    loadString(   &m_uiColorSnippetTemplate,   sCodeSnippetTemplateUIKey   );
    loadString(   &m_hexColorSnippetTemplate,  sCodeSnippetTemplateHexKey  );
    loadString(   &m_rgbColorSnippetTemplate,  sCodeSnippetTemplateRGBKey  );
    loadString(   &m_rgbaColorSnippetTemplate, sCodeSnippetTemplateRGBAKey );

    loadShortcut( &m_showApplicationShortcut,  sShowApplicationShortcutKey );
    loadShortcut( &m_holdColorShortcut,        sHoldColorShortcutKey       );

    loadBoolean(  &m_updatesContinuously,      sUpdatesContinuouslyKey     );
    loadBoolean(  &m_floatWindow,              sFloatWindowKey             );
    loadBoolean(  &m_showMouseCoordinates,     sShowMouseCoordinatesKey    );
    loadBoolean(  &m_clickInSwatchEnabled,     sSwatchClickEnabledKey      );
    loadBoolean(  &m_dragInSwatchEnabled,      sSwatchDragEnabledKey       );
    loadBoolean(  &m_arrowKeysEnabled,         sArrowKeysEnabledKey        );
    loadBoolean(  &m_showsHoldLabels,          sShowsHoldLabelsKey         );
    loadBoolean(  &m_usesLowercaseHex,         sUsesLowercaseHexKey        );
    loadBoolean(  &m_usesPoundPrefix,          sUsesPoundPrefixKey         );
    loadBoolean(  &m_showsHoldColorSliders,    sShowsHoldColorSlidersKey   );
                  
    loadBoolean(  &m_usesDifferentColorSpaceInHoldColor, sUsesDifferentColorSpaceInHoldColor );
    loadBoolean(  &m_usesMainColorSpaceForCopyAsText,    sUsesMainColorSpaceForCopyAsText    );
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

    saveInteger( m_colorMode,                sColorModeKey               );
    saveInteger( m_holdColorMode,            sHoldColorModeKey           );
    saveInteger( m_colorProfileType,         sColorProfileTypeKey        );

    saveInteger( m_zoomLevel,                sZoomLevelKey               );
    saveInteger( m_apertureSize,             sApertureSizeKey            );
    saveInteger( m_apertureColor,            sApertureColorKey           );
    saveInteger( m_clickInSwatchAction,      sSwatchClickActionKey       );
    saveInteger( m_dragInSwatchAction,       sSwatchDragActionKey        );

    saveObject( m_nsColorSnippetTemplate,    sCodeSnippetTemplateNSKey   );
    saveObject( m_uiColorSnippetTemplate,    sCodeSnippetTemplateUIKey   );
    saveObject( m_hexColorSnippetTemplate,   sCodeSnippetTemplateHexKey  );
    saveObject( m_rgbColorSnippetTemplate,   sCodeSnippetTemplateRGBKey  );
    saveObject( m_rgbaColorSnippetTemplate,  sCodeSnippetTemplateRGBAKey );
    
    saveShortcut( m_showApplicationShortcut, sShowApplicationShortcutKey );
    saveShortcut( m_holdColorShortcut,       sHoldColorShortcutKey       );
    
    saveBoolean( m_updatesContinuously,      sUpdatesContinuouslyKey     );
    saveBoolean( m_floatWindow,              sFloatWindowKey             );
    saveBoolean( m_showMouseCoordinates,     sShowMouseCoordinatesKey    );
    saveBoolean( m_clickInSwatchEnabled,     sSwatchClickEnabledKey      );
    saveBoolean( m_dragInSwatchEnabled,      sSwatchDragEnabledKey       );
    saveBoolean( m_arrowKeysEnabled,         sArrowKeysEnabledKey        );
    saveBoolean( m_usesLowercaseHex,         sUsesLowercaseHexKey        );
    saveBoolean( m_usesPoundPrefix,          sUsesPoundPrefixKey         );
    saveBoolean( m_showsHoldLabels,          sShowsHoldLabelsKey         );
    saveBoolean( m_showsHoldColorSliders,    sShowsHoldColorSlidersKey   );

    saveBoolean( m_usesDifferentColorSpaceInHoldColor, sUsesDifferentColorSpaceInHoldColor );
    saveBoolean( m_usesMainColorSpaceForCopyAsText,    sUsesMainColorSpaceForCopyAsText    );

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
    

@synthesize colorMode           = m_colorMode,
            holdColorMode       = m_holdColorMode,
            colorProfileType    = m_colorProfileType;
            
@synthesize zoomLevel           = m_zoomLevel,
            apertureSize        = m_apertureSize,
            apertureColor       = m_apertureColor,
            clickInSwatchAction = m_clickInSwatchAction,
            dragInSwatchAction  = m_dragInSwatchAction;

@synthesize nsColorSnippetTemplate   = m_nsColorSnippetTemplate,
            uiColorSnippetTemplate   = m_uiColorSnippetTemplate,
            hexColorSnippetTemplate  = m_hexColorSnippetTemplate,
            rgbColorSnippetTemplate  = m_rgbColorSnippetTemplate,
            rgbaColorSnippetTemplate = m_rgbaColorSnippetTemplate;

@synthesize showApplicationShortcut  = m_showApplicationShortcut,
            holdColorShortcut        = m_holdColorShortcut;


@synthesize updatesContinuously   = m_updatesContinuously,
            floatWindow           = m_floatWindow,
            showMouseCoordinates  = m_showMouseCoordinates,
            clickInSwatchEnabled  = m_clickInSwatchEnabled,
            dragInSwatchEnabled   = m_dragInSwatchEnabled,
            arrowKeysEnabled      = m_arrowKeysEnabled,
            usesLowercaseHex      = m_usesLowercaseHex,
            showsHoldLabels       = m_showsHoldLabels,
            showsHoldColorSliders = m_showsHoldColorSliders,
            usesPoundPrefix       = m_usesPoundPrefix;

@synthesize usesDifferentColorSpaceInHoldColor = m_usesDifferentColorSpaceInHoldColor,
            usesMainColorSpaceForCopyAsText    = m_usesMainColorSpaceForCopyAsText;

@end
