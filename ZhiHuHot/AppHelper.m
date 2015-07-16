//
//  AppHelper.m
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/19.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#import "AppHelper.h"

@implementation AppHelper

static AppHelper *sharesingleton=nil;

+ (id)shareAppHelper
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharesingleton = [[self alloc] init];
    });
    
    return sharesingleton;
}

+(id)allocWithZone:(NSZone *)zone
{
    if (sharesingleton == nil) {
        sharesingleton = [super allocWithZone:zone];
    }
    return sharesingleton;
}

-(id)copyWithZone:(NSZone *)zone
{
    return self;//覆盖父类 NScoping 中的方法
}

//-(id)retain
//{
//    return self;
//}

//-(NSUInteger)retainCount
//{
//    return NSUIntegerMax;//无穷大的数，表示不能释放
//}

//-(oneway void)release
//{
//    //什么也不做
//}
//-(id)autorelease
//{
//    return self;
//}

- (BOOL)isValidDateString:(NSString *)dateString {
    return dateString.integerValue > 20130520 && dateString.integerValue <= [self stringOfToday].integerValue;
}

-(BOOL)isTodayWithDateString:(NSString *)dateString
{
    BOOL ret = FALSE;
    if ([dateString isEqualToString:[self stringOfToday]]) {
        ret = TRUE;
    }
    return ret;
}

- (NSString *)stringOfToday
{
    static NSDateFormatter *dateFormatter = nil;
    
    if(!dateFormatter)
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyyMMdd"];
    }
    
    return [dateFormatter stringFromDate:[NSDate date]];
}

-(UIColor *)backgroundColor
{
    return [UIColor colorWithRed:0.3f green:0.6f blue:1.0f alpha:1.0f];
}


-(void)showAlertViewWithError:(NSError *) error type:(AlertErrorType)type
{
    NSString* errorMessage = nil;
    switch (type) {
        case NET_DOWNLOAD_ERROR:
            errorMessage = @"NET_DOWNLOAD_ERROR";
            break;
        case PSC_STORE_ERROR:
            errorMessage = @"PSC_STORE_ERROR";
            break;
        case MOC_SAVE_ERROR:
            errorMessage = @"MOC_SAVE_ERROR";
            break;
        default:
            errorMessage = @"ERROR_UNKNOWN";
            break;
    }
    
//    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR", nil) message:NSLocalizedString(errorMessage, nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)  otherButtonTitles:nil, nil];
    
     UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(errorMessage, nil) message:[error localizedFailureReason] delegate:nil cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)  otherButtonTitles:nil, nil];
    [alertView show];
}

@end
