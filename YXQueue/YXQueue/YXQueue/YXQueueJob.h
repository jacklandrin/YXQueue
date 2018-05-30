//
//  YXQueueJob.h
//  YXQueueDemo
//
//  Created by jack on 2017/5/27.
//  Copyright © 2017年 YIXIA. All rights reserved.
//

#import "YXQueueOperation.h"

@class YXQueueJob;
@class YXQueueOperation;

typedef NS_ENUM(NSInteger, YXQueueJobState)
{
    YXQueueJobStateReady,            //job has been added
    YXQueueJobStateExecuting,        //job is executed
    YXQueueJobStateCanceled,         //job is canceled
    YXQueueJobStateFinishedSuccess,  //job done success
    YXQueueJobStateFinishedFailed,   //job done failed
    YXQueueJobStateDroped            //job is droped
};

@protocol YXQueueJobDelegate <NSObject>

@optional
/**
 job finished
 */
- (void)queueJob:(YXQueueJob*)job operationFinished:(YXQueueOperation*)operation;
/**
 job started
 */
- (void)queueJob:(YXQueueJob*)job operationDidStart:(YXQueueOperation*)operation;
/**
 job failed
 */
- (void)queueJob:(YXQueueJob*)job operationFailed:(YXQueueOperation*)operation withError:(NSError*)error;
/**
 job was cancelled
 */
- (void)queueJob:(YXQueueJob*)job operationDidCanceled:(YXQueueOperation*)operation;
/**
 the progress updated
 */
- (void)queueJob:(YXQueueJob*)job operationDidUpdateProgress:(float)progress;

@end

@interface YXQueueJob : NSObject <YXQueueOperationDelegate>

@property (nonatomic, strong) NSDate *time; //job created time
@property (nonatomic, assign) YXQueueJobState jobState; //current job state
@property (nonatomic, assign) BOOL resultInMainThread; //whether callback in main thread
@property (nonatomic, strong) NSError *error; //error, if it's not nil, callback failure
@property (nonatomic, assign) NSUInteger tag; //job id, you can use it to distinguish which job

+ (Class)operationClass; //corresponding operation class
+ (Class)managerClass; //corresponding jobManager class

- (NSString*)jobTypeString; //job type

- (void)doJob; //add job into queue
- (void)doCancel; //non-current job can be canceled

- (void)addDelegate:(id<YXQueueJobDelegate>)delegate;
- (void)removeDelegate:(id<YXQueueJobDelegate>)delegate;

@end
