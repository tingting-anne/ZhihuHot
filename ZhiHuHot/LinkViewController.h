//
//  LinkViewController.h
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/23.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LinkViewController : UIViewController<UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (weak, nonatomic) NSURL* url;

@end
