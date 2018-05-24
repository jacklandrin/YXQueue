//
//  YXQueueDownloadJob.m
//  YXQueue
//
//  Created by jack on 2017/6/14.
//  Copyright © 2017年 YIXIA. All rights reserved.
//

#import "YXQueueDownloadJob.h"
#import "YXQueueDownloadOperation.h"
#import "YXQueueDownloadJobManager.h"

@interface YXQueueDownloadJob()
{
    NSDictionary *_parameter;
}


@end

@implementation YXQueueDownloadJob

- (NSString *)jobTypeString
{
    return @"download";
}

+ (Class)managerClass
{
    return [YXQueueDownloadJobManager class];
}

+ (Class)operationClass
{
    return [YXQueueDownloadOperation class];
}

- (void)queueOperation:(YXQueueOperation *)operation didFailureWithError:(NSError *)error
{
    [super queueOperation:operation didFailureWithError:error];
}

- (void)queueOperation:(YXQueueOperation *)operation didFinishWithResult:(id)response
{
    [super queueOperation:operation didFinishWithResult:response];
}

- (void)queueOperation:(YXQueueOperation *)operation didUpdateProgress:(float)progress
{
    [super queueOperation:operation didUpdateProgress:progress];
}


@end
