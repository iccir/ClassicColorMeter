//
//  PreviewView.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PreviewView : NSView

@property (nonatomic /*retain*/) CGImageRef image;
@property (nonatomic) CGPoint offset;
@property (nonatomic) CGFloat imageScale;
@property (nonatomic) CGRect apertureRect;

@property (nonatomic) ApertureColor apertureColor;
@property (nonatomic) NSInteger zoomLevel;

@property (nonatomic, strong) NSString *statusText;

@property (nonatomic) BOOL showsLocation;

@end
