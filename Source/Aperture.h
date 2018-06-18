//
//  Aperture.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2012-06-14.
//
//

#import <Foundation/Foundation.h>


@protocol ApertureDelegate;

@interface Aperture : NSObject

- (void) update;

- (void) averageAndUpdateColor:(Color *)color;

@property (nonatomic, weak) id<ApertureDelegate> delegate;

@property (nonatomic, readonly /*strong*/) CGImageRef image;
@property (nonatomic, readonly) CGPoint offset;
@property (nonatomic, readonly) CGFloat scaleFactor;    // rect of image to display
@property (nonatomic, readonly) CGRect apertureRect;    // rect of aperture

@property (nonatomic, assign) NSInteger apertureSize;
@property (nonatomic, assign) NSInteger zoomLevel;
@property (nonatomic, assign) BOOL updatesContinuously;
@property (nonatomic, assign) ColorConversion colorConversion;

@property (nonatomic, readonly) NSString *longColorProfileLabel;
@property (nonatomic, readonly) NSString *shortColorProfileLabel;

@end


@protocol ApertureDelegate <NSObject>
- (void) aperture:(Aperture *)aperture didUpdateImage:(CGImageRef)image;
- (void) apertureDidUpdateColorProfile:(Aperture *)aperture;
@end
