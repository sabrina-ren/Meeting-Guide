//
//  GuideViewController.m
//  Guide
//
//  Created by Jim Ramlall on 2013-05-21.
//  Copyright (c) 2013 Jim Ramlall. All rights reserved.
//

#import "GuideViewController.h"
#import "DefinitionViewController.h"
#import "RoomViewController.h"
#import "TimerApplication.h"
#import "GuideAppDelegate.h"
#import "Room.h"
#import "MeetingType.h"
#import "MenuViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "PopoverBackgroundView.h"
#import "StepsViewController.h"
#import <sqlite3.h>
#import <SystemConfiguration/SystemConfiguration.h>


@class Room;

@implementation GuideViewController

- (void)viewDidLoad {    
    // Brighten screen (from sleep)
    [[UIScreen mainScreen] setBrightness: 0.6];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.sound = YES;
    awake = YES;

    [super viewDidLoad];
    
    numMeetings = 5;

    // Get stored data
    defaults = [NSUserDefaults standardUserDefaults];
    savedRoom = [defaults objectForKey:@"defaultRoom"];
    savedBuilding = [[defaults objectForKey:@"defaultBuilding"] intValue];
    currentBuilding = savedBuilding;
    externalPort = [defaults objectForKey:@"defaultPort"];
    sound = YES;

    roomDictionaries = [Room initializeRoomData];
    roomStillExists = FALSE;
    for (NSDictionary* dictionary in roomDictionaries) {
        if ([dictionary objectForKey:savedRoom]) roomStillExists = TRUE;
    }
    if (roomStillExists) [roomButton setTitle: savedRoom forState:UIControlStateNormal];
    else [roomButton setTitle:nil forState:UIControlStateNormal];

    
    // If a room was saved, update meetings (else RoomViewController will be opened)
    if (savedRoom && roomStillExists) [self updateMeetingsFor:savedRoom];
    [self initializeMeetingButtons];
    
    for (int i=0; i<numMeetings; i++) { // Add unhighlight function to top issue buttons
        UIButton* temp = [self valueForKey:[NSString stringWithFormat:@"top%i",i]];
        [temp addTarget:self action:@selector(unhighlightTopIssue:) forControlEvents:UIControlEventTouchDragOutside];
    }
    
    // Set notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidTimeout:) name:applicationDidTimeoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidWake:) name:applicationWoke object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationInactive:) name:applicationInactiveNotification object:nil];

    // Init dark screen for when app times out
    darkView = [[UIView alloc] init];
    [darkView setFrame:CGRectMake(0, 0, 1024, 790)];
    [darkView setBackgroundColor:[UIColor blackColor]];
    darkView.alpha = 0.8;
    
    // Set navigation bar appearance
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
//    [[UIBarButtonItem appearance] setTintColor:[UIColor grayColor]];
    
    grayColour = [UIColor colorWithHue:0 saturation:0 brightness:0.8 alpha:1];
    menuColour = [UIColor colorWithRed:136/255.0 green:130/255.0 blue:122/255.0 alpha:1];
    blueColour = [UIColor colorWithRed:162/255.0 green:211/255.0 blue:226/255.0 alpha:1];
    highlight = [UIColor colorWithRed:169/255.0 green:196/255.0 blue:209/255.0 alpha:1];
    
    // Set buttons' title and appearance
    [roomButton setImage:[UIImage imageNamed:@"location.png"] forState:UIControlStateNormal];
    [roomButton setImage:[UIImage imageNamed:@"locationSelected.png"] forState:UIControlStateHighlighted];
    [roomButton setTitleColor:grayColour forState:UIControlStateHighlighted];
    roomButton.titleEdgeInsets = UIEdgeInsetsMake(0, -110, 0, 0); // Position title and image
    roomButton.imageEdgeInsets = UIEdgeInsetsMake(11, 105, 11, 45);
    
    UIButton* mailButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *mailImage = [UIImage imageNamed:@"mail.png"];
    [mailButton setBackgroundImage:mailImage forState:UIControlStateNormal];
    [mailButton setBackgroundImage:[UIImage imageNamed:@"mailSelected.png"] forState:UIControlStateHighlighted];
    [mailButton setTitle:@"Comment" forState:UIControlStateNormal];
    [mailButton setTitleColor:menuColour forState:UIControlStateNormal];
    [mailButton setTitleColor:grayColour forState:UIControlStateHighlighted];
    [mailButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:18.0]];
    mailButton.titleEdgeInsets = UIEdgeInsetsMake(0, -60, 0, 0); // Offset title from image
    [mailButton addTarget:self action:@selector(openMail:) forControlEvents:UIControlEventTouchUpInside];
    mailButton.frame = CGRectMake(0, 0, mailImage.size.width/3, mailImage.size.height/3); // Frame needs to be set for button to appear, based on image size
    UIBarButtonItem *mailItem = [[UIBarButtonItem alloc] initWithCustomView:mailButton]; // Creates bar button item
    
    UIButton* questionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage* questionImage = [UIImage imageNamed:@"question.png"];
    [questionButton setBackgroundImage:questionImage forState:UIControlStateNormal];
    [questionButton setBackgroundImage:[UIImage imageNamed:@"questionSelected"] forState:UIControlStateHighlighted];
    [questionButton setTitle:@"Help" forState:UIControlStateNormal];
    [questionButton setTitleColor:menuColour forState:UIControlStateNormal];
    [questionButton setTitleColor:grayColour forState:UIControlStateHighlighted];
    [questionButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:18.0]];
    questionButton.titleEdgeInsets = UIEdgeInsetsMake(0,-20, -2, 0);
    [questionButton addTarget:self action:@selector(openHelp:) forControlEvents:UIControlEventTouchUpInside];
    questionButton.frame = CGRectMake(0, 0, questionImage.size.width/2.5, questionImage.size.height/3); // Based on image size
    UIBarButtonItem* questionItem = [[UIBarButtonItem alloc] initWithCustomView:questionButton];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:questionItem, mailItem, nil];
}

