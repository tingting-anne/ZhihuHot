//
//  AppHelper.h
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/19.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@interface AppHelper : NSObject

+ (id)shareAppHelper;

- (BOOL)isValidDateString:(NSString *)dateString;
- (BOOL)isTodayWithDateString:(NSString *)dateString;
- (NSString *)stringOfToday;
- (UIColor *)backgroundColor;

@end
