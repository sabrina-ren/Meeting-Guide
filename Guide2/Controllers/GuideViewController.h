//
//  GuideViewController.h
//  Guide
//
//  Created by Jim Ramlall on 2013-05-21.
//  Copyright (c) 2013 Jim Ramlall. All rights reserved.
//

// Main Home Page

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "RoomViewController.h"
@class GuideAppDelegate;


@interface GuideViewController : UIViewController <RoomViewControllerDelegate, MFMailComposeViewControllerDelegate> {
    GuideAppDelegate* appDelegate;
    
    int numMeetings;
    __weak IBOutlet UIButton* i0;
    __weak IBOutlet UIButton* i1;
    __weak IBOutlet UIButton* i2;
    __weak IBOutlet UIButton* i3;
    __weak IBOutlet UIButton* i4;
    
    __weak IBOutlet UIButton* meetingName0;
    __weak IBOutlet UIButton* meetingName1;
    __weak IBOutlet UIButton* meetingName2;
    __weak IBOutlet UIButton* meetingName3;
    __weak IBOutlet UIButton* meetingName4;
    
    __weak IBOutlet UIButton* top0;
    __weak IBOutlet UIButton* top1;
    __weak IBOutlet UIButton* top2;
    __weak IBOutlet UIButton* top3;
    __weak IBOutlet UIButton* top4;
    
    __weak IBOutlet UIButton* roomButton;
    
    RoomViewController *roomViewController;
        
    NSUserDefaults* defaults;
    UIView* darkView;
    BOOL awake;
    
    NSMutableArray* meetingArray;
    NSMutableArray* roomDictionaries;
    NSString* externalPort;
    NSString* topIssuesId;
    
    UIColor* highlight;
    UIColor* blueColour;
    UIColor* grayColour;
    UIColor* menuColour;
    
    NSString* chosenType;
    NSString* savedRoom;
    int currentBuilding;
    int savedBuilding;
    
    BOOL internetIsAvailable;
    BOOL roomStillExists;
    
    BOOL sound;
}

@property (nonatomic) UIPopoverController *pop;

- (IBAction)highlightTopIssue:(id)sender;
- (IBAction)chooseRoom:(id)sender;
- (IBAction)chooseType:(id)sender;
- (IBAction)chooseTop:(id)sender;
- (IBAction)infoButton:(id)sender;
- (IBAction)openMail:(id)sender;

@end
