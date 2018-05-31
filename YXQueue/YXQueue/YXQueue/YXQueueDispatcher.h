//
//  YXQueueManager.h
//  YXQueueDemo
//
//  Created by jack on 2017/5/26.
//  Copyright © 2017年 JackLiu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YXQueueJob;
@class YXQueueJobManager;
@class YXQueueOperationModel;

@interface YXQueueDispatcher : NSObject

+ (YXQueueDispatcher*)sharedManager;

/**
 add new job
 */
- (void)addJob:(YXQueueJob*)job;

/**
 drop a job
 */
- (void)dropJob:(YXQueueJob*)job;

/**
 cancel a job
 */
- (void)cancelJob:(YXQueueJob*)job;

/**
 cancel all jobs
 */
- (void)cancelAllJobs;

/**
 pause all jobs
 */
- (void)pauseAllJobs;

/**
 resume all jobs
 */
- (void)resumeAllJobs;

/**
 suspend or resume all jobs
 */
- (void)setAllQueueSuspended:(BOOL)suspended;

/**
 get queue by type
 */
+ (NSOperationQueue*)operationQueueForType:(YXQueueOperationModel*)operationType;
- (NSOperationQueue*)operationQueueForType:(YXQueueOperationModel*)operationType;

/**
 get job manager
 */
- (YXQueueJobManager*)jobManagerForJob:(YXQueueJob*)job create:(BOOL)create;
- (YXQueueJobManager*)jobManagerForJob:(YXQueueJob *)job;

@end
