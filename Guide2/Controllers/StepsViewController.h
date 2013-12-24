//
//  StepsViewController.h
//  Guide
//
//  Created by Jim Ramlall on 2013-06-06.
//  Copyright (c) 2013 Jim Ramlall. All rights reserved.
//

// Steps View 

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <AVFoundation/AVFoundation.h>
#import "GuideAppDelegate.h"

@interface StepsViewController : UIViewController <MFMailComposeViewControllerDelegate, AVAudioPlayerDelegate> {
    GuideAppDelegate* appDelegate;
    
    __weak IBOutlet UIImageView* image;
    __weak IBOutlet UIScrollView* scroll;
    __weak IBOutlet UIButton* backButton;
    __weak IBOutlet UIButton* nextButton;
    __weak IBOutlet UIButton* playButton;
    __weak IBOutlet UIButton *speakerButton;
    __weak IBOutlet UIButton *titleOption;
    NSTimer* timer;
    int currentIndex;
    
    NSMutableArray* steps;
    NSMutableArray* pictures;
    NSMutableArray* buttons;
    NSMutableArray* audioData;
    
    AVAudioPlayer* audioPlayer;
    BOOL autoPlay;
    BOOL stopAtLast;
    BOOL playButtonState;
    
    BOOL sound;
}

@property (nonatomic) NSString* packageId;
@property (nonatomic) NSString* option;
@property (nonatomic) NSString* meeting;
@property (nonatomic) UIColor* colour;
@property (nonatomic) UIColor* highlightColour;
@property (weak, nonatomic) NSString* externalPort;
@property (nonatomic) UIColor* menuColour;
@property (nonatomic) BOOL sound;

- (IBAction)selectNext:(id)sender;
- (IBAction)selectPrevious:(id)sender;
- (IBAction)playPause:(id)sender;
- (IBAction)mute:(id)sender;

@end
