//
//  Story.h
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/18.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Date;

@interface Story : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * images;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSNumber *sortId;
@property (nonatomic, retain) Date *date;

@end

@interface Story(Load)

+ (void)loadFromArray:(NSArray *)storyArray withDate:(NSString *)date intoManagedObjectContext:(NSManagedObjectContext *)context;

@end