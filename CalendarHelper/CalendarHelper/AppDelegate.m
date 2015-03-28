//
//  AppDelegate.m
//  CalendarHelper
//
//  Created by mtjddnr on 2015. 3. 28..
//  Copyright (c) 2015년 smoon.kr. All rights reserved.
//

#import "AppDelegate.h"
#import <EventKit/EventKit.h>

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityMaskEvent];
    EKEventStore *store = [[EKEventStore alloc] init];
    
    switch (status) {
        case EKAuthorizationStatusNotDetermined: {
            [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
                if (granted == NO) exit(0);
                [self search:self.arguments[@"search"] withStore:store];
            }];
            break;
        }
        case EKAuthorizationStatusAuthorized: {
            [self search:self.arguments[@"search"] withStore:store];
            break;
        }
        default: {
            NSLog(@"Not authorized");
            exit(0);
            break;
        }
    }
}

- (void)search:(NSString *)keyword withStore:(EKEventStore *)store {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *startComponents = [[NSDateComponents alloc] init];
    if (self.arguments[@"syear"]) startComponents.year = [self.arguments[@"syear"] integerValue];
    if (self.arguments[@"smonth"]) startComponents.month = [self.arguments[@"smonth"] integerValue];
    if (self.arguments[@"sday"]) startComponents.day = [self.arguments[@"sday"] integerValue];

    if (!(self.arguments[@"syear"] || self.arguments[@"smonth"] || self.arguments[@"sday"])) startComponents.day = -1;
    
    NSDateComponents *endComponents = [[NSDateComponents alloc] init];
    if (self.arguments[@"eyear"]) endComponents.year = [self.arguments[@"eyear"] integerValue];
    if (self.arguments[@"emonth"]) endComponents.month = [self.arguments[@"emonth"] integerValue];
    if (self.arguments[@"eday"]) endComponents.day = [self.arguments[@"eday"] integerValue];
    
    if (!(self.arguments[@"eyear"] || self.arguments[@"emonth"] || self.arguments[@"eday"])) endComponents.year = 1;
    
    // Create the predicate from the event store's instance method
    NSPredicate *predicate = [store predicateForEventsWithStartDate:[calendar dateByAddingComponents:startComponents
                                                                                              toDate:[NSDate date]
                                                                                             options:0]
                                                            endDate:[calendar dateByAddingComponents:endComponents
                                                                                              toDate:[NSDate date]
                                                                                             options:0]
                                                          calendars:nil];
    // Fetch all events that match the predicate
    NSArray *events = [store eventsMatchingPredicate:predicate];
    
    NSXMLElement *root = (NSXMLElement *)[NSXMLNode elementWithName:@"items"];
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithRootElement:root];
    [xmlDoc setVersion:@"1.0"];
    [xmlDoc setStandalone:NO];
    [root addChild:[NSXMLElement elementWithName:@"predicateFormat" stringValue:predicate.predicateFormat]];
    [root addChild:[NSXMLElement elementWithName:@"count" stringValue:[NSString stringWithFormat:@"%lu", (unsigned long)[events count]]]];

    __block BOOL notFound = YES;
    NSLocale *locale = [NSLocale currentLocale];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:@"E MMM d yyyy hh:mm" options:0 locale:locale];
    [dateFormatter setDateFormat:dateFormat];
    [dateFormatter setLocale:locale];
    keyword = [keyword lowercaseString];
    
    NSDateFormatter *argFormat = [[NSDateFormatter alloc] init];
    [argFormat setDateFormat:@"yyyy|!|M|!|d"];
    
    
    NSString *uid = [NSString stringWithFormat:@"%li", (long)[[NSDate date] timeIntervalSince1970]];
    [events enumerateObjectsUsingBlock:^(EKEvent *event, NSUInteger idx, BOOL *stop) {
        
        if ([[event.title lowercaseString] containsString:keyword] || [[event.notes lowercaseString] containsString:keyword]) {
            NSXMLElement *item = (NSXMLElement *)[NSXMLNode elementWithName:@"item"];
            NSString *arg = [NSString stringWithFormat:@"%@|!|%@", event.title, [argFormat stringFromDate:event.startDate]];
            
            [item setAttributesWithDictionary:@{ @"uid": uid, @"valid": @"yes", @"autocomplete": @"", @"arg": arg }];
            
            
            NSString *sub = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:event.startDate]];
            
            [item addChild:[NSXMLElement elementWithName:@"title" stringValue:event.title]];
            [item addChild:[NSXMLElement elementWithName:@"subtitle" stringValue:sub]];
           
            //NSLog(@"%@ -> %@", event.calendarItemIdentifier, event.title);
            
            [root addChild:item];
            notFound = NO;
        }
    }];
    
    printf("%s", [[[NSString alloc] initWithData:[xmlDoc XMLData] encoding:NSUTF8StringEncoding] UTF8String]);
    exit(0);
}
@end

