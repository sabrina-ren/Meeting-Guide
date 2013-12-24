//
//  StepsViewController.m
//  Guide
//
//  Created by Jim Ramlall on 2013-06-06.
//  Copyright (c) 2013 Jim Ramlall. All rights reserved.
//

#import "StepsViewController.h"

#import <sqlite3.h>

@implementation StepsViewController
@synthesize option, colour, highlightColour, meeting, sound;


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
    appDelegate = [[UIApplication sharedApplication] delegate];
    sound = appDelegate.sound;
    
    [super viewDidLoad];
    NSLog(_packageId, option);
    
    scroll.bounces = NO;
    scroll.pagingEnabled = NO;
    scroll.scrollsToTop = NO;

    // Initialize data
    [self initData];
    [self viewText];
    
    [titleOption setTitle:option forState:UIControlStateNormal];
    titleOption.enabled = NO;
    
    playButton.exclusiveTouch = YES;
    speakerButton.exclusiveTouch = YES;
    backButton.exclusiveTouch = YES;
    nextButton.exclusiveTouch = YES;
    
    // Set up playback
    currentIndex=0;
    [self setSoundButtonTo:sound];
    [self setPlayButtonTo:YES];

    if (audioData.count == 0) {
        timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(viewNext:) userInfo:nil repeats:true];
        sound = NO;
        speakerButton.hidden = YES;
    }
    else if (!sound) {
        timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(viewNext:) userInfo:nil repeats:true];
    }
    autoPlay = YES;
    stopAtLast = YES;
    [self setStepAt:0]; // Start autoplay
    
    // Back button
    UIImage* backImage = [UIImage imageNamed:@"back.png"];
    UIButton* backNavButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backNavButton setBackgroundImage:backImage forState:UIControlStateNormal];
    [backNavButton setBackgroundImage:[UIImage imageNamed:@"backSelected.png"] forState:UIControlStateHighlighted];
    [backNavButton setTitleColor:[UIColor colorWithHue:0 saturation:0 brightness:0.8 alpha:1] forState:UIControlStateHighlighted];
    backNavButton.frame = CGRectMake(0, 0, backImage.size.width/1.3, backImage.size.height/1.3);
    if (meeting)[backNavButton setTitle:meeting forState:UIControlStateNormal];
    else [backNavButton setTitle:@"Home" forState:UIControlStateNormal];
    [backNavButton setTitleColor:_menuColour forState:UIControlStateNormal];
    backNavButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    backNavButton.titleEdgeInsets = UIEdgeInsetsMake(0, 30, 0, 0);
    [backNavButton addTarget:self action:@selector(swipeRight:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* backItem = [[UIBarButtonItem alloc] initWithCustomView:backNavButton];
    
    self.navigationItem.leftBarButtonItem = backItem;
    
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    swipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRecognizer];
}

- (void) setSoundButtonTo: (BOOL) isSound {
    if (isSound) [speakerButton setImage:[UIImage imageNamed:@"speaker.png"] forState:UIControlStateNormal];
    else [speakerButton setImage:[UIImage imageNamed:@"mute.png"] forState:UIControlStateNormal];
}

