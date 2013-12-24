//
//  MenuViewController.h
//  Guide
//
//  Created by Sabrina Ren on 2013-05-26.
//  Copyright (c) 2013 Jim Ramlall. All rights reserved.
//

// Meeting Menu View

#import <UIKit/UIKit.h>
#import "MeetingType.h"
#import <MessageUI/MessageUI.h>


@interface MenuViewController : UIViewController <MFMailComposeViewControllerDelegate> {
    __weak IBOutlet UIScrollView* scroll;
    __weak IBOutlet UIButton* titleMeeting;
    __weak IBOutlet UIButton* roundSwitch;
    __weak IBOutlet UIButton* attendeeButton;
    __weak IBOutlet UIButton* presenterButton;

    NSMutableArray* groupButtons;
    NSMutableArray* optionButtons;
    NSMutableArray* menuPackages;
    NSMutableArray* presenterItems;
    
    UIColor* highlightColour;
    
    BOOL isPresenter;
    int menuType;
    
    UIButton* backButton;
}

@property (weak, nonatomic) MeetingType* chosenMeeting;
@property (weak, nonatomic) NSString*room;
@property (weak, nonatomic) NSString* externalPort;
@property (nonatomic) UIColor* menuColour;

- (IBAction)chooseGroup:(id)sender;
- (IBAction)touchDownMenu:(id)sender;
- (IBAction)roleSwitch:(id)sender;
- (IBAction)swipeRight:(id)sender;
- (IBAction)dragOut:(id)sender;

@end
