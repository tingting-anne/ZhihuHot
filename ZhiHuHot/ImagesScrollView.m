//
//  ImagesScrollView.m
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/29.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import "ImagesScrollView.h"
#import "SDWebImage/UIImageView+WebCache.h"

#define UISCREENWIDTH  self.bounds.size.width
#define UISCREENHEIGHT  self.bounds.size.height
#define HIGHT self.bounds.origin.y //由于_pageControl是添加进父视图的,所以实际位置要参考,滚动视图的y坐标

static CGFloat const chageImageTime = 5.0;//轮训时间

@interface ImagesScrollView ()
{
    //用于确定滚动式由人导致的还是计时器到了,系统帮我们滚动的,YES,则为系统滚动,NO则为客户滚动
    BOOL _isTimeUp;
    
    NSString* dailyImagePlacehold;
    NSTextAlignment titleStyle;
    
    NSUInteger currentImage;//记录中间图片的下标,开始总是为0
}
@property (retain,nonatomic,readwrite) NSArray * imageNameArray;
@property (retain,nonatomic,readonly) NSArray * adTitleArray;

@property (strong, nonatomic)UILabel * leftAdLabel;
@property (strong, nonatomic)UILabel * centerAdLabel;
@property (strong, nonatomic)UILabel * rightAdLabel;

@property (strong, nonatomic)UIImageView * leftImageView;
@property (strong, nonatomic)UIImageView * centerImageView;
@property (strong, nonatomic)UIImageView * rightImageView;

@property(strong, nonatomic)NSArray* imageNewsId;//轮训图片对应的newsID

//循环滚动的周期时间
@property (strong, nonatomic)NSTimer * moveTime;

-(void)setLabel:(UILabel*)label withTitle:(NSString *)title onImageView:(UIImageView*)imageView;
-(void)createImageAndLabel;
-(void)createPageControll;

-(NSUInteger)nextImageIndex;
-(NSUInteger)preImageIndex;

@end

@implementation ImagesScrollView
-(void)setLabel:(UILabel*)label withTitle:(NSString *)title onImageView:(UIImageView*)imageView
{
    if (label.text) {
        label.text = title;
        [label sizeToFit];
        return;
    }

    label.text = title;
   // [label sizeToFit];
    label.numberOfLines = 0;
    //label.font = [UIFont systemFontOfSize:20.0f];
    label.font = [UIFont fontWithName:@"Arial Rounded MT Bold" size:20.0f];
   // NSLog(@"%@, %@", [UIFont familyNames], [UIFont fontNamesForFamilyName:@"System"]);
    label.textColor = [UIColor whiteColor];
    label.shadowColor = [UIColor blackColor];
    label.shadowOffset = CGSizeMake(0.5, 0.5);
    label.textAlignment = titleStyle;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    [imageView addSubview:label];
    NSLayoutConstraint *Leading = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeLeading multiplier:1.0f constant:8.0f];
    [imageView addConstraint:Leading];
    
    NSLayoutConstraint *Trailing = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:-8.0f];
    [imageView addConstraint:Trailing];
    
    NSLayoutConstraint *Bottom = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeBottom multiplier:1.0f constant:-30.0f];
    [imageView addConstraint:Bottom];
    
    imageView.userInteractionEnabled = YES;//必须赋值，否则无法交互
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [imageView addGestureRecognizer:tap];
}

-(void)createImageAndLabel
{
    _leftImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, UISCREENWIDTH, UISCREENHEIGHT)];
    [self addSubview:_leftImageView];
    _centerImageView = [[UIImageView alloc]initWithFrame:CGRectMake(UISCREENWIDTH, 0, UISCREENWIDTH, UISCREENHEIGHT)];
    [self addSubview:_centerImageView];
    _rightImageView = [[UIImageView alloc]initWithFrame:CGRectMake(UISCREENWIDTH*2, 0, UISCREENWIDTH, UISCREENHEIGHT)];
    [self addSubview:_rightImageView];
    
    _leftAdLabel = [[UILabel alloc] init];
    _centerAdLabel = [[UILabel alloc] init];
    _rightAdLabel = [[UILabel alloc] init];
}

