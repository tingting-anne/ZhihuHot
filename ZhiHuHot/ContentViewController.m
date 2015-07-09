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
#import "AppHelper.h"

@interface ContentViewController()
{
    BOOL isFirstLoad;
    BOOL isLinkOpen;
    ContentHeaderView *headerView;
}

@property(strong,nonatomic)NetClient* netClient;
@property(strong,nonatomic)LinkViewController* linkViewController;

-(void)loadDailyWebViewPart:(NSDictionary*) dic;
-(void)loadThemeWebViewPart:(NSDictionary*) dic;
-(void)loadData;
-(void)loadErrorWithError:(NSError *)error;

@end

@implementation ContentViewController

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    self.netClient = [[NetClient alloc] init];
    isFirstLoad = TRUE;
    
    //Long story short, the view may be loaded in awakeFromNib, but its contents are loaded lazily, which is why you should use viewDidLoad instead of awakeFromNib for what you are trying to achieve.
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.webView.delegate = self;//放在awakeFromNib中没有调用成功
    self.activity.hidden = NO;
    [self.view bringSubviewToFront:self.activity];
    
    [self loadData];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.webView stopLoading];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    NSLog(@"------------------------");
    NSLog(@"didReceiveMemoryWarning");
    NSLog(@"------------------------");
}

-(void)loadData
{
    [self.activity startAnimating];
    
    [self.netClient downloadWithNewsID:[self.newsID unsignedIntegerValue] withCompletionHandler:^(NSDictionary* dic, NSError *error){
        
        if (error || !dic || (!dic[@"body"] && !dic[@"share_url"])) {
            [self loadErrorWithError:error];
            return;
        }
        
        if (dic[@"body"] == nil) {//再次链接
            isLinkOpen = TRUE;
            NSURL* share_url = [[NSURL alloc] initWithString:dic[@"share_url"]];
            [self.webView loadRequest:[NSURLRequest requestWithURL:share_url]];
        }
        else{
            isLinkOpen = FALSE;
            
            [self.netClient downloadCss:dic[@"css"][0] withCompletionHandler:^(NSData* cssData, NSError *error){
                
                if (error) {
                    [self loadErrorWithError:error];
                    return;
                }
                
                static NSString* defaultCssString = nil;
                NSString *cssString = nil;
                
                if(!cssData){
                    if (defaultCssString) {
                        cssString = defaultCssString;
                    }
                    else{
                        [self loadErrorWithError:error];
                        return;
                    }
                }
                else{
                    cssString = [[NSString alloc] initWithData:cssData  encoding:NSUTF8StringEncoding];
                    
                    if (!defaultCssString) {
                        defaultCssString = cssString;
                    }
                }
                    
                NSString * htmlString = [NSString stringWithFormat:@"<html><head><style type=\"text/css\"> %@ </style></head><body>%@</body></html>", cssString, dic[@"body"]];
                
                [self.webView loadHTMLString:htmlString baseURL:nil];
                
                if ([dic objectForKey:@"image"]) {
                    [self loadDailyWebViewPart:dic];
                }
                else{
                    [self loadThemeWebViewPart:dic];
                }
            }];
        }
    }];
}

-(void)loadDailyWebViewPart:(NSDictionary *)dic
{
    NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ContentHeaderView" owner:self options:nil];
    headerView = [nibArray firstObject];
    
    // Setup header view
    CGRect headerFrame = CGRectMake(0, 0, self.view.bounds.size.width, 205);
    headerView.frame = headerFrame;

    NSString *dailyImagePlacehold = [NSString stringWithFormat:@"dailyImagePlacehold%d",(int)self.view.bounds.size.width];
    
    [headerView.imageView sd_setImageWithURL:[NSURL URLWithString:dic[@"image"]] placeholderImage:[UIImage imageNamed:dailyImagePlacehold] options:SDWebImageHighPriority];
    
    headerView.titleLable.text = dic[@"title"];
    headerView.imageSourceLabel.text = dic[@"image_source"];
  //  [self.webView.scrollView addSubview:headerView];
}

-(void)loadThemeWebViewPart:(NSDictionary *)dic
{
}

-(void)loadErrorWithError:(NSError *)error
{
    if (self.webView.loading) {
        [[AppHelper shareAppHelper] showAlertViewWithError:error type:NET_DOWNLOAD_ERROR];
    }
    
    [self.activity stopAnimating];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (isLinkOpen) {//链接方式打开，都在当前页处理
        return TRUE;
    }
    
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
    [self.activity startAnimating];
    
    if (headerView) {
        [self.webView.scrollView addSubview:headerView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activity stopAnimating];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self loadErrorWithError:error];
}
@end
