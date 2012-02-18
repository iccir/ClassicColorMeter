//
//  SnippetsController.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 9/14/11.
//  Copyright (c) 2011 Ricci Adams. All rights reserved.
//

#import "SnippetsController.h"
#import "Preferences.h"


@interface SnippetsController ()
- (void) _handlePreferencesDidChange:(NSNotification *)note;
@end


@implementation SnippetsController

@synthesize nsColorSnippetField = o_nsColorSnippetField,
            uiColorSnippetField = o_uiColorSnippetField,
            htmlSnippetField    = o_htmlSnippetField,
            rgbSnippetField     = o_rgbSnippetField,
            rgbaSnippetField    = o_rgbASnippetField;


- (id) initWithWindow:(NSWindow *)window
{
    if ((self = [super initWithWindow:window])) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handlePreferencesDidChange:) name:PreferencesDidChangeNotification object:nil];
    }
    
    return self;
}


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [o_nsColorSnippetField setTarget:nil];
    [o_nsColorSnippetField setAction:NULL];

    [o_uiColorSnippetField setTarget:nil];
    [o_uiColorSnippetField setAction:NULL];

    [o_htmlSnippetField setTarget:nil];
    [o_htmlSnippetField setAction:NULL];

    [o_rgbSnippetField setTarget:nil];
    [o_rgbSnippetField setAction:NULL];

    [o_rgbASnippetField setTarget:nil];
    [o_rgbASnippetField setAction:NULL];
}


- (NSString *) windowNibName
{
    return @"Snippets";
}


- (void ) windowDidLoad
{
    [self _handlePreferencesDidChange:nil];
}



- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    Preferences *preferences = [Preferences sharedInstance];

    void (^update)(NSTextField *, NSString *) = ^(NSTextField *field, NSString *string) {
        if (!string) string = @"";
        [field setStringValue:string];
    };

    update( o_nsColorSnippetField, [preferences nsColorSnippetTemplate]   );
    update( o_uiColorSnippetField, [preferences uiColorSnippetTemplate]   );
    update( o_htmlSnippetField,    [preferences hexColorSnippetTemplate]  );
    update( o_rgbSnippetField,     [preferences rgbColorSnippetTemplate]  );
    update( o_rgbASnippetField,    [preferences rgbaColorSnippetTemplate] );
}


- (IBAction) updateSnippets:(id)sender
{
    Preferences *preferences = [Preferences sharedInstance];

    if (sender == o_nsColorSnippetField) {
        [preferences setNsColorSnippetTemplate:[sender stringValue]];
        
    } else if (sender == o_uiColorSnippetField) {
        [preferences setUiColorSnippetTemplate:[sender stringValue]];
    
    } else if (sender == o_htmlSnippetField) {
        [preferences setHexColorSnippetTemplate:[sender stringValue]];

    } else if (sender == o_rgbSnippetField) {
        [preferences setRgbColorSnippetTemplate:[sender stringValue]];

    } else if (sender == o_rgbASnippetField) {
        [preferences setRgbaColorSnippetTemplate:[sender stringValue]];
    }
}


- (IBAction) restoreDefaults:(id)sender
{
    Preferences *preferences = [Preferences sharedInstance];
    [preferences restoreCodeSnippets];
}


- (void) _flush
{
    id firstResponder = [[self window] firstResponder];
    NSTextField *textField = nil;

    if ([firstResponder isKindOfClass:[NSText class]] && [firstResponder isFieldEditor]) {
        id delegate = [firstResponder delegate];
        if ([delegate isKindOfClass:[NSTextField class]]) {
            textField = delegate;
        }
        
    } else if ([firstResponder isKindOfClass:[NSTextField class]]) {
        textField = firstResponder;
    }

    if (textField) {
        [[self window] makeFirstResponder:nil];
        [[self window] makeFirstResponder:textField];
    }
}


- (void) windowDidBecomeMain:(NSNotification *)notification
{
    [self _flush];
}


- (void) windowDidResignMain:(NSNotification *)notification
{
    [self _flush];
}


@end
