//
//  ResultView.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ResultViewDelegate;


@interface ResultView : NSView

@property (nonatomic) Color *color;
@property (nonatomic, weak) id<ResultViewDelegate> delegate;
@property (nonatomic, getter=isClickEnabled) BOOL clickEnabled;
@property (nonatomic, getter=isDragEnabled)  BOOL dragEnabled;

@property (nonatomic) BOOL drawsBorder;

@end


@protocol ResultViewDelegate <NSObject>
- (void) resultViewClicked:(ResultView *)view;
- (void) resultView:(ResultView *)view dragInitiatedWithEvent:(NSEvent *)event;
@end
