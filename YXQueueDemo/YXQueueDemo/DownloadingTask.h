//
//  DownloadingTask.h
//  YXQueueDemo
//
//  Created by jack on 2018/5/25.
//  Copyright © 2018年 JackLiu. All rights reserved.
//

#import <YXQueueDownloadJob.h>

typedef enum {
    DownloadStatusWaiting,
    DownloadStatusDownloading,
    DownloadStatusDone,
    DownloadStatusFailure
} DownloadStatus;

@class DownloadingTask;

@protocol DownloadingTaskDelegate <NSObject>

- (void)downloadingTaskDidChanged:(DownloadingTask*)task;

@end

@interface DownloadingTask : NSObject <YXQueueJobDelegate>

@property (nonatomic, assign) DownloadStatus downloadStatus;
@property (nonatomic, copy  ) NSString *fileNameStr;
@property (nonatomic, copy  ) NSString *filePath;
@property (nonatomic, assign) float progress;
@property (nonatomic, weak  ) id<DownloadingTaskDelegate> delegate;

@end
