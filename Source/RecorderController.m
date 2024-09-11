// (c) 2015-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import "RecorderController.h"

@interface RecorderController () {
    NSTimeInterval  _startTime;
    NSMutableArray *_lines;
}

@property (nonatomic) IBOutlet NSButton *startStopButton;
@property (nonatomic) IBOutlet NSTextField *statusField;

@property (atomic, getter=isRecording) BOOL recording;

@end


@implementation RecorderController


- (NSString *) windowNibName
{
    return @"Recorder";
}


- (IBAction) startOrStop:(id)sender
{
    BOOL recording = [self isRecording];

    if (recording) {
        [_startStopButton setTitle:NSLocalizedString(@"Start Recording", nil)];
        [_statusField setStringValue:@""];

        recording = NO;
        
        NSSavePanel *panel = [NSSavePanel savePanel];
        
        [panel setAllowedFileTypes:[NSArray arrayWithObject:(id)kUTTypePlainText]];

        NSString *contents = [_lines componentsJoinedByString:@"\n"];
        _lines = nil;
        
        [panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
            if (result == NSModalResponseOK) {
                NSError *error = nil;
                [contents writeToURL:[panel URL] atomically:YES encoding:NSUTF8StringEncoding error:&error];
            }
        }];

    } else {
        _startTime = [NSDate timeIntervalSinceReferenceDate];
        _lines     = [NSMutableArray array];

        [_startStopButton setTitle:NSLocalizedString(@"Stop and Save", nil)];
        recording = YES;
    }
    
    [self setRecording:recording];
}


- (void) addSampleWithText:(NSString *)text
{
    NSInteger count = [_lines count];
    
    NSTimeInterval elapsed = [NSDate timeIntervalSinceReferenceDate] - _startTime;
    
    NSString *line = [NSString stringWithFormat:@"%g\t%@", elapsed, text];
    [_lines addObject:line];
    
    if (count % 5 == 0) {
        [_statusField setStringValue:[NSString stringWithFormat:@"%ld samples collected", count]];
    }
}


@end
