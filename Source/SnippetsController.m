//
//  SnippetsController.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 9/14/11.
//  Copyright (c) 2011 Ricci Adams. All rights reserved.
//

#import "SnippetsController.h"
#import "Preferences.h"


@interface SnippetsController () {
    NSTextField *oNSColorSnippetField;
    NSTextField *oUIColorSnippetField;
    NSTextField *oHTMLSnippetField;
    NSTextField *oRGBSnippetField;
    NSTextField *oRGBASnippetField;
}

- (void) _handlePreferencesDidChange:(NSNotification *)note;

@end


@implementation SnippetsController

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

    [oNSColorSnippetField setTarget:nil];
    [oNSColorSnippetField setAction:NULL];
    [oNSColorSnippetField release];
    oNSColorSnippetField = nil;

    [oUIColorSnippetField setTarget:nil];
    [oUIColorSnippetField setAction:NULL];
    [oUIColorSnippetField release];
    oUIColorSnippetField = nil;

    [oHTMLSnippetField setTarget:nil];
    [oHTMLSnippetField setAction:NULL];
    [oHTMLSnippetField release];
    oHTMLSnippetField = nil;

    [oRGBSnippetField setTarget:nil];
    [oRGBSnippetField setAction:NULL];
    [oRGBSnippetField release];
    oRGBSnippetField = nil;

    [oRGBASnippetField setTarget:nil];
    [oRGBASnippetField setAction:NULL];
    [oRGBASnippetField release];
    oRGBASnippetField = nil;

    [super dealloc];
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

    update( oNSColorSnippetField, [preferences nsColorSnippetTemplate]   );
    update( oUIColorSnippetField, [preferences uiColorSnippetTemplate]   );
    update( oHTMLSnippetField,    [preferences hexColorSnippetTemplate]  );
    update( oRGBSnippetField,     [preferences rgbColorSnippetTemplate]  );
    update( oRGBASnippetField,    [preferences rgbaColorSnippetTemplate] );
}


- (IBAction) updateSnippets:(id)sender
{
    Preferences *preferences = [Preferences sharedInstance];

    if (sender == oNSColorSnippetField) {
        [preferences setNsColorSnippetTemplate:[sender stringValue]];
        
    } else if (sender == oUIColorSnippetField) {
        [preferences setUiColorSnippetTemplate:[sender stringValue]];
    
    } else if (sender == oHTMLSnippetField) {
        [preferences setHexColorSnippetTemplate:[sender stringValue]];

    } else if (sender == oRGBSnippetField) {
        [preferences setRgbColorSnippetTemplate:[sender stringValue]];

    } else if (sender == oRGBASnippetField) {
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


@synthesize nsColorSnippetField = oNSColorSnippetField,
            uiColorSnippetField = oUIColorSnippetField,
            htmlSnippetField    = oHTMLSnippetField,
            rgbSnippetField     = oRGBSnippetField,
            rgbaSnippetField    = oRGBASnippetField;

@end
