//
//  TopStory.m
//  ZhiHuHot
//
//  Created by ltt.fly on 15/7/2.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import "TopStory.h"


@implementation TopStory

@dynamic id;
@dynamic image;
@dynamic title;

@end

@implementation TopStory(Load)

+(void)loadFromArray:(NSArray *)topStoryArray intoManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request =[NSFetchRequest fetchRequestWithEntityName:@"TopStory"];

    TopStory* topStory = nil;
    NSError *error = nil;
    
    NSMutableArray* idArray = [[NSMutableArray alloc] init];
    
    for (NSDictionary* dic in topStoryArray) {
        [idArray addObject:dic[@"id"]];
        
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"id = %@", dic[@"id"]];
        [request setPredicate:predicate];
    
        NSArray* result = [context executeFetchRequest:request error:&error];
        
        if (!result || error || [result count] > 1) {
            NSLog(@"Error in %s", __FUNCTION__);
        }
        else if([result count] <= 0){
            topStory = [NSEntityDescription insertNewObjectForEntityForName:@"TopStory" inManagedObjectContext:context];
            topStory.id = dic[@"id"];
            topStory.title = dic[@"title"];
            topStory.image = dic[@"image"];
        }
        else{
            //找到重新赋值即可
            topStory = result[0];
            topStory.title = dic[@"title"];
            topStory.image = dic[@"image"];
        }
    }
    
    //只保持最新的数据即可
    [request setPredicate:nil];
    NSArray* result = [context executeFetchRequest:request error:&error];
    if (!result || error || [result count] < [topStoryArray count]) {
        NSLog(@"Error in %s", __FUNCTION__);
    }
    else{
        for (topStory in result) {
            if (![idArray containsObject:topStory.id]) {
                [context deleteObject:topStory];
            }
        }
    }
}

+ (NSArray *)getArrayFromManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request =[NSFetchRequest fetchRequestWithEntityName:@"TopStory"];
    
    NSError *error;
    NSArray* result = [context executeFetchRequest:request error:&error];
    
    TopStory* topStory;
    NSMutableArray* dicArray = [[NSMutableArray alloc] init];
    
    for (topStory in result) {
        //必须每个object都allco，否则array所有元素都指向同一个对象
         NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
        [dic setValue:topStory.id forKey:@"id"];
        [dic setValue:topStory.title forKey:@"title"];
        [dic setValue:topStory.image forKey:@"image"];
        
        [dicArray addObject:dic];
    }
    return dicArray;
}
@end