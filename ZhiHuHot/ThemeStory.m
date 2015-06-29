//
//  ThemeStory.m
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/18.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import "ThemeStory.h"
#import "Theme.h"


@implementation ThemeStory

@dynamic id;
@dynamic images;
@dynamic title;
@dynamic them;

@end


@implementation ThemeStory(Load)

+(void)loadFromArray:(NSArray *)array withThemeID:(NSUInteger)themeID intoManagedObjectContext:(NSManagedObjectContext *)context
{
    for (NSDictionary *storyDictionary in array) {
        ThemeStory *story =  nil;
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ThemeStory"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"id = %@", storyDictionary[@"id"]];
        
        NSError *error;
        NSArray *matchedResult = [context executeFetchRequest:fetchRequest error:&error];
        
        //If no objects match the criteria specified by request, returns an empty array.
        if (matchedResult == nil || error || [matchedResult count] > 1) {
            NSLog(@"Error in %s", __FUNCTION__);
        } else if ([matchedResult count] <= 0) {
            
            Theme* theme = [Theme getThemeWithID:themeID inManagedObjectContext:context];
            if(theme != nil){
                story = [NSEntityDescription insertNewObjectForEntityForName:@"ThemeStory" inManagedObjectContext:context];
                story.id = storyDictionary[@"id"];
                story.title = storyDictionary[@"title"];
                story.images = storyDictionary[@"images"][0];
                story.them = theme;
            }
            else{
                NSLog(@"%s has a them story which id[%u] has no them", __FUNCTION__, themeID);
            }
        }
    }
}

@end