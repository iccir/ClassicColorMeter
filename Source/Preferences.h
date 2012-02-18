//
//  Preferences.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const PreferencesDidChangeNotification;

@class Shortcut;

@interface Preferences : NSObject

+ (id) sharedInstance;

- (void) restoreCodeSnippets;

@property (nonatomic, assign) ColorMode colorMode;
@property (nonatomic, assign) ColorMode holdColorMode;
@property (nonatomic, assign) ColorProfileType colorProfileType;

@property (nonatomic, assign) NSInteger zoomLevel;
@property (nonatomic, assign) NSInteger apertureSize;
@property (nonatomic, assign) ApertureColor apertureColor;
@property (nonatomic, assign) NSInteger clickInSwatchAction;
@property (nonatomic, assign) NSInteger dragInSwatchAction;

@property (nonatomic, strong) NSString *nsColorSnippetTemplate;
@property (nonatomic, strong) NSString *uiColorSnippetTemplate;
@property (nonatomic, strong) NSString *hexColorSnippetTemplate;
@property (nonatomic, strong) NSString *rgbColorSnippetTemplate;
@property (nonatomic, strong) NSString *rgbaColorSnippetTemplate;

@property (nonatomic, strong) Shortcut *showApplicationShortcut;
@property (nonatomic, strong) Shortcut *holdColorShortcut;

@property (nonatomic, assign) BOOL updatesContinuously;
@property (nonatomic, assign) BOOL floatWindow;
@property (nonatomic, assign) BOOL showMouseCoordinates;
@property (nonatomic, assign) BOOL clickInSwatchEnabled;
@property (nonatomic, assign) BOOL dragInSwatchEnabled;
@property (nonatomic, assign) BOOL arrowKeysEnabled;
@property (nonatomic, assign) BOOL usesLowercaseHex;
@property (nonatomic, assign) BOOL showsHoldColorSliders;
@property (nonatomic, assign) BOOL usesPoundPrefix;
@property (nonatomic, assign) BOOL showsHoldLabels;
@property (nonatomic, assign) BOOL usesDifferentColorSpaceInHoldColor;
@property (nonatomic, assign) BOOL usesMainColorSpaceForCopyAsText;

@end
