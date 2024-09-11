// (c) 2011-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>

@interface Shortcut : NSObject

+ (Shortcut *) emptyShortcut;

+ (NSString *) stringForModifierFlags:(NSUInteger)modifierFlags;
+ (NSString *) stringForKeyCode:(unsigned short)keyCode;

+ (Shortcut *) shortcutWithPreferencesString:(NSString *)string;
+ (Shortcut *) shortcutWithWithKeyCode:(unsigned short)keycode modifierFlags:(NSUInteger)modifierFlags;

- (id) initWithPreferencesString:(NSString *)string;
- (id) initWithKeyCode:(unsigned short)keycode modifierFlags:(NSUInteger)modifierFlags;

@property (nonatomic, readonly) NSUInteger shortcutID;
@property (nonatomic, readonly) NSUInteger modifierFlags;
@property (nonatomic, readonly) unsigned short keyCode;

@property (nonatomic, readonly) NSString *preferencesString;
@property (nonatomic, readonly) NSString *displayString;

@end
