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
#import "TopStory.h"
#import "Date.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "DailyTableSectionHeader.h"
#import "ContentViewController.h"
#import "Definitions.h"
#import "NetClient.h"
#import "ListTableViewCell.h"
#import "ImagesScrollView.h"

#define HEIGHT_OF_SECTION_HEADER 30.0f
#define HEIGHT_OF_CELL 90.0f
#define HEIGHT_OF_FIRST_SECTION_HEADER 240.0f

@interface DailyTableViewController ()<ImagesScrollViewDelegate, SWRevealViewControllerDelegate>
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
    UIEdgeInsets originContentInset;
    
    //判断拉动方向
    CGFloat startContentOffsetY;
    SCROLL_DIRECTION_ENUM direction;
    CGSize originContentSize;
}

@property(strong,nonatomic)NSFetchedResultsController* fetchedResultsController;
@property(strong,nonatomic)NSManagedObjectContext* managedObjectContext;
@property(strong,nonatomic)NetClient* netClient;
@property(strong,nonatomic)ImagesScrollView * scrollView;
@property(strong,nonatomic)UIView* firstSectionView;

- (void)localeChanged:(NSNotification *)notif;
-(NSString *)headerStringFormateWithDate:(NSString *)dateString;
-(BOOL)updateLatestStories;
- (void)reloadTableViewDataSource;
- (void)resetMoreFrame;
- (void)resetForNavItemTitle:(CGFloat)endOffsetY;
- (void)createScrollView;
- (void)setTopStories:(NSArray*) topStories;
- (void)didSelectedNewsID:(NSNumber*)newsID;

- (void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position;

@end

@implementation DailyTableViewController

#pragma mark -

- (void)localeChanged:(NSNotification *)notif
{
    // the user changed the locale (region format) in Settings, so we are notified here to
    // update the date format in the table view cells
    //
    [self.tableView reloadData];
}

#pragma mark - 构建图片滚动视图
- (void)createScrollView
{
    CGRect headerRect = {{0,64}, {self.tableView.frame.size.width, HEIGHT_OF_FIRST_SECTION_HEADER}};
    self.firstSectionView = [[UIView alloc] initWithFrame:headerRect];
    
    self.scrollView = [[ImagesScrollView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, HEIGHT_OF_FIRST_SECTION_HEADER)];
    //如果滚动视图的父视图由导航控制器控制,必须要设置该属性(ps,猜测这是为了正常显示,导航控制器内部设置了UIEdgeInsetsMake(64, 0, 0, 0))
    [self.firstSectionView addSubview:self.scrollView];
    
    self.scrollView.imageScrolldelegate = self;
    self.scrollView.PageControlShowStyle = UIPageControlShowStyleCenter;
    //self.scrollView.pageControl.pageIndicatorTintColor = [UIColor blueColor];
    //self.scrollView.pageControl.currentPageIndicatorTintColor = [UIColor purpleColor];
    
    //由于PageControl这个空间必须要添加在滚动视图的父视图上(添加在滚动视图上的话会随着图片滚动,而达不到效果)
    [self.firstSectionView addSubview:self.scrollView.pageControl];
}

-(void)setTopStories:(NSArray *)topStories
{
    static NSArray* preTopStories = nil;
    
    if (!topStories) {
        if(!preTopStories){
            //用数据库中的数据
            NSLog(@"[%@ %@] updateLatestStories: failed, use DB to update top stories", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
            
            preTopStories = [TopStory getArrayFromManagedObjectContext:self.managedObjectContext];
        }
        
        topStories = preTopStories;
    }
    else{
        preTopStories = topStories;
    }

    if (topStories && topStories.count > 0) {
        NSMutableArray* imageNameArray = [[NSMutableArray alloc] initWithObjects:nil];
        NSMutableArray* titleArray = [[NSMutableArray alloc] initWithObjects:nil];
        NSMutableArray* idArray = [[NSMutableArray alloc] initWithObjects:nil];
        
        for (NSDictionary *dic in topStories) {
            [imageNameArray addObject:dic[@"image"]];
            [titleArray addObject:dic[@"title"]];
            [idArray addObject:dic[@"id"]];
        }
        
        [self.scrollView setImageArray:imageNameArray titleArray:titleArray newsID:idArray];
    }
}

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
    memset(&originContentSize, 0, sizeof(CGSize));
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    _managedObjectContext = managedObjectContext;
    self.netClient = [[NetClient alloc] init];
    
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
        NSSortDescriptor *sortID = [[NSSortDescriptor alloc] initWithKey:@"sortId" ascending:YES];
        [request setSortDescriptors:[NSArray arrayWithObjects:sortDate, sortID, nil]];
        
        [request setFetchBatchSize:20];
        
        //CoreData: annotation: fault fulfilled from database for
        
        //pre-fetch the relationship, since otherwise it would have to hit the persistent store every time, which is slower
        [request setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"date"]];
        
        //tell fetch request to return full objects
        [request setReturnsObjectsAsFaults:NO];
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"date.date" cacheName:@"DailyCache"];
        
        self.fetchedResultsController.delegate = self;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createScrollView];
    
    // if the local changes behind our back, we need to be notified so we can update the date
    // format in the table view cells
    //
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(localeChanged:)
                                                 name:NSCurrentLocaleDidChangeNotification
                                               object:nil];
    
#ifdef DEBUG
    //[self notification];
#endif
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
//    self.menuBarButtonItem.target = self.revealViewController;//SWRevealViewController
//    self.menuBarButtonItem.action = @selector(revealToggle:);
    
    //[self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    //[self.view addGestureRecognizer:self.revealViewController.tapGestureRecognizer];
    
    if(![self updateLatestStories])
    {
        [self setTopStories:nil];
    }
    
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSCurrentLocaleDidChangeNotification
                                                  object:nil];
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
        
        self.revealViewController.delegate = self;
        self.revealViewController.rearViewRevealWidth = 220.0f;
        self.revealViewController.rearViewRevealOverdraw = 0.0f;
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    originContentInset = self.tableView.contentInset;

    //进入ContentViewController页面后再返回，offset变了，所以这里写死
    [_refreshHeaderView setOriginContentOffset:CGPointMake(0.0f, -64.0f) insets:UIEdgeInsetsMake(64.0f, 0.0f, 0.0f, 0.0f)];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.scrollView stopScrollTimer];
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
        direction = SCROLL_DIRECTION_NUM;
        if (endOffsetY < startContentOffsetY) { //下拉
            direction = SCROLL_DIRECTION_DOWN;
        } else if (endOffsetY > startContentOffsetY) {//上拉
            direction = SCROLL_DIRECTION_UP;
        }
        //NSLog(@"%lf, %lf", lastestSectionView.frame.origin.y,self.tableView.contentInset.top);
        CGFloat headerHieght = self.navigationController.navigationBar.frame.size.height + [[UIApplication sharedApplication] statusBarFrame].size.height;
        if (direction == SCROLL_DIRECTION_DOWN && lastestSectionView.frame.origin.y - headerHieght >= self.tableView.contentOffset.y) {
            
            NSIndexPath *objectIndexPath = [NSIndexPath indexPathForRow:0 inSection:latestSection-1];
            Story *story = [self.fetchedResultsController objectAtIndexPath:objectIndexPath];
            self.navigationItem.title = [self headerStringFormateWithDate:story.date.date];
        }
        else if (direction == SCROLL_DIRECTION_UP && (lastestSectionView.frame.origin.y - (headerHieght - HEIGHT_OF_SECTION_HEADER)) <= self.tableView.contentOffset.y) {
            if(lastestSectionView.headerString.text != self.navigationItem.title){
                self.navigationItem.title = lastestSectionView.headerString.text;
            }
        }
    }
}

-(BOOL)updateLatestStories
{
    static NSDate* preDate = nil;
    
    NSTimeInterval interval = 0.0;
    if(preDate == nil){
        preDate = [NSDate date];
        interval = UPDATECONTENTINTERVAL;
    }
    else{
        NSDate* current = [NSDate date];
        interval = [current timeIntervalSinceDate:preDate];
        preDate = current;
    }
    
    BOOL ret = FALSE;
    if (interval >= UPDATECONTENTINTERVAL) {
        ret = TRUE;
        [self.netClient downloadLatestStoriesWithCompletionHandler:^(NSError* error){
            if(error){
                [[AppHelper shareAppHelper] showAlertViewWithError:error type:NET_DOWNLOAD_ERROR];
            }
        } topStoriesCompletionHandler:^(NSArray* topStories){
            //为空也要设置，会根据数据库的值显示
            [self setTopStories:topStories];
        }];
    }
    return ret;
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
            [[AppHelper shareAppHelper] showAlertViewWithError:error type:NET_DOWNLOAD_ERROR];
        }
    } topStoriesCompletionHandler:^(NSArray* topStories){
        if (topStories) {
            [self setTopStories:topStories];
        }
    }];
}

- (void)didSelectedNewsID:(NSNumber*)newsID
{
#ifdef DEBUG
    NSLog(@"you click ImageScrollView newsID:%d", [newsID intValue]);
#endif

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ContentViewController *contentViewController = [storyboard instantiateViewControllerWithIdentifier:@"contentViewController"];
    
    contentViewController.contentType = DAILY_STORY_CONTENT;
    contentViewController.newsID = newsID;
    [self.navigationController pushViewController:contentViewController animated:YES];
}

- (void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position
{
    if (FrontViewPositionLeft == position) {
        [self.scrollView setImageViewUserInteractionEnabled:TRUE];
    }
    else if(FrontViewPositionRight == position){
        [self.scrollView setImageViewUserInteractionEnabled:FALSE];
    }
}

#pragma mark -Table view delegate

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return HEIGHT_OF_FIRST_SECTION_HEADER;
    }
    else{
        return HEIGHT_OF_SECTION_HEADER;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return self.firstSectionView;
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

    sectionHeaderView.backgroundColor = [UIColor colorWithRed:0.3f green:0.6f blue:1.0f alpha:0.9f];
    sectionHeaderView.headerString.font = [UIFont fontWithName:@"Arial Rounded MT Bold" size:19.0f];
    sectionHeaderView.headerString.textColor = [UIColor whiteColor];
    
    return sectionHeaderView;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger sectionNum = [self.fetchedResultsController.sections count];
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:indexPath.section];
    NSUInteger rowNumOfSection = sectionInfo.numberOfObjects;
    
    if (indexPath.row == (rowNumOfSection - 1)){ //当前section最后一个cell
        
        static NSDateFormatter *dateFormatter = nil;
        
        if (!dateFormatter)
        {
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateStyle = NSDateFormatterFullStyle;
            dateFormatter.dateFormat = @"yyyyMMdd";
        }
        
        Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
        currentDateString = story.date.date;
        
        if(indexPath.section == (sectionNum -1)){ //最后一个section
            lastCell = TRUE;
        }
        else{
            NSDate *currentDate = [dateFormatter dateFromString:currentDateString];
            
            if (SCROLL_DIRECTION_UP == direction) {
                NSIndexPath* nextIndexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section+1];
                Story *nextStory = [self.fetchedResultsController objectAtIndexPath:nextIndexPath];
                
                if (!nextStory.date.isLatest) {//不是最新数据
                    [self.netClient downloadBeforeDate:currentDateString withCompletionHandler:nil];
                }
                else{
                    NSTimeInterval interval = -60*60*24;
                    NSDate *shouldDate = [NSDate dateWithTimeInterval:interval sinceDate:currentDate];
                    NSDate *nextDate = [dateFormatter dateFromString:nextStory.date.date];
                    
                    if([shouldDate compare:nextDate] != NSOrderedSame){//日期不连续
                        lastCell = TRUE;
                        
                        originContentSize = self.tableView.contentSize;//便于出措时还原
                        CGSize contentSize = self.tableView.contentSize;
                        contentSize.height  = cell.frame.origin.y + cell.frame.size.height;
                        self.tableView.contentSize = contentSize;
                        [self resetMoreFrame];
                    }
                    else if (lastCell) {//还原
                        lastCell = FALSE;
                    }
                }
            }
            else if(SCROLL_DIRECTION_DOWN == direction && indexPath.section > 0){
                NSIndexPath* nextIndexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section-1];
                Story *nextStory = [self.fetchedResultsController objectAtIndexPath:nextIndexPath];
            
                NSTimeInterval interval = 60*60*24;
                NSDate *shouldDate = [NSDate dateWithTimeInterval:interval sinceDate:currentDate];
                NSDate *nextDate = [dateFormatter dateFromString:nextStory.date.date];
                
                if([shouldDate compare:nextDate] != NSOrderedSame //日期不连续
                   || !nextStory.date.isLatest) {//不是最新数据
    
                    NSDate* dateAfterShouldDate = [NSDate dateWithTimeInterval:interval sinceDate:shouldDate];
                    NSString* dateAfterShouldDateStr = [dateFormatter stringFromDate:dateAfterShouldDate];
                    [self.netClient downloadBeforeDate:dateAfterShouldDateStr withCompletionHandler:nil];
                }
            }
        }
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
        UIBarButtonItem* back = [[UIBarButtonItem alloc] init];
        back.title = self.navigationItem.title;
        self.navigationItem.backBarButtonItem = back;
        
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
        CGFloat firstSectionHeaderHeight = HEIGHT_OF_FIRST_SECTION_HEADER;
        //CGFloat sectionHeaderHeight = HEIGHT_OF_SECTION_HEADER;
        if (scrollView.contentOffset.y <= firstSectionHeaderHeight && scrollView.contentOffset.y >= 0) {
            scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, scrollView.contentInset.left, scrollView.contentInset.bottom, scrollView.contentInset.right);
        } else if (scrollView.contentOffset.y>=firstSectionHeaderHeight) {
            scrollView.contentInset = UIEdgeInsetsMake(-firstSectionHeaderHeight, scrollView.contentInset.left, scrollView.contentInset.bottom, scrollView.contentInset.right);
        }
        else if (scrollView.contentOffset.y <= -64) {
            if (originContentInset.top > 0) {
                scrollView.contentInset = originContentInset;
            }
        }
        else if(scrollView.contentOffset.y > -64 && scrollView.contentOffset.y < 0)
        {
            scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, scrollView.contentInset.left, scrollView.contentInset.bottom, scrollView.contentInset.right);
        }
    }
    
    [_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    
    if(lastCell)
    {
        [self.tableView bringSubviewToFront:loadMoreTableFooterView];
        [loadMoreTableFooterView loadMoreScrollViewDidScroll:scrollView];
    }
    
    [self resetForNavItemTitle:scrollView.contentOffset.y];
    
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
            [[AppHelper shareAppHelper] showAlertViewWithError:error type:NET_DOWNLOAD_ERROR];
            if (originContentSize.height > self.tableView.contentSize.height && originContentSize.width > 0) {//由于不连续日期的更新
                self.tableView.contentSize = originContentSize;
                memset(&originContentSize, 0, sizeof(CGSize));
            }
        }
        else{
            lastCell = FALSE;
            [self resetMoreFrame];
            [self updateOffset];
        }
    }];
}

-(void) updateOffset
{
    self.tableView.contentOffset = CGPointMake(self.tableView.contentOffset.x, self.tableView.contentOffset.y + 90.0f);
}

- (BOOL)loadMoreTableFooterDataSourceIsLoading:(LoadMoreTableFooterView*)view
{
    return isLoadMoreing;
}

//#pragma mark test mothed
//-(void)notification
//{
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(notificationEvent:)
//                                                 name:NSManagedObjectContextObjectsDidChangeNotification
//                                               object:self.managedObjectContext];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(notificationEvent:)
//                                                 name:NSManagedObjectContextDidSaveNotification
//                                               object:self.managedObjectContext];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(notificationEvent:)
//                                                 name:NSManagedObjectContextWillSaveNotification
//                                               object:self.managedObjectContext];
//}
//
//-(void)notificationEvent:(NSNotification*)notify
//{
//    NSLog(@"%s: %@", __FUNCTION__,[notify description]);
//}

@end
