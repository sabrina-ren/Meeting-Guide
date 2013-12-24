//
//  MeetingType.h
//  Guide
//
//  Created by Jim Ramlall on 2013-05-17.
//  Copyright (c) 2013 Jim Ramlall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface MeetingType : NSObject

@property (nonatomic, copy) NSString* meetingId;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* description;
@property (nonatomic) BOOL isAvailable;
@property (nonatomic, copy) UIColor* meetingColour;

- (id) initWithName: (NSString*) name;
+ (NSMutableArray*) initMeetingData: (NSString*) room;

@end
