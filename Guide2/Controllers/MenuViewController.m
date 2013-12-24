//
//  MenuViewController.m
//  Guide
//
//  Created by Sabrina Ren on 2013-05-26.
//  Copyright (c) 2013 Jim Ramlall. All rights reserved.
//

#import "MenuViewController.h"
#import "PopoverBackgroundView.h"
#import "StepsViewController.h"
#import <sqlite3.h>
#import <QuartzCore/QuartzCore.h>
#import "GuideAppDelegate.h"

@implementation MenuViewController
@synthesize chosenMeeting;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [titleMeeting setTitle:chosenMeeting.name forState:UIControlStateNormal];
    titleMeeting.enabled = NO;
    
    [self initMenuItems];
    if (groupButtons.count==1) [self chooseGroup:groupButtons[0]]; // If there is only one group, show group buttons
    
    float h, s, b, a;
    if ([chosenMeeting.meetingColour getHue:&h saturation:&s brightness:&b alpha:&a])
        highlightColour = [UIColor colorWithHue:h saturation:s*0.8 brightness:b*1.03 alpha:0.95];
    
    attendeeButton.hidden = YES;
    presenterButton.hidden = YES;
    roundSwitch.hidden = YES;
    isPresenter = NO;
    [self roleSwitch:nil];
    
    scroll.bounces = YES;
    scroll.pagingEnabled = NO;
    scroll.scrollsToTop = NO;
    scroll.delaysContentTouches = YES;
    
    UIImage* backImage = [UIImage imageNamed:@"back.png"];
    backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setBackgroundImage:backImage forState:UIControlStateNormal];
    [backButton setBackgroundImage:[UIImage imageNamed:@"backSelected.png"] forState:UIControlStateHighlighted];
    backButton.frame = CGRectMake(0, 0, backImage.size.width/1.3, backImage.size.height/1.3);
    [backButton setTitle:@"Home" forState:UIControlStateNormal];
    [backButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:18.0]];
    [backButton setTitleColor:_menuColour forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor colorWithHue:0 saturation:0 brightness:0.8 alpha:1] forState:UIControlStateHighlighted];
    backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    backButton.titleEdgeInsets = UIEdgeInsetsMake(0, 30, 0, 0);
    
    [backButton addTarget:self action:@selector(swipeRight:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.leftBarButtonItem = backItem;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationInactive:) name:applicationInactiveNotification object:nil];
    
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    swipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRecognizer];
}

- (void) initMenuItems {
    groupButtons = [[NSMutableArray alloc] init];
    optionButtons = [[NSMutableArray alloc]init];
    menuPackages = [[NSMutableArray alloc]init];
    presenterItems = [[NSMutableArray alloc]init];
        
    sqlite3 *roomDB = nil;
    if (sqlite3_open([[[NSBundle mainBundle] pathForResource:@"MeetingRoom_db" ofType:@"sqlite"] UTF8String], &roomDB) == SQLITE_OK) {
        
        NSString* sqlStr = [NSString stringWithFormat:@"SELECT DISTINCT package.name, package.id, steps.option FROM package JOIN meetingPackage ON package.id = meetingPackage.packageId JOIN roomPackage ON meetingPackage.packageId = roomPackage.packageId JOIN steps ON roomPackage.packageId = steps.packageId WHERE roomPackage.roomId = %@ AND meetingPackage.meetingId = '%@' ORDER BY package.name, package.id, steps.option", _room, chosenMeeting.meetingId];
        const char *sql = [sqlStr UTF8String];
        sqlite3_stmt *selectstmt;
        
        CGFloat menuOriginX = 20;
        CGFloat menuOriginY = 0;
        CGFloat menuWidth = 397;

        CGFloat optOriginX = 0;
        CGFloat optOriginY = 0;
        CGFloat optWidth = 575;
        CGFloat height = 85;
        
        if (sqlite3_prepare_v2(roomDB, sql , -1, &selectstmt, NULL) == SQLITE_OK) {
            while((sqlite3_step(selectstmt)) == SQLITE_ROW) {
                NSString *packageName = [NSString stringWithUTF8String:(char*)sqlite3_column_text(selectstmt, 0)];
                NSString *packageId = [NSString stringWithUTF8String:(char*)sqlite3_column_text(selectstmt, 1)];
                NSString *optionName = [NSString stringWithUTF8String:(char*)sqlite3_column_text(selectstmt, 2)];
                
                if (![packageName isEqualToString:((UIButton*)[groupButtons lastObject]).titleLabel.text]) {
                    // If starting new menu group
                    UIButton* button = [self buttonWithTitle:packageName andType: @"menu"];
                    button.frame = CGRectMake(menuOriginX, menuOriginY, menuWidth, height);
                    button.bounds = button.frame;
                    button.tag = groupButtons.count;
                    [groupButtons addObject:button];
                    [[self view] addSubview:button];
                    menuOriginY = menuOriginY + height;
                    optOriginY = 0;
                    
                    [menuPackages addObject:[[NSMutableArray alloc] init]];
                    [optionButtons addObject:[[NSMutableArray alloc] init]];
                }

                UIButton *optButton = [self buttonWithTitle:optionName andType:@"option"];
                
                if ([packageId isEqualToString:@"L2"]) {
                    // If object is first presenter item, reset the y-origin
                    if (![[[menuPackages lastObject] lastObject] isEqualToString:packageId]) optOriginY = 0; 
                    [presenterItems addObject:optButton];
                }
                else [[optionButtons lastObject] addObject:optButton];
                
                optButton.frame = CGRectMake(optOriginX, optOriginY, optWidth, height);
                optButton.bounds = optButton.frame;
                optButton.tag = [[menuPackages lastObject] count];
                optOriginY = optOriginY + height;

                [[menuPackages lastObject] addObject:packageId]; // Package id is stored to pass to next view controller
                [scroll addSubview:optButton];
            }
            sqlite3_reset(selectstmt);
            sqlite3_finalize(selectstmt);
        } else NSLog(@"Error: %s\n", sqlite3_errmsg(roomDB));
    }
    sqlite3_close(roomDB);
}

