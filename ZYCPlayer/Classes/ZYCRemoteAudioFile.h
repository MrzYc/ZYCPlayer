//
//  ZYCRemoteAudioFile.h
//  ZYCPlayer
//
//  Created by Circcus on 2017/6/12.
//  Copyright © 2017年 zhaoyongchuang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZYCRemoteAudioFile : NSObject

+ (NSString *)cacheFilePath:(NSURL *)url;

+ (long long)cacheFileSize:(NSURL *)url;

+ (BOOL)cacheFileExists:(NSURL *)url;


+ (NSString *)tmpFilePath:(NSURL *)url;
+ (long long)tmpFileSize:(NSURL *)url;
+ (BOOL)tmpFileExists:(NSURL *)url;
+ (void)clearTmpFile:(NSURL *)url;


+ (NSString *)contentType:(NSURL *)url;

+ (void)moveTmpPathToCachePath:(NSURL *)url;


@end
