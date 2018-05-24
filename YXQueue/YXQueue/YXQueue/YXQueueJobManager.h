//
//  YXQueueJobManager.h
//  YXQueueDemo
//
//  Created by jack on 2017/5/31.
//  Copyright © 2017年 YIXIA. All rights reserved.
//

#import "YXQueueJob.h"

@interface YXQueueJobManager : NSObject

@property (nonatomic, strong) YXQueueJob *job; //the job added in queue
@property (atomic, assign) BOOL isCancel; //if it's be cancelled
@property (nonatomic, readonly) NSMutableArray *operations; //all opeeations in the queue

/**
 initialization job manager
 */
- (instancetype)initWithJob:(YXQueueJob*)job;

/**
 get all operations in this queue with queue name
 @param resourceIdentifier queue name
 */
- (NSArray*)operationsWithResourceID:(NSString*)resourceIdentifier;
/**
 set the dependencies of jobs
 */
+ (NSArray*)makeOperationsForJob:(YXQueueJob*)job withDependencies:(NSArray*)dependencies;
/**
 when job is added in queue, the method will be invoked
 */
- (void)reloadOperations;

/**
drop job
 */
- (void)drop;
/**
 cacel job
 */
- (void)cancel;
/**
 pause job
 */
- (void)pause;

/**
 restart job
 */
- (void)restart;

@end
