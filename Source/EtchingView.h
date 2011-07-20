//
//  EtchingView.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EtchingView : NSView

@property (nonatomic, assign) CGFloat activeDarkOpacity;
@property (nonatomic, assign) CGFloat activeLightOpacity;
@property (nonatomic, assign) CGFloat inactiveDarkOpacity;
@property (nonatomic, assign) CGFloat inactiveLightOpacity;

@end
