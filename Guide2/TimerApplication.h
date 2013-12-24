//
//  TimerApplication.h
//  Guide
//
//  Created by Jim Ramlall on 2013-05-31.
//  Copyright (c) 2013 Jim Ramlall. All rights reserved.
//


// Times out and wakes up application

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define applicationTimeoutInMinutes 10 // Amount of time app can idle before darkening screen
#define applicationDidTimeoutNotification @"AppTimeout"
#define applicationWoke @"AppWoke"

@interface TimerApplication : UIApplication
{
    NSTimer *idleTimer;
}

- (void) resetIdleTimer;

@end
