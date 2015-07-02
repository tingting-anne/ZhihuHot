//
//  TopStory.h
//  ZhiHuHot
//
//  Created by ltt.fly on 15/7/2.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TopStory : NSManagedObject

@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * image;
@property (nonatomic, retain) NSString * title;

@end

@interface TopStory(Load)

+ (void)loadFromArray:(NSArray *)topStoryArray intoManagedObjectContext:(NSManagedObjectContext *)context;

+ (NSArray *)getArrayFromManagedObjectContext:(NSManagedObjectContext *)context;
@end