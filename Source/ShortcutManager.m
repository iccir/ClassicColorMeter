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
    NSHashTable         *m_listeners;
    NSMutableDictionary *m_shortcutIDToRefMap;
    NSMutableDictionary *m_shortcutIDToShortcutMap;  
    NSArray             *m_shortcuts;
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
        m_listeners               = [[NSHashTable hashTableWithWeakObjects] retain];
        m_shortcutIDToRefMap      = [[NSMutableDictionary alloc] init];
        m_shortcutIDToShortcutMap = [[NSMutableDictionary alloc] init];
    }

    return self;
}


- (void) dealloc
{
    for (Shortcut *shortcut in m_shortcuts) {
        [self _unregisterShortcut:shortcut];
    }

    [m_listeners release];
    m_listeners = nil;

    [m_shortcutIDToRefMap release];
    m_shortcutIDToRefMap = nil;

    [m_shortcutIDToShortcutMap release];
    m_shortcutIDToShortcutMap = nil;

    [m_shortcuts release];
    m_shortcuts = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark Private Methods

- (BOOL) _handleHotKeyID:(NSUInteger)keyID
{
    NSNumber *keyIDAsNumber = [[NSNumber alloc] initWithUnsignedInteger:keyID];

    Shortcut *shortcut = [m_shortcutIDToShortcutMap objectForKey:keyIDAsNumber];
    BOOL yn = NO;

    if (shortcut) {
        for (id<ShortcutListener> listener in m_listeners) {
            yn = yn || [listener performShortcut:shortcut];
        }
    }

    [keyIDAsNumber release];

    return yn;
}


- (void) _unregisterShortcutIDAsNumber:(NSNumber *)key
{
    EventHotKeyRef hotKeyRef = [[m_shortcutIDToRefMap objectForKey:key] pointerValue];
    if (hotKeyRef) UnregisterEventHotKey(hotKeyRef);

    [m_shortcutIDToRefMap      removeObjectForKey:key];
    [m_shortcutIDToShortcutMap removeObjectForKey:key];
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
        [m_shortcutIDToRefMap setObject:[NSValue valueWithPointer:hotKeyRef] forKey:shortcutIDAsNumber];
        [m_shortcutIDToShortcutMap setObject:shortcut forKey:shortcutIDAsNumber];
    }

    [shortcutIDAsNumber release];
}


#pragma mark -
#pragma mark Public Methods

- (void) addListener:(id<ShortcutListener>)listener
{
    [m_listeners addObject:listener];
}


- (void) removeListener:(id<ShortcutListener>)listener
{
    [m_listeners removeObject:listener];
}


#pragma mark -
#pragma mark Accessors

- (void) setShortcuts:(NSArray *)shortcuts
{
    if (shortcuts != m_shortcuts) {
        // Add new shortcuts
        for (Shortcut *shortcut in shortcuts) {
            if (![m_shortcuts containsObject:shortcut]) {
                [self _registerShortcut:shortcut];
            }
        }
        
        // Delete old shortcuts 
        for (Shortcut *shortcut in m_shortcuts) {
            if (![shortcuts containsObject:shortcut]) {
                [self _unregisterShortcut:shortcut];
            }
        }
        
        [m_shortcuts release];
        m_shortcuts = [shortcuts copy];
    }
}


@synthesize shortcuts = m_shortcuts;


@end
