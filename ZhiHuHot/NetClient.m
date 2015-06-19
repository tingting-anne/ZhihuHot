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
#import "ThemeStory.h"
#import "AppHelper.h"
#import "Definitions.h"

@interface NetClient ()

-(BOOL)getAndSaveStoriesWithUrl:(NSString *)urlString;

@end

@implementation NetClient

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)context
{
    if ((self = [super init])){
        _context = context;
    }
    return self;
}

-(BOOL)getAndSaveStoriesWithUrl:(NSString *)urlString
{
    __block BOOL ret = FALSE;
    
    AFHTTPSessionManager *smanager = [AFHTTPSessionManager manager];
    smanager.responseSerializer = [AFHTTPResponseSerializer serializer]; //告诉manager只下载原始数据, 不要解析数据
    NSDictionary *dict = @{@"format": @"json"};
    [smanager GET:urlString parameters:dict success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSData *data = responseObject;
        NSDictionary* storiesDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        
        NSString *dateString = storiesDictionary[@"date"];
        NSArray *storiesArray = storiesDictionary[@"stories"];
        [self.context performBlock:^{
            NSError *saveError = nil;
            [Story loadFromArray:storiesArray withDate:dateString intoManagedObjectContext:self.context];
            [self.context save:&saveError];
            if (!saveError) {
                ret = TRUE;
            }
        }];
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"%s %@",__FUNCTION__,error);
    }];
    
    return ret;
}

- (BOOL)downloadLatestStories
{
    NSString *urlString = [NSString stringWithFormat:@"%s", LATESTSTORIES];
    return [self getAndSaveStoriesWithUrl:urlString];
}

- (BOOL)downloadBeforeDate:(NSString *)dateString
{
    if (![[AppHelper shareAppHelper] isValidDateString:dateString]) {
        NSLog(@"%s not a valid date string", __FUNCTION__);
        return FALSE;
    }
    
    NSString *urlString = [NSString stringWithFormat:[NSString stringWithFormat:@"%s", BEFORESTORIES], dateString];
    return [self getAndSaveStoriesWithUrl:urlString];
}

- (BOOL)downloadThemes
{
    NSString *urlString = [NSString stringWithFormat:@"%s", THEMES];
    __block BOOL ret = FALSE;
    
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
            if (!saveError) {
                ret = TRUE;
            }
        }];
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"%s %@",__FUNCTION__,error);
    }];
    
    return ret;
}

- (BOOL)downloadThemeStoriesWithThemeID:(NSUInteger)themeID
{
    NSString *urlString = [NSString stringWithFormat:[NSString stringWithFormat:@"%s", THEMESTORIES],
                           [NSNumber numberWithUnsignedLong:themeID]];
    __block BOOL ret = FALSE;
    
    AFHTTPSessionManager *smanager = [AFHTTPSessionManager manager];
    smanager.responseSerializer = [AFHTTPResponseSerializer serializer]; //告诉manager只下载原始数据, 不要解析数据
    NSDictionary *dict = @{@"format": @"json"};
    [smanager GET:urlString parameters:dict success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSData *data = responseObject;
        NSDictionary* themeStoriesDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        NSArray *themeStoriesArray = themeStoriesDictionary[@"stories"];
        [self.context performBlock:^{
            NSError *saveError = nil;
            [ThemeStory loadFromArray:themeStoriesArray withThemeID:themeID intoManagedObjectContext:self.context];
            [self.context save:&saveError];
            if (!saveError) {
                ret = TRUE;
            }
        }];
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"%s %@",__FUNCTION__,error);
    }];
    
    return ret;
}

@end