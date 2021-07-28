//
//  SnippetsController.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 9/14/11.
//  Copyright (c) 2011 Ricci Adams. All rights reserved.
//

#import "PermissionRequestController.h"
#import "Preferences.h"


@interface PermissionRequestController ()

- (IBAction) openSystemPreferences:(id)sender;

@end


@implementation PermissionRequestController

- (NSString *) windowNibName
{
    return @"PermissionRequest";
}


- (IBAction) openSystemPreferences:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


@end
