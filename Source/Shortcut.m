//
//  Shortcut.m
//  PixelWinch
//
//  Created by Ricci Adams on 4/23/11.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "Shortcut.h"
#import <Carbon/Carbon.h>

@interface Shortcut () {
    NSUInteger     _modifierFlags;
    unsigned short _keyCode;
}

@end


static NSString *sNumericPadMarker    = @"<<<PAD>>>";
static NSString **sKeyCodeToStringMap = nil;

static NSString *sGetPreferencesString(NSUInteger modifierFlags, unsigned short keyCode)
{
    NSMutableString *result = [NSMutableString string];

    [result appendString:@"key,"];

    if (modifierFlags & NSControlKeyMask)   [result appendString:@"^"];
    if (modifierFlags & NSAlternateKeyMask) [result appendString:@"~"];
    if (modifierFlags & NSShiftKeyMask)     [result appendString:@"$"];
    if (modifierFlags & NSCommandKeyMask)   [result appendString:@"@"];
    if (modifierFlags == 0)                 [result appendString:@"_"];

    [result appendFormat:@",%04lx", (long)keyCode];
    
    return result;
}


static void sReadPreferencesString(NSString *string, NSUInteger *outFlags, NSUInteger *outDatum)
{
    NSUInteger   modifierFlags = 0;
    NSUInteger   datum         = 0;

    NSArray *components = [string componentsSeparatedByString:@","];
    
    if ([components count] >= 3) {
        NSString *modifierString = [components objectAtIndex:1];
        NSString *datumString    = [components objectAtIndex:2];

        if ([modifierString rangeOfString:@"^"].location != NSNotFound) {
            modifierFlags |= NSControlKeyMask;
        }
        
        if ([modifierString rangeOfString:@"~"].location != NSNotFound) {
            modifierFlags |= NSAlternateKeyMask;
        }

        if ([modifierString rangeOfString:@"$"].location != NSNotFound) {
            modifierFlags |= NSShiftKeyMask;
        }

        if ([modifierString rangeOfString:@"@"].location != NSNotFound) {
            modifierFlags |= NSCommandKeyMask;
        }

        const char *cString = [datumString cStringUsingEncoding:NSUTF8StringEncoding];
        sscanf(cString, "%04lx", &datum);
    }

    if (outFlags) *outFlags = modifierFlags;
    if (outDatum) *outDatum = datum;
}


@implementation Shortcut


#pragma mark -
#pragma mark Class Methods

+ (void) initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sKeyCodeToStringMap = calloc(sizeof(void *), 128);

        sKeyCodeToStringMap[36]  = @"\u21A9";
        sKeyCodeToStringMap[48]  = @"\u21E5";
        sKeyCodeToStringMap[49]  = @"Space";
        sKeyCodeToStringMap[51]  = @"\u232B";
        sKeyCodeToStringMap[53]  = @"\u238B";
        sKeyCodeToStringMap[64]  = @"F17";
        sKeyCodeToStringMap[71]  = @"\u2327";
        sKeyCodeToStringMap[76]  = @"\u2305";
        sKeyCodeToStringMap[79]  = @"F18";
        sKeyCodeToStringMap[80]  = @"F19";
        sKeyCodeToStringMap[96]  = @"F5";
        sKeyCodeToStringMap[97]  = @"F6";
        sKeyCodeToStringMap[98]  = @"F7";
        sKeyCodeToStringMap[99]  = @"F3";
        sKeyCodeToStringMap[65]  = sNumericPadMarker;
        sKeyCodeToStringMap[67]  = sNumericPadMarker;
        sKeyCodeToStringMap[69]  = sNumericPadMarker;
        sKeyCodeToStringMap[75]  = sNumericPadMarker;
        sKeyCodeToStringMap[78]  = sNumericPadMarker;
        sKeyCodeToStringMap[81]  = sNumericPadMarker;
        sKeyCodeToStringMap[82]  = sNumericPadMarker;
        sKeyCodeToStringMap[83]  = sNumericPadMarker;
        sKeyCodeToStringMap[84]  = sNumericPadMarker;
        sKeyCodeToStringMap[85]  = sNumericPadMarker;
        sKeyCodeToStringMap[86]  = sNumericPadMarker;
        sKeyCodeToStringMap[87]  = sNumericPadMarker;
        sKeyCodeToStringMap[88]  = sNumericPadMarker;
        sKeyCodeToStringMap[89]  = sNumericPadMarker;
        sKeyCodeToStringMap[91]  = sNumericPadMarker;
        sKeyCodeToStringMap[92]  = sNumericPadMarker;
        sKeyCodeToStringMap[100] = @"F8";
        sKeyCodeToStringMap[101] = @"F9";
        sKeyCodeToStringMap[103] = @"F11";
        sKeyCodeToStringMap[105] = @"F13";
        sKeyCodeToStringMap[106] = @"F16";
        sKeyCodeToStringMap[107] = @"F14";
        sKeyCodeToStringMap[109] = @"F10";
        sKeyCodeToStringMap[111] = @"F12";
        sKeyCodeToStringMap[113] = @"F15";
        sKeyCodeToStringMap[114] = @"\x3F";
        sKeyCodeToStringMap[115] = @"\u2196";
        sKeyCodeToStringMap[116] = @"\u21DE";
        sKeyCodeToStringMap[117] = @"\u2326";
        sKeyCodeToStringMap[118] = @"F4";
        sKeyCodeToStringMap[119] = @"\u2198";
        sKeyCodeToStringMap[120] = @"F2";
        sKeyCodeToStringMap[121] = @"\u21DF";
        sKeyCodeToStringMap[122] = @"F1";
        sKeyCodeToStringMap[123] = @"\u2190";
        sKeyCodeToStringMap[124] = @"\u2192";
        sKeyCodeToStringMap[125] = @"\u2193";
        sKeyCodeToStringMap[126] = @"\u2191";
    });
}


