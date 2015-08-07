//
//  Definitions.h
//  ZhiHuHot
//
//  Created by ltt.fly on 15/6/19.
//  Copyright (c) 2015年 ltt.fly. All rights reserved.
//

#ifndef ZhiHuHot_Definitions_h
#define ZhiHuHot_Definitions_h

#define LATESTSTORIES       "http://news-at.zhihu.com/api/4/news/latest"
#define BEFORESTORIES       "http://news.at.zhihu.com/api/4/news/before/%@"
#define THEMES              "http://news-at.zhihu.com/api/4/themes"
#define THEMESTORIES        "http://news-at.zhihu.com/api/4/theme/%@"
#define NEWSCONTENT         "http://news-at.zhihu.com/api/4/news/%@"

#ifdef DEBUG
#define UPDATECONTENTINTERVAL   10 //更新间隔
#else
#define UPDATECONTENTINTERVAL   10*60 //更新间隔
#endif

typedef enum CONTENTTYPE{
    DAILY_STORY_CONTENT,
    THEME_STORY_CONTENT,
}CONTENTTYPE;

typedef enum SCROLL_DIRECTION_ENUM{
    SCROLL_DIRECTION_UP,
    SCROLL_DIRECTION_DOWN,
    SCROLL_DIRECTION_NUM,
}SCROLL_DIRECTION_ENUM;

#define ZHHErrorDomain @"ZhihuHotDomain"

typedef enum : NSUInteger {
    ZHHInvalidDateString,
} ZHHError;

typedef enum AlertErrorType{
    NET_DOWNLOAD_ERROR,
    PSC_STORE_ERROR,
    MOC_SAVE_ERROR,
}AlertErrorType;

typedef enum LoadManagerObjectResultType{
    LOAD_BY_ADD,
    LOAD_BY_GET,
    LOAD_ERROR,
}LoadManagerObjectResultType;

#endif
