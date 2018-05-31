//
//  YXQueueOperation.m
//  YXQueueDemo
//
//  Created by jack on 2017/5/27.
//  Copyright © 2017年 JackLiu. All rights reserved.
//

#import "YXQueueOperation.h"
#import "YXQueueJob.h"

@interface YXQueueOperation()
{
    dispatch_semaphore_t _operationSemaphore;
    NSTimeInterval _startTime;
}

@end

@implementation YXQueueOperation

-(void)dealloc
{
    _job = nil;
    if (_operationSemaphore) {
        _operationSemaphore = nil;
    }
}

-(instancetype)initWithJob:(YXQueueJob *)queueJob
{
    if (self = [super init]) {
        _job = queueJob;
    }
    return self;
}

-(void)main
{
    @try {
        @autoreleasepool {
            if ([self isCancelled]) {
                if (_job.resultInMainThread) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self doCompletion];
                    });
                } else {
                    [self doCompletion];
                }
                
                return;
            }
            
            if ([self.job respondsToSelector:@selector(queueOperationDidStarted:)]) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.job queueOperationDidStarted:self];
                });
            }
            
            _operationSemaphore = dispatch_semaphore_create(0);
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                [self executeTaskWithResultBlock:^{
                    if (_operationSemaphore) {
                        dispatch_semaphore_signal(_operationSemaphore);
                    }
                }];
            });
            
            if ([self isCancelled]) {
                dispatch_semaphore_signal(_operationSemaphore);
                _operationSemaphore = nil;
                return;
            }
            
            dispatch_semaphore_wait(_operationSemaphore, DISPATCH_TIME_FOREVER);
            _operationSemaphore = nil;
            if ([self isCancelled]) {
                return;
            }
            
            if (_job.resultInMainThread) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self doCompletion];
                });
            } else {
                [self doCompletion];
            }
        }
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
}

-(YXQueueJob *)job
{
    return _job;
}

- (void)doCompletion
{
    if ([self isCancelled]) {
        return;
    }
    
    if (self.operationError) {
        self.progress = 0;
        [self notifiProgressDidChange];
        if ([self.job respondsToSelector:@selector(queueOperation:didFailureWithError:)]) {
            [self.job queueOperation:self didFailureWithError:self.operationError];
        }
    } else {
        self.progress = 1;
        [self notifiProgressDidChange];
        if ([self.job respondsToSelector:@selector(queueOperation:didFinishWithResult:)]) {
            [self.job queueOperation:self didFinishWithResult:self.operationReslut];
        }
    }
}


- (BOOL)isCancelled
{
    return [super isCancelled] || self.job.jobState == YXQueueJobStateCanceled || self.job.jobState == YXQueueJobStateFinishedFailed;
}

-(void)cancel
{
    if (!self.isFinished) {
        [super cancel];
    }
    
    if (_operationSemaphore) {
        dispatch_semaphore_signal(_operationSemaphore);
    }
    
    if ([self.job respondsToSelector:@selector(queueOperationDidCancelled:)]) {
        [self.job queueOperationDidCancelled:self];
    }
}

- (YXQueueOperationModel*)operationModel
{
    return [[YXQueueOperationModel alloc] init];
}

-(void)executeTaskWithResultBlock:(void (^)(void))block
{
    if (block) {
        block();
    }
}

- (void)notifiProgressDidChange
{
    if ([self.job respondsToSelector:@selector(queueOperation:didUpdateProgress:)]) {
        if ([NSThread isMainThread]) {
            [self.job queueOperation:self didUpdateProgress:self.progress];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"download progress:%f",self.progress);
                [self.job queueOperation:self didUpdateProgress:self.progress];
            });
        }
    }
}

@end

@implementation YXQueueOperationModel

- (instancetype)init
{
    if (self = [super init]) {
        self.maxConcurrentOperationCount = 1;
        self.operationTypeString = nil;
    }
    return self;
}

@end
