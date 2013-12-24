//
//  PopoverViewController.h
//  Guide2
//
//  Created by Jim Ramlall on 2013-05-21.
//  Copyright (c) 2013 Jim Ramlall. All rights reserved.
//

// Room Selection View

#import <UIKit/UIKit.h>

@class Room;
@class RoomViewController;

@protocol RoomViewControllerDelegate <NSObject>
- (void)viewController:(RoomViewController *)controller didChooseRoom:(NSString*)room inBuilding:(int)building withPort:(NSString*)port;
@end

@interface RoomViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource> {
    IBOutlet UILabel *numLabel;
    IBOutlet UILabel *nameLabel;
    IBOutlet UILabel *capacityLabel;
    IBOutlet UILabel *numPortsLabel;
    IBOutlet UILabel *externalLabel;
    __weak IBOutlet UIButton *doneButton;
    
    __weak IBOutlet UIButton *lockImage;
    __weak IBOutlet UIImageView *image;
    __weak IBOutlet UIPickerView *picker;
    
    NSMutableArray *meetingRooms;
    NSMutableArray *roomKeys;
    NSMutableArray *buildingNames;
    
    int buildingIndex;
}

@property (nonatomic) NSMutableArray* buildingRooms;
@property (strong, nonatomic) Room* chosenRoom;
@property (nonatomic) int chosenBuilding;
@property (nonatomic) BOOL isLocked;
@property (nonatomic) NSString *savedRoom;
@property (nonatomic) int savedBuilding;
@property (nonatomic, weak) id <RoomViewControllerDelegate> delegate;

- (IBAction)lock:(id)sender;
- (IBAction)goBackToView:(id)sender;

@end
