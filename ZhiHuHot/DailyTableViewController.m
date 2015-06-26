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
#define HEIGHT_OF_CELL 90.0f

@interface DailyTableViewController ()
{
    //----- 下拉刷新------
    EGORefreshTableHeaderView *_refreshHeaderView;
    BOOL _reloading;
    
    //------上拉刷新------
    LoadMoreTableFooterView *loadMoreTableFooterView;
    BOOL isLoadMoreing;
    
    //用于上拉刷新异步
    BOOL lastCell;
    NSString *currentDateString;
    
    //------navigationItem标题修改------
    DailyTableSectionHeader* lastestSectionView;
    NSInteger latestSection;
    
    //判断拉动方向
    CGFloat startContentOffsetY;
//    CGFloat willEndContentOffsetY;
//    CGFloat endContentOffsetY;
}

@property(strong,nonatomic)NSFetchedResultsController* fetchedResultsController;
@property(strong,nonatomic)NSManagedObjectContext* managedObjectContext;
@property(strong,nonatomic)NetClient* netClient;

-(NSString *)headerStringFormateWithDate:(NSString *)dateString;
-(void)updateLatestStories;
- (void)reloadTableViewDataSource;
- (void)resetMoreFrame;
- (void)resetForNavItemTitle:(CGFloat)endOffsetY;

@end

@implementation DailyTableViewController

#pragma mark -

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    AppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = [appDelegate managedObjectContext];
    
    if (_refreshHeaderView == nil) {
        
        EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
        
        view.delegate = self;
        [self.tableView addSubview:view];
        _refreshHeaderView = view;
        [_refreshHeaderView refreshLastUpdatedDate];
    }
    
    if (loadMoreTableFooterView == nil)
    {
        loadMoreTableFooterView = [[LoadMoreTableFooterView alloc] initWithFrame:CGRectMake(0.0f, self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
        loadMoreTableFooterView.delegate = self;
        [self.tableView addSubview:loadMoreTableFooterView];
    }
    latestSection = 0;
    lastestSectionView = nil;
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
        
        NSSortDescriptor *sortDate = [[NSSortDescriptor alloc] initWithKey:@"date.date" ascending:NO];
        NSSortDescriptor *sortID = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:NO];
        [request setSortDescriptors:[NSArray arrayWithObjects:sortDate, sortID, nil]];
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"date.date" cacheName:nil];
        
        self.fetchedResultsController.delegate = self;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#ifdef DEBUG
   // [self notification];
#endif
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
//    self.menuBarButtonItem.target = self.revealViewController;//SWRevealViewController
//    self.menuBarButtonItem.action = @selector(revealToggle:);
    
    //[self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    //[self.view addGestureRecognizer:self.revealViewController.tapGestureRecognizer];
    
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
    
    [_refreshHeaderView setOriginContentOffset:self.tableView.contentOffset insets:self.tableView.contentInset];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

#pragma mark -

- (void)resetMoreFrame
{
    loadMoreTableFooterView.frame = CGRectMake(0.0f, self.tableView.contentSize.height, self.view.frame.size.width, self.tableView.bounds.size.height);
}

- (void)resetForNavItemTitle:(CGFloat)endOffsetY
{
   //lastestSectionView=nil说明没用拉动
    if (lastestSectionView){
        SCROLL_DIRECTION_ENUM direction = SCROLL_DIRECTION_NUM;
        if (endOffsetY < startContentOffsetY) { //下拉
            direction = SCROLL_DIRECTION_DOWN;
        } else if (endOffsetY > startContentOffsetY) {//上拉
            direction = SCROLL_DIRECTION_UP;
        }
        NSLog(@"%lf, %lf", lastestSectionView.frame.origin.y,self.tableView.contentInset.top);
        CGFloat headerHieght = self.navigationController.navigationBar.frame.size.height + [[UIApplication sharedApplication] statusBarFrame].size.height;
        if (direction == SCROLL_DIRECTION_DOWN && lastestSectionView.frame.origin.y - headerHieght >= self.tableView.contentOffset.y) {
            
            NSIndexPath *objectIndexPath = [NSIndexPath indexPathForRow:0 inSection:latestSection-1];
            Story *story = [self.fetchedResultsController objectAtIndexPath:objectIndexPath];
            if(story.date.date != self.navigationItem.title){
                self.navigationItem.title = [self headerStringFormateWithDate:story.date.date];
            }
        }
        else if (direction == SCROLL_DIRECTION_UP && (lastestSectionView.frame.origin.y - (headerHieght - HEIGHT_OF_SECTION_HEADER)) <= self.tableView.contentOffset.y) {
            if(lastestSectionView.headerString.text != self.navigationItem.title){
                self.navigationItem.title = lastestSectionView.headerString.text;
            }
        }
    }
}

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
            return NSLocalizedString(@"DAILY_LATEST", @"today's news");
        }
        
        static NSDateFormatter *dateFormatter = nil;
        
        if (!dateFormatter)
        {
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateStyle = NSDateFormatterFullStyle;
        }
        dateFormatter.dateFormat = @"yyyyMMdd";
        NSDate *date = [dateFormatter dateFromString:dateString];
        
        NSString *dateComponent = @"MMMd EEEE";
        NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:dateComponent options:0 locale:[NSLocale currentLocale]];
        [dateFormatter setDateFormat:dateFormat];
    
        return [dateFormatter stringFromDate:date];
    }
    return nil;
}

- (void)reloadTableViewDataSource{
    _reloading = YES;
    
    [self.netClient downloadLatestStoriesWithCompletionHandler:^(NSError* error){
        
        _reloading = NO;
        
        [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
        
        if(error){
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR", nil) message:NSLocalizedString(@"NET_DOWNLOAD_ERROR", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)  otherButtonTitles:nil, nil];
            [alertView show];
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
    
    lastestSectionView = sectionHeaderView;
    latestSection = section;
    return sectionHeaderView;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger sectionNum = [self.fetchedResultsController.sections count];
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:indexPath.section];
    NSUInteger rowNumOfSection = sectionInfo.numberOfObjects;
    if (indexPath.section == (sectionNum -1) && indexPath.row == (rowNumOfSection - 1)) {
        
        lastCell = TRUE;
        Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
        currentDateString = story.date.date;
    }
    
    if (self.tableView.contentSize.height > self.view.bounds.size.height
        && self.tableView.contentSize.height > loadMoreTableFooterView.frame.origin.y) {
        [self resetMoreFrame];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return HEIGHT_OF_CELL;
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
    if (!_reloading && !isLoadMoreing && [_refreshHeaderView getState] == EGOOPullRefreshNormal
        && [loadMoreTableFooterView getState] == PullLoadMoreNormal) {
        
        //解决sectionHeaderView卡在navigationBar下面的问题
        CGFloat sectionHeaderHeight = HEIGHT_OF_SECTION_HEADER;
        if (scrollView.contentOffset.y <= sectionHeaderHeight && scrollView.contentOffset.y >= 0) {
            scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, scrollView.contentInset.left, scrollView.contentInset.bottom, scrollView.contentInset.right);
        } else if (scrollView.contentOffset.y>=sectionHeaderHeight) {
            scrollView.contentInset = UIEdgeInsetsMake(-sectionHeaderHeight, scrollView.contentInset.left, scrollView.contentInset.bottom, scrollView.contentInset.right);
        }
    }
    
    [_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    
    if(lastCell)
    {
        [loadMoreTableFooterView loadMoreScrollViewDidScroll:scrollView];
    }
    
//    NSLog(@"insert:[%lf, %lf, %lf, %lf], offset:[%lf, %lf]", scrollView.contentInset.top,
//          scrollView.contentInset.left, scrollView.contentInset.bottom,scrollView.contentInset.right,scrollView.contentOffset.x, scrollView.contentOffset.y);
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{ //拖动前的起始坐标
    startContentOffsetY = scrollView.contentOffset.y;
}

//- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{ //将要停止前的坐标
//    willEndContentOffsetY = scrollView.contentOffset.y;
//}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    [_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
    
    if(lastCell)
    {
        [loadMoreTableFooterView loadMoreScrollViewDidEndDragging:scrollView];
    }
    [self resetForNavItemTitle:scrollView.contentOffset.y];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //防止继续滚动导致出现新的section
    [self resetForNavItemTitle:scrollView.contentOffset.y];
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

#pragma mark LoadMoreTableFooterDelegate Methods

- (void)loadMoreTableFooterDidTriggerLoadMore:(LoadMoreTableFooterView*)view
{
    isLoadMoreing = YES;
    
    [self.netClient downloadBeforeDate:currentDateString withCompletionHandler:^(NSError *error){
        
        isLoadMoreing = NO;
        
        [loadMoreTableFooterView loadMoreScrollViewDataSourceDidFinishedLoading:self.tableView];
        
        if(error){
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR", nil) message:NSLocalizedString(@"NET_DOWNLOAD_ERROR", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)  otherButtonTitles:nil, nil];
            [alertView show];
        }
        else{
            lastCell = FALSE;
        }
    }];
}

- (BOOL)loadMoreTableFooterDataSourceIsLoading:(LoadMoreTableFooterView*)view
{
    return isLoadMoreing;
}

#pragma mark test mothed
-(void)notification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notificationEvent:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:self.managedObjectContext];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notificationEvent:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:self.managedObjectContext];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notificationEvent:)
                                                 name:NSManagedObjectContextWillSaveNotification
                                               object:self.managedObjectContext];
}

-(void)notificationEvent:(NSNotification*)notify
{
    NSLog(@"%s: %@", __FUNCTION__,[notify description]);
}

@end
