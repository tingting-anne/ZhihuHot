//
//  ContentViewController.m
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/17.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import "ContentViewController.h"
#import "NetClient.h"
#import "ContentHeaderView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "LinkViewController.h"

@interface ContentViewController()
{
    BOOL isFirstLoad;
}
@property(strong,nonatomic)NetClient* netClient;
@property(strong,nonatomic)LinkViewController* linkViewController;

-(void)loadDailyWebViewPart:(NSDictionary*) dic;
-(void)loadThemeWebViewPart:(NSDictionary*) dic;

@end

@implementation ContentViewController

-(void)awakeFromNib
{
    self.netClient = [[NetClient alloc] initWithManagedObjectContext:nil];
    isFirstLoad = TRUE;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.webView.delegate = self;//放在awakeFromNib中没有调用成功
    self.activity.hidesWhenStopped = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setNewsID:(NSNumber *)newsID
{
    self.activity.hidden = NO;
    [self.activity startAnimating];
    
    [self.netClient downloadWithNewsID:[newsID unsignedIntegerValue] withCompletionHandler:^(NSDictionary* dic, NSError *error){
        
        if(error){
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR", nil) message:NSLocalizedString(@"NET_DOWNLOAD_ERROR", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)  otherButtonTitles:nil, nil];
            [alertView show];
            return;
        }
        
        NSString *htmlString = [NSString stringWithFormat:@"<html><head><link rel=\"stylesheet\" type=\"text/css\" href=%@ /></head><body>%@</body></html>", dic[@"css"][0], dic[@"body"]];
        
        [self.webView loadHTMLString:htmlString baseURL:nil];
        
        if (DAILY_STORY_CONTENT == self.contentType) {
            [self loadDailyWebViewPart:dic];
        }
        else{
            [self loadThemeWebViewPart:dic];
        }
        
        [self.activity stopAnimating];
        self.activity.hidden = YES;
    }];
}

-(void)loadDailyWebViewPart:(NSDictionary *)dic
{
    NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ContentHeaderView" owner:self options:nil];
    ContentHeaderView *headerView = [nibArray firstObject];
    
    // Setup header view
    CGRect headerFrame = CGRectMake(0, 0, self.webView.frame.size.width, 220);
    headerView.frame = headerFrame;

    [headerView.imageView sd_setImageWithURL:[NSURL URLWithString:dic[@"image"]] placeholderImage:[UIImage imageNamed:@"placeholder"]];
    
    headerView.titleLable.text = dic[@"title"];
    headerView.imageSourceLabel.text = dic[@"image_source"];
    [self.webView.scrollView addSubview:headerView];
}

-(void)loadThemeWebViewPart:(NSDictionary *)dic
{
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL ret = TRUE;
    if (isFirstLoad) {
        isFirstLoad = FALSE;
    }
    else{
        ret = FALSE;
        
        self.linkViewController = [[LinkViewController alloc] init];
        self.linkViewController.url = request.URL;
        
        [self.navigationController pushViewController:self.linkViewController animated:YES];
    }
    return ret;
}

-(void)webViewDidStartLoad:(UIWebView *)webView
{
    self.activity.hidden = NO;
    [self.activity startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activity stopAnimating];
    self.activity.hidden = YES;
}

@end
