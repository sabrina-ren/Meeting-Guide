//
//  MeetingType.m
//  Guide
//
//  Created by Jim Ramlall on 2013-05-17.
//  Copyright (c) 2013 Jim Ramlall. All rights reserved.
//

#import "MeetingType.h"
@class Room;

@implementation MeetingType
@synthesize isAvailable;

- (id)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = name;
        isAvailable = NO;
        return self;
    }
    return nil;
}

+ (NSMutableArray*) initMeetingData:(NSString*) room {
    NSLog(@"Initializing meeting data");
    
    NSMutableArray *meetingArray = [[NSMutableArray alloc]init];
    sqlite3 *roomDB = nil;
    NSString* databasePath = [[NSBundle mainBundle] pathForResource:@"MeetingRoom_db" ofType:@"sqlite"];
    
    if (sqlite3_open([databasePath UTF8String], &roomDB) == SQLITE_OK) {
        
        // Create meeting objects for all meeting types from database
        NSString* sqlStr = @"SELECT meeting.name, meeting.id, meeting.description, meeting.colour FROM meeting ORDER BY meeting.name ASC";
        const char *sql = [sqlStr UTF8String];
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(roomDB, sql , -1, &selectstmt, NULL) == SQLITE_OK) {
            while((sqlite3_step(selectstmt)) == SQLITE_ROW) {
                
                MeetingType *meetingObj = [[MeetingType alloc] initWithName:[NSString stringWithUTF8String: (char*)sqlite3_column_text(selectstmt, 0)]];
                meetingObj.meetingId = [NSString stringWithUTF8String:(char*)sqlite3_column_text(selectstmt, 1)];
                meetingObj.description = [NSString stringWithUTF8String:(char*)sqlite3_column_text(selectstmt, 2)];
                
                NSString *colour = [NSString stringWithUTF8String:(char*)sqlite3_column_text(selectstmt, 3)];
                NSArray *rgb = [colour componentsSeparatedByString:@" "];
                meetingObj.meetingColour = [UIColor colorWithRed:[rgb[0] floatValue]/255.0 green:[rgb[1] floatValue]/255.0 blue:[rgb[2] floatValue]/255.0 alpha:1];
                
                [meetingArray addObject:meetingObj];
            }
            sqlite3_reset(selectstmt);
            sqlite3_finalize(selectstmt);
            
        } else NSLog(@"error: %s\n",sqlite3_errmsg(roomDB));
        
        // Find available meetings for selected room
        sqlStr = [NSString stringWithFormat:@"SELECT meeting.name FROM meeting JOIN meetingPackage ON meeting.id = meetingPackage.meetingId JOIN roomPackage ON meetingPackage.packageId = roomPackage.packageId WHERE meetingPackage.required=1 AND roomPackage.roomId = %@ ORDER BY meeting.name ASC", room];
        sql = [sqlStr UTF8String];
        
        if (sqlite3_prepare_v2(roomDB, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            int i=0;
            while((sqlite3_step(selectstmt)) == SQLITE_ROW) {
                NSString *type = [NSString stringWithUTF8String:(char*)sqlite3_column_text(selectstmt, 0)];
                NSLog(@"database type: %@",type);
                NSLog(@"meeting array type: %@",((MeetingType*)meetingArray[i]).name);
                
                // Go through list of all meeting types until match is found
                while (![((MeetingType*)meetingArray[i]).name isEqualToString:type]) {
                    i++;
                }
                // Set this meeting type to be available
                ((MeetingType*)meetingArray[i]).isAvailable = YES;
                
                i++;
                
            }
            sqlite3_reset(selectstmt);
            sqlite3_finalize(selectstmt);
            
        } else NSLog(@"Error: %s\n", sqlite3_errmsg(roomDB));
        
    } else NSLog(@"Error: %s\n", sqlite3_errmsg(roomDB));
    
    sqlite3_close(roomDB);
    return meetingArray;
}

@end