- (void)handleTap:(UITapGestureRecognizer *)tap{
    if (self.imageScrolldelegate && [self.imageScrolldelegate respondsToSelector:@selector(didSelectedNewsID:)]) {
        [self.imageScrolldelegate didSelectedNewsID:_imageNewsId[currentImage%_imageNewsId.count]];
    }
}

-(NSUInteger)preImageIndex
{
    NSUInteger ret = 0;
    if (currentImage >= 1) {
        ret = (currentImage - 1) % _imageNameArray.count;
    }
    else{
        ret = (_imageNameArray.count - (1 - currentImage)) % _imageNameArray.count;
    }
   return ret;
}

-(NSUInteger)nextImageIndex
{
    return (currentImage + 1) % _imageNameArray.count;
}

-(void)setImageViewUserInteractionEnabled:(BOOL)enable
{
    _leftImageView.userInteractionEnabled = enable;
    _rightImageView.userInteractionEnabled = enable;
    _centerImageView.userInteractionEnabled = enable;
}

-(void)stopScrollTimer
{
    [_moveTime invalidate];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame withShowStyle:NSTextAlignmentLeft];
}

- (instancetype)initWithFrame:(CGRect)frame withShowStyle:(NSTextAlignment)adTitleStyle
{
    self = [super initWithFrame:frame];
    if (self) {
        self.bounces = NO;
        
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.pagingEnabled = YES;
        self.contentOffset = CGPointMake(UISCREENWIDTH, 0);
        self.contentSize = CGSizeMake(UISCREENWIDTH * 3, UISCREENHEIGHT);
        self.delegate = self;
        
        [self createImageAndLabel];
        titleStyle = adTitleStyle;
        
        _isTimeUp = NO;
        currentImage = 0;
        
        dailyImagePlacehold = [NSString stringWithFormat:@"dailyImagePlacehold%d",(int)UISCREENWIDTH];
        NSLog(@"dailyImagePlacehold %@", dailyImagePlacehold);
    }
    return self;
}

- (void)setImageArray:(NSArray *)imageArray titleArray:(NSArray *)titleArray newsID:(NSArray *)newsID
{
    if (_moveTime) {
        [_moveTime setFireDate:[NSDate distantFuture]];
    }
    
    BOOL reDrawPageControll = FALSE;
    if (_imageNameArray.count != imageArray.count) {
        reDrawPageControll = TRUE;
    }
    
    currentImage = 0;
    _pageControl.currentPage = currentImage;
    _isTimeUp = NO;
    
    [self setImageNameArray:imageArray];
    [self setAdTitleArray:titleArray];
    _imageNewsId = newsID;
    
    if(reDrawPageControll){
        [self createPageControll];
    }
    
    if(!_moveTime){
        _moveTime = [NSTimer scheduledTimerWithTimeInterval:chageImageTime target:self selector:@selector(animalMoveImage) userInfo:nil repeats:YES];
        //NSLog(@"%lf", [[_moveTime fireDate] timeIntervalSinceDate:[NSDate date]]);
    }
    else{
        [_moveTime setFireDate:[NSDate dateWithTimeIntervalSinceNow:chageImageTime]];
    }
}

- (void)setImageNameArray:(NSArray *)imageNameArray
{
    _imageNameArray = imageNameArray;
    
    [_leftImageView sd_setImageWithURL:[NSURL URLWithString:_imageNameArray[[self preImageIndex]]] placeholderImage:[UIImage imageNamed:dailyImagePlacehold] options:SDWebImageHighPriority];
    
    [_centerImageView sd_setImageWithURL:[NSURL URLWithString:_imageNameArray[currentImage%_imageNameArray.count]] placeholderImage:[UIImage imageNamed:dailyImagePlacehold] options:SDWebImageHighPriority];
    
    [_rightImageView sd_setImageWithURL:[NSURL URLWithString:_imageNameArray[[self nextImageIndex]]] placeholderImage:[UIImage imageNamed:dailyImagePlacehold] options:SDWebImageHighPriority];
}