- (UIButton*) buttonWithTitle: (NSString*) title andType: (NSString*) type {
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.contentEdgeInsets = UIEdgeInsetsMake(0, 50, 0, 0);
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    
    [button addTarget:self action:@selector(touchDownMenu:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(dragOut:) forControlEvents:UIControlEventTouchDragExit];
    
    if ([type isEqualToString:@"menu"]) {
        [button setBackgroundColor:chosenMeeting.meetingColour];
        [button.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:28.0]];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(chooseGroup:) forControlEvents:UIControlEventTouchUpInside];
        
        button.exclusiveTouch = YES;
    }
    else {
        [button setBackgroundColor:[UIColor whiteColor]];
        [button.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:24.0]];
        [button setTitleColor: [UIColor grayColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(chooseOption:) forControlEvents:UIControlEventTouchUpInside];
        
        button.exclusiveTouch = YES;
        button.hidden = YES;
    }
    return button;
}

- (IBAction)chooseOption:(id)sender {
    StepsViewController *stepsViewController = (StepsViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"stepsView"];
    
    [sender setHighlighted:YES];
    [sender setSelected:YES];
    
    stepsViewController.packageId = [menuPackages[menuType] objectAtIndex:((UIButton*)sender).tag];
    stepsViewController.option = [sender titleLabel].text;
    stepsViewController.colour = chosenMeeting.meetingColour;
    stepsViewController.highlightColour = highlightColour;
    stepsViewController.externalPort = _externalPort;
    stepsViewController.meeting = chosenMeeting.name;
    stepsViewController.menuColour = _menuColour;
    stepsViewController.navigationItem.rightBarButtonItems = self.navigationItem.rightBarButtonItems;

    [[self navigationController] pushViewController:stepsViewController animated:YES];
    [self performSelector: @selector(unhighlightThis:) withObject:sender afterDelay:0.5];

}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UIButton *button in groupButtons) button.backgroundColor = chosenMeeting.meetingColour;
    for (UIButton *button in optionButtons[menuType]) button.hidden = YES;
    for (UIButton *button in presenterItems) button.hidden = YES;
    attendeeButton.hidden = YES;
    presenterButton.hidden = YES;
    roundSwitch.hidden = YES;
}

- (IBAction)roleSwitch:(id)sender {
    CABasicAnimation *rotateAnimation;
    rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotateAnimation.duration = 0.2;
    rotateAnimation.cumulative = YES;
    rotateAnimation.fillMode = kCAFillModeForwards;
    rotateAnimation.removedOnCompletion = NO;
    [roundSwitch.layer setAnchorPoint:CGPointMake(0.56, 0.5)];
    
    if (isPresenter && sender!=presenterButton) { 
        rotateAnimation.fromValue = [NSNumber numberWithFloat:(-M_PI/4.5)];
        rotateAnimation.toValue = [NSNumber numberWithFloat:0];
        
        isPresenter = NO;
        [presenterButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [attendeeButton setTitleColor:chosenMeeting.meetingColour forState:UIControlStateHighlighted];
        [attendeeButton setTitleColor:chosenMeeting.meetingColour forState:UIControlStateNormal];
        [roundSwitch.layer addAnimation:rotateAnimation forKey:@"rotateAnimation"];
        
    }
    else if (!isPresenter && sender!=attendeeButton){
        rotateAnimation.fromValue = [NSNumber numberWithFloat:0];
        rotateAnimation.toValue = [NSNumber numberWithFloat:(-M_PI/4.5)];
    
        isPresenter = YES;
        [attendeeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [presenterButton setTitleColor:chosenMeeting.meetingColour forState:UIControlStateNormal];
        [presenterButton setTitleColor:chosenMeeting.meetingColour forState:UIControlStateHighlighted];
        [roundSwitch.layer addAnimation:rotateAnimation forKey:@"rotateAnimation"];
    }
    if (sender!=nil)[self chooseGroup:groupButtons[1]];
}

- (IBAction)touchDownMenu:(id)sender {
    if ([groupButtons containsObject:sender]) {
        for (UIButton *temp in groupButtons) {
            temp.backgroundColor = highlightColour;
        }
    }
    else for (UIButton *temp in optionButtons[menuType]) {
        temp.backgroundColor = [UIColor whiteColor];
    }
    [sender setBackgroundColor:chosenMeeting.meetingColour];
}

- (IBAction)chooseGroup:(id)sender {    
    menuType = ((UIButton*)sender).tag;
    
    // Unhide chosen buttons, hide all others
    for (int i=0; i<optionButtons.count; i++) { 
        for (UIButton* button in optionButtons[i]) {
            if (i==menuType) button.hidden = NO;
            else button.hidden = YES;
        }
    }
    for (UIButton *button in presenterItems) button.hidden = YES;
    
    [scroll setContentOffset:CGPointZero animated:NO];
    scroll.scrollEnabled = NO;
    [scroll performSelector:@selector(flashScrollIndicators) withObject:nil afterDelay:0.0];
    
    if ([optionButtons[menuType] count] > 7) { // If there are too many options
        scroll.scrollEnabled = YES;
        scroll.contentSize = CGSizeMake(575, ([optionButtons[menuType] count] * 85 ));
    }
        
    if ([chosenMeeting.meetingId isEqualToString:@"LM"] &&
        [((UIButton*) groupButtons[menuType]).titleLabel.text isEqualToString:@"Options"]) {
        attendeeButton.hidden = NO;
        presenterButton.hidden = NO;
        roundSwitch.hidden = NO;
        
        if (isPresenter) {
            if ([presenterItems count] > 7) {
                scroll.scrollEnabled = YES;
                scroll.contentSize = CGSizeMake(575, [presenterItems count] * 85);
            }
            for (UIButton *button in presenterItems) button.hidden = NO;
            for (UIButton *button in optionButtons[1]) button.hidden = YES; // Hide attendees
        }
        
    }
    else {
        attendeeButton.hidden = YES;
        presenterButton.hidden = YES;
        roundSwitch.hidden = YES;
    }
}

- (IBAction)highlightOption:(id)sender {
    [sender setBackgroundColor:chosenMeeting.meetingColour];
    [sender setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void) unhighlightThis: (UIButton*) button {
    [button setSelected:NO];
    [button setBackgroundColor:[UIColor whiteColor]];
}

- (IBAction)dragOut:(id)sender {
    [sender setBackgroundColor:[UIColor whiteColor]];
    if ([groupButtons containsObject:sender])[self touchesEnded:nil withEvent:nil];
}

- (void)applicationInactive:(NSNotification *) notif {
    // Unhighlight buttons if user four finger pinches halfway
    NSLog(@"beep");
    for (UIButton* button in groupButtons) {
        button.backgroundColor = chosenMeeting.meetingColour;
    }
    for (UIButton* button in optionButtons[menuType]) {
        [self unhighlightThis:button];
        button.hidden = YES;
    }
    for (UIButton* button in presenterItems) {
        [self unhighlightThis:button];
        button.hidden = YES;
    }
    presenterButton.hidden = YES;
    attendeeButton.hidden = YES;
    roundSwitch.hidden = YES;
}

- (IBAction)swipeRight:(id)sender {
    NSLog(@"swiped");
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end


