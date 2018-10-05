//
//  Preferences.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#if USE_RECEIPT_VALIDATION
#include "ReceiptValidation.m"
#endif

int main(int argc, char *argv[])
{
#if USE_RECEIPT_VALIDATION && !DEBUG
    __block int returnCode = 0;

    ReceiptValidationCheck(^{
        returnCode = NSApplicationMain(argc,  (const char **) argv);
    }, ^{
        returnCode = 173;
        exit(173);
    });
    
    return returnCode;
#else
    return NSApplicationMain(argc,  (const char **) argv);
#endif
}
