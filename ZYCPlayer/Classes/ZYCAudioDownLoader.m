//
//  ZYCAudioDownLoader.m
//  ZYCPlayer
//
//  Created by Circcus on 2017/6/12.
//  Copyright © 2017年 zhaoyongchuang. All rights reserved.
//

#import "ZYCAudioDownLoader.h"
#import "ZYCRemoteAudioFile.h"

@interface ZYCAudioDownLoader () <NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSURL *url;


@end

@implementation ZYCAudioDownLoader


- (NSURLSession *)session {
    if (!_session) {
        _session= [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}




- (void)downLoadwithURL:(NSURL *)url offset:(long long)offset {
    
    [self cancelAndClean];
    
    self.url = url;
    self.offset = offset;
    
    // 请求的是某一个区间的数据 Range
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0];
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-", offset] forHTTPHeaderField:@"Range"];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
    [task resume];
    
}


- (void)cancelAndClean {
    [self.session invalidateAndCancel];
    self.session = nil;
    [ZYCRemoteAudioFile clearTmpFile:self.url];
    
    self.loadedSize = 0;
}


#pragma mark --- NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    //1 从content-Length 取出来
    //2.如果 Content-Range 有,应该从content_Range里面获取
    self.totalSize = [response.allHeaderFields[@"Content-Length"] longLongValue];
    NSString *contentRangeStr = response.allHeaderFields[@"Content-Range"];
    if (contentRangeStr.length != 0) {
        self.totalSize = [[contentRangeStr componentsSeparatedByString:@"/"].lastObject longLongValue];
        
    }
    self.mimeType = response.MIMEType;
    
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:[ZYCRemoteAudioFile tmpFilePath:self.url] append:YES];
    [self.outputStream open];
    completionHandler(NSURLSessionResponseAllow);
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    self.loadedSize += data.length;
    [self.outputStream write:data.bytes maxLength:data.length];
    if ([self.delegate respondsToSelector:@selector(downLoading)]) {
        [self.delegate downLoading];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error == nil) {
        NSURL *url = self.url;
        if ([ZYCRemoteAudioFile tmpFileSize:url] == self.totalSize) {
            //移动文件从 tep 到 cache
            [ZYCRemoteAudioFile moveTmpPathToCachePath:url];
        }
    }else {
        NSLog(@"有错误");
    }
}















@end
