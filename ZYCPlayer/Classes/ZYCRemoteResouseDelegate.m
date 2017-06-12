//
//  ZYCRemoteResouseDelegate.m
//  ZYCPlayer
//
//  Created by 赵永闯 on 2017/6/10.
//  Copyright © 2017年 zhaoyongchuang. All rights reserved.
//

#import "ZYCRemoteResouseDelegate.h"
#import "ZYCRemoteAudioFile.h"
#import "ZYCAudioDownLoader.h"
#import "NSURL+Stream.h"


@interface ZYCRemoteResouseDelegate () <ZYCAudioDownLoaderDelegate>


@property (nonatomic , strong) ZYCAudioDownLoader *downLoader;

/** 请求数组 */
@property (nonatomic , strong) NSMutableArray *loadingRequests;

@end

@implementation ZYCRemoteResouseDelegate


- (ZYCAudioDownLoader *)downLoader {
    if (!_downLoader) {
        _downLoader = [[ZYCAudioDownLoader alloc] init];
        _downLoader.delegate = self;
    }
    return _downLoader;
}

- (NSMutableArray *)loadingRequests {
    if (!_loadingRequests) {
        _loadingRequests = [NSMutableArray array];
    }
    return _loadingRequests;
}


//当外界需要播放一段音频资源时，会抛出一个请求，给这个对象
// 这个对象，可以根据请求信息，跑数据给外界
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    
    NSLog(@"%@", loadingRequest);
    //1.判断本地有没有该音频资源的缓存文件,如果有 -> 直接根据本地缓存,向外界传递数据
    NSURL *url = [loadingRequest.request.URL httpURL];
    
    long long requestOffset = loadingRequest.dataRequest.requestedOffset;
    long long currentOffset = loadingRequest.dataRequest.currentOffset;
    if (requestOffset != currentOffset) {
        requestOffset = currentOffset;
    }
    
    if ([ZYCRemoteAudioFile cacheFileExists:url]) {
        [self handleLoadingRequest:loadingRequest];
        return YES;
    }
    
    //记录所有的请求
    [self.loadingRequests addObject:loadingRequest];
    
    //2.判断有没有正在下载
    if (self.downLoader.loadedSize == 0) {
        [self.downLoader downLoadwithURL:url offset:requestOffset];
        
        return YES;
    }
    
    //3.判断当前是否需要重新下载
    //3.1 当前资源请求, 开始点 -> 下载的开始点
    //3.2 当资源的请求, 开始点 -> 下载的开始点 + 下载长度 + 100
    if (requestOffset < self.downLoader.offset || requestOffset > (self.downLoader.offset + self.downLoader.loadedSize + 100)) {
        [self.downLoader downLoadwithURL:url offset:requestOffset];
        return YES;
    }
    
    // 开始处理资源请求 (在下载过程当中, 也要不断的判断)
    [self handleAllLoadingRequest];
    
    return YES;
    
    
//    
//    //根据请求信息，返回给外界数据
//    // 1. 填充相应的信息头信息
//    loadingRequest.contentInformationRequest.contentLength = 4093201;
//    loadingRequest.contentInformationRequest.contentType = @"public.mp3";
//    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
//    
//    // 2. 相应数据给外界
//    NSData *data = [NSData dataWithContentsOfFile:@"/Users/yululu/Desktop/235319.mp3" options:NSDataReadingMappedIfSafe error:nil];
//    
//    long long requestOffset = loadingRequest.dataRequest.requestedOffset;
//    NSInteger requestLength = loadingRequest.dataRequest.requestedLength;
//    
//    NSData *subData = [data subdataWithRange:NSMakeRange(requestOffset, requestLength)];
//    
//    [loadingRequest.dataRequest respondWithData:subData];
//    
//    // 3. 完成本次请求(一旦,所有的数据都给完了, 才能调用完成请求方法)
//    [loadingRequest finishLoading];
//    
//    return YES;
}



// 取消请求
- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"取消某个请求");
    [self.loadingRequests removeObject:loadingRequest];
}

- (void)downLoading {
    [self handleAllLoadingRequest];
}

//处理本地已经下载好的资源
- (void)handleLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSURL *url = loadingRequest.request.URL;
    long long totalSize = [ZYCRemoteAudioFile cacheFileSize:url];
    loadingRequest.contentInformationRequest.contentLength = totalSize;
    
    NSString *contentType = [ZYCRemoteAudioFile contentType:url];
    loadingRequest.contentInformationRequest.contentType = contentType;
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    
    //响应数据给外界
    NSData *data = [NSData dataWithContentsOfFile:[ZYCRemoteAudioFile cacheFilePath:url] options:NSDataReadingMappedIfSafe error:nil];
    
    long long requestOffset = loadingRequest.dataRequest.requestedOffset;
    NSInteger requestLength = loadingRequest.dataRequest.requestedLength;
    
    NSData *subData = [data subdataWithRange:NSMakeRange(requestOffset, requestLength)];
    
    [loadingRequest.dataRequest respondWithData:subData];
    
    //完成本次请求,调用
    [loadingRequest finishLoading];
    
    
}

- (void)handleAllLoadingRequest {
    //    NSLog(@"在这里不断的处理请求");
    NSLog(@"-----%@", self.loadingRequests);
    NSMutableArray *deleteRequests = [NSMutableArray array];
    for (AVAssetResourceLoadingRequest *loadingRequest in self.loadingRequests) {
        // 1. 填充内容信息头
        NSURL *url = loadingRequest.request.URL;
        long long totalSize = self.downLoader.totalSize;
        loadingRequest.contentInformationRequest.contentLength = totalSize;
        NSString *contentType = self.downLoader.mimeType;
        loadingRequest.contentInformationRequest.contentType = contentType;
        loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
        
        // 2. 填充数据
        NSData *data = [NSData dataWithContentsOfFile:[ZYCRemoteAudioFile tmpFilePath:url] options:NSDataReadingMappedIfSafe error:nil];
        if (data == nil) {
            data = [NSData dataWithContentsOfFile:[ZYCRemoteAudioFile cacheFilePath:url] options:NSDataReadingMappedIfSafe error:nil];
        }
        
        long long requestOffset = loadingRequest.dataRequest.requestedOffset;
        long long currentOffset = loadingRequest.dataRequest.currentOffset;
        if (requestOffset != currentOffset) {
            requestOffset = currentOffset;
        }
        NSInteger requestLength = loadingRequest.dataRequest.requestedLength;
        
        
        long long responseOffset = requestOffset - self.downLoader.offset;
        long long responseLength = MIN(self.downLoader.offset + self.downLoader.loadedSize - requestOffset, requestLength) ;
        
        NSData *subData = [data subdataWithRange:NSMakeRange(responseOffset, responseLength)];
        
        [loadingRequest.dataRequest respondWithData:subData];
        
        
        
        // 3. 完成请求(必须把所有的关于这个请求的区间数据, 都返回完之后, 才能完成这个请求)
        if (requestLength == responseLength) {
            [loadingRequest finishLoading];
            [deleteRequests addObject:loadingRequest];
        }
        
    }
    
    [self.loadingRequests removeObjectsInArray:deleteRequests];

}

















@end
