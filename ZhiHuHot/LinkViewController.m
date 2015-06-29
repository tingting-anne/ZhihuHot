//
//  LinkViewController.m
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/23.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import "LinkViewController.h"

@interface LinkViewController ()
{
    uint loadCount;
}
@end

@implementation LinkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
   // [self.view bringSubviewToFront:self.activity];
  //  self.activity.hidden = NO;
    
    // Do any additional setup after loading the view from its nib.
    self.webView.delegate = self;
    self.webView.scalesPageToFit = YES;
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UIWebViewDelegate

-(void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.activity startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activity stopAnimating];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR", nil) message:NSLocalizedString(@"NET_DOWNLOAD_ERROR", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)  otherButtonTitles:nil, nil];
    [alertView show];
    
    [self.activity stopAnimating];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
