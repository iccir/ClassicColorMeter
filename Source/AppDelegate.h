//
//  AppDelegate.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PreviewView, ResultView;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>

- (IBAction) changeColorMode:(id)sender;
- (IBAction) changeApertureSize:(id)sender;

- (IBAction) showPreferences:(id)sender;

// View menu
- (IBAction) lockPosition:(id)sender;
- (IBAction) lockX:(id)sender;
- (IBAction) lockY:(id)sender;
- (IBAction) updateMagnification:(id)sender;
- (IBAction) toggleContinuous:(id)sender;
- (IBAction) toggleMouseLocation:(id)sender;
- (IBAction) toggleFloatWindow:(id)sender;
- (IBAction) copyImage:(id)sender;
- (IBAction) saveImage:(id)sender;

// Color menu
- (IBAction) holdColor:(id)sender;
- (IBAction) copyColorAsText:(id)sender;
- (IBAction) copyColorAsImage:(id)sender;
- (IBAction) sendFeedback:(id)sender;

@property (nonatomic, retain) IBOutlet NSWindow      *window;
@property (nonatomic, retain) IBOutlet NSPopUpButton *colorModePopUp;
@property (nonatomic, retain) IBOutlet NSSlider      *apertureSizeSlider;
@property (nonatomic, retain) IBOutlet PreviewView   *previewView;

@property (nonatomic, retain) IBOutlet ResultView    *resultView;

@property (nonatomic, retain) IBOutlet NSTextField   *profileField;
@property (nonatomic, retain) IBOutlet NSTextField   *statusText;

@property (nonatomic, retain) IBOutlet NSTextField   *label1;
@property (nonatomic, retain) IBOutlet NSTextField   *label2;
@property (nonatomic, retain) IBOutlet NSTextField   *label3;

@property (nonatomic, retain) IBOutlet NSTextField   *value1;
@property (nonatomic, retain) IBOutlet NSTextField   *value2;
@property (nonatomic, retain) IBOutlet NSTextField   *value3;

@end
