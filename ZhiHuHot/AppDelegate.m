//
//  AppDelegate.m
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/16.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import "AppDelegate.h"
#import "NetClient.h"
#import "AppHelper.h"
#import "SDWebImage/SDImageCache.h"
#import "DataCache.h"
#import "Story.h"

@interface AppDelegate ()

@property (readonly, strong, nonatomic) NSManagedObjectContext *writeManagedObjectContext;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    //NSURLCache* urlCache = [NSURLCache sharedURLCache];
//    urlCache.diskCapacity = 5 * 1024 * 1024;
//    urlCache.memoryCapacity = 1024 * 1024;
    
    NSUInteger memoryCapacity = 1024 * 1024;
    NSUInteger diskCapacity = 5 * 1024 * 1024;
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:memoryCapacity diskCapacity:diskCapacity diskPath:@"ZhihuURLCache"];
    [NSURLCache setSharedURLCache:sharedCache];
    
    SDImageCache* sdImageCache = [SDImageCache sharedImageCache];
    sdImageCache.maxCacheAge = 7 * 24 * 60 * 60;
    sdImageCache.maxCacheSize = 10 * 1024 * 1024;
    sdImageCache.maxMemoryCost = 2 * 1024 * 1024;
    
    DataCache* dataCache = [DataCache sharedDataCache];
    dataCache.maxCacheAge = 7 * 24 * 60 * 60;
    dataCache.maxCacheSize = 5 * 1024 * 1024;
    dataCache.maxMemoryCost = 1024 * 1024;
    
    //Default NSURLCache :disk:20M, memory:4M
    
    NSLog(@"NSURLCache diskCapacity:%lu, memoryCapacity:%lu", (unsigned long)sharedCache.diskCapacity, (unsigned long)sharedCache.memoryCapacity);
    
    /////////////////////////////////////////////////////////////
    
    NetClient *netClient = [[NetClient alloc] init];    
    [netClient downloadThemesWithCompletionHandler:^(NSError* error){
        if (error) {
            NSLog(@"ERROR downloadThemes : %s", __FUNCTION__);
        }
    }];
    
    [[UINavigationBar appearance] setBarTintColor:[[AppHelper shareAppHelper] backgroundColor]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    [[UINavigationBar appearance] setTitleTextAttributes:
        [NSDictionary dictionaryWithObjectsAndKeys:
        [UIColor whiteColor], NSForegroundColorAttributeName,
        [UIFont fontWithName:@"Arial Rounded MT Bold" size:19.0f], NSFontAttributeName,
         nil]];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [Story deleteStoriesBeforeDays:30 inManagedObjectContext:self.managedObjectContext];
    [self saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

-(void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
     [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "LTT.ZhiHuHot" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ZhiHuHot" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ZhiHuHot.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    
    NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],
                                       NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES],
                                       NSInferMappingModelAutomaticallyOption, nil];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:optionsDictionary error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _writeManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_writeManagedObjectContext setPersistentStoreCoordinator:coordinator];
    
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _managedObjectContext.parentContext = _writeManagedObjectContext;
    
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            [[AppHelper shareAppHelper] showAlertViewWithError:error type:MOC_SAVE_ERROR];
        }
    }
    
    if (_writeManagedObjectContext != nil) {
        [_writeManagedObjectContext performBlock:^{
            NSError *error = nil;
            if ([_writeManagedObjectContext hasChanges] && ![_writeManagedObjectContext save:&error]) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                [[AppHelper shareAppHelper] showAlertViewWithError:error type:PSC_STORE_ERROR];
            }
        }];
    }
}

@end
