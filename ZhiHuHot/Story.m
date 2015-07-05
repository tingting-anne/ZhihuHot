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
@dynamic sortId;
@dynamic date;

@end

@implementation Story(Load)

+(void)loadFromArray:(NSArray *)storyArray withDate:(NSString *)date intoManagedObjectContext:(NSManagedObjectContext *)context
{
    Story* story = nil;
    NSError *error = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription* description = [NSEntityDescription entityForName:@"Story" inManagedObjectContext:context];
    [request setEntity:description];
    
    UInt32 sortId = 0;
    for (NSDictionary* dic in storyArray) {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"id = %@", dic[@"id"]];
        [request setPredicate:predicate];
        
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
            story.sortId = [NSNumber numberWithUnsignedInt:sortId];
        }
        else{
            story = result[0];
            story.title = dic[@"title"];
            story.images = dic[@"images"][0];
            story.date = [Date loadFromString:date inManagedObjectContext:context];
            story.sortId = [NSNumber numberWithUnsignedInt:sortId];
        }
        sortId++;
    }
}

+ (void)deleteStoriesBeforeDays:(NSUInteger)days inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSError *error = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Story"];
    
    NSTimeInterval timeInterval = days * 24 * 60 * 60 * -1.0f;
    NSDate *dateDelete = [NSDate dateWithTimeIntervalSinceNow:timeInterval];
    NSLog(@"dateDelete %@", dateDelete);
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterFullStyle];
    dateFormatter.dateFormat = @"yyyyMMdd";
    
    NSString *dateDeleteString = [dateFormatter stringFromDate:dateDelete];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"date.date < %@", dateDeleteString];
    [request setPredicate:predicate];
        
    NSArray* result = [context executeFetchRequest:request error:&error];
    if (result && !error && [result count] > 0) {
        for (Story *story in result) {
            [context deleteObject:story];
        }
    }
}
@end