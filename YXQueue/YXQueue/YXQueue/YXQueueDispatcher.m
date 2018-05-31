//
//  YXQueueManager.m
//  YXQueueDemo
//
//  Created by jack on 2017/5/26.
//  Copyright © 2017年 JackLiu. All rights reserved.
//

#import "YXQueueDispatcher.h"
#import "YXQueueJobManager.h"
#import "YXQueueOperation.h"

@interface YXQueueDispatcher() <YXQueueJobDelegate>

@property (nonatomic, strong) NSMutableDictionary *queueList;
@property (nonatomic, strong) NSMutableArray *jobManagerList;
@property (nonatomic, strong) NSMutableSet *delegateSet;

@end

@implementation YXQueueDispatcher

-(void)dealloc
{
    _jobManagerList = nil;
    _queueList = nil;
    
}

-(instancetype)init
{
    if (self = [super init]) {
        _jobManagerList = [[NSMutableArray alloc] init];
        _queueList = [[NSMutableDictionary alloc] init];
        _delegateSet = (NSMutableSet*)CFBridgingRelease(CFSetCreateMutable(NULL, 0, &kCFCopyStringSetCallBacks));
    }
    return self;
}

+ (YXQueueDispatcher *)sharedManager
{
    static YXQueueDispatcher *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[YXQueueDispatcher alloc] init];
    });
    return sharedManager;
}

- (NSOperationQueue*)operationQueueForType:(YXQueueOperationModel*)operationType
{
    if (operationType.operationTypeString.length == 0) {
        return nil;
    }
    NSOperationQueue *jobQueue = [_queueList objectForKey:operationType.operationTypeString];
    if (!jobQueue) {
        jobQueue = [[NSOperationQueue alloc] init];
        [jobQueue setMaxConcurrentOperationCount:operationType.maxConcurrentOperationCount];
        [_queueList setObject:jobQueue forKey:operationType.operationTypeString];
    }
    return jobQueue;
}

+ (NSOperationQueue*)operationQueueForType:(YXQueueOperationModel *)operationType
{
    return [[self sharedManager] operationQueueForType:operationType];
}

- (YXQueueJobManager *)jobManagerForJob:(YXQueueJob *)job
{
    return [self jobManagerForJob:job create:NO];
}

- (YXQueueJobManager *)jobManagerForJob:(YXQueueJob *)job create:(BOOL)create
{
    if (!job) {
        return nil;
    }
    
    YXQueueJobManager *jobManager = nil;
    NSArray *jobManagerList = [_jobManagerList copy];
    for (YXQueueJobManager *manager in jobManagerList) {
        if (job == manager.job) {
            jobManager = manager;
            if (create) {
                [jobManager reloadOperations];
            }
            break;
        }
    }
    
    if (!jobManager && create) {
        jobManager = [[[[job class] managerClass] alloc] initWithJob:job];
        [_jobManagerList addObject:jobManager];
    }
    return jobManager;
}

#pragma mark -- add

- (void)addJob:(YXQueueJob *)job
{
    if (!job) {
        return;
    }
    
    YXQueueJobManager *jobManager = [self jobManagerForJob:job create:YES];
    [job addDelegate:self];
    [jobManager.operations enumerateObjectsUsingBlock:^(YXQueueOperation* obj, NSUInteger idx, BOOL *stop) {
        NSOperationQueue *queue = [self operationQueueForType:obj.operationModel];
        if (queue && queue.isSuspended) {
            [queue setSuspended:NO];
        }
        if (queue && !obj.isInQueue) {
            obj.isInQueue = YES;
            [queue addOperation:obj];
        }
    }];
}

- (void)dropJob:(YXQueueJob *)job
{
    if (!job) {
        return;
    }
    
    YXQueueJobManager *jobManager = [self jobManagerForJob:job];
    if (jobManager) {
        [jobManager drop];
        [_jobManagerList removeObject:jobManager];
    }
    else
    {
        job.jobState = YXQueueJobStateDroped;
    }
}

- (void)cancelJob:(YXQueueJob *)job
{
    if (!job) {
        return;
    }
    YXQueueJobManager *jobManager = [self jobManagerForJob:job];
    if (jobManager) {
        [jobManager cancel];
        [_jobManagerList removeObject:jobManager];
    } else {
        job.jobState = YXQueueJobStateCanceled;
    }
}

- (void)cancelAllJobs
{
    [_jobManagerList removeAllObjects];
}


#pragma mark - delegate
- (void)addDelegate:(id<YXQueueJobDelegate>)delegate
{
    [_delegateSet addObject:delegate];
}

- (void)removeDelegate:(id<YXQueueJobDelegate>)delegate
{
    [_delegateSet removeObject:delegate];
}

#pragma mark -- pause
- (void)pauseAllJobs
{
    [[_queueList allValues] makeObjectsPerformSelector:@selector(setSuspended:) withObject:@YES];
}

- (void)resumeAllJobs
{
    [[_queueList allValues] makeObjectsPerformSelector:@selector(setSuspended:) withObject:@NO];
}

-(void)setAllQueueSuspended:(BOOL)suspended
{
    [_jobManagerList enumerateObjectsUsingBlock:^(NSOperationQueue* obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj setSuspended:suspended];
    }];
}



@end
