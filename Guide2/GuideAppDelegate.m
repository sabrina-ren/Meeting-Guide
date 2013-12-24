//
//  Guide2AppDelegate.m
//  Guide2
//
//  Created by Jim Ramlall on 2013-05-21.
//  Copyright (c) 2013 Jim Ramlall. All rights reserved.
//

#import "GuideAppDelegate.h"
#import "RoomViewController.h"
#import "Room.h"
#import "TimerApplication.h"
#import "GuideViewController.h"

@implementation GuideAppDelegate

@synthesize roomArray;

- (void)copyDatabaseIfNeeded {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSString* dbPath = [self getDBPath];
    BOOL success = [fileManager fileExistsAtPath:dbPath];
    
    if (!success) {
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath]
                                   stringByAppendingPathComponent:@"MeetingRoom_db.sqlite"];
        success = [fileManager copyItemAtPath:defaultDBPath toPath:dbPath error:&error];
        if (!success) NSAssert1(0,@"Failed to create writable database file with message '%@'.",[error localizedDescription]);
    }
}

- (NSString*) getDBPath {
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDir = [paths objectAtIndex:0];
//    return [documentsDir stringByAppendingPathComponent:@"MeetingRoom_db.sqlite"];
    return [[NSBundle mainBundle] pathForResource:@"MeetingRoom_db" ofType:@"sqlite"];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {

}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self copyDatabaseIfNeeded];
    // Initialize room array
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    self.roomArray = tempArray;
    // Once db is copied, get initial data to display
    [Room initializeRoomData];
    
//    UINavigationController *controller = (UINavigationController*)self.window.rootViewController;

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidTimeout:) name:applicationDidTimeoutNotification object:nil];
    
    if ([[UINavigationBar class] respondsToSelector:@selector(appearance)])
        [[UINavigationBar appearance] setTitleTextAttributes:
         [NSDictionary dictionaryWithObjectsAndKeys:[UIColor darkGrayColor], UITextAttributeTextColor, [UIColor clearColor], UITextAttributeTextShadowColor,
          [UIFont fontWithName:@"HelveticaNeue" size:17.0], UITextAttributeFont,
          nil]];

    return YES;
}

- (void)applicationDidTimeout:(NSNotification *) notif {
    NSLog(@"time exceeded!");
    
    [((UINavigationController*)self.window.rootViewController) popToRootViewControllerAnimated:YES];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Inactive notification sent to view controllers to unhighlight buttons
    [[NSNotificationCenter defaultCenter] postNotificationName:applicationInactiveNotification object:nil];
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:applicationWoke object:nil];

    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
