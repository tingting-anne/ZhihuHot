//
//  NetClient.m
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/19.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import "NetClient.h"
#import "AFNetworking.h"
#import "Story.h"
#import "Theme.h"
#import "Date.h"
#import "TopStory.h"
#import "ThemeStory.h"
#import "AppHelper.h"
#import "Definitions.h"
#import "DataCache.h"
#import "AppDelegate.h"

@interface NetClient ()

@property (weak, nonatomic)AppDelegate * appDelegate;
@property(readonly, strong, nonatomic)NSManagedObjectContext* context;
@property(readonly, strong, nonatomic)AFHTTPSessionManager * smanager;

-(void)getAndSaveStoriesWithUrl:(NSString *)urlString today:(BOOL) isToday withCompletionHandler:(void(^)(NSError *error))completionHandler topStoriesCompletionHandler:(void(^)(NSArray *topStories))topStories;
- (void)saveContext;
@end

@implementation NetClient

-(instancetype)init
{
    if ((self = [super init])){
        
        _appDelegate = [[UIApplication sharedApplication] delegate];
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _context.parentContext = [_appDelegate managedObjectContext];
        
        static dispatch_once_t onceToken;
        static AFHTTPSessionManager *aFHTTPSessionManager = nil;
        dispatch_once(&onceToken, ^{
            aFHTTPSessionManager = [AFHTTPSessionManager manager];
            aFHTTPSessionManager.responseSerializer = [AFHTTPResponseSerializer serializer]; //告诉manager只下载原始数据, 不要解析数据
        });
        
        _smanager = aFHTTPSessionManager;
    }
    return self;
}

-(void)getAndSaveStoriesWithUrl:(NSString *)urlString today:(BOOL) isToday withCompletionHandler:(void(^)(NSError *error))completionHandler topStoriesCompletionHandler:(void(^)(NSArray *topStories))topStoriescompletionHandler
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSDictionary *dict = @{@"format": @"json"};
    [self.smanager GET:urlString parameters:dict success:^(NSURLSessionDataTask *task, id responseObject) {
        
        //主线程
        NSData *data = responseObject;
        NSDictionary* storiesDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        
        NSString *dateString = storiesDictionary[@"date"];
        NSArray *storiesArray = storiesDictionary[@"stories"];
        NSArray *topStoriesArray = storiesDictionary[@"top_stories"];
        
        if (topStoriescompletionHandler) {
            topStoriescompletionHandler(topStoriesArray);
        }
        
        [self.context performBlock:^{
            [Story loadFromArray:storiesArray withDate:dateString latest:!isToday intoManagedObjectContext:self.context];
            
            if (isToday) {
                [TopStory loadFromArray:topStoriesArray intoManagedObjectContext:self.context];
            }
            
            [self saveContext];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandler) {
                    completionHandler(nil);
                }
            });
        }];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        NSLog(@"%s %@",__FUNCTION__,error);
        if (topStoriescompletionHandler) {
            topStoriescompletionHandler(nil);
        }
        
        if (completionHandler) {
            completionHandler(error);
        }
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];
}

- (void)downloadLatestStoriesWithCompletionHandler:(void(^)(NSError *error))completionHandler topStoriesCompletionHandler:(void(^)(NSArray *topStories))topStories
{
    NSString *urlString = [NSString stringWithFormat:@"%s", LATESTSTORIES];
    [self getAndSaveStoriesWithUrl:urlString today:YES withCompletionHandler:completionHandler topStoriesCompletionHandler:topStories];
}

- (void)downloadBeforeDate:(NSString *)dateString withCompletionHandler:(void(^)(NSError *error))completionHandler
{
    if (![[AppHelper shareAppHelper] isValidDateString:dateString]) {
        NSLog(@"%s not a valid date string", __FUNCTION__);
        NSError* error = [NSError errorWithDomain:ZHHErrorDomain code:ZHHInvalidDateString userInfo:nil];
        
        if (completionHandler) {
            completionHandler(error);
        }
    }
    else{
        NSString *urlString = [NSString stringWithFormat:[NSString stringWithFormat:@"%s", BEFORESTORIES], dateString];
        [self getAndSaveStoriesWithUrl:urlString today:NO withCompletionHandler:completionHandler topStoriesCompletionHandler:nil];
    }
}

- (void)downloadThemesWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSString *urlString = [NSString stringWithFormat:@"%s", THEMES];
    
    NSDictionary *dict = @{@"format": @"json"};
    [self.smanager GET:urlString parameters:dict success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSData *data = responseObject;
        NSDictionary* themesDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        NSArray *themeArray = themesDictionary[@"others"];
        
        [self.context performBlock:^{
            
            [Theme loadFromArray:themeArray intoManagedObjectContext:self.context];
            [self saveContext];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandler) {
                    completionHandler(nil);
                }
            });
        }];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"%s %@",__FUNCTION__,error);
        
        if (completionHandler) {
            completionHandler(error);
        }
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];
}

- (void)downloadThemeStoriesWithThemeID:(NSUInteger)themeID withCompletionHandler:(void(^)(NSError *error))completionHandler
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSString *urlString = [NSString stringWithFormat:[NSString stringWithFormat:@"%s", THEMESTORIES],
                           [NSNumber numberWithUnsignedLong:themeID]];
    
    NSDictionary *dict = @{@"format": @"json"};
    [self.smanager GET:urlString parameters:dict success:^(NSURLSessionDataTask *task, id responseObject) {
#ifdef DEBUG
        NSLog(@"%s netclient ok", __FUNCTION__);
#endif
        NSData *data = responseObject;
        NSDictionary* themeStoriesDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        NSArray *themeStoriesArray = themeStoriesDictionary[@"stories"];
        [self.context performBlock:^{
            
            [ThemeStory loadFromArray:themeStoriesArray withThemeID:themeID intoManagedObjectContext:self.context];
            [self saveContext];

            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandler) {
                    completionHandler(nil);
                }
            });
        }];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"%s %@",__FUNCTION__,error);
        
        if (completionHandler) {
            completionHandler(error);
        }
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];
}

- (void)downloadWithNewsID:(NSUInteger)newsID withCompletionHandler:(void(^)(NSDictionary* dic, NSError *error))completionHandler
{
    NSString *urlString = [NSString stringWithFormat:[NSString stringWithFormat:@"%s", NEWSCONTENT],[NSNumber numberWithUnsignedLong:newsID]];
    
    [[DataCache sharedDataCache] queryDiskCacheForKey:urlString done:^(NSData *data, DataCacheType cacheType){
        if (data) {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if (completionHandler) {
                completionHandler(dic, nil);
            }
        }
        else{
            NSDictionary *dict = @{@"format": @"json"};
            [self.smanager GET:urlString parameters:dict success:^(NSURLSessionDataTask *task, id responseObject) {
                
                NSData *data = responseObject;
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                
                if (completionHandler) {
                    completionHandler(dic, nil);
                }
                
                [[DataCache sharedDataCache] storeData:data forKey:urlString];
                
            }failure:^(NSURLSessionDataTask *task, NSError *error) {
                NSLog(@"%s %@",__FUNCTION__,error);
                
                if (completionHandler) {
                    completionHandler(nil, error);
                }
            }];
        }
    }];
}

- (void)downloadCss:(NSString *)href withCompletionHandler:(void(^)(NSData* cssData, NSError *error))completionHandler
{
    [[DataCache sharedDataCache] queryDiskCacheForKey:href done:^(NSData *data, DataCacheType cacheType){
        if (data) {
            if (completionHandler) {
                completionHandler(data, nil);
            }
        }
        else{
            [self.smanager GET:href parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                
                NSData *data = responseObject;
                if (completionHandler) {
                    completionHandler(data, nil);
                }
                
                [[DataCache sharedDataCache] storeData:data forKey:href];
                
            }failure:^(NSURLSessionDataTask *task, NSError *error) {
                NSLog(@"%s %@",__FUNCTION__,error);
                
                if (completionHandler) {
                    completionHandler(nil, error);
                }
            }];
        }
    }];
}

- (void)saveContext {
    if (self.context != nil) {
        NSError *error = nil;
        if ([self.context hasChanges] && ![self.context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            [[AppHelper shareAppHelper] showAlertViewWithError:error type:MOC_SAVE_ERROR];
        }
    }
    
    [self.appDelegate saveContext];
}

@end
