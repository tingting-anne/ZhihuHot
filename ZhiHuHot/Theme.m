//
//  Theme.m
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/18.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import "Theme.h"
#import "ThemeStory.h"


@implementation Theme

@dynamic thumbnail;
@dynamic id;
@dynamic sortId;
@dynamic name;
@dynamic themStories;

@end

@implementation Theme(Load)

+(void)loadFromArray:(NSArray *)array intoManagedObjectContext:(NSManagedObjectContext *)context
{
    Theme *theme = nil;
    NSError *error = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Theme"];
    
    NSArray* resultChage = [context executeFetchRequest:request error:&error];
    if ([resultChage count] == [array count]) {
        resultChage = nil;
        return;
    }
    
    UInt32 sortId = 0;
    for (NSDictionary *themeDic in array) {
        request.predicate = [NSPredicate predicateWithFormat:@"id = %@", themeDic[@"id"]];
        NSArray *resultArray = [context executeFetchRequest:request error:&error];
        
        if (!resultArray || error || [resultArray count] > 1) {
            NSLog(@"ERROR in %s", __FUNCTION__);
        }else if ([resultArray count] <= 0) {
            theme = [NSEntityDescription insertNewObjectForEntityForName:@"Theme" inManagedObjectContext:context];
            theme.id = themeDic[@"id"];
            theme.name = themeDic[@"name"];
            theme.thumbnail = themeDic[@"thumbnail"];
            theme.sortId = [NSNumber numberWithUnsignedInt:sortId];
        }
        else{
            theme = resultArray[0];
            if ([theme.sortId unsignedIntegerValue] != sortId) {
                theme.name = themeDic[@"name"];
                theme.thumbnail = themeDic[@"thumbnail"];
                theme.sortId = [NSNumber numberWithUnsignedInt:sortId];
            }
        }
        sortId++;
    }
}

+(Theme *)getThemeWithID:(NSUInteger)thmeID inManagedObjectContext:(NSManagedObjectContext *)context
{
    Theme *theme = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Theme"];
    request.predicate = [NSPredicate predicateWithFormat:@"id = %lu", thmeID];
    
    NSError *error;
    NSArray *resultArray = [context executeFetchRequest:request error:&error];
    
    if (resultArray && !error && [resultArray count] == 1) {
        theme = resultArray.firstObject;
    } else {
        NSLog(@"ERROR in %s", __FUNCTION__);
    }
    
    return theme;

}
@end