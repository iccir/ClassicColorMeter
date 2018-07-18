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

@property (nonatomic) BOOL     usesMyClippedValues;
@property (nonatomic) BOOL     highlightsMyClippedValues;
@property (nonatomic) NSColor *colorForMyClippedValues;

@property (nonatomic) BOOL     usesSystemClippedValues;
@property (nonatomic) BOOL     highlightsSystemClippedValues;
@property (nonatomic) NSColor *colorForSystemClippedValues;

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

@property (nonatomic) BOOL showsColorWindow;
@property (nonatomic) BOOL showsMiniWindow;

@end
