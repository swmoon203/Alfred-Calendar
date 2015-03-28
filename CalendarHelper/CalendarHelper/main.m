//
//  main.m
//  CalendarHelper
//
//  Created by mtjddnr on 2015. 3. 28..
//  Copyright (c) 2015년 smoon.kr. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
        for (int i = 0; i < argc; i++) {
            NSString *key = [NSString stringWithUTF8String:argv[i]];
            if ([[key substringToIndex:1] isEqualToString:@"-"] && i+1 < argc) {
                [arguments setObject:[NSString stringWithUTF8String:argv[++i]] forKey:[key substringFromIndex:1]];
            }
        }
        NSApplication *application = [NSApplication sharedApplication];
        AppDelegate *app = [[AppDelegate alloc] init];
        application.delegate = app;
        app.arguments = arguments;
        [application run];
    }
}
