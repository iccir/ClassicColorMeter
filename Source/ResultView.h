// (c) 2011-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

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
