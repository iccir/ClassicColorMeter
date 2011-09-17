//
//  ShortcutManager.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-05-01.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "ShortcutManager.h"
#import <Carbon/Carbon.h>
#import "Shortcut.h"


static id sSharedInstance = nil;

@interface ShortcutManager () {
    NSHashTable         *_listeners;
    NSMutableDictionary *_shortcutIDToRefMap;
    NSMutableDictionary *_shortcutIDToShortcutMap;  
    NSArray             *_shortcuts;
}

- (BOOL) _handleHotKeyID:(NSUInteger)hotKeyID;
- (void) _unregisterShortcut:(Shortcut *)shortcut;

@end


static OSStatus sHandleEvent(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData)
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	EventHotKeyID hotKeyID = { 0, 0 };
	if (noErr == GetEventParameter(inEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hotKeyID), NULL, &hotKeyID)) {
        [(ShortcutManager *)inUserData _handleHotKeyID:(NSUInteger)hotKeyID.id];
    }

	[pool release];

    return noErr;
}


@implementation ShortcutManager

+ (BOOL) hasSharedInstance
{
    return (sSharedInstance != nil);
}


+ (id) sharedInstance
{
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sSharedInstance = [[self alloc] init];

		EventTypeSpec eventSpec = { kEventClassKeyboard, kEventHotKeyPressed };
		InstallApplicationEventHandler(&sHandleEvent, 1, &eventSpec, sSharedInstance, NULL);
    });

    return sSharedInstance;
}


#pragma mark -
#pragma mark Lifecycle

- (id) init
{
    if ((self = [super init])) {
        _listeners               = [[NSHashTable hashTableWithWeakObjects] retain];
        _shortcutIDToRefMap      = [[NSMutableDictionary alloc] init];
        _shortcutIDToShortcutMap = [[NSMutableDictionary alloc] init];
    }

    return self;
}


- (void) dealloc
{
    for (Shortcut *shortcut in _shortcuts) {
        [self _unregisterShortcut:shortcut];
    }

    [_listeners release];
    _listeners = nil;

    [_shortcutIDToRefMap release];
    _shortcutIDToRefMap = nil;

    [_shortcutIDToShortcutMap release];
    _shortcutIDToShortcutMap = nil;

    [_shortcuts release];
    _shortcuts = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark Private Methods

- (BOOL) _handleHotKeyID:(NSUInteger)keyID
{
    NSNumber *keyIDAsNumber = [[NSNumber alloc] initWithUnsignedInteger:keyID];

    Shortcut *shortcut = [_shortcutIDToShortcutMap objectForKey:keyIDAsNumber];
    BOOL yn = NO;

    if (shortcut) {
        for (id<ShortcutListener> listener in _listeners) {
            yn = yn || [listener performShortcut:shortcut];
        }
    }

    [keyIDAsNumber release];

    return yn;
}


- (void) _unregisterShortcutIDAsNumber:(NSNumber *)key
{
    EventHotKeyRef hotKeyRef = [[_shortcutIDToRefMap objectForKey:key] pointerValue];
    if (hotKeyRef) UnregisterEventHotKey(hotKeyRef);

    [_shortcutIDToRefMap      removeObjectForKey:key];
    [_shortcutIDToShortcutMap removeObjectForKey:key];
}


- (void) _unregisterShortcut:(Shortcut *)shortcut
{
    NSUInteger shortcutID = [shortcut shortcutID];

    NSNumber *shortcutIDAsNumber = [[NSNumber alloc] initWithUnsignedInteger:shortcutID];
    [self _unregisterShortcutIDAsNumber:shortcutIDAsNumber];
    [shortcutIDAsNumber release];
}


- (void) _registerShortcut:(Shortcut *)shortcut
{
    NSUInteger     shortcutID    = [shortcut shortcutID];
    unsigned short keyCode       = [shortcut keyCode];
    NSUInteger     modifierFlags = [shortcut modifierFlags];

    EventHotKeyID  eventKeyID   = { 'htk1', (UInt32)shortcutID };
	EventHotKeyRef hotKeyRef    = NULL;

    NSNumber *shortcutIDAsNumber = [[NSNumber alloc] initWithUnsignedInteger:shortcutID];
    [self _unregisterShortcutIDAsNumber:shortcutIDAsNumber];

    UInt32 flags = 0;
    if (modifierFlags & NSControlKeyMask  )  flags |= controlKey;
    if (modifierFlags & NSCommandKeyMask  )  flags |= cmdKey;
    if (modifierFlags & NSShiftKeyMask    )  flags |= shiftKey;
    if (modifierFlags & NSAlternateKeyMask)  flags |= optionKey;

	if (RegisterEventHotKey(keyCode, flags, eventKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef) == noErr) {
        [_shortcutIDToRefMap setObject:[NSValue valueWithPointer:hotKeyRef] forKey:shortcutIDAsNumber];
        [_shortcutIDToShortcutMap setObject:shortcut forKey:shortcutIDAsNumber];
    }

    [shortcutIDAsNumber release];
}


#pragma mark -
#pragma mark Public Methods

- (void) addListener:(id<ShortcutListener>)listener
{
    [_listeners addObject:listener];
}


- (void) removeListener:(id<ShortcutListener>)listener
{
    [_listeners removeObject:listener];
}


#pragma mark -
#pragma mark Accessors

- (void) setShortcuts:(NSArray *)shortcuts
{
    if (shortcuts != _shortcuts) {
        // Add new shortcuts
        for (Shortcut *shortcut in shortcuts) {
            if (![_shortcuts containsObject:shortcut]) {
                [self _registerShortcut:shortcut];
            }
        }
        
        // Delete old shortcuts 
        for (Shortcut *shortcut in _shortcuts) {
            if (![shortcuts containsObject:shortcut]) {
                [self _unregisterShortcut:shortcut];
            }
        }
        
        [_shortcuts release];
        _shortcuts = [shortcuts copy];
    }
}


@synthesize shortcuts = _shortcuts;


@end
