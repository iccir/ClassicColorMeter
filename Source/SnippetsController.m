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

@property (nonatomic, strong) IBOutlet NSTextField *nsColorSnippetField;
@property (nonatomic, strong) IBOutlet NSTextField *uiColorSnippetField;
@property (nonatomic, strong) IBOutlet NSTextField *htmlSnippetField;
@property (nonatomic, strong) IBOutlet NSTextField *rgbSnippetField;
@property (nonatomic, strong) IBOutlet NSTextField *rgbaSnippetField;

- (IBAction) updateSnippets:(id)sender;
- (IBAction) restoreDefaults:(id)sender;

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

    [_nsColorSnippetField setTarget:nil];
    [_nsColorSnippetField setAction:NULL];

    [_uiColorSnippetField setTarget:nil];
    [_uiColorSnippetField setAction:NULL];

    [_htmlSnippetField setTarget:nil];
    [_htmlSnippetField setAction:NULL];

    [_rgbSnippetField setTarget:nil];
    [_rgbSnippetField setAction:NULL];

    [_rgbaSnippetField setTarget:nil];
    [_rgbaSnippetField setAction:NULL];
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

    update( _nsColorSnippetField, [preferences nsColorSnippetTemplate]   );
    update( _uiColorSnippetField, [preferences uiColorSnippetTemplate]   );
    update( _htmlSnippetField,    [preferences hexColorSnippetTemplate]  );
    update( _rgbSnippetField,     [preferences rgbColorSnippetTemplate]  );
    update( _rgbaSnippetField,    [preferences rgbaColorSnippetTemplate] );
}


- (IBAction) updateSnippets:(id)sender
{
    Preferences *preferences = [Preferences sharedInstance];

    if (sender == _nsColorSnippetField) {
        [preferences setNsColorSnippetTemplate:[sender stringValue]];
        
    } else if (sender == _uiColorSnippetField) {
        [preferences setUiColorSnippetTemplate:[sender stringValue]];
    
    } else if (sender == _htmlSnippetField) {
        [preferences setHexColorSnippetTemplate:[sender stringValue]];

    } else if (sender == _rgbSnippetField) {
        [preferences setRgbColorSnippetTemplate:[sender stringValue]];

    } else if (sender == _rgbaSnippetField) {
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
