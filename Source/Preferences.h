//
//  Preferences.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const PreferencesDidChangeNotification;

@interface Preferences : NSObject

+ (id) sharedInstance;

@property ColorMode colorMode;
@property NSInteger zoomLevel;
@property NSInteger apertureSize;
@property ApertureColor apertureColor;

@property BOOL updatesContinuously;
@property BOOL floatWindow;
@property BOOL showMouseCoordinates;
@property BOOL swatchClickEnabled;
@property BOOL swatchDragEnabled;

@end
