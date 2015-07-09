//
//  MenuTableViewController.m
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/17.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import "MenuTableViewController.h"
#import "AppDelegate.h"
#import "Theme.h"
#import "SubjectTableViewController.h"
#import "AppHelper.h"
#import "NetClient.h"

@interface MenuTableViewController ()

@property(strong,nonatomic)NSFetchedResultsController* fetchedResultsController;
@property(strong,nonatomic)NSManagedObjectContext* managedObjectContext;
@property(strong,nonatomic)NSIndexPath* lastSelectIndexPath;//上次点中的path

@end

@implementation MenuTableViewController

-(void)awakeFromNib
{
    [super awakeFromNib];
   
    AppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = [appDelegate managedObjectContext];
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    _managedObjectContext = managedObjectContext;
    
    if (_managedObjectContext == nil) {
        NSLog(@"%s error managedObjectContext is nil", __FUNCTION__);
        
        self.fetchedResultsController = nil;
    }
    else
    {
        NSFetchRequest* request = [[NSFetchRequest alloc] init];
        NSEntityDescription* entityDescription = [NSEntityDescription entityForName:@"Theme" inManagedObjectContext:self.managedObjectContext];
        [request setEntity:entityDescription];
        
        NSSortDescriptor *sortDescription = [[NSSortDescriptor alloc] initWithKey:@"sortId" ascending:YES];
        [request setSortDescriptors:@[sortDescription]];
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"MenueCache"];
        
        self.fetchedResultsController.delegate = self;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    NetClient *netClient = [[NetClient alloc] init];
    [netClient downloadThemesWithCompletionHandler:^(NSError* error){
        if (error) {
            NSLog(@"ERROR downloadThemes : %s", __FUNCTION__);
        }
    }];
    
    
    NSError *error;
    BOOL success = [self.fetchedResultsController performFetch:&error];
    if (!success) NSLog(@"[%@ %@] performFetch: failed", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    if (error) {
        NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
    }
    [self.tableView reloadData];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.tableView.backgroundColor = [UIColor colorWithRed:0.04f green:0.13f blue:0.15f alpha:1.0f];
    self.tableView.separatorColor = self.tableView.backgroundColor;
    
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        CGRect rect = self.tableView.frame;
        rect.origin.y += 20;
        rect.size.height -= 20;
        self.tableView.frame = rect;
        
//        CGRect rect1 = self.view.frame;
//        rect1.origin.y += 20;
//        self.view.frame = rect1;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //主要是去掉选择后再返回界面时，会出现多个cell选中的状态,这里选择后将上次的选择恢复
    if (self.lastSelectIndexPath && [self.lastSelectIndexPath compare:indexPath] != NSOrderedSame) {
        UITableViewCell* cellLast = [self.tableView cellForRowAtIndexPath:self.lastSelectIndexPath];
        cellLast.textLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
        cellLast.backgroundColor = [UIColor colorWithRed:0.04f green:0.13f blue:0.15f alpha:1.0f];
    }
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.textLabel.font = [UIFont fontWithName:@"Arial Rounded MT Bold" size:17.0f];
    cell.backgroundColor = [UIColor colorWithRed:0.04f green:0.03f blue:0.15f alpha:1.0f];
    //cell.contentView.backgroundColor = [UIColor colorWithRed:0.04f green:0.03f blue:0.15f alpha:1.0f];
    
    self.lastSelectIndexPath = indexPath;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    if ([[self.fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        rows = [sectionInfo numberOfObjects];
    }
    return rows + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *cellIdentifier = nil;
    switch (indexPath.row) {
        case 0:
            cellIdentifier = @"home";
            break;
            
        default:
            cellIdentifier = @"subject";
            break;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"首页";
    } else {
        NSIndexPath *objectIndexPath = [NSIndexPath indexPathForRow:indexPath.row-1 inSection:indexPath.section];
        Theme *theme = [self.fetchedResultsController objectAtIndexPath:objectIndexPath];
        cell.textLabel.text = theme.name;
    }
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];//取消选中的默认颜色设置*
    
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
    cell.textLabel.textColor = [UIColor whiteColor];
    //cell.contentView.backgroundColor = [UIColor colorWithRed:0.04f green:0.13f blue:0.15f alpha:1.0f];
    cell.backgroundColor = [UIColor colorWithRed:0.04f green:0.13f blue:0.15f alpha:1.0f];
    
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
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    UINavigationController *destViewController = (UINavigationController*)segue.destinationViewController;
    
    Theme *theme = nil;
    if (indexPath.row > 0) {
        NSIndexPath *objectIndexPath = [NSIndexPath indexPathForRow:indexPath.row-1 inSection:indexPath.section];
        theme = [self.fetchedResultsController objectAtIndexPath:objectIndexPath];
    }
    
    if (theme != nil
        && [[destViewController childViewControllers].firstObject isKindOfClass:[SubjectTableViewController class]]) {

        SubjectTableViewController *subjectTableViewCtroller = (SubjectTableViewController *)[destViewController childViewControllers][0];
        subjectTableViewCtroller.thumbnail = theme.thumbnail;
        subjectTableViewCtroller.themeID = theme.id;
        subjectTableViewCtroller.title = theme.name;
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
@end
