//
//  NetClient.h
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/19.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NetClient : NSObject

@property(readonly, strong, nonatomic)NSManagedObjectContext* context;

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)context;

- (void)downloadLatestStoriesWithCompletionHandler:(void(^)(NSError *error, NSArray *topStories))completionHandler;

- (void)downloadBeforeDate:(NSString *)dateString withCompletionHandler:(void(^)(NSError *error))completionHandler;

- (void)downloadThemesWithCompletionHandler:(void(^)(NSError *error))completionHandler;

- (void)downloadThemeStoriesWithThemeID:(NSUInteger)themeID withCompletionHandler:(void(^)(NSError *error))completionHandler;

- (void)downloadWithNewsID:(NSUInteger)newsID withCompletionHandler:(void(^)(NSDictionary* dic, NSError *error))completionHandler;

- (void)downloadCss:(NSString *)href withCompletionHandler:(void(^)(NSData* cssData, NSError *error))completionHandler;
@end
