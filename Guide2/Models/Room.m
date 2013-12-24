//
//  MeetingTypeDataController.m
//  Guide
//
//  Created by Jim Ramlall on 2013-05-17.
//  Copyright (c) 2013 Jim Ramlall. All rights reserved.
//

#import "Room.h"
#import <sqlite3.h>

@implementation Room

@synthesize roomNumber, picture;

- (id) initWithNumber:(NSString* )num {
    self = [super init];
    roomNumber = num;
    return self;
}

- (id)init {
    if (self = [super init]) {
        self = [self initWithNumber:0];
        return self;
    }
    return nil;
}

+ (NSMutableArray*) initializeRoomData {
    NSMutableArray *buildingRooms = [[NSMutableArray alloc] init];
//    [buildingRooms addObject:[[NSMutableDictionary alloc]init]]; // To return to view controller
    
    sqlite3 *roomDB = nil;
    
    if (sqlite3_open([[[NSBundle mainBundle] pathForResource:@"MeetingRoom_db" ofType:@"sqlite"] UTF8String], &roomDB) == SQLITE_OK) {
        const char *sql = "SELECT room.id, room.name, room.maxCapacity, room.numPorts, room.picture, room.externalPort, room.buildingId FROM room ORDER BY room.buildingId";
        sqlite3_stmt *selectstmt;
        if (sqlite3_prepare_v2(roomDB, sql , -1, &selectstmt, NULL) == SQLITE_OK) {
            int i=0;
            int prevBuildingId = -1;
            while((sqlite3_step(selectstmt)) == SQLITE_ROW) {
                NSString* number = [NSString stringWithFormat:@"%d", sqlite3_column_int(selectstmt, 0)];
               
                // Create room object, set properties
                Room *roomObj = [[Room alloc] initWithNumber:number];
                roomObj.roomName = [NSString stringWithUTF8String:(char*)sqlite3_column_text(selectstmt, 1)];
                roomObj.maxCapacity = [NSString stringWithFormat:@"%d", sqlite3_column_int(selectstmt, 2)];
                roomObj.numPorts = [NSString stringWithFormat:@"%d", sqlite3_column_int(selectstmt, 3)];
                
                // Set room picture
                NSData *data = [[NSData alloc] initWithBytes:sqlite3_column_blob(selectstmt, 4) length:sqlite3_column_bytes(selectstmt, 4)];
                if(data == nil) NSLog(@"No image found.");
                else roomObj.picture = [UIImage imageWithData:data];
                
                // Set external port
                if (sqlite3_column_text(selectstmt, 5)) {
                    roomObj.externalPort = [NSString stringWithUTF8String:(char*)sqlite3_column_text(selectstmt,5)];
                }
                

                roomObj.buildingId = sqlite3_column_int(selectstmt, 6);
                
                if (roomObj.buildingId != prevBuildingId) {
                    prevBuildingId = roomObj.buildingId;
                    [buildingRooms addObject:[[NSMutableDictionary alloc] init]];
                    i = 0;
//                    [[buildingRooms lastObject] setObject: roomObj forKey:roomObj.roomNumber];
                }
                roomObj.index = [NSString stringWithFormat:@"%i",i]; // For saving default data

                [[buildingRooms lastObject] setObject: roomObj forKey:roomObj.roomNumber];

//                [roomDictionary setObject:roomObj forKey:roomObj.roomNumber];
                i++;
            }
            sqlite3_reset(selectstmt);
            sqlite3_finalize(selectstmt);
            
        } else NSLog(@"error: %s\n",sqlite3_errmsg(roomDB));
    }
    sqlite3_close(roomDB);
    
    NSLog(@"Initialized room array");
    return buildingRooms;
}

@end
