//
//  YXQueueJob.m
//  YXQueueDemo
//
//  Created by jack on 2017/5/27.
//  Copyright © 2017年 YIXIA. All rights reserved.
//

#import "YXQueueJob.h"
#import "YXQueueOperation.h"
#import "YXQueueJobManager.h"
#import "YXQueueDispatcher.h"

@interface YXQueueJob()

@property (nonatomic, assign) NSInteger errorCode;
@property (nonatomic, strong) NSString *errorMessage;
@property (nonatomic, strong) NSMutableDictionary *properties;
@property (nonatomic, strong) id result;
@property (nonatomic, strong) NSHashTable *delegateSet;

@end

@implementation YXQueueJob

-(instancetype)init
{
    if (self = [super init]) {
        _jobState = YXQueueJobStateExecuting;
        _time = [NSDate date];
    }
    
    return self;
}

-(NSHashTable *)delegateSet
{
    if (!_delegateSet) {
        _delegateSet = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory capacity:0];
    }
    return _delegateSet;
}

+ (Class)operationClass
{
    return [YXQueueOperation class];
}

+ (Class)managerClass
{
    return [YXQueueJobManager class];
}

- (void)doJob
{
    self.jobState = YXQueueJobStateReady;
    [[YXQueueDispatcher sharedManager] addJob:self];
}

- (void)doCancel
{
    [[YXQueueDispatcher sharedManager] cancelJob:self];
}

- (BOOL)canDoJob
{
    return (self.jobState == YXQueueJobStateFinishedFailed || self.jobState == YXQueueJobStateCanceled);
}

#pragma mark -  properties
- (id)valueOfProperty:(NSString *)propName
{
    return [_properties objectForKey:propName];
}

- (void)addProperty:(NSString *)propName withValue:(id)propValue
{
    if (!_properties)
    {
        _properties = [[NSMutableDictionary alloc] init];
    }
    if (propName && propValue)
    {
        [_properties setObject:propValue forKey:propName];
    }
}

- (void)addParameter:(NSString *)value forKey:(NSString *)key
{
    NSMutableDictionary *paramsDict = [self _parametersDictionary];
    if (value && key)
    {
        [paramsDict setObject:value forKey:key];
    }
}

- (void)addParameters:(NSDictionary *)parameters forKey:(NSString *)key
{
    NSMutableDictionary *paramsDict = [self _parametersDictionary];
    if (key)
    {
        if (parameters) {
            [paramsDict setObject:parameters forKey:key];
        } else {
            [paramsDict removeObjectForKey:key];
        }
    }
}

- (void)addParameters:(NSDictionary *)params
{
    NSMutableDictionary *paramsDict = [self _parametersDictionary];
    if (params)
    {
        [paramsDict addEntriesFromDictionary:params];
    }
}

- (void)removeProperty:(NSString *)propName
{
    [_properties  removeObjectForKey:propName];
    if (_properties  && (_properties.count == 0))
    {
        _properties  = nil;
    }
}

- (void)removeParameterForKey:(NSString *)key
{
    [[self parametersDictionary] removeObjectForKey:key];
}

- (NSMutableDictionary *)_parametersDictionary
{
    NSMutableDictionary * paramsDict = [self parametersDictionary];
    if (!paramsDict)
    {
        paramsDict = [NSMutableDictionary dictionary];
        [self addProperty:@"parameters-dict" withValue:paramsDict];
    }
    return paramsDict;
}

- (NSMutableDictionary *)parametersDictionary
{
    return [self.properties objectForKey:@"parameters-dict"];
}


#pragma mark operationDelegate
- (void)queueOperationDidStarted:(YXQueueOperation *)operation
{
    self.jobState = YXQueueJobStateExecuting;
    for (id<YXQueueJobDelegate> delegate in _delegateSet) {
        if ([delegate respondsToSelector:@selector(queueJob:operationDidStart:)]) {
            [delegate queueJob:self operationDidStart:operation];
        }
    }
}

-(void)queueOperation:(YXQueueOperation *)operation didFinishWithResult:(id)response
{
    if ([self.class operationClass] == operation.class) {
        self.result = response;
        self.jobState = YXQueueJobStateFinishedSuccess;
    } else {
        self.jobState = YXQueueJobStateExecuting;
    }
    for (id<YXQueueJobDelegate> delegate in _delegateSet) {
        if ([delegate respondsToSelector:@selector(queueJob:operationFinished:)]) {
            [delegate queueJob:self operationFinished:operation];
        }
    }
}

-(void)queueOperation:(YXQueueOperation *)operation didFailureWithError:(NSError *)error
{
    [self setError:error];
    self.jobState = YXQueueJobStateFinishedFailed;
    for (id<YXQueueJobDelegate> delegate in _delegateSet) {
        if ([delegate respondsToSelector:@selector(queueJob:operationFailed:withError:)]) {
            [delegate queueJob:self operationFailed:operation withError:error];
        }
    }
}

- (void)queueOperationDidCancelled:(YXQueueOperation *)operation
{
    if ([self.class operationClass] == operation.class) {
        self.jobState = YXQueueJobStateCanceled;
    }
    for (id<YXQueueJobDelegate> delegate in _delegateSet) {
        if ([delegate respondsToSelector:@selector(queueJob:operationDidCanceled:)]) {
            [delegate queueJob:self operationDidCanceled:operation];
        }
    }
}

- (void)queueOperation:(YXQueueOperation *)operation didUpdateProgress:(float)progress
{
    NSLog(@"job download progress:%f",progress);
    for (id<YXQueueJobDelegate> delegate in _delegateSet) {
        if ([delegate respondsToSelector:@selector(queueJob:operationDidUpdateProgress:)]) {
            [delegate queueJob:self operationDidUpdateProgress:progress];
        }
    }
}

-(void)setJobState:(YXQueueJobState)jobState
{
    if (jobState == YXQueueJobStateCanceled && (self.jobState == YXQueueJobStateFinishedSuccess || self.jobState == YXQueueJobStateFinishedFailed)) {
        return;
    }
    
    if (jobState != self.jobState || jobState == YXQueueJobStateExecuting) {
        _jobState = jobState;
    }
}

- (void)addDelegate:(id<YXQueueJobDelegate>)delegate
{
    @synchronized (self.delegateSet) {
        if (![self.delegateSet containsObject:delegate]) {
            [self.delegateSet addObject:delegate];
        }
    }
}

- (void)removeDelegate:(id<YXQueueJobDelegate>)delegate
{
    @synchronized (self.delegateSet) {
        if (delegate) {
            [self.delegateSet removeObject:delegate];
        }
    }
}

- (NSString *)errorDomain
{
    return [self valueOfProperty:@"errDomain"];
}

- (void)setErrorDomain:(NSString*)errorDomain
{
    [self addProperty:@"errorDomain" withValue:errorDomain];
}

- (NSError *)error
{
    if (self.errorCode == 0 || !self.errorMessage) return nil;
    
    NSString *errorDomain = [self errorDomain];
    if (!errorDomain)
    {
        errorDomain = @"YXQueueJobErrorDomain";
    }
    
    return [NSError errorWithDomain:errorDomain
                               code:self.errorCode
                           userInfo:@{NSLocalizedDescriptionKey:self.errorMessage}];
}

- (void)setError:(NSError *)error
{
    self.errorCode = error.code;
    self.errorMessage = error.localizedDescription;
    self.errorDomain = error.domain;
}

- (NSString *)jobTypeString
{
    return nil;
}

@end
