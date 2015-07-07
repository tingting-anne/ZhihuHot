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

@end

@implementation Date(Load)

+ (Date *)loadFromString:(NSString *)dateString inManagedObjectContext:(NSManagedObjectContext *)context withLoadManagerObjectResult:(LoadManagerObjectResultType *)resultType
{
    Date* date = nil;
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription* description = [NSEntityDescription entityForName:@"Date" inManagedObjectContext:context];
    [request setEntity:description];
    
    NSPredicate* predicte = [NSPredicate predicateWithFormat:@"date = %@", dateString];
    [request setPredicate:predicte];

    NSError* error = nil;
    *resultType = LOAD_ERROR;
    
    NSArray* result = [context executeFetchRequest:request error:&error];
    if (!result || error || [result count] > 1) {
        NSLog(@"Error in %s", __FUNCTION__);
    } else if([result count] <= 0){
        date = [NSEntityDescription insertNewObjectForEntityForName:@"Date" inManagedObjectContext:context];
        date.date = dateString;
        *resultType = LOAD_BY_ADD;
    }else{
        date = result.firstObject;
        *resultType = LOAD_BY_GET;
    }
    return date;
}

@end