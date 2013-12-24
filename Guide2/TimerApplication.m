//
//  TimerApplication.m
//  Guide
//
//  Created by Jim Ramlall on 2013-05-31.
//  Copyright (c) 2013 Jim Ramlall. All rights reserved.
//

#import "TimerApplication.h"
#import "GuideViewController.h"

@implementation TimerApplication

-(void)sendEvent:(UIEvent *)event {
    [super sendEvent:event];
    if (!idleTimer) {
        [self resetIdleTimer];
    }
    
    NSSet *allTouches = [event allTouches];
    if ([allTouches count]>0) {
        // If screen is touched
        UITouchPhase phase = ((UITouch *)[allTouches anyObject]).phase;
        if (phase ==UITouchPhaseBegan) {
            [self resetIdleTimer];
            [[NSNotificationCenter defaultCenter] postNotificationName:applicationWoke object:nil];
        }
    }
}

-(void)resetIdleTimer {
    if (idleTimer) {
        [idleTimer invalidate]; // Stop existing timer
    }
    int timeout = applicationTimeoutInMinutes*60;
    
    // Create new timer to call idleTimerExceeded in two minutes
    idleTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(idleTimerExceeded) userInfo:nil repeats:NO];
}


-(void)idleTimerExceeded {
    // Posts notification that application timed out
    [[NSNotificationCenter defaultCenter] postNotificationName:applicationDidTimeoutNotification object:nil];
}

@end
