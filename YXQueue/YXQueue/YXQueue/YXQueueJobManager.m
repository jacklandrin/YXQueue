//
//  YXQueueJobManager.m
//  YXQueueDemo
//
//  Created by jack on 2017/5/31.
//  Copyright © 2017年 JackLiu. All rights reserved.
//

#import "YXQueueJobManager.h"
#import "YXQueueOperation.h"
#import "YXQueueDispatcher.h"

@implementation YXQueueJobManager

- (void)dealloc
{
    _job = nil;
}

- (instancetype)init
{
    return [self initWithJob:nil];
}

- (instancetype)initWithJob:(YXQueueJob *)job
{
    if (self = [super init]) {
        _job = job;
        _isCancel = NO;
        
        _operations = [[NSMutableArray alloc] init];
        [self resetOperations];
    }
    
    return self;
}

- (void)setJob:(YXQueueJob *)job
{
    if (_job != job) {
        _job = job;
    }
    [self resetOperations];
}

- (NSArray *)operationsWithResourceID:(NSString *)resourceIdentifier
{
    if (!resourceIdentifier) {
        return nil;
    }
    NSMutableArray *operations = [NSMutableArray array];
    [_operations enumerateObjectsUsingBlock:^(YXQueueOperation *obj, NSUInteger idx, BOOL *stop){
        if ([obj.resourceIdentifier isEqualToString:resourceIdentifier]) {
            [operations addObject:obj];
        }
    }];
    return operations;
}

- (void)restartOperations
{
    [_operations enumerateObjectsUsingBlock:^(YXQueueOperation *obj, NSUInteger idx, BOOL *stop){
        if (!obj.isFinished && !obj.isInQueue)
        {
            NSOperationQueue *queue = [YXQueueDispatcher operationQueueForType:obj.operationModel];
            [queue setSuspended:NO];
            obj.isInQueue = YES;
            [queue addOperation:obj];
        }
    }];
}

- (void)reloadOperations
{
    
}

/**
 * reset operation array
 */
- (void)resetOperations
{
    //cancel operation before removing
    [_operations makeObjectsPerformSelector:@selector(cancel)];
    [_operations removeAllObjects];
    
    //add operation corresponding job
    [_operations addObjectsFromArray:[[self class] makeOperationsForJob:self.job withDependencies:nil]];
}

/**
 * recursively create job corresponding operation meta
 */
+ (NSArray *)makeOperationsForJob:(YXQueueJob *)job withDependencies:(NSArray *)dependencies
{
    if (!job || ![job isKindOfClass:[YXQueueJob class]])
    {
        return nil;
    }
    
    NSMutableArray *operationArray = [NSMutableArray array];
    
    YXQueueOperation *operation = [((YXQueueOperation *)[[[job class] operationClass] alloc]) initWithJob:job];
    if (operation) {
        [dependencies enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [operation addDependency:obj];
        }];
        [operationArray addObject:operation];
    }
    
    return operationArray;
}

- (void)cancel
{
    self.job.jobState = YXQueueJobStateCanceled;
    [_operations makeObjectsPerformSelector:@selector(cancel)];
}

- (void)drop
{
    [self cancel];
    self.job.jobState = YXQueueJobStateDroped;
}

- (void)pause
{
    self.job.jobState = YXQueueJobStateCanceled;
    [_operations makeObjectsPerformSelector:@selector(cancel)];
}

- (void)restart
{
    self.job.jobState = YXQueueJobStateReady;
    [self resetOperations];
}

@end
