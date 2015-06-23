//
//  ContentViewController.h
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/17.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContentViewController : UIViewController<UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic)NSNumber* newsID;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activity;

@end