- (void) viewDidAppear:(BOOL)animated {
    // If there is no saved room and no title, open room view controller
    if ([roomButton titleForState:UIControlStateNormal]==nil || !roomStillExists) {
        [self chooseRoom:nil]; // doesn't work if put anywhere else
    }
}

- (void) initializeMeetingButtons {
    for (int i=0; i<numMeetings; i++) {
        UIButton* temp = [self valueForKey:[NSString stringWithFormat:@"meetingName%i", i]];
        temp.tag = i;
        temp.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        temp.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        [temp setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [temp setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    }
}

- (void) updateMeetingsFor: (NSString*) room { // Update available meetings and top issues
    meetingArray = [[NSMutableArray alloc]init];
    meetingArray = [MeetingType initMeetingData:room]; // Array of meetingType objects
    for (int i=0; i<numMeetings; i++) {
        UIButton* temp = [self valueForKey:[NSString stringWithFormat:@"meetingName%i", i]];
        
        if ([meetingArray[i] isAvailable]) {
            [temp setTitle:[meetingArray[i] name] forState:UIControlStateNormal];
            [temp setBackgroundColor:[meetingArray[i] meetingColour]];
            ((UIButton*)[self valueForKey:[NSString stringWithFormat:@"i%i",i]]).alpha = 0.5;
            temp.enabled = YES;
        }
        else {
            [temp setTitle:[NSString stringWithFormat:@"%@\nunavailable",[meetingArray[i] name]] forState:UIControlStateDisabled];
            [temp setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
            [temp setBackgroundColor:[UIColor colorWithHue:0 saturation:0 brightness:0.9 alpha:1]];
            ((UIButton*)[self valueForKey:[NSString stringWithFormat:@"i%i",i]]).alpha = 0.9;
            temp.titleLabel.numberOfLines = 2;
            temp.enabled = NO;
        }
    }
    [self updateTopIssuesFor:room];
}

- (void) updateTopIssuesFor: (NSString*) room {

    if ([meetingArray[4] isAvailable]) topIssuesId = @"T2"; // Find top issues for VTC if available
    else topIssuesId = @"T1"; // Else find for Live Meeting
    
    sqlite3 *roomDB = nil;
    if (sqlite3_open([[[NSBundle mainBundle] pathForResource:@"MeetingRoom_db" ofType:@"sqlite"] UTF8String], &roomDB) == SQLITE_OK) {
        
        NSString* sqlStr = [NSString stringWithFormat:@"SELECT DISTINCT option FROM troubleshoot LEFT JOIN roomPackage ON roomPackage.packageId = optionId WHERE (roomPackage.packageId = optionId AND roomPackage.roomId = %@) OR optionId = '%@' ORDER BY rank", roomButton.titleLabel.text, topIssuesId];
        const char *sql = [sqlStr UTF8String];
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(roomDB, sql , -1, &selectstmt, NULL) == SQLITE_OK) {
            for (int i=0; i<5; i++) {
                UIButton* temp =  [self valueForKey:[NSString stringWithFormat:@"top%i", i]];
                temp.tag = i;
                
                if ((sqlite3_step(selectstmt)) == SQLITE_ROW) {
                    [temp setTitle: [NSString stringWithUTF8String:(char*)sqlite3_column_text(selectstmt, 0)] forState:UIControlStateNormal];
                    temp.enabled = YES;
                }
                else {
                    [temp setTitle:@"" forState:UIControlStateNormal];
                    temp.enabled = NO;
                }
            }
            
            sqlite3_reset(selectstmt);
            sqlite3_finalize(selectstmt);
        } else NSLog(@"error: %s\n", sqlite3_errmsg(roomDB));
    }
    sqlite3_close(roomDB);
}

- (IBAction)highlightTopIssue:(id)sender {

    for (int i=0; i<5; i++) {
        UIButton* temp = [self valueForKey:[NSString stringWithFormat:@"top%i",i]];
        temp.backgroundColor = blueColour;
    }
    ((UIButton*) sender).backgroundColor = highlight;
}

- (void) unhighlightTopIssue: (UIButton*) button {
    [button setBackgroundColor:blueColour];
}

- (IBAction)chooseRoom:(id)sender {
    roomViewController = (RoomViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"a"];
    roomViewController.delegate = self;
    roomViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    roomViewController.buildingRooms = roomDictionaries;
    roomViewController.chosenRoom = [[Room alloc] init];
    roomViewController.chosenRoom.roomNumber = [roomButton titleForState:UIControlStateNormal];
    roomViewController.chosenBuilding = currentBuilding;
    roomViewController.isLocked = (savedRoom!=nil);
    roomViewController.savedRoom = savedRoom;
    roomViewController.savedBuilding = savedBuilding;
    
    NSLog(@"chosen room number %@", [roomButton titleForState:UIControlStateNormal]);
    NSLog(@"saved room %@", savedRoom);
    NSLog(@"chosen building %i", currentBuilding);
    
    [self presentViewController:roomViewController animated:YES completion:nil];
}

- (void)viewController:(RoomViewController *)controller didChooseRoom:(NSString*)item inBuilding:(int)building withPort:(NSString*)port {
    // RoomView protocol
    roomStillExists = YES;
    currentBuilding = building;
    [roomButton setTitle:item forState:UIControlStateNormal];
    externalPort = port; // Saved for hardware setup
    [self updateMeetingsFor: item];
    savedRoom = [defaults objectForKey:@"defaultRoom"];

    [self dismissViewControllerAnimated:YES completion: nil];
}


- (IBAction)chooseType:(id)sender {
    MenuViewController *menuViewController = (MenuViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"menuView"];
    menuViewController.chosenMeeting = meetingArray[((UIButton*) sender).tag];
    menuViewController.room = roomButton.titleLabel.text;
    menuViewController.externalPort = externalPort;
    menuViewController.menuColour = menuColour;
    menuViewController.navigationItem.rightBarButtonItems = self.navigationItem.rightBarButtonItems;
    
    [[self navigationController] pushViewController:menuViewController animated:YES];
}

- (IBAction)chooseTop:(id)sender {
    StepsViewController *stepsViewController = (StepsViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"stepsView"];
    stepsViewController.colour = blueColour;
    stepsViewController.menuColour = menuColour;
    stepsViewController.highlightColour = highlight;
    stepsViewController.packageId = topIssuesId;
    stepsViewController.option = ((UIButton*) sender).titleLabel.text;
    
    stepsViewController.navigationItem.rightBarButtonItems = self.navigationItem.rightBarButtonItems;

    [[self navigationController] pushViewController:stepsViewController animated:YES];
    [self performSelector: @selector(unhighlightTopIssue:) withObject:sender afterDelay:0.5];
}

- (IBAction) infoButton:(id)sender {

    DefinitionViewController* defController = (DefinitionViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"def"];
    
    // Animate button
    UIButton* infoButton = (UIButton*) sender;
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat:M_PI/4];
    rotationAnimation.duration = 0.3;
    rotationAnimation.cumulative = NO;
    rotationAnimation.fillMode = kCAFillModeForwards;
    rotationAnimation.removedOnCompletion = NO;
    [infoButton.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
    [infoButton.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    
    int i;
    for (i=0; i<numMeetings; i++) {
        if (sender==[self valueForKey:[NSString stringWithFormat:@"i%i",i]]) {
            break;
        }
    }
    defController.typeName = ((MeetingType*) meetingArray[i]).name;
    defController.nameColour = [meetingArray[i] meetingColour];
    
    // Format definition
    NSArray *defLine = [[NSArray alloc] initWithArray:[((NSString*)((MeetingType*) meetingArray[i]).description) componentsSeparatedByString:@";;"]]; // Array of definition points
    
    int lineCount = 0;
    int maxCharLength = 50;

    
    defController.definition = [[NSMutableString alloc] init];
    
    for (int i=0; i<defLine.count; i++) {
        lineCount++; // Each point is min one line
        
        NSMutableString *temp = [[NSMutableString alloc] initWithString:defLine[i]]; // Create mutable string from point
        if (i==0) [temp insertString:@" " atIndex:0];
        
        [temp insertString:@"\n- " atIndex:0]; // Insert dash at beginning
        
        if (temp.length > maxCharLength) {
            int j = maxCharLength;
            while ([temp characterAtIndex:j]!=' ') j--; // Work backwards until a space is found
            [temp insertString:@"\n  " atIndex:j]; // New line at space
            lineCount++; // Increase line count
        }
        [defController.definition appendString:temp];
    }
    
    int lineHeight = 24;
    int popoverWidth = 450;
    int popoverHeightPadding = 62;
    
    defController.infoButton = infoButton;
    defController.textHeight = lineHeight*lineCount;
    CGSize size = CGSizeMake(popoverWidth, popoverHeightPadding + defController.textHeight);
    
    self.pop = [[UIPopoverController alloc] initWithContentViewController:defController];
    [self.pop setPopoverContentSize:size];
    self.pop.popoverBackgroundViewClass = [PopoverBackgroundView class];
    [self.pop presentPopoverFromRect:[sender frame] inView:self.view permittedArrowDirections:(UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown) animated:YES];
}

- (IBAction)openHelp:(id)sender {
    UIViewController* helpController = (UIViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"help"];

    self.pop = [[UIPopoverController alloc] initWithContentViewController:helpController];
    [self.pop setPopoverContentSize:CGSizeMake(460, 170)];
    self.pop.popoverBackgroundViewClass = [PopoverBackgroundView class];
    
    [self.pop presentPopoverFromRect:CGRectMake(self.view.frame.size.width - 1, 0, 1, 1) inView:self.navigationController.visibleViewController.view
 permittedArrowDirections:(UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown) animated:YES];
}

- (IBAction)openMail:(id)sender {
    
    if (![MFMailComposeViewController canSendMail]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Mail Account"
                                                        message:@"Go to Settings to set up your Mail account"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        [mailer setSubject:[NSString stringWithFormat:@"Feedback Message from Room %@", roomButton.titleLabel.text]];
        [mailer setToRecipients:[NSArray arrayWithObject:@"DesktopLab.A.CA@gsk.com"]];
        [mailer setMessageBody:@"Name: \n\nFeedback:" isHTML:NO];
        
        [[mailer navigationBar] setTintColor:[UIColor whiteColor]];
        [[UIBarButtonItem appearance] setTintColor:[UIColor lightGrayColor]];
        [mailer setModalPresentationStyle:UIModalPresentationFormSheet];
        mailer.mailComposeDelegate = self;
        
        [self presentViewController:mailer animated:YES completion:nil];
        [self performSelector:@selector(checkInternetConnection) withObject:nil afterDelay:0.5]; // Present mailer first
    }
}

- (void)checkInternetConnection {
    SCNetworkReachabilityFlags flags;
    BOOL receivedFlags;
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(CFAllocatorGetDefault(), [@"www.google.com" UTF8String]);
    receivedFlags = SCNetworkReachabilityGetFlags(reachability, &flags);
    CFRelease(reachability);
    
    if (!receivedFlags || (flags == 0)) {
        internetIsAvailable = NO;
        UIAlertView* alert;
        
        alert = [[UIAlertView alloc] initWithTitle:@"No Internet Connection"
                                           message:@"Go to Settings > Wi-Fi and connect to GSK Public Wireless. Your message will be saved in the Outbox."
                                          delegate:nil
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil];
        [alert show];
    }
    else internetIsAvailable = YES;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled: you cancelled the operation and no email message was queued.");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved: you saved the email message in the drafts folder.");
            break;
        case MFMailComposeResultSent:
        {
            if (!internetIsAvailable) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Message Saved in Outbox"
                                                                message:@"No internet connection. Go to Settings > Wi-Fi and connect to GSK Public Wireless to finish sending your message."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            NSLog(@"Mail send: the email message is queued in the Mail outbox. Please ensure internet is connected");
            break;
        }
        case MFMailComposeResultFailed:
            NSLog(@"Mail failed: the email message was not saved or queued.");
            break;
        default:
            NSLog(@"Mail not sent.");
            break;
    }    
    [self dismissViewControllerAnimated:YES completion:nil];
}



- (void)applicationDidTimeout:(NSNotification *) notif {
    awake = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.pop dismissPopoverAnimated:YES];
    sound = YES;

    if (savedRoom){ // Revert to saved room
        [roomButton setTitle:savedRoom forState:UIControlStateNormal];
        [self updateMeetingsFor:savedRoom];
    }

    // Darken screen
    [[UIScreen mainScreen] setBrightness: 0.5];
    [[[self navigationController] view] addSubview:darkView];
}

-(void) applicationDidWake:(NSNotification *) notif  {
    if (!awake) {
        [[UIScreen mainScreen] setBrightness: 0.6];
        [darkView removeFromSuperview];
        if (!savedRoom) [self chooseRoom:nil];
        awake = YES;
    }
}

- (void)applicationInactive:(NSNotification *) notif {
    // Unhighlight buttons if user four finger pinches halfway
    for (int i=0; i<5; i++) {
        UIButton* temp = [self valueForKey:[NSString stringWithFormat:@"top%i",i]];
        temp.backgroundColor = blueColour;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end








