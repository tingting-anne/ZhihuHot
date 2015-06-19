//
//  Date.m
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/18.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import "Date.h"
#import "Story.h"


@implementation Date

@dynamic date;
@dynamic stories;
@dynamic topStories;

@end

@implementation Date(Load)

+(Date *)loadFromString:(NSString *)dateString inManagedObjectContext:(NSManagedObjectContext *)context
{
    Date* date = nil;
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription* description = [NSEntityDescription entityForName:@"Date" inManagedObjectContext:context];
    [request setEntity:description];
    
    NSPredicate* predicte = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"date = %@", dateString]];
    [request setPredicate:predicte];
    
    NSError* error = nil;
    NSArray* result = [context executeFetchRequest:request error:&error];
    if (!result || error || [result count] > 1) {
        NSLog(@"Error in %s", __FUNCTION__);
    } else if([result count] <= 0){
        date = [NSEntityDescription insertNewObjectForEntityForName:@"Date" inManagedObjectContext:context];
        date.date = dateString;
    }
    return date;
}

@end