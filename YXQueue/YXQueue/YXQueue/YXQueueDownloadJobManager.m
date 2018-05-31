//
//  YXQueueDownloadJobManager.m
//  YXQueue
//
//  Created by jack on 2017/6/14.
//  Copyright © 2017年 JackLiu. All rights reserved.
//

#import "YXQueueDownloadJobManager.h"
#import "YXQueueDownloadOperation.h"
#import "YXQueueDownloadJob.h"

@implementation YXQueueDownloadJobManager

-(void)reloadOperations
{
    [self.operations enumerateObjectsUsingBlock:^(YXQueueDownloadOperation* operation, NSUInteger idx, BOOL * _Nonnull stop) {

    }];
}

@end
