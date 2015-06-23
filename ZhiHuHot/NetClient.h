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

- (BOOL)downloadLatestStories;
- (BOOL)downloadBeforeDate:(NSString *)dateString;
- (BOOL)downloadThemes;
- (BOOL)downloadThemeStoriesWithThemeID:(NSUInteger)themeID;
- (BOOL)downloadNewsDictionary:(NSDictionary **)dic WithNewsID:(NSUInteger)newsID;

@end
