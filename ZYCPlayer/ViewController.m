//
//  ViewController.m
//  ZYCPlayer
//
//  Created by 赵永闯 on 2017/6/4.
//  Copyright © 2017年 zhaoyongchuang. All rights reserved.
//

#import "ViewController.h"
#import "ZYCRemotePlayer.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *playTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;

@property (weak, nonatomic) IBOutlet UIProgressView *loadPV;

@property (nonatomic, weak) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UISlider *playSlider;

@property (weak, nonatomic) IBOutlet UIButton *mutedBtn;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;


@end

@implementation ViewController


- (NSTimer *)timer {
    if (!_timer) {
        NSTimer *timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(update) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        _timer = timer;
    }
    return _timer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self timer];
}


- (void)update {
    
    NSLog(@"%zd", [ZYCRemotePlayer shareInstance].state);
    
    // 68
    // 01:08
    // 设计数据模型的
    // 弱业务逻辑存放位置的问题
    self.playTimeLabel.text =  [ZYCRemotePlayer shareInstance].currentTimeFormat;
    self.totalTimeLabel.text = [ZYCRemotePlayer shareInstance].totalTimeFormat;
    
    self.playSlider.value = [ZYCRemotePlayer shareInstance].progress;
    
    self.volumeSlider.value = [ZYCRemotePlayer shareInstance].volume;
    
    self.loadPV.progress = [ZYCRemotePlayer shareInstance].loadDataProgress;
    
    self.mutedBtn.selected = [ZYCRemotePlayer shareInstance].muted;
    
}

//播放
- (IBAction)play:(id)sender {
    
//    NSURL *url = [NSURL URLWithString:@"http://audio.xmcdn.com/group23/M04/63/C5/wKgJNFg2qdLCziiYAGQxcTOSBEw402.m4a"];
    NSURL *url = [NSURL URLWithString:@"http://120.25.226.186:32812/resources/videos/minion_01.mp4"];
    [[ZYCRemotePlayer shareInstance] playWithURL:url isCache:YES];

}
//暂停
- (IBAction)pause:(id)sender {
    [[ZYCRemotePlayer shareInstance] pause];
}

//继续
- (IBAction)resume:(id)sender {
    [[ZYCRemotePlayer shareInstance] resume];
}

//快进
- (IBAction)kuaijiKn:(id)sender {
    [[ZYCRemotePlayer shareInstance] seekWithTimeDiffer:15];
}

//播放进度
- (IBAction)progress:(UISlider *)sender {
    [[ZYCRemotePlayer shareInstance] seekWithProgress:sender.value];

}
//播放速率
- (IBAction)rate:(id)sender {
    [[ZYCRemotePlayer shareInstance] setRate:2];

}

//静音
- (IBAction)muted:(UIButton *)sender {
    sender.selected = !sender.selected;
    [[ZYCRemotePlayer shareInstance] setMuted:sender.selected];
}

//声音
- (IBAction)volume:(UISlider *)sender {
    [[ZYCRemotePlayer shareInstance] setVolume:sender.value];

}

@end
