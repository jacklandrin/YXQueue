//
//  YXQueueDownloadOperation.m
//  YXQueue
//
//  Created by jack on 2017/6/14.
//  Copyright © 2017年 JackLiu. All rights reserved.
//

#import "YXQueueDownloadOperation.h"
#import "YXQueueDownloadJob.h"


typedef void (^DownloadProgressBlock) (NSProgress*);
typedef NSURL* (^DownloadDestinationUrl)(NSURL*, NSURLResponse*);
typedef void (^DownloadSuccess)(NSURLResponse *response, NSURL *fileURL);
typedef void (^DownloadFailure)(NSURLResponse *response, NSError *error);

@interface YXQueueDownloadOperation() <NSURLSessionTaskDelegate,NSURLSessionDownloadDelegate>
{
    YXQueueOperationModel *_model;
}

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, copy  ) DownloadProgressBlock downloadProgressBlock;
@property (nonatomic, copy  ) DownloadDestinationUrl destinationUrl;
@property (nonatomic, copy  ) DownloadSuccess downloadSuccess;
@property (nonatomic, copy  ) DownloadFailure downloadFailure;

@end

@implementation YXQueueDownloadOperation

- (instancetype)initWithJob:(YXQueueJob *)queueJob
{
    NSAssert([queueJob isKindOfClass:[YXQueueDownloadJob class]], @"queueJob must be YXQueueDownloadJob");
    if (self = [super initWithJob:queueJob]) {
        self.resourceIdentifier = @"com.queue.download";
        self.queuePriority = NSOperationQueuePriorityLow;
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
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
        _model.maxConcurrentOperationCount = 5;
    }
    return _model;
}

- (void)executeTaskWithResultBlock:(void (^)(void))block
{
    __weak typeof(self) weakSelf = self;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.job.downloadUrl] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:3600];
    NSURLSessionDownloadTask *downloadTask = [self downloadTaskWithRequest:request progress:^(NSProgress *downloadProgress) {
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

-(NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                            progress:(void (^)(NSProgress * _Nullable))progress
                                         destination:(NSURL *(^)(NSURL * _Nullable, NSURLResponse * _Nullable))destination
                                             success:(void (^)(NSURLResponse * _Nullable, NSURL * _Nullable))success
                                             failure:(void (^)(NSURLResponse * _Nullable, NSError * _Nullable))failure
{
    NSURLSessionDownloadTask *task = [_session downloadTaskWithRequest:request];
    self.downloadProgressBlock = progress;
    self.destinationUrl = destination;
    self.downloadSuccess = success;
    self.downloadFailure = failure;
    [task resume];
    return task;
}

#pragma mark - NSURLSessionDownloadDelegate
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    if (self.downloadProgressBlock) {
        NSProgress *progress = [NSProgress progressWithTotalUnitCount:totalBytesExpectedToWrite];
        progress.completedUnitCount = totalBytesWritten;
        self.downloadProgressBlock(progress);
    }
}


- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    if (downloadTask.error) {
        self.downloadFailure(downloadTask.response, downloadTask.error);
        return;
    }
    NSURL *fileURL = [NSURL URLWithString:@""];
    if (self.destinationUrl) {
        fileURL = self.destinationUrl(location, downloadTask.response);
        NSError *error = nil;
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:fileURL error:&error];
        if (error) {
            self.downloadFailure(downloadTask.response, error);
        } else {
            self.downloadSuccess(downloadTask.response, location);
        }
    }
    
}


#pragma mark - NSURLSessionTaskDelegate
-(void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error && self.downloadFailure) {
        self.downloadFailure(task.response, error);
    }
}


@end
