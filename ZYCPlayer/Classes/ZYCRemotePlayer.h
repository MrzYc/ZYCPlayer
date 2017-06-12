//
//  ZYCRemotePlayer.h
//  ZYCPlayer
//
//  Created by 赵永闯 on 2017/6/4.
//  Copyright © 2017年 zhaoyongchuang. All rights reserved.
//

#import <Foundation/Foundation.h>


/** 播放器的状态 */
typedef NS_ENUM(NSInteger, ZYCRemotePlayerState) {
    ZYCRemotePlayerStateUnknown = 0,   //未知状态
    ZYCRemotePlayerStateLoading   = 1, //
    ZYCRemotePlayerStatePlaying   = 2,
    ZYCRemotePlayerStateStopped   = 3,
    ZYCRemotePlayerStatePause     = 4,
    ZYCRemotePlayerStateFailed    = 5
};

@interface ZYCRemotePlayer : NSObject

+ (instancetype)shareInstance;



- (void)playWithURL:(NSURL *)url isCache:(BOOL)isCache;

//暂停播放
- (void)pause;

//继续播放
- (void)resume;

//停止播放
- (void)stop;


//快进/快退
- (void)seekWithTimeDiffer:(NSTimeInterval)timeDiffer;

//进度信息
- (void)seekWithProgress:(float)progress;

#pragma 数据
/** 是否静音 */
@property (nonatomic, assign) BOOL muted;
/** 音量 */
@property (nonatomic, assign) float volume;
/** 速率 */
@property (nonatomic, assign) float rate;

/** 总时间 */
@property (nonatomic, assign, readonly) NSTimeInterval totalTime;
/**  */
@property (nonatomic, copy, readonly) NSString *totalTimeFormat;
/** 当前时间 */
@property (nonatomic, assign, readonly) NSTimeInterval currentTime;
/**  */
@property (nonatomic, copy) NSString *currentTimeFormat;


/** 进度 */
@property (nonatomic, assign, readonly) float progress;
/** 资源URL */
@property (nonatomic, strong, readonly) NSURL *url;
/** 加载进度 */
@property (nonatomic, assign, readonly) float loadDataProgress;

@property (nonatomic, assign, readonly) ZYCRemotePlayerState state;



@end
