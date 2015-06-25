//
//  Story.m
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/18.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import "Story.h"
#import "Date.h"


@implementation Story

@dynamic title;
@dynamic images;
@dynamic id;
@dynamic date;

@end

@implementation Story(Load)

+(void)loadFromArray:(NSArray *)storyArray withDate:(NSString *)date intoManagedObjectContext:(NSManagedObjectContext *)context
{
    for (NSDictionary* dic in storyArray) {
        Story* story = nil;
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription* description = [NSEntityDescription entityForName:@"Story" inManagedObjectContext:context];
        [request setEntity:description];
        
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"id = %@", dic[@"id"]];
        [request setPredicate:predicate];
        
        NSError *error = nil;
        NSArray* result = [context executeFetchRequest:request error:&error];
        
        if (!result || error || [result count] > 1) {
             NSLog(@"Error in %s", __FUNCTION__);
        }
        else if([result count] <= 0){
            story = [NSEntityDescription insertNewObjectForEntityForName:@"Story" inManagedObjectContext:context];
            story.id = dic[@"id"];
            story.title = dic[@"title"];
            story.images = dic[@"images"][0];
            story.date = [Date loadFromString:date inManagedObjectContext:context];
        }
    }
}

@end