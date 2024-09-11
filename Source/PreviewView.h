// (c) 2011-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Cocoa/Cocoa.h>


@interface PreviewView : NSView

@property (nonatomic /*strong*/) CGImageRef image;
@property (nonatomic) CGPoint offset;
@property (nonatomic) CGFloat imageScale;
@property (nonatomic) CGRect apertureRect;

@property (nonatomic) ApertureOutline apertureOutline;
@property (nonatomic) NSInteger zoomLevel;

@property (nonatomic) NSString *errorText;
@property (nonatomic) NSString *statusText;

@property (nonatomic) BOOL showsLocation;

@end
