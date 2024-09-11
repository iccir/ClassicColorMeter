// (c) 2011-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

typedef void(^ColorSliderBarDrawingBlock)(Color *color, NSRect rect);

@interface ColorSliderCell : NSSliderCell

@property (nonatomic) ColorComponent component;
@property (nonatomic) Color *color;

@end
