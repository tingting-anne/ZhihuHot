//
//  DailyTableViewController.m
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/17.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import "DailyTableViewController.h"
#import "AppDelegate.h"
#import "AppHelper.h"
#import "SWRevealViewController.h"
#import "Story.h"
#import "Date.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "DailyTableSectionHeader.h"
#import "ContentViewController.h"
#import "Definitions.h"
#import "NetClient.h"
#import "ListTableViewCell.h"

#define HEIGHT_OF_SECTION_HEADER 30.0f

@interface DailyTableViewController ()
{
    EGORefreshTableHeaderView *_refreshHeaderView;
    BOOL _reloading;
    
    //保存初始内容，EGOTableViewPullRefreshAndLoadMore执行完后要重新赋值，否则导航条会遮挡住表单元
    //originContentInset[64,0,0,0] originContentOffset[0, -64]
    CGPoint originContentOffset;
    UIEdgeInsets originContentInset;
}

@property(strong,nonatomic)NSFetchedResultsController* fetchedResultsController;
@property(strong,nonatomic)NSManagedObjectContext* managedObjectContext;
@property(strong,nonatomic)NetClient* netClient;

-(NSString *)headerStringFormateWithDate:(NSString *)dateString;
-(void)updateLatestStories;

- (void)reloadTableViewDataSource;

@end

@implementation DailyTableViewController

#pragma mark -

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    AppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = [appDelegate managedObjectContext];
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    _managedObjectContext = managedObjectContext;
    self.netClient = [[NetClient alloc] initWithManagedObjectContext:self.managedObjectContext];
    
    if (_managedObjectContext == nil) {
        NSLog(@"%s error managedObjectContext is nil", __FUNCTION__);
        
        self.fetchedResultsController = nil;
    }
    else
    {
        NSFetchRequest* request = [[NSFetchRequest alloc] init];
        NSEntityDescription* entityDescription = [NSEntityDescription entityForName:@"Story" inManagedObjectContext:self.managedObjectContext];
        [request setEntity:entityDescription];
        
        NSSortDescriptor *sortDescription = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:NO];
        [request setSortDescriptors:@[sortDescription]];
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"date.date" cacheName:nil];
        
        self.fetchedResultsController.delegate = self;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
//    self.menuBarButtonItem.target = self.revealViewController;//SWRevealViewController
//    self.menuBarButtonItem.action = @selector(revealToggle:);
    
    //[self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    //[self.view addGestureRecognizer:self.revealViewController.tapGestureRecognizer];
    
    if (_refreshHeaderView == nil) {
        
        EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
        
//        NSLog(@"%lf, %lf, %lf, %lf, [%lf,%lf,%lf,%lf]", self.tableView.frame.origin.x,self.tableView.frame.origin.y, self.tableView.frame.size.height, self.view.frame.size.width,
//              self.navigationController.navigationBar.frame.origin.x, self.navigationController.navigationBar.frame.origin.y,
//             self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.frame.size.height);
        
        view.delegate = self;
        [self.tableView addSubview:view];
        _refreshHeaderView = view;
        [_refreshHeaderView refreshLastUpdatedDate];
    }
    
    [self updateLatestStories];
    
    NSError *error;
    BOOL success = [self.fetchedResultsController performFetch:&error];
    if (!success){
        NSLog(@"[%@ %@] performFetch: failed", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    }
    if (error) {
        NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
    }
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(self.revealViewController){
        self.menuBarButtonItem.target = self.revealViewController;//SWRevealViewController
        self.menuBarButtonItem.action = @selector(revealToggle:);
        
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
        [self.view addGestureRecognizer:self.revealViewController.tapGestureRecognizer];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    originContentOffset = self.tableView.contentOffset;
    originContentInset = self.tableView.contentInset;
}

#pragma mark -

-(void)updateLatestStories
{
    static NSDate* preDate = nil;
    
    NSTimeInterval interval = 0.0;
    if(preDate == nil){
        preDate = [NSDate date];
        //interval = UPDATECONTENTINTERVAL;
    }
    else{
        NSDate* current = [NSDate date];
        interval = [current timeIntervalSinceDate:preDate];
        preDate = current;
    }
    
    if (interval >= UPDATECONTENTINTERVAL) {
        [self.netClient downloadLatestStoriesWithCompletionHandler:nil];
    }
}

-(NSString *)headerStringFormateWithDate:(NSString *)dateString
{
    if ([[AppHelper shareAppHelper] isValidDateString:dateString]) {
        if ([[AppHelper shareAppHelper] isTodayWithDateString:dateString]) {
            return @"今日";
        }
        
        static NSDateFormatter *dateFormatter = nil;
        
        if (!dateFormatter)
        {
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateStyle = NSDateFormatterFullStyle;
            dateFormatter.dateFormat = @"yyyyMMdd";
            NSDate *date = [dateFormatter dateFromString:dateString];
            
            NSString *dateComponent = @"MMMd EEEE";
            NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:dateComponent options:0 locale:[NSLocale currentLocale]];
            [dateFormatter setDateFormat:dateFormat];
            
            return [dateFormatter stringFromDate:date];
        }
    }
    return nil;
}

- (void)reloadTableViewDataSource{
    _reloading = YES;
    
    [self.netClient downloadLatestStoriesWithCompletionHandler:^(NSError* error){
        
        _reloading = NO;
        [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
        
        if(!error){
            
//            self.tableView.contentInset = UIEdgeInsetsMake(self.navigationController.navigationBar.frame.size.height+self.navigationController.navigationBar.frame.origin.y,0, 0, 0);
//            
//            CGPoint point;
//            point.x = 0.0f;
//            point.y = 0.0f - 64.0f;
//            self.tableView.contentOffset = point;
        
            self.tableView.contentInset = originContentInset;
            self.tableView.contentOffset = originContentOffset;
            
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


#pragma mark -Table view delegate

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 0.0f;
    }
    else{
        return HEIGHT_OF_SECTION_HEADER;
    }
        
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return nil;
    }
    
    CGRect headerRect = {{0,0}, {self.tableView.frame.size.width, HEIGHT_OF_SECTION_HEADER}};
    
    NSArray *bundleSource = [[NSBundle mainBundle] loadNibNamed:@"DailyTableSectionHeader" owner:self options:nil];
    DailyTableSectionHeader *sectionHeaderView = [bundleSource firstObject];
    sectionHeaderView.frame = headerRect;
    
    NSString *dateString = [[[self.fetchedResultsController sections] objectAtIndex:section] name];
    NSString *headerString = [self headerStringFormateWithDate:dateString];
    sectionHeaderView.headerString.text = headerString;
    
    return sectionHeaderView;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger sectionNum = [self.fetchedResultsController.sections count];
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:indexPath.section];
    NSUInteger rowNumOfSection = sectionInfo.numberOfObjects;
    if (indexPath.section == (sectionNum -1) && indexPath.row == (rowNumOfSection - 1)) {
        
        Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
        NSString *currentDateString = story.date.date;
        
        [self.netClient downloadBeforeDate:currentDateString withCompletionHandler:nil];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90.0f;
}

#pragma mark - Table view data source delegate

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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString *imageURL = story.images;
    ListTableViewCell *cell = nil;
    
    if (imageURL) {
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"hasImageStoryCell" forIndexPath:indexPath];
        
        [cell.customImageView sd_setImageWithURL:[NSURL URLWithString:imageURL] placeholderImage:[UIImage imageNamed:@"placeholder"]];
    }
    else{
        cell = [tableView dequeueReusableCellWithIdentifier:@"storyCell" forIndexPath:indexPath];
    }
    cell.customeLabel.text = story.title;
    
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"storyCell" forIndexPath:indexPath];
//    cell.textLabel.text = @"111";
    
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
    
    if ([segue.destinationViewController isKindOfClass:[ContentViewController class]]) {
        ContentViewController *contentViewController = segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        
        Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
        contentViewController.contentType = DAILY_STORY_CONTENT;
        contentViewController.newsID = story.id;
    }
    else{
        NSLog(@"%s error", __FUNCTION__);
    }
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
