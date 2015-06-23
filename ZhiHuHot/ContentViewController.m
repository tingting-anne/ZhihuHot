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

@interface ContentViewController()

@property(strong,nonatomic)NetClient* netClient;

-(void)loadDailyWebViewPart:(NSDictionary*) dic;
-(void)loadThemeWebViewPart:(NSDictionary*) dic;

@end

@implementation ContentViewController

-(void)awakeFromNib
{
    self.webView.delegate = self;
    self.activity.hidesWhenStopped = YES;
    self.netClient = [[NetClient alloc] initWithManagedObjectContext:nil];
}

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setNewsID:(NSNumber *)newsID
{
    [self.activity startAnimating];
    [self.netClient downloadWithNewsID:[newsID unsignedIntegerValue] success:^(NSDictionary* dic){
        
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
    CGRect headerFrame = CGRectMake(self.webView.frame.origin.x, self.webView.frame.origin.y, self.webView.frame.size.width, 220);
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
    return TRUE;
}

-(void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.activity startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activity stopAnimating];
}

@end
