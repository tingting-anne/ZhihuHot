//
//  Theme.h
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/18.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ThemeStory;

@interface Theme : NSManagedObject

@property (nonatomic, retain) NSString * thumbnail;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSNumber *sortId;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *themStories;
@end

@interface Theme (CoreDataGeneratedAccessors)

- (void)addThemStoriesObject:(ThemeStory *)value;
- (void)removeThemStoriesObject:(ThemeStory *)value;
- (void)addThemStories:(NSSet *)values;
- (void)removeThemStories:(NSSet *)values;

@end

@interface Theme(Load)

+ (void)loadFromArray:(NSArray *)array intoManagedObjectContext:(NSManagedObjectContext *)context;
+ (Theme*)getThemeWithID:(NSUInteger)thmeID inManagedObjectContext:(NSManagedObjectContext *)context;

@end