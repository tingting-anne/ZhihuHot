//
//  ThemeStory.h
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/18.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Theme;

@interface ThemeStory : NSManagedObject

@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSNumber * sortId;
@property (nonatomic, retain) NSString * images;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) Theme *them;

@end

@interface ThemeStory(Load)

+(void)loadFromArray:(NSArray *)array withThemeID:(NSUInteger)themeID intoManagedObjectContext:(NSManagedObjectContext *)context;

@end