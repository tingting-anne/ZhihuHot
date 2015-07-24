//
//  Date.m
//  ZhiHuHot
//
//  Created by ltt.fly on 15/7/15.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import "Date.h"
#import "Story.h"


@implementation Date

@dynamic date;
@dynamic isLatest;
@dynamic stories;

@end

@implementation Date(Load)

+ (Date *)loadFromString:(NSString *)dateString latest:(BOOL)isLatest inManagedObjectContext:(NSManagedObjectContext *)context withLoadManagerObjectResult:(LoadManagerObjectResultType *)resultType
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
        date.isLatest = [NSNumber numberWithBool:isLatest];
        *resultType = LOAD_BY_ADD;
    }else{
        date = result.firstObject;
        date.isLatest = [NSNumber numberWithBool:isLatest];
        *resultType = LOAD_BY_GET;
    }
    return date;
}

+ (BOOL)deleteDateBeforeDays:(NSUInteger)days inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSError *error = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Date"];
    
    NSTimeInterval timeInterval = days * 24 * 60 * 60 * -1.0f;
    NSDate *dateDelete = [NSDate dateWithTimeIntervalSinceNow:timeInterval];

    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterFullStyle];
        dateFormatter.dateFormat = @"yyyyMMdd";
    }

    NSString *dateDeleteString = [dateFormatter stringFromDate:dateDelete];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"date < %@", dateDeleteString];
    [request setPredicate:predicate];
    
    BOOL ret = FALSE;
    NSArray* result = [context executeFetchRequest:request error:&error];
    if (result && !error && [result count] > 0) {
        ret = TRUE;
#ifdef DEBUG
        NSLog(@"%s, dateDelete %@",__FUNCTION__, dateDelete);
#endif
        
        for (Date *date in result) {
            [context deleteObject:date];
        }
    }
    return ret;
}

@end