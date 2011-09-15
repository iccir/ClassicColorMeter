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

@property (nonatomic, assign) NSInteger zoomLevel;
@property (nonatomic, assign) NSInteger apertureSize;
@property (nonatomic, assign) ApertureColor apertureColor;
@property (nonatomic, assign) NSInteger clickInSwatchAction;
@property (nonatomic, assign) NSInteger dragInSwatchAction;

@property (nonatomic, retain) NSString *nsColorSnippetTemplate;
@property (nonatomic, retain) NSString *uiColorSnippetTemplate;
@property (nonatomic, retain) NSString *hexColorSnippetTemplate;
@property (nonatomic, retain) NSString *rgbColorSnippetTemplate;
@property (nonatomic, retain) NSString *rgbaColorSnippetTemplate;

@property (nonatomic, retain) Shortcut *showApplicationShortcut;
@property (nonatomic, retain) Shortcut *holdColorShortcut;

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
