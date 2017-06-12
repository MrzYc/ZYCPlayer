//
//  ZYCAudioDownLoader.h
//  ZYCPlayer
//
//  Created by Circcus on 2017/6/12.
//  Copyright © 2017年 zhaoyongchuang. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol ZYCAudioDownLoaderDelegate <NSObject>

- (void)downLoading;

@end

@interface ZYCAudioDownLoader : NSObject

@property (nonatomic, weak) id<ZYCAudioDownLoaderDelegate> delegate;

@property (nonatomic, assign) long long totalSize;
@property (nonatomic, assign) long long loadedSize;
@property (nonatomic, assign) long long offset;
@property (nonatomic, strong) NSString *mimeType;

- (void)downLoadwithURL:(NSURL *)url offset:(long long)offset;



@end
