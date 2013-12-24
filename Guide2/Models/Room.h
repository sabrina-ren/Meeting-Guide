//
//  MeetingTypeDataController.h
//  Guide
//
//  Created by Jim Ramlall on 2013-05-17.
//  Copyright (c) 2013 Jim Ramlall. All rights reserved.
//

@interface Room : NSObject 

@property (nonatomic, copy) NSString* roomNumber;
@property (nonatomic, copy) NSString* roomName;
@property (nonatomic, copy) NSString* maxCapacity;
@property (nonatomic, copy) UIImage* picture;
@property (nonatomic, copy) NSString* externalPort;
@property (nonatomic, copy) NSString* numPorts;
@property (nonatomic) NSString* index;
@property (nonatomic) NSUInteger buildingId;

- (id)initWithNumber:(NSString*)num;
+ (NSMutableArray*) initializeRoomData;

@end
