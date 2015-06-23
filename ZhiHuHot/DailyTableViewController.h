//
//  DailyTableViewController.h
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/17.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface DailyTableViewController : UITableViewController<NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuBarButtonItem;

@end
