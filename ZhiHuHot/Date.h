//
//  Date.h
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/18.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Definitions.h"

@class NSManagedObject, Story;

@interface Date : NSManagedObject

@property (nonatomic, retain) NSString * date;
@property (nonatomic, retain) NSSet *stories;
@end

@interface Date (CoreDataGeneratedAccessors)

- (void)addStoriesObject:(Story *)value;
- (void)removeStoriesObject:(Story *)value;
- (void)addStories:(NSSet *)values;
- (void)removeStories:(NSSet *)values;

@end

@interface Date(Load)

+ (Date *)loadFromString:(NSString *)dateString inManagedObjectContext:(NSManagedObjectContext *)context withLoadManagerObjectResult:(LoadManagerObjectResultType *)resultType;

@end