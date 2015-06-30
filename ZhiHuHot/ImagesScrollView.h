//
//  ImagesScrollView.h
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/29.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, UIPageControlShowStyle)
{
    UIPageControlShowStyleNone,//default
    UIPageControlShowStyleLeft,
    UIPageControlShowStyleCenter,
    UIPageControlShowStyleRight,
};

@interface ImagesScrollView : UIScrollView<UIScrollViewDelegate>

@property (retain,nonatomic,readonly) UIPageControl * pageControl;
@property (assign,nonatomic,readwrite) UIPageControlShowStyle  PageControlShowStyle;

- (instancetype)initWithFrame:(CGRect)frame withShowStyle:(NSTextAlignment)titleStyle;
- (void)setImageArray:(NSArray *)imageArray titleArray:(NSArray *)titleArray;

@end

