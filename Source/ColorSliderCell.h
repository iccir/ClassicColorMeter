//
//  ColorSliderCell.h
//  ColorMeter
//
//  Created by Ricci Adams on 2011-07-29.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

typedef void(^ColorSliderBarDrawingBlock)(Color *color, NSRect rect);

@interface ColorSliderCell : NSSliderCell

@property (nonatomic) ColorComponent component;
@property (nonatomic) Color *color;

@end
