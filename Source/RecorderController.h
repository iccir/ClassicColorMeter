//
//  RecorderController.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2015-05-10.
//
//

#import <Foundation/Foundation.h>

@interface RecorderController : NSWindowController

- (void) addSampleWithText:(NSString *)text;

@property (atomic, readonly, getter=isRecording) BOOL recording;

@end
