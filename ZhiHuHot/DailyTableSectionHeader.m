//
//  DailyTableSectionHeader.m
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/21.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import "DailyTableSectionHeader.h"
@interface DailyTableSectionHeader()

@property(strong,nonatomic)UILabel* headerLabel;

@end

@implementation DailyTableSectionHeader

-(instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        _headerLabel = [[UILabel alloc] init];
        self.contentView.backgroundColor = [UIColor colorWithRed:0.3f green:0.6f blue:1.0f alpha:0.9f];
        _headerLabel.font = [UIFont fontWithName:@"Arial Rounded MT Bold" size:19.0f];
        _headerLabel.textColor = [UIColor whiteColor];
        self.headerLabel.textAlignment = NSTextAlignmentCenter;
        
        [self.contentView addSubview:_headerLabel];
        
//        NSLayoutConstraint *Leading = [NSLayoutConstraint constraintWithItem:_headerLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeading multiplier:1.0f constant:0.0f];
//        [self.contentView addConstraint:Leading];
//        
//        NSLayoutConstraint *Trailing = [NSLayoutConstraint constraintWithItem:_headerLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:0.0f];
//        [self.contentView addConstraint:Trailing];
//        
//        NSLayoutConstraint *Bottom = [NSLayoutConstraint constraintWithItem:_headerLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f];
//        [self.contentView addConstraint:Bottom];
//        
//        NSLayoutConstraint *Top = [NSLayoutConstraint constraintWithItem:_headerLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f];
//        [self.contentView addConstraint:Top];
    }
    
    return self;
}

-(void)setHeaderTitle:(NSString *)headerTitle
{
    _headerLabel.frame = self.frame;
    _headerTitle = headerTitle;
    self.headerLabel.text = _headerTitle;
}
@end
