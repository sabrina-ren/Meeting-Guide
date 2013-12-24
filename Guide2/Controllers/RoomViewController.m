//
//  PopoverViewController.m
//  Guide2
//
//  Created by Jim Ramlall on 2013-05-21.
//  Copyright (c) 2013 Jim Ramlall. All rights reserved.
//

#import "RoomViewController.h"
#import "Room.h"
#import <sqlite3.h>
#import <QuartzCore/QuartzCore.h>


@implementation RoomViewController

@synthesize delegate, buildingRooms, chosenRoom, savedRoom, isLocked, chosenBuilding, savedBuilding;

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self initializeBuildingData];

    roomKeys = [[NSMutableArray alloc] init];

    [picker setDelegate:self];
    [picker setDataSource:self];
    
    for (NSMutableDictionary* roomDictionary in buildingRooms) {
        NSArray *keys = [roomDictionary allKeys];
        [roomKeys addObject:[keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
    }
    
    if (!chosenRoom.roomNumber || buildingIndex >= buildingRooms.count){
        buildingIndex = 0;
        chosenRoom.roomNumber = [roomKeys[0] objectAtIndex:0];
        NSLog(@"no chosen room, defaulting to: %@", [roomKeys[0] objectAtIndex:0]);
    }
    chosenRoom = [[buildingRooms objectAtIndex:buildingIndex] objectForKey:chosenRoom.roomNumber];
    
    [picker selectRow:buildingIndex inComponent:0 animated:YES];
    [picker selectRow:[chosenRoom.index integerValue] inComponent:1 animated:YES];
    
    [image setImage: chosenRoom.picture];
    [numLabel setText: [NSString stringWithFormat:@"Room %@", chosenRoom.roomNumber]];
    [nameLabel setText: chosenRoom.roomName];
    [capacityLabel setText: [NSString stringWithFormat:@"Capacity: %@", chosenRoom.maxCapacity]];
    [numPortsLabel setText: [NSString stringWithFormat:@"Ethernet Ports: %@", chosenRoom.numPorts]];

    if (chosenRoom.externalPort) [externalLabel setText: [NSString stringWithFormat:@"External: %@", chosenRoom.externalPort]];
    else [externalLabel setText:@"No external ports"];

    if (isLocked && ([savedRoom isEqualToString:chosenRoom.roomNumber]))
        [lockImage setImage:[UIImage imageNamed:@"savedRoom.jpg"] forState:UIControlStateNormal];
    else if (isLocked) [lockImage setImage:[UIImage imageNamed:@"locked.jpg"] forState:UIControlStateNormal];
    
    UIImage* doneImage = [UIImage imageNamed:@"x.png"];
    [doneButton setBackgroundImage:doneImage forState:UIControlStateNormal];
    [doneButton setBackgroundImage:[UIImage imageNamed:@"xSelected.png"] forState:UIControlStateHighlighted];
    doneButton.frame = CGRectMake(0, 0, doneImage.size.width/3, doneImage.size.height/3);
    
    NSLog(@"RoomView Loaded");
}

- (void)initializeBuildingData {
    buildingNames = [[NSMutableArray alloc] init];
    sqlite3 *roomDB = nil;
    
    if (sqlite3_open([[[NSBundle mainBundle] pathForResource:@"MeetingRoom_db" ofType:@"sqlite"] UTF8String], &roomDB) == SQLITE_OK) {
        const char *sql = "SELECT DISTINCT room.buildingId, building.name FROM room JOIN building ON room.buildingId = building.Id";
        sqlite3_stmt *selectstmt;
        if (sqlite3_prepare_v2(roomDB, sql , -1, &selectstmt, NULL) == SQLITE_OK) {
            while((sqlite3_step(selectstmt)) == SQLITE_ROW) {
                NSString* name = [NSString stringWithFormat:@"%d - %s", sqlite3_column_int(selectstmt, 0), sqlite3_column_text(selectstmt, 1)];
                
                if ([[name substringToIndex:1] intValue] == chosenBuilding) buildingIndex = buildingNames.count;
                
                [buildingNames addObject:name];
            }
            sqlite3_reset(selectstmt);
            sqlite3_finalize(selectstmt);
        } else NSLog(@"error: %s\n",sqlite3_errmsg(roomDB));
    }
    sqlite3_close(roomDB);
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (component == 0) return buildingNames.count;
    else {
        return [[roomKeys objectAtIndex:buildingIndex] count];
    }
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    // Component 0
    [(UIView*)[[picker subviews] objectAtIndex:0] setHidden:YES]; // background
    [(UIView*)[[picker subviews] objectAtIndex:1] setHidden:YES]; // wheel shadow
    
    UIView * viewForPickerView = [[UIView alloc]initWithFrame:CGRectMake(0.0, 0.0, 300.0, 216.0)];
    [viewForPickerView setBackgroundColor:[UIColor colorWithHue:0 saturation:0 brightness:0.98 alpha:1]];
    [[[picker subviews] objectAtIndex:2] addSubview:viewForPickerView]; // background & border

    [(UIView*)[[picker subviews] objectAtIndex:3] setHidden:YES]; // selector tint, 4: text
    ((UIView*)[[picker subviews] objectAtIndex:5]).alpha = 0.1; // wheel shadow
    ((UIView*)[[picker subviews] objectAtIndex:6]).alpha = 0.6; // selector
    
    // Component 1
    [(UIView*)[[picker subviews] objectAtIndex:7] setHidden:YES]; // background & border 
    
    UIView * viewForComponent2 = [[UIView alloc]initWithFrame:CGRectMake(0.0, 0.0, 175.0, 216.0)];
    [viewForComponent2 setBackgroundColor:[UIColor colorWithHue:0 saturation:0 brightness:0.98 alpha:1]];
    [[[picker subviews] objectAtIndex:8] addSubview:viewForComponent2]; // background & border
    
    [(UIView*)[[picker subviews] objectAtIndex:9] setHidden:YES]; // selector tint, 10: text
    ((UIView*)[[picker subviews] objectAtIndex:11]).alpha = 0.1; // wheel shadow
    ((UIView*)[[picker subviews] objectAtIndex:12]).alpha = 0.6; // selector
    [(UIView*)[[picker subviews] objectAtIndex:13] setHidden:YES];
    [(UIView*)[[picker subviews] objectAtIndex:14] setHidden:YES];
    
    if (component == 0) return [buildingNames objectAtIndex:row];
    else {
        return [NSString stringWithFormat:@" %@",[roomKeys[buildingIndex] objectAtIndex:row]];
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (component == 0) {
        buildingIndex = row;
        [picker reloadComponent:1];
        [picker selectRow:0 inComponent:1 animated:YES];
        [self reloadInformationForRow:0];
    }
    else {
        [self reloadInformationForRow:row];
    }
}

- (void)reloadInformationForRow:(int) row {
    chosenRoom = [buildingRooms[buildingIndex] objectForKey:[roomKeys[buildingIndex]objectAtIndex:row] ];

    [numLabel setText: [NSString stringWithFormat:@"Room %@", chosenRoom.roomNumber]];
    [nameLabel setText: chosenRoom.roomName];
    [capacityLabel setText: [NSString stringWithFormat:@"Capacity: %@", chosenRoom.maxCapacity]];
    [numPortsLabel setText: [NSString stringWithFormat:@"Ethernet Ports: %@", chosenRoom.numPorts]];
    
    [image setImage: chosenRoom.picture];
    if (chosenRoom.externalPort) [externalLabel setText: [NSString stringWithFormat:@"External: %@", chosenRoom.externalPort]];
    else [externalLabel setText:@"No external ports"];
    
    if (isLocked && ([savedRoom isEqualToString:chosenRoom.roomNumber]))
        [lockImage setImage:[UIImage imageNamed:@"savedRoom.jpg"] forState:UIControlStateNormal];
    else if (isLocked) [lockImage setImage:[UIImage imageNamed:@"locked.jpg"] forState:UIControlStateNormal];
}

- (IBAction)lock:(id)sender {
     NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (isLocked && (savedRoom==chosenRoom.roomNumber)) {
        isLocked = NO;
        savedRoom = nil;
        [defaults setObject:nil forKey:@"defaultRoom"];
        [defaults setObject:nil forKey:@"defaultBuilding"];
        [defaults setObject:nil forKey:@"defaultPort"];
        [lockImage setImage:[UIImage imageNamed:@"unlocked.jpg"] forState:UIControlStateNormal];
    }
    
    else {                
        [defaults setObject:[buildingNames[buildingIndex] substringToIndex:1] forKey:@"defaultBuilding"];
        [defaults setObject:chosenRoom.roomNumber forKey:@"defaultRoom"];
        [defaults setObject: chosenRoom.index forKey:@"defaultIndex"];
        [defaults setObject:chosenRoom.externalPort forKey:@"defaultPort"];
        
        NSLog(@"Data saved");
        
        savedRoom = chosenRoom.roomNumber;
        savedBuilding = [[buildingNames[buildingIndex] substringToIndex:1] intValue];
        isLocked = YES;
        [lockImage setImage:[UIImage imageNamed:@"savedRoom.jpg"] forState:UIControlStateNormal];
    }
    [defaults synchronize];
    NSString* testing = [defaults objectForKey:@"defaultRoom"];
    NSLog(@"default room saved as %@", testing);
}

- (IBAction)goBackToView:(id)sender {
    [self.delegate viewController:self didChooseRoom:chosenRoom.roomNumber inBuilding:[[buildingNames[buildingIndex] substringToIndex:1] intValue] withPort:chosenRoom.externalPort];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component{
    switch (component) {
        case 0:
            return 300;
        case 1:
            return 175;
    }
    return 0;
}

@end