+ (Shortcut *) shortcutWithPreferencesString:(NSString *)string
{
    return [[[self alloc] initWithPreferencesString:string] autorelease];
}


+ (Shortcut *) shortcutWithWithKeyCode:(unsigned short)keycode modifierFlags:(NSUInteger)modifierFlags
{
    return [[[self alloc] initWithKeyCode:keycode modifierFlags:modifierFlags] autorelease];
}


+ (NSString *) stringForModifierFlags:(NSUInteger)modifierFlags
{
    NSMutableString *result = [NSMutableString stringWithCapacity:4];
    
    if (modifierFlags & NSControlKeyMask)   [result appendFormat:@"%C", kControlUnicode];
    if (modifierFlags & NSAlternateKeyMask) [result appendFormat:@"%C", kOptionUnicode];
    if (modifierFlags & NSShiftKeyMask)     [result appendFormat:@"%C", kShiftUnicode];
    if (modifierFlags & NSCommandKeyMask)   [result appendFormat:@"%C", kCommandUnicode];

    return result;
}


+ (NSString *) stringForKeyCode:(unsigned short)keyCode
{
    BOOL isNumericPad = NO;
    NSString *mapLookup = nil;

    if ((keyCode >= 0) && (keyCode < 128)) {
        mapLookup = sKeyCodeToStringMap[keyCode];

        if (mapLookup == sNumericPadMarker) {
            mapLookup = nil;
            isNumericPad = YES;
        } 
        
        if (mapLookup) {
            return mapLookup;
        }
    }

    TISInputSourceRef tisSource = TISCopyCurrentKeyboardInputSource();
	if (!tisSource) return nil;

	UInt32 keysDown = 0;
	CFDataRef layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData);
	if (!layoutData) return nil;

	const UCKeyboardLayout *keyLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
			
	UniCharCount length = 4, realLength;
	UniChar characters[4];
    NSString *result = nil;

	if (noErr == UCKeyTranslate(keyLayout, keyCode, kUCKeyActionDisplay, 0, LMGetKbdType(), kUCKeyTranslateNoDeadKeysBit, &keysDown, length, &realLength, characters)) {
        result = [[NSString stringWithCharacters:characters length:1] uppercaseString];

        if (isNumericPad) {
            result = [NSString stringWithFormat:@"[%@]", result];
        }
    }


    if (tisSource) CFRelease(tisSource);
    
    return result;
}


#pragma mark -
#pragma mark Lifecycle

- (id) initWithKeyCode:(unsigned short)keyCode modifierFlags:(NSUInteger)modifierFlags
{
    if ((self = [super init])) {
        _keyCode       = keyCode;
        _modifierFlags = modifierFlags;
    }

    return self;
}


- (id) initWithPreferencesString:(NSString *)string
{
    NSUInteger   modifierFlags = 0;
    NSUInteger   datum         = 0;

    sReadPreferencesString(string, &modifierFlags, &datum);
    
    return [self initWithKeyCode:datum modifierFlags:modifierFlags];
}


- (id) init
{
    [self release];
    return nil;
}


- (id) copyWithZone:(NSZone *)zone
{
    return [self retain];
}


- (BOOL) isEqual:(id)anotherObject
{
    if (anotherObject == self) return YES;

    if ([anotherObject isKindOfClass:[Shortcut class]]) {
        Shortcut *anotherShortcut = (Shortcut *)anotherObject;

        return anotherShortcut->_modifierFlags == _modifierFlags &&
               anotherShortcut->_keyCode       == _keyCode;
    }

    return NO;
}


- (NSUInteger) hash
{
    return [self shortcutID];
}


#pragma mark -
#pragma mark Accessors

- (NSUInteger) shortcutID
{
    NSUInteger shortcutID = 0;

    if (_modifierFlags & NSControlKeyMask  )  shortcutID |= 0x10000;
    if (_modifierFlags & NSCommandKeyMask  )  shortcutID |= 0x20000;
    if (_modifierFlags & NSShiftKeyMask    )  shortcutID |= 0x40000;
    if (_modifierFlags & NSAlternateKeyMask)  shortcutID |= 0x80000;

    shortcutID |= _keyCode;
    
    return shortcutID;
}


- (NSString *) preferencesString
{
    return sGetPreferencesString(_modifierFlags, _keyCode);
}


- (NSString *) displayString
{
    NSString *modifierString = [Shortcut stringForModifierFlags:_modifierFlags];
    NSString *keyCodeString  = [Shortcut stringForKeyCode:_keyCode];

    return [NSString stringWithFormat:@"%@%@", modifierString, keyCodeString];
}


@synthesize modifierFlags = _modifierFlags,
            keyCode       = _keyCode;

@end
