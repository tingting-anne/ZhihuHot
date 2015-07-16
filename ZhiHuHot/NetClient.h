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

- (void)downloadLatestStoriesWithCompletionHandler:(void(^)(NSError *error))completionHandler topStoriesCompletionHandler:(void(^)(NSArray *topStories))topStories;

- (void)downloadBeforeDate:(NSString *)dateString withCompletionHandler:(void(^)(NSError *error))completionHandler;

- (void)downloadThemesWithCompletionHandler:(void(^)(NSError *error))completionHandler;

- (void)downloadThemeStoriesWithThemeID:(NSUInteger)themeID withCompletionHandler:(void(^)(NSError *error))completionHandler;

- (void)downloadWithNewsID:(NSUInteger)newsID withCompletionHandler:(void(^)(NSDictionary* dic, NSError *error))completionHandler;

- (void)downloadCss:(NSString *)href withCompletionHandler:(void(^)(NSData* cssData, NSError *error))completionHandler;
@end
