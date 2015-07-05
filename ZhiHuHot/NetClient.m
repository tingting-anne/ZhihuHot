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

@interface NetClient ()

-(void)getAndSaveStoriesWithUrl:(NSString *)urlString today:(BOOL) isToday withCompletionHandler:(void(^)(NSError *error, NSArray *topStories))completionHandler;

@end

@implementation NetClient

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)context
{
    if ((self = [super init])){
        _context = context;
    }
    return self;
}

-(void)getAndSaveStoriesWithUrl:(NSString *)urlString today:(BOOL) isToday withCompletionHandler:(void(^)(NSError *error, NSArray *topStories))completionHandler
{
    AFHTTPSessionManager *smanager = [AFHTTPSessionManager manager];
    smanager.responseSerializer = [AFHTTPResponseSerializer serializer]; //告诉manager只下载原始数据, 不要解析数据
    NSDictionary *dict = @{@"format": @"json"};
    [smanager GET:urlString parameters:dict success:^(NSURLSessionDataTask *task, id responseObject) {
        
        //主线程
        NSData *data = responseObject;
        NSDictionary* storiesDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        
        NSString *dateString = storiesDictionary[@"date"];
        NSArray *storiesArray = storiesDictionary[@"stories"];
        NSArray *topStoriesArray = storiesDictionary[@"top_stories"];
        
        [self.context performBlock:^{
            NSError *saveError = nil;
            [Story loadFromArray:storiesArray withDate:dateString intoManagedObjectContext:self.context];
            
            if (isToday) {
                [TopStory loadFromArray:topStoriesArray intoManagedObjectContext:self.context];
            }
            
            [self.context save:&saveError];
            if (saveError) {
                NSLog(@"%s context save error, error:%@",__FUNCTION__,saveError);
            }
            
            if (completionHandler) {
                completionHandler(saveError, topStoriesArray);
            }
        }];
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"%s %@",__FUNCTION__,error);
        
        if (completionHandler) {
            completionHandler(error, nil);
        }
    }];
}

- (void)downloadLatestStoriesWithCompletionHandler:(void(^)(NSError *error, NSArray *topStories))completionHandler
{
    NSString *urlString = [NSString stringWithFormat:@"%s", LATESTSTORIES];
    [self getAndSaveStoriesWithUrl:urlString today:YES withCompletionHandler:completionHandler];
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
        [self getAndSaveStoriesWithUrl:urlString today:NO withCompletionHandler:^(NSError *error, NSArray *topStories){
            completionHandler(error);
        }];
    }
}

- (void)downloadThemesWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    NSString *urlString = [NSString stringWithFormat:@"%s", THEMES];
    
    AFHTTPSessionManager *smanager = [AFHTTPSessionManager manager];
    smanager.responseSerializer = [AFHTTPResponseSerializer serializer]; //告诉manager只下载原始数据, 不要解析数据
    NSDictionary *dict = @{@"format": @"json"};
    [smanager GET:urlString parameters:dict success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSData *data = responseObject;
        NSDictionary* themesDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        NSArray *themeArray = themesDictionary[@"others"];
        
        [self.context performBlock:^{
            NSError *saveError = nil;
            [Theme loadFromArray:themeArray intoManagedObjectContext:self.context];
            [self.context save:&saveError];
            if (saveError) {
                NSLog(@"%s context save error, error:%@",__FUNCTION__,saveError);
            }
            
            if (completionHandler) {
                completionHandler(saveError);
            }
        }];
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"%s %@",__FUNCTION__,error);
        
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

- (void)downloadThemeStoriesWithThemeID:(NSUInteger)themeID withCompletionHandler:(void(^)(NSError *error))completionHandler
{
    NSString *urlString = [NSString stringWithFormat:[NSString stringWithFormat:@"%s", THEMESTORIES],
                           [NSNumber numberWithUnsignedLong:themeID]];
    
    AFHTTPSessionManager *smanager = [AFHTTPSessionManager manager];
    smanager.responseSerializer = [AFHTTPResponseSerializer serializer]; //告诉manager只下载原始数据, 不要解析数据
    NSDictionary *dict = @{@"format": @"json"};
    [smanager GET:urlString parameters:dict success:^(NSURLSessionDataTask *task, id responseObject) {
#ifdef DEBUG
        NSLog(@"%s netclient ok", __FUNCTION__);
#endif
        NSData *data = responseObject;
        NSDictionary* themeStoriesDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        NSArray *themeStoriesArray = themeStoriesDictionary[@"stories"];
        [self.context performBlock:^{
            NSError *saveError = nil;
            [ThemeStory loadFromArray:themeStoriesArray withThemeID:themeID intoManagedObjectContext:self.context];
            [self.context save:&saveError];
            if (saveError) {
                NSLog(@"%s context save error, error:%@",__FUNCTION__,saveError);
            }
#ifdef DEBUG
            else{
                NSLog(@"netclient save ok");
            }
#endif
            if (completionHandler) {
                completionHandler(saveError);
            }
        }];
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"%s %@",__FUNCTION__,error);
        
        if (completionHandler) {
            completionHandler(error);
        }
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
            AFHTTPSessionManager *smanager = [AFHTTPSessionManager manager];
            smanager.responseSerializer = [AFHTTPResponseSerializer serializer]; //告诉manager只下载原始数据, 不要解析数据
            NSDictionary *dict = @{@"format": @"json"};
            [smanager GET:urlString parameters:dict success:^(NSURLSessionDataTask *task, id responseObject) {
                
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
            AFHTTPSessionManager *smanager = [AFHTTPSessionManager manager];
            smanager.responseSerializer = [AFHTTPResponseSerializer serializer]; //告诉manager只下载原始数据, 不要解析数据
        
            [smanager GET:href parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                
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
@end
