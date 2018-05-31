//
//  YXQueueOperation.h
//  YXQueueDemo
//
//  Created by jack on 2017/5/27.
//  Copyright © 2017年 JackLiu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YXQueueOperation;
@class YXQueueJob;

@protocol YXQueueOperationDelegate <NSObject>

/**
 job started
 */
- (void)queueOperationDidStarted:(YXQueueOperation*)operation;
/**
 job is done
 */
- (void)queueOperation:(YXQueueOperation*)operation didFinishWithResult:(id)response;
/**
 job is failed
 */
- (void)queueOperation:(YXQueueOperation*)operation didFailureWithError:(NSError*)error;
/**
 job is cancelled
 */
- (void)queueOperationDidCancelled:(YXQueueOperation*)operation;

@optional
/**
 job updated progress
 */
- (void)queueOperation:(YXQueueOperation*)operation didUpdateProgress:(float)progress;

@end

@interface YXQueueOperationModel : NSObject

@property (nonatomic, copy) NSString *operationTypeString;//operation type
@property (nonatomic, assign) NSUInteger maxConcurrentOperationCount;//max thread concurrent operation count

@end

@interface YXQueueOperation : NSOperation
{
     YXQueueJob *_job;
}

- (instancetype)initWithJob:(YXQueueJob*)queueJob;
- (YXQueueJob *)job;

@property (nonatomic, assign) BOOL isInQueue; //if the operation is added in queue

@property (nonatomic, strong) id operationReslut; //job's result, if doesn't have error, it will be success
@property (nonatomic, strong) NSError *operationError; //job's error, if it's not nil, it will be failed.

@property (nonatomic, assign) NSTimeInterval cancelledTime; // job cancelled time
@property (nonatomic, copy) NSString *resourceIdentifier; //queue name

@property (nonatomic, assign) float progress; //current progress

@property (nonatomic, readonly) YXQueueOperationModel *operationModel; //operation config

/**
 task's content
 */
- (void)executeTaskWithResultBlock:(void (^)(void))block;
/**
 when the job is done, the method will be invoked
 */
- (void)doCompletion;
/**
 notify the job's progress
 */
- (void)notifiProgressDidChange;

@end
