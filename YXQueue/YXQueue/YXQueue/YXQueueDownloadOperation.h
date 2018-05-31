//
//  YXQueueDownloadOperation.h
//  YXQueue
//
//  Created by jack on 2017/6/14.
//  Copyright © 2017年 JackLiu. All rights reserved.
//

#import "YXQueueOperation.h"

@class YXQueueDownloadJob;

@interface YXQueueDownloadOperation : YXQueueOperation

@property (strong, readonly) YXQueueDownloadJob *job;

@end