- (void) setPlayButtonTo: (BOOL) play {
    playButtonState = play;
    if (play) [playButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
    else [playButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
}

- (void) initData {
    steps = [[NSMutableArray alloc] init];
    pictures = [[NSMutableArray alloc] init];
    audioData = [[NSMutableArray alloc] init];
    
    // For double digits
    NSMutableArray *moreSteps = [[NSMutableArray alloc] init]; 
    NSMutableArray *morePictures = [[NSMutableArray alloc] init];
    NSMutableArray *moreAudio = [[NSMutableArray alloc] init];
    
    sqlite3 *roomDB = nil;
    if (sqlite3_open([[[NSBundle mainBundle] pathForResource:@"MeetingRoom_db" ofType:@"sqlite"] UTF8String], &roomDB) == SQLITE_OK) {
        
        NSString* sqlStr = [NSString stringWithFormat:@"SELECT text, pictures, audio FROM steps WHERE packageId = '%@' AND option = '%@' ORDER BY text ASC", _packageId, [option stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
        const char *sql = [sqlStr UTF8String];
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(roomDB, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            while((sqlite3_step(selectstmt)) == SQLITE_ROW) {
                NSString* step = [NSString stringWithUTF8String:(char*)sqlite3_column_text(selectstmt, 0)];
                NSData* picData = [[NSData alloc] initWithBytes:sqlite3_column_blob(selectstmt, 1) length:sqlite3_column_bytes(selectstmt, 1)];
                NSData* audData = nil;
                if (sqlite3_column_blob(selectstmt, 2)) {
                    audData =[[NSData alloc] initWithBytes:sqlite3_column_blob(selectstmt, 2) length:sqlite3_column_bytes(selectstmt, 2)];
                }
                
                if ([step characterAtIndex:1]!= '.') { // If double digit step
                    [moreSteps addObject:step];
                    if (picData.bytes!=0)[morePictures addObject:[UIImage imageWithData:picData]];
                    if (audData.bytes!=0) [moreAudio addObject:audData];
                }
                else { // Single digit
                    [steps addObject:step];
                    if (picData.bytes!=0)[pictures addObject:[UIImage imageWithData:picData]];
                    if (audData.bytes!=0) [audioData addObject:audData];
                }
            }
            sqlite3_reset(selectstmt);
            sqlite3_finalize(selectstmt);
        } else NSLog(@"error: %s\n", sqlite3_errmsg(roomDB));
    }
    sqlite3_close(roomDB);
    
    // Add double digits to end of arrays
    [steps addObjectsFromArray:moreSteps];
    [pictures addObjectsFromArray:morePictures];
    [audioData addObjectsFromArray:moreAudio];
}

- (void)viewText {
    buttons = [[NSMutableArray alloc] init];
    
    CGFloat buttonWidth = 320;
    CGFloat originY = 0;
    
    for (int i=0; i<steps.count; i++) {
        
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setHeadIndent:25];
        [style setLineBreakMode:NSLineBreakByWordWrapping];
        
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"HelveticaNeue-Light" size:22.0], NSFontAttributeName, style, NSParagraphStyleAttributeName, [UIColor whiteColor], NSForegroundColorAttributeName,  nil];
        NSAttributedString *step = [[NSAttributedString alloc] initWithString:steps[i] attributes:attributes];
        CGRect rect = [step boundingRectWithSize:CGSizeMake(buttonWidth - 35, 0) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        button.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 10);
        
        [button setBackgroundColor: highlightColour];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        
        [button addTarget:self action:@selector(viewImage:) forControlEvents:UIControlEventTouchUpInside];
        
        button.frame = CGRectMake(0, originY, buttonWidth, rect.size.height + 20);
        originY = originY + rect.size.height + 20;
        
        button.bounds = button.frame;
        [button setAttributedTitle:step forState:UIControlStateNormal];
        
        [buttons addObject:button];
        [scroll addSubview:button];
    }

    if (_externalPort && [_packageId isEqualToString:@"ET"]) {
        UILabel *portLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, originY + 10, buttonWidth, 75)];
        [portLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:22.0]];
        [portLabel setNumberOfLines:2];
        [portLabel setTextColor:[UIColor darkGrayColor]];
        [portLabel setText:[NSString stringWithFormat:@"    This room's external port \n    number is %@", _externalPort]];
        [scroll addSubview:portLabel];
    }
    
    if (originY > 620) {
        
        [scroll performSelector:@selector(flashScrollIndicators) withObject:nil afterDelay:0.0];
        scroll.bounces = YES;
    }
    [scroll setContentSize:CGSizeMake(buttonWidth, originY)];
}

- (void) viewNext:(NSTimer*)thisTimer{
    currentIndex++;
    NSLog(@"Current index is %i", currentIndex);

    [self setStepAt:currentIndex];
    if (currentIndex == buttons.count - 1) {
        if (timer) {
           [self setPlayButtonTo:NO];
        }
        [self stopTimer];
        autoPlay = NO;
        stopAtLast = YES;
    }
}

- (IBAction)viewImage:(id)sender {
    if (sound)[self setPlayButtonTo:YES];
    else [self setPlayButtonTo:NO];
    [self stopTimer];
    autoPlay = NO;
    currentIndex = [[[sender titleLabel].text substringToIndex:2] intValue] - 1;
    [self setStepAt:currentIndex];
}

