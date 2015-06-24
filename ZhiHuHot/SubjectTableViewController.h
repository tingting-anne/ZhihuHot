//
//  SubjectTableViewController.h
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/17.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "EGOTableViewPullRefreshAndLoadMore/EGORefreshTableHeaderView.h"

@interface SubjectTableViewController : UITableViewController<NSFetchedResultsControllerDelegate,EGORefreshTableHeaderDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuBarButtonItem;
@property (strong, nonatomic) NSNumber* themeID;

@end