//
//  ColorSliderCell.h
//  ColorMeter
//
//  Created by Ricci Adams on 7/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

typedef void(^ColorSliderBarDrawingBlock)(Color *color, NSRect rect);

@interface ColorSliderCell : NSSliderCell

@property (nonatomic) ColorComponent component;
@property (nonatomic, retain) Color *color;

@end
