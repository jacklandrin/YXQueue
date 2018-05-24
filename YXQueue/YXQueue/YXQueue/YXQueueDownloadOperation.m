//
//  YXQueueDownloadOperation.m
//  YXQueue
//
//  Created by jack on 2017/6/14.
//  Copyright © 2017年 YIXIA. All rights reserved.
//

#import "YXQueueDownloadOperation.h"
#import "YXQueueDownloadJob.h"

@interface YXQueueDownloadOperation()
{
    YXQueueOperationModel *_model;
}

@end

@implementation YXQueueDownloadOperation

- (instancetype)initWithJob:(YXQueueJob *)queueJob
{
    NSAssert([queueJob isKindOfClass:[YXQueueDownloadJob class]], @"queueJob must be YXQueueDownloadJob");
    if (self = [super initWithJob:queueJob]) {
        self.resourceIdentifier = @"com.queue.download";
        self.queuePriority = NSOperationQueuePriorityLow;
    }
    return self;
}

- (YXQueueDownloadJob *)job
{
    return (YXQueueDownloadJob*)_job;
}

- (YXQueueOperationModel *)operationModel
{
    if (!_model) {
        _model = [[YXQueueOperationModel alloc] init];
        _model.operationTypeString = @"downloadOperation";
        _model.maxConcurrentOperationCount = 1;
    }
    return _model;
}

- (void)executeTaskWithResultBlock:(void (^)())block
{
    __weak typeof(self) weakSelf = self;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.job.downloadUrl] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:3600];
    NSURLSessionDownloadTask *downloadTask = [[YXRequestManager shareManager] downloadTaskWithRequest:request progress:^(NSProgress *downloadProgress) {
        weakSelf.progress = (float)downloadProgress.completedUnitCount / (float)downloadProgress.totalUnitCount;
        [weakSelf notifiProgressDidChange];
    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        return [NSURL fileURLWithPath:weakSelf.job.targePath];
    } success:^(NSURLResponse *response, NSURL *fileURL) {
        self.operationReslut = response;
        if (block) {
            block();
        }
    } failure:^(NSURLResponse *response, NSError *error) {
        weakSelf.operationError = error;
        if (block) {
            block();
        }
    }];
    downloadTask.priority = NSOperationQueuePriorityLow;
}
@end
