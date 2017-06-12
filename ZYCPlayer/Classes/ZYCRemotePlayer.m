//
//  ZYCRemotePlayer.m
//  ZYCPlayer
//
//  Created by 赵永闯 on 2017/6/4.
//  Copyright © 2017年 zhaoyongchuang. All rights reserved.
//

#import "ZYCRemotePlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "ZYCRemoteResouseDelegate.h"
#import "NSURL+Stream.h"

@interface ZYCRemotePlayer () <NSCopying, NSMutableCopying>
{
    BOOL _isUserPause;
}
@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) ZYCRemoteResouseDelegate *resourceLoaderDelegate;

@end

@implementation ZYCRemotePlayer
static ZYCRemotePlayer *_shareInstance;

+ (instancetype)shareInstance {
    if (!_shareInstance) {
        _shareInstance = [[ZYCRemotePlayer alloc] init];
    }
    return _shareInstance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (!_shareInstance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _shareInstance = [super allocWithZone:zone];
        });
    }
    return _shareInstance;
}


- (id)copyWithZone:(NSZone *)zone
{
    return _shareInstance;
}

-(id)mutableCopyWithZone:(NSZone *)zone {
    return _shareInstance;
}


- (void)playWithURL:(NSURL *)url isCache:(BOOL)isCache {
 
    NSURL *currentURL = [(AVURLAsset *)self.player.currentItem.asset URL];
    if ([url isEqual:currentURL]) {
        NSLog(@"当前播放任务已经存在");
        [self resume];
        return;
    }
    
    //创建播放器对象
    //如果我们使用这样的方法，播放远程音频，已经把帮我们封装了三个步骤 1.资源的请求 2.资源的组织 3.资源的播放
    //如果资源加载比较慢，有可能会造成调用了play方法，但并没有播放音频
    
    if (self.player.currentItem) {
        [self removeObserver];
    }
    
    _url = url;
    
    if (isCache) {
        url = [url steamingURL];

    }

    //1.资源请求
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    
    //网络音频的请求， 是通过这个对象，调用代理的方法，进行加载
    //拦截加载的请求，只需要，重新修改他的代理方法就可以
    self.resourceLoaderDelegate = [ZYCRemoteResouseDelegate new];
    [asset.resourceLoader setDelegate:self.resourceLoaderDelegate queue:dispatch_get_main_queue()];
    
    //2.资源的组织
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    //当资源组织好了，然后去播放
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playInterupt) name:AVPlayerItemPlaybackStalledNotification object:nil];

    //3.资源播放
    self.player = [AVPlayer playerWithPlayerItem:item];
}



- (void)pause {
    [self.player pause];
    _isUserPause = YES;
    if (self.player) {
        self.state = ZYCRemotePlayerStatePause;
    }
}

- (void)resume {
    [self.player play];
    _isUserPause = NO;
    // 此时当前播放器存在, 并且, 数据组织者里面的数据准备, 已经足够播放了
    if (self.player && self.player.currentItem.playbackLikelyToKeepUp) {
        self.state = ZYCRemotePlayerStatePlaying;
    }
}
- (void)stop {
    [self.player pause];
    self.player = nil;
    if (self.player) {
        self.state = ZYCRemotePlayerStateStopped;
    }
}

- (void)seekWithProgress:(float)progress {
    if (progress < 0 || progress > 1) {
        return;
    }
    
    // 可以指定时间节点去播放
    // 时间: CMTime : 影片时间
    // 影片时间 -> 秒
    // 秒 -> 影片时间
    
    //1.当前音频资源的总时长
    CMTime totalTime = self.player.currentItem.duration;
    NSTimeInterval totalSec = CMTimeGetSeconds(totalTime);
    NSTimeInterval playTimeSec = totalSec * progress;
    CMTime currentTime = CMTimeMake(playTimeSec, 1);

    [self.player seekToTime:currentTime completionHandler:^(BOOL finished) {
        if (finished) {
            NSLog(@"确定加载这个时间点的音频资源");
        }else {
            NSLog(@"取消加载这个时间点的音频资源");
        }
    }];
}

