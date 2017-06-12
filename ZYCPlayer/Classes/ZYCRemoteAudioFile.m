//
//  ZYCRemoteAudioFile.m
//  ZYCPlayer
//
//  Created by Circcus on 2017/6/12.
//  Copyright © 2017年 zhaoyongchuang. All rights reserved.
//

#import "ZYCRemoteAudioFile.h"
#import <MobileCoreServices/MobileCoreServices.h>


#define kCacbePath NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject

#define kTemPath  NSTemporaryDirectory()


@implementation ZYCRemoteAudioFile


+ (NSString *)cacheFilePath:(NSURL *)url {
    return  [kCacbePath stringByAppendingPathComponent:url.lastPathComponent];
}

//根据文件路径计算文件大小
+ (long long)cacheFileSize:(NSURL *)url {
    if (![self cacheFileExists:url]) {
        return 0;
    }
    
    // 获取文件路径
    NSString *path = [self cacheFilePath:url];
    NSDictionary *fileInfoDic = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return [fileInfoDic[NSFileSize] longLongValue];
}

//文件下载中
+ (BOOL)cacheFileExists:(NSURL *)url {
    NSString *path = [self cacheFilePath:url];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+ (NSString *)tmpFilePath:(NSURL *)url {
    return [kTemPath stringByAppendingPathComponent:url.lastPathComponent];
}

+ (BOOL)tmpFileExists:(NSURL *)url {
    NSString *path = [self tmpFilePath:url];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

//计算cache文件夹文件的大小
+ (long long)tmpFileSize:(NSURL *)url {
    if (![self tmpFileExists:url]) {
        return 0;
    }
    
    //获取文件路径
    NSString *path = [self tmpFilePath:url];
    NSDictionary *fileInfoDic = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return [fileInfoDic[NSFileSize] longLongValue];
}

+(void)clearTmpFile:(NSURL *)url {
    NSString *tmpPath = [self tmpFilePath:url];
    BOOL isDirectory = YES;
    BOOL isEx = [[NSFileManager defaultManager] fileExistsAtPath:tmpPath isDirectory:&isDirectory];
    if (isEx && !isDirectory) {
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
    }
}

+ (NSString *)contentType:(NSURL *)url {
    NSString *path = [self cacheFilePath:url];
    NSString *fileExtension = path.pathExtension;
    
    CFStringRef contentTypeCF = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)(fileExtension), NULL);
    NSString *contentType = CFBridgingRelease(contentTypeCF);
    return contentType;
    
}

+ (void)moveTmpPathToCachePath:(NSURL *)url {
    NSString *tmpPath = [self tmpFilePath:url];
    NSString *cachePath = [self cacheFilePath:url];
    [[NSFileManager defaultManager] moveItemAtPath:tmpPath toPath:cachePath error:nil];
}


@end
