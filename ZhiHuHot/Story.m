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

+(void)loadFromArray:(NSArray *)storyArray withDate:(NSString *)date latest:(BOOL)isLatest intoManagedObjectContext:(NSManagedObjectContext *)context
{
    Story* story = nil;
    LoadManagerObjectResultType resultType = LOAD_ERROR;
    Date* dateObject = [Date loadFromString:date latest:isLatest inManagedObjectContext:context withLoadManagerObjectResult:&resultType];
    
    UInt32 sortId = 0;
    if (LOAD_BY_ADD == resultType) {
        for (NSDictionary* dic in storyArray) {
            story = [NSEntityDescription insertNewObjectForEntityForName:@"Story" inManagedObjectContext:context];
            story.id = dic[@"id"];
            story.title = dic[@"title"];
            story.images = dic[@"images"][0];
            story.date = dateObject;
            story.sortId = [NSNumber numberWithUnsignedInt:sortId];
            sortId++;
        }
    }
    else if(LOAD_BY_GET == resultType){
        NSError *error = nil;
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription* description = [NSEntityDescription entityForName:@"Story" inManagedObjectContext:context];
        [request setEntity:description];
        
        NSPredicate* predicateChage = [NSPredicate predicateWithFormat:@"date.date = %@", date];
        [request setPredicate:predicateChage];
        NSArray* resultChage = [context executeFetchRequest:request error:&error];
        if ([resultChage count] == [storyArray count]) {
            resultChage = nil;
            return;
        }
        
        for (NSDictionary* dic in storyArray) {
            NSPredicate* predicate = [NSPredicate predicateWithFormat:@"id = %@", dic[@"id"]];
            [request setPredicate:predicate];
            
            NSArray* result = [context executeFetchRequest:request error:&error];
            
            if (!result || error || [result count] > 1){
                 NSLog(@"Error in %s", __FUNCTION__);
            }
            else if([result count] <= 0){//说明更新时有增加
                story = [NSEntityDescription insertNewObjectForEntityForName:@"Story" inManagedObjectContext:context];
                story.id = dic[@"id"];
                story.title = dic[@"title"];
                story.images = dic[@"images"][0];
                story.date = dateObject;
                story.sortId = [NSNumber numberWithUnsignedInt:sortId];
            }
            else{
                story = result[0];
                if ([story.sortId unsignedIntegerValue] != sortId) {
                    story.title = dic[@"title"];
                    story.images = dic[@"images"][0];
                    story.date = dateObject;
                    story.sortId = [NSNumber numberWithUnsignedInt:sortId];
                }
            }
            sortId++;
        }
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