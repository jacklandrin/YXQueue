//
//  DownloadingTask.m
//  YXQueueDemo
//
//  Created by jack on 2018/5/25.
//  Copyright © 2018年 JackLiu. All rights reserved.
//

#import "DownloadingTask.h"

@implementation DownloadingTask

- (instancetype)init
{
    if (self = [super init]) {
        self.downloadStatus = DownloadStatusWaiting;
        self.progress = 0.0;
    }
    return self;
}

- (void)queueJob:(YXQueueJob *)job operationDidUpdateProgress:(float)progress
{
    self.progress = progress;
    [self doNotifiyTaskChanged];
}

- (void)queueJob:(YXQueueJob *)job operationDidStart:(YXQueueOperation *)operation
{
    self.downloadStatus = DownloadStatusDownloading;
    [self doNotifiyTaskChanged];
}

- (void)queueJob:(YXQueueJob *)job operationFinished:(YXQueueOperation *)operation
{
    self.downloadStatus = DownloadStatusDone;
    [self doNotifiyTaskChanged];
}

- (void)queueJob:(YXQueueJob *)job operationFailed:(YXQueueOperation *)operation withError:(NSError *)error
{
    self.downloadStatus = DownloadStatusFailure;
    [self doNotifiyTaskChanged];
}

- (void)doNotifiyTaskChanged
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadingTaskDidChanged:)]) {
        [self.delegate downloadingTaskDidChanged:self];
    }
}

@end
