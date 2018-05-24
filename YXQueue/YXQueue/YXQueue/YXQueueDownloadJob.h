//
//  YXQueueDownloadJob.h
//  YXQueue
//
//  Created by jack on 2017/6/14.
//  Copyright © 2017年 YIXIA. All rights reserved.
//

#import "YXQueueJob.h"

@interface YXQueueDownloadJob : YXQueueJob

@property (nonatomic, strong) NSString *downloadUrl;
@property (nonatomic, strong) NSString *targePath;

@end
