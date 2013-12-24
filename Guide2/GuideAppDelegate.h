//
//  GuideAppDelegate.h
//  Guide2
//
//  Created by Jim Ramlall on 2013-05-21.
//  Copyright (c) 2013 Jim Ramlall. All rights reserved.
//

#import <UIKit/UIKit.h>

#define applicationInactiveNotification @"AppInactive"

@class Room;

@interface GuideAppDelegate : UIResponder <UIApplicationDelegate> 

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) NSMutableArray *roomArray;
@property (nonatomic) BOOL sound;

- (void) copyDatabaseIfNeeded;
- (NSString*) getDBPath;

@end