- (void) setStepAt:(int) index {

    if (currentIndex >= buttons.count) currentIndex = 0;
    for (UIButton* button in buttons) {
        [button setBackgroundColor:highlightColour];
        [button setSelected:NO];
    }
    NSLog(@"Set step at %i\n\n", currentIndex);

    [buttons[currentIndex] setBackgroundColor:colour];
    [buttons[currentIndex] setSelected:YES];
    
    if (currentIndex>0)[scroll scrollRectToVisible:[[buttons objectAtIndex:currentIndex] frame] animated:YES];
    else [scroll setContentOffset:CGPointZero];

    if (pictures.count > currentIndex)[image setImage:[pictures objectAtIndex:currentIndex]];

    NSError* error;
    [audioPlayer stop];
    if (audioData.count > currentIndex) {
        audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData[currentIndex] error:&error];
        audioPlayer.delegate = self;
        audioPlayer.numberOfLoops = 0;
        audioPlayer.volume = 1.0f;
        [audioPlayer prepareToPlay];
        if (audioPlayer == nil) NSLog(@"Error playing sound: %@", error.description);
        else if (sound)[audioPlayer play];
    }
}

- (void) stopTimer {
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (!autoPlay) {
        [self setPlayButtonTo:NO];
        NSLog(@"stopping");
    }
    else if ((currentIndex == buttons.count - 1) && stopAtLast) {
        [self setPlayButtonTo:NO];
        NSLog(@"stopping at last");
        autoPlay = NO;
    }
    else if (autoPlay) [self viewNext:nil];
    NSLog(@"Finished playing\n\n\n\n\n");
}

- (IBAction)selectNext:(id)sender {
    autoPlay = NO;
    if (sound) [self setPlayButtonTo:YES];
    else [self setPlayButtonTo:NO];
    [self stopTimer];
    [self setStepAt:++currentIndex];
}

- (IBAction)selectPrevious:(id)sender {
    autoPlay = NO;
    if (sound) [self setPlayButtonTo:YES];
    else [self setPlayButtonTo:NO];
    [self stopTimer];
    if (currentIndex==0) currentIndex = buttons.count;
    [self setStepAt:--currentIndex];
}

- (IBAction)playPause:(id)sender {
    NSLog(@"Auto play was: %i", autoPlay);
    
    if (sound) {
        NSLog(@"Sound: yes");
        
        if (audioPlayer.isPlaying) {
            NSLog(@"Audio is playing -> stop");
            [audioPlayer stop];
            
            if (currentIndex == buttons.count - 1) {
                NSLog(@"Play button state: %i", playButtonState);
                if (!playButtonState) {
                    stopAtLast = NO;
                    autoPlay = YES;
                    [self setStepAt:++currentIndex];
                }
                else autoPlay = NO;
                [self setPlayButtonTo:autoPlay];
                
            }
            playButtonState = NO;
            [self setPlayButtonTo:playButtonState];
        }
        else { // not playing
            NSLog(@"Audio is stopped -> play");
            if (currentIndex == buttons.count - 1) {
                stopAtLast = NO;
                autoPlay = YES;
            }
            autoPlay= YES;
            playButtonState = YES;
            [self setPlayButtonTo:playButtonState];
            [audioPlayer play];
        }
    }
    
    else {
        autoPlay = !autoPlay;
        [self setPlayButtonTo:autoPlay];
        [self stopTimer];
        NSLog(@"no sound, autoplay was: %i", autoPlay);
        if (!autoPlay) {
            autoPlay = NO;
        }
        else {
            NSLog(@"start autoplay");
            autoPlay = YES;
            
            if (currentIndex == buttons.count-1) currentIndex = -1;
            
            [self setStepAt:++currentIndex];
            
            timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(viewNext:) userInfo:nil repeats:true];
        }
    }
}

- (IBAction)mute:(id)sender {
    sound = !sound; 
    [self stopTimer];

    if (sound) { 
        NSLog(@"Sound is turned on");
        [speakerButton setSelected:NO]; // Sets speaker icon
        [audioPlayer play];
        [self setPlayButtonTo:YES];
    }
    else { // If muted
        NSLog(@"Sound is muted");
        [audioPlayer stop];
        // New timer to handle autoplay
        if (autoPlay) {
            if (currentIndex < buttons.count - 1) {
                timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(viewNext:) userInfo:nil repeats:true];
            } else [self setPlayButtonTo:NO];
        }
        else [self setPlayButtonTo:NO];
    }
    [self setSoundButtonTo:sound];
}

- (IBAction)swipeRight:(id)sender {
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void) viewWillDisappear:(BOOL)animated {
    // Stop timer and audio
    appDelegate.sound = sound;
    [self stopTimer];
    [audioPlayer stop];
    NSLog(@"Audio player stopped");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
