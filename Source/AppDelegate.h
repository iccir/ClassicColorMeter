//
//  AppDelegate.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ResultView.h"
#import "ShortcutManager.h"

@class PreviewView, RecessedButton;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate, ShortcutListener, ResultViewDelegate, NSDraggingSource>

- (IBAction) changeColorMode:(id)sender;
- (IBAction) changeApertureSize:(id)sender;

- (IBAction) showPreferences:(id)sender;
- (IBAction) showSnippets:(id)sender;

- (IBAction) changeColorConversionValue:(id)sender;
- (IBAction) writeTopLabelValueToPasteboard:(id)sender;
- (IBAction) writeBottomLabelValueToPasteboard:(id)sender;

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

- (IBAction) showColorWindow:(id)sender;

// Color menu
- (IBAction) holdColor:(id)sender;
- (IBAction) pasteTextAsColor:(id)sender;

- (IBAction) performColorActionForSender:(id)sender;

- (IBAction) updateComponent:(id)sender;

- (IBAction) sendFeedback:(id)sender;

@property (nonatomic, strong) IBOutlet NSWindow      *window;

@property (nonatomic, strong) IBOutlet NSView        *leftContainer;
@property (nonatomic, strong) IBOutlet NSView        *middleContainer;
@property (nonatomic, strong) IBOutlet NSView        *rightContainer;

@property (nonatomic, strong) IBOutlet NSPopUpButton *colorModePopUp;
@property (nonatomic, strong) IBOutlet NSSlider      *apertureSizeSlider;
@property (nonatomic, strong) IBOutlet PreviewView   *previewView;

@property (nonatomic, strong) IBOutlet ResultView    *resultView;

@property (nonatomic, strong) IBOutlet NSTextField   *apertureSizeLabel;

@property (nonatomic, strong) IBOutlet NSTextField   *label1;
@property (nonatomic, strong) IBOutlet NSTextField   *label2;
@property (nonatomic, strong) IBOutlet NSTextField   *label3;

@property (nonatomic, strong) IBOutlet NSTextField    *holdingLabel;
@property (nonatomic, strong) IBOutlet RecessedButton *profileButton;
@property (nonatomic, strong) IBOutlet RecessedButton *topHoldLabelButton;
@property (nonatomic, strong) IBOutlet RecessedButton *bottomHoldLabelButton;

@property (nonatomic, strong) IBOutlet NSTextField   *value1;
@property (nonatomic, strong) IBOutlet NSTextField   *value2;
@property (nonatomic, strong) IBOutlet NSTextField   *value3;

@property (nonatomic, strong) IBOutlet NSSlider      *slider1;
@property (nonatomic, strong) IBOutlet NSSlider      *slider2;
@property (nonatomic, strong) IBOutlet NSSlider      *slider3;

@property (nonatomic, strong) IBOutlet NSWindow      *colorWindow;
@property (nonatomic, weak)   IBOutlet ResultView    *colorResultView;

@end