- (void)seekWithTimeDiffer:(NSTimeInterval)timeDiffer {
    
    // 1. 当前音频资源的总时长
    NSTimeInterval totalTimeSec = [self totalTime];
    // 2. 当前音频, 已经播放的时长
    
    NSTimeInterval playTimeSec = [self currentTime];
    playTimeSec += timeDiffer;
    
    [self seekWithProgress:playTimeSec / totalTimeSec];
}

- (void)setRate:(float)rate {
    [self.player setRate:rate];
}

- (float)rate {
    return self.player.rate;
}

- (void)setMuted:(BOOL)muted {
    self.player.muted = muted;
}

- (BOOL)muted {
    return self.player.muted;
}

- (void)setVolume:(float)volume {
    
    if (volume < 0 || volume > 1) {
        return;
    }
    if (volume > 0) {
        [self setMuted:NO];
    }
    self.player.volume = volume;
}

- (float)volume {
    return self.player.volume;
}


- (NSString *)currentTimeFormat {
    return [NSString stringWithFormat:@"%02zd:%02zd", (int)self.currentTime / 60, (int)self.currentTime % 60];
}

- (NSString *)totalTimeFormat {
    return [NSString stringWithFormat:@"%02zd:%02zd", (int)self.totalTime / 60, (int)self.totalTime % 60];
}

#pragma mark -数据/事件

-(NSTimeInterval)totalTime {
    CMTime totalTime = self.player.currentItem.duration;
    NSTimeInterval totalTimeSec = CMTimeGetSeconds(totalTime);
    if (isnan(totalTimeSec)) {
        return 0;
    }
    return totalTimeSec;
}

- (NSTimeInterval)currentTime {
    CMTime playTime = self.player.currentItem.currentTime;
    NSTimeInterval playTimeSec = CMTimeGetSeconds(playTime);
    if (isnan(playTimeSec)) {
        return 0;
    }
    return playTimeSec;
}

- (float)progress {
    if (self.totalTime == 0) {
        return 0;
    }
    return self.currentTime / self.totalTime;
}

- (float)loadDataProgress {
    
    if (self.totalTime == 0) {
        return 0;
    }
    
    CMTimeRange timeRange = [[self.player.currentItem loadedTimeRanges].lastObject CMTimeRangeValue];
    
    CMTime loadTime = CMTimeAdd(timeRange.start, timeRange.duration);
    NSTimeInterval loadTimeSec = CMTimeGetSeconds(loadTime);
    
    return loadTimeSec / self.totalTime;
    
}

- (void)setState:(ZYCRemotePlayerState)state {
    _state = state;
    
    // 如果需要告知外界相关的事件
    // block
    // 代理
    // 发通知
    
}

- (void)removeObserver {
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}


- (void)playEnd {
    NSLog(@"播放完成");
    self.state = ZYCRemotePlayerStateStopped;
}

- (void)playInterupt {
    // 来电话, 资源加载跟不上
    NSLog(@"播放被打断");
    self.state = ZYCRemotePlayerStatePause;
}

#pragma mark - KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        if (status == AVPlayerItemStatusReadyToPlay) {
            NSLog(@"资源准备好了, 这时候播放就没有问题");
            [self resume];
        }else {
            NSLog(@"状态未知");
            self.state = ZYCRemotePlayerStateFailed;
        }
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        BOOL ptk = [change[NSKeyValueChangeNewKey] boolValue];
        if (ptk) {
            NSLog(@"当前的资源, 准备的已经足够播放了");
            //
            // 用户的手动暂停的优先级最高
            if (!_isUserPause) {
                [self resume];
            }else {
                
            }
            
        }else {
            NSLog(@"资源还不够, 正在加载过程当中");
            self.state = ZYCRemotePlayerStateLoading;
        }
    }
}



@end
