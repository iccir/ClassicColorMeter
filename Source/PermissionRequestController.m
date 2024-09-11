// (c) 2011-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import "PermissionRequestController.h"
#import "Preferences.h"
#import "ScreenCapturer.h"


@interface PermissionRequestController ()

- (IBAction) openSystemPreferences:(id)sender;

@end


@implementation PermissionRequestController

- (NSString *) windowNibName
{
    return @"PermissionRequest";
}


- (IBAction) requestScreenAccess:(id)sender
{
    [ScreenCapturer requestScreenCaptureAccess];
}


- (IBAction) openSystemPreferences:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


@end
