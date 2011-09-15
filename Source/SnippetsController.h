//
//  SnippetsController.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 9/14/11.
//  Copyright (c) 2011 Ricci Adams. All rights reserved.
//


@interface SnippetsController : NSWindowController

@property (nonatomic, retain) IBOutlet NSTextField *nsColorSnippetField;
@property (nonatomic, retain) IBOutlet NSTextField *uiColorSnippetField;
@property (nonatomic, retain) IBOutlet NSTextField *htmlSnippetField;
@property (nonatomic, retain) IBOutlet NSTextField *rgbSnippetField;
@property (nonatomic, retain) IBOutlet NSTextField *rgbaSnippetField;

- (IBAction) updateSnippets:(id)sender;
- (IBAction) restoreDefaults:(id)sender;

@end