- (void)setAdTitleArray:(NSArray *)adTitleArray
{
    _adTitleArray = adTitleArray;
    
    //Passing address of non-local object to __autoreleasing parameter for write-back
    [self setLabel:_leftAdLabel withTitle:_adTitleArray[[self preImageIndex]] onImageView:_leftImageView];
    [self setLabel:_centerAdLabel withTitle:_adTitleArray[currentImage%_adTitleArray.count] onImageView:_centerImageView];
    [self setLabel:_rightAdLabel withTitle:_adTitleArray[[self nextImageIndex]] onImageView:_rightImageView];
}

-(void)createPageControll
{
    _pageControl.numberOfPages = _imageNameArray.count;
    
    if (self.PageControlShowStyle == UIPageControlShowStyleLeft)
    {
        _pageControl.frame = CGRectMake(10, HIGHT+UISCREENHEIGHT - 20, 20*_pageControl.numberOfPages, 20);
    }
    else if (self.PageControlShowStyle == UIPageControlShowStyleCenter)
    {
        _pageControl.frame = CGRectMake(0, 0, 20*_pageControl.numberOfPages, 20);
        _pageControl.center = CGPointMake(UISCREENWIDTH/2.0, HIGHT+UISCREENHEIGHT - 10);
    }
    else
    {
        _pageControl.frame = CGRectMake( UISCREENWIDTH - 20*_pageControl.numberOfPages, HIGHT+UISCREENHEIGHT - 20, 20*_pageControl.numberOfPages, 20);
    }
    _pageControl.currentPage = 0;
    _pageControl.enabled = NO;
    // [self performSelector:@selector(addPageControl) withObject:nil afterDelay:0.1f];
}

- (void)setPageControlShowStyle:(UIPageControlShowStyle)PageControlShowStyle
{
    _PageControlShowStyle = PageControlShowStyle;
    if (PageControlShowStyle == UIPageControlShowStyleNone) {
        return;
    }
     _pageControl = [[UIPageControl alloc]init];
    
    if(_imageNameArray && _imageNameArray.count > 0){
        [self createPageControll];
    }
}

#pragma mark - 计时器到时,系统滚动图片
- (void)animalMoveImage
{
      _isTimeUp = YES;
 //   [self setContentOffset:CGPointMake(UISCREENWIDTH * 2, 0) animated:YES];
//    [NSTimer scheduledTimerWithTimeInterval:0.3f target:self selector:@selector(scrollViewDidEndDecelerating:) userInfo:nil repeats:NO];
    [UIView animateWithDuration:.3 animations:^{
        [self setContentOffset:CGPointMake(2*UISCREENWIDTH, 0)];
    } completion:^(BOOL finished) {
        [self changePage];
    }];
}

-(void)changePage
{
    if (!_imageNameArray || _imageNameArray.count <=0) {
        return;
    }
    if (self.contentOffset.x == 0)
    {
        currentImage = [self preImageIndex];
        _pageControl.currentPage = currentImage;
    }
    else if(self.contentOffset.x == UISCREENWIDTH * 2)
    {
        currentImage = [self nextImageIndex];
        _pageControl.currentPage = currentImage;
    }
    else
    {
        return;
    }
    
    [_centerImageView sd_setImageWithURL:[NSURL URLWithString:_imageNameArray[currentImage%_imageNameArray.count]] placeholderImage:[UIImage imageNamed:dailyImagePlacehold]];
    _centerAdLabel.text = _adTitleArray[currentImage%_imageNameArray.count];
    self.contentOffset = CGPointMake(UISCREENWIDTH, 0);
    
    [_leftImageView sd_setImageWithURL:[NSURL URLWithString:_imageNameArray[[self preImageIndex]]] placeholderImage:[UIImage imageNamed:dailyImagePlacehold]];
    [_rightImageView sd_setImageWithURL:[NSURL URLWithString:_imageNameArray[[self nextImageIndex]]] placeholderImage:[UIImage imageNamed:dailyImagePlacehold]];
    
    _leftAdLabel.text = _adTitleArray[[self preImageIndex]];
    _rightAdLabel.text = _adTitleArray[[self nextImageIndex]];
    
    //手动控制图片滚动应该取消那个三秒的计时器
    if (!_isTimeUp) {
        [_moveTime setFireDate:[NSDate dateWithTimeIntervalSinceNow:chageImageTime]];
    }
    _isTimeUp = NO;
}

#pragma mark - 图片停止时,调用该函数使得滚动视图复用
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self changePage];
}

@end
