//
//  NSURL+Stream.m
//  ZYCPlayer
//
//  Created by 赵永闯 on 2017/6/10.
//  Copyright © 2017年 zhaoyongchuang. All rights reserved.
//

#import "NSURL+Stream.h"

@implementation NSURL (Stream)

//把数据流资源给截成一段一段的
- (NSURL *)steamingURL {
    
    NSURLComponents *compents = [NSURLComponents componentsWithString:self.absoluteString];
    compents.scheme = @"sreaming";
    return compents.URL;
    
}

- (NSURL *)httpURL {
    NSURLComponents *compents = [NSURLComponents componentsWithString:self.absoluteString];
    compents.scheme = @"http";
    return compents.URL;
}

@end
