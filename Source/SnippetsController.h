//
//  SnippetsController.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 9/14/11.
//  Copyright (c) 2011 Ricci Adams. All rights reserved.
//


@interface SnippetsController : NSWindowController

@property (nonatomic, strong) IBOutlet NSTextField *nsColorSnippetField;
@property (nonatomic, strong) IBOutlet NSTextField *uiColorSnippetField;
@property (nonatomic, strong) IBOutlet NSTextField *htmlSnippetField;
@property (nonatomic, strong) IBOutlet NSTextField *rgbSnippetField;
@property (nonatomic, strong) IBOutlet NSTextField *rgbaSnippetField;

- (IBAction) updateSnippets:(id)sender;
- (IBAction) restoreDefaults:(id)sender;

@end
