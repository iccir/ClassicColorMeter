//
//  PreviewView.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PreviewView : NSView

@property (nonatomic) NSInteger apertureSize;
@property (nonatomic) ApertureColor apertureColor;
@property (nonatomic) NSInteger zoomLevel;
@property (nonatomic /*retain*/) CGImageRef image;
@property (nonatomic) NSPoint mouseLocation;
@property (nonatomic) BOOL showsLocation;

@end
