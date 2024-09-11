// (c) 2015-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>

@interface RecorderController : NSWindowController

- (void) addSampleWithText:(NSString *)text;

@property (atomic, readonly, getter=isRecording) BOOL recording;

@end
