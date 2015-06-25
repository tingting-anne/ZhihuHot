//
//  SubjectTableViewController.m
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/17.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import "SubjectTableViewController.h"
#import "AppDelegate.h"
#import "AppHelper.h"
#import "SWRevealViewController.h"
#import "Theme.h"
#import "ThemeStory.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "ContentViewController.h"
#import "Definitions.h"
#import "NetClient.h"
#import "ListTableViewCell.h"

@interface SubjectTableViewController ()
{
    EGORefreshTableHeaderView *_refreshHeaderView;
    BOOL _reloading;
}
@property(strong,nonatomic)NSFetchedResultsController* fetchedResultsController;
@property(strong,nonatomic)NSManagedObjectContext* managedObjectContext;
@property(strong, nonatomic)NetClient* netClient;

-(void)updateThemeStories;
- (void)reloadTableViewDataSource;

@end

@implementation SubjectTableViewController

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    AppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = [appDelegate managedObjectContext];
    
    self.netClient = [[NetClient alloc] initWithManagedObjectContext:self.managedObjectContext];
}

-(void)setThemeID:(NSNumber*)themeID
{
    _themeID = themeID;
    
    [self updateThemeStories];
    
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription* entityDescription = [NSEntityDescription entityForName:@"ThemeStory" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entityDescription];
    
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"them.id = %@", self.themeID];
    [request setPredicate:predicate];
    
    NSSortDescriptor *sortDescription = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:NO];
    [request setSortDescriptors:@[sortDescription]];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    self.fetchedResultsController.delegate = self;
    
    NSError *error;
    BOOL success = [self.fetchedResultsController performFetch:&error];
    if (!success) NSLog(@"[%@ %@] performFetch: failed", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    if (error) {
        NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
    }
    [self.tableView reloadData];
}

-(void)updateThemeStories
{
    static NSMutableDictionary* themeUpdateDate = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        themeUpdateDate = [[NSMutableDictionary alloc] init];
    });

    NSTimeInterval interval = 0.0;
    NSDate* preDate = [themeUpdateDate objectForKey:self.themeID];
    
    if(preDate == nil){
        [themeUpdateDate setObject:[NSDate date] forKey:self.themeID];
        interval = UPDATECONTENTINTERVAL;
    }
    else{
        NSDate* current = [NSDate date];
        interval = [current timeIntervalSinceDate:preDate];
        preDate = current;
    }
    
    if (interval >= UPDATECONTENTINTERVAL) {
        [self.netClient downloadThemeStoriesWithThemeID:[self.themeID unsignedLongLongValue] withCompletionHandler:nil];
    }
    
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    _managedObjectContext = managedObjectContext;
    
    if (_managedObjectContext == nil) {
        NSLog(@"%s error managedObjectContext is nil", __FUNCTION__);
        
        self.fetchedResultsController = nil;
        abort();
    }
}

- (void)reloadTableViewDataSource{
    _reloading = YES;
    
    [self.netClient downloadThemeStoriesWithThemeID:[self.themeID unsignedLongLongValue] withCompletionHandler:^(NSError* error){
        
        _reloading = NO;
        [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
        
        if(!error){
            //[self.tableView reloadData];
        }
        else{
#ifdef DEBUG
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Load content error" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
            [alertView show];
#endif
        }
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
//    self.menuBarButtonItem.target = self.revealViewController;//SWRevealViewController
//    self.menuBarButtonItem.action = @selector(revealToggle:);
//
//    
//    if(self.revealViewController)
//    {
//        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
//    }
    
    if(_refreshHeaderView == nil) {
        
        EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
        
        view.delegate = self;
        [self.tableView addSubview:view];
        _refreshHeaderView = view;
        [_refreshHeaderView refreshLastUpdatedDate];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(self.revealViewController)
    {
        self.menuBarButtonItem.target = self.revealViewController;//SWRevealViewController
        self.menuBarButtonItem.action = @selector(revealToggle:);

        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [_refreshHeaderView setOriginContentOffset:self.tableView.contentOffset insets:self.tableView.contentInset];
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger sectionNum = [self.fetchedResultsController.sections count];
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:indexPath.section];
    NSUInteger rowNumOfSection = sectionInfo.numberOfObjects;
    if (indexPath.section == (sectionNum -1) && indexPath.row == (rowNumOfSection - 1)) {
        
        [self.netClient downloadThemeStoriesWithThemeID:[self.themeID unsignedLongLongValue] withCompletionHandler:nil];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    if ([[self.fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        rows = [sectionInfo numberOfObjects];
    }
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ThemeStory *themeStory = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString *imageURL = themeStory.images;
    
    ListTableViewCell* cell = nil;
    
    if (imageURL) {
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"hasImageThemeCell" forIndexPath:indexPath];
        
        [cell.customImageView sd_setImageWithURL:[NSURL URLWithString:imageURL] placeholderImage:[UIImage imageNamed:@"placeholder"]];
    }
    else{
        cell = [tableView dequeueReusableCellWithIdentifier:@"themeCell" forIndexPath:indexPath];
    }
    cell.customeLabel.text = themeStory.title;
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ContentViewController *contentViewController = segue.destinationViewController;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    
    ThemeStory *themeStory = [self.fetchedResultsController objectAtIndexPath:indexPath];
    contentViewController.contentType = THEME_STORY_CONTENT;
    contentViewController.newsID = themeStory.id;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    [_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    [_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

#pragma mark EGORefreshTableHeaderDelegate Methods
//下拉到一定距离，手指放开时调用
- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
    
    [self reloadTableViewDataSource];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
    
    return _reloading; // should return if data source model is reloading
    
}

//取得下拉刷新的时间
- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
    
    return [NSDate date]; // should return date data source was last changed
    
}

@end
