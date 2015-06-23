//
//  ContentViewController.m
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/17.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import "ContentViewController.h"
#import "NetClient.h"

@implementation ContentViewController

-(void)awakeFromNib
{
    self.webView.delegate = self;
    self.activity.hidesWhenStopped = YES;
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
    NetClient* netClient = [[NetClient alloc] initWithManagedObjectContext:nil];
    NSDictionary* dicInfo;
    [netClient downloadNewsDictionary:&dicInfo WithNewsID:[newsID unsignedIntegerValue]];
    NSString* css = dicInfo[@"css"][0];
    [self.webView loadHTMLString:css baseURL:nil];
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
