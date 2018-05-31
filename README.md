# YXQueue

### An OOP and easily using job queue for iOS
YXQueue is encapsulate for NSOperation. Thread's manager and invoker are divided by YXQueue. Using it, developers won't focus too mach on thread management, just pay attention to how to create a job and implement delegate. 

## Architecture
- YXQueueDispatcher

	It's designed as dispatcher of all YXQueues. It maintains the **NSOperationQueue** for all jobs. 

- YXQueueJob

	You can understand job as a model for operations. Configration of operations is set here.

- YXQueueJobManager

	It manages operations producted by job. Cause dependencies of operation, maybe YXQueueJobManager needs to manage multioperation for one job.

- YXQueueOperation

	It inherits from NSOperation. You can implement your operation content in `- (void)executeTaskWithResultBlock:(void (^)(void))block`
	
- `<YXQueueJobDelegate>`

	It provides job's callback of finishing, starting, canceling and progress changing.



## Usage

### 1. Inheriting YXQueueEngine

YXQueue provides YXDownloadQueue to multithread download big file. It would be seen as a demo for thread's manager.

Firstly, implementing a subclass for **YXQueueJob**. Adding necessary properties of model, and configing job's type, appropriate class of YXQueueJobManager and YXQueueOperation. Such as **YXQueueDownloadJob**:

```
@interface YXQueueDownloadJob : YXQueueJob

@property (nonatomic, strong) NSString *downloadUrl;
@property (nonatomic, strong) NSString *targePath;

@end

```
config:

```
- (NSString *)jobTypeString
{
    return @"download";
}

+ (Class)managerClass
{
    return [YXQueueDownloadJobManager class];
}

+ (Class)operationClass
{
    return [YXQueueDownloadOperation class];
}
```

Subsenquence, create **YXQueueDownloadOperation** inheriting from **YXQueueOperation**. Config operationModel, resourceIdentifier(thread's name) and appropriate class of job. **YXQueueOperationModel** can rule the max concurrent thread count and operation type. Implement the method `- (void)executeTaskWithResultBlock:(void (^)(void))block`.

```
- (instancetype)initWithJob:(YXQueueJob *)queueJob
{
    NSAssert([queueJob isKindOfClass:[YXQueueDownloadJob class]], @"queueJob must be YXQueueDownloadJob");
    if (self = [super initWithJob:queueJob]) {
        self.resourceIdentifier = @"com.queue.download";
        self.queuePriority = NSOperationQueuePriorityLow;
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

- (YXQueueDownloadJob *)job
{
    return (YXQueueDownloadJob*)_job;
}

- (YXQueueOperationModel *)operationModel
{
    if (!_model) {
        _model = [[YXQueueOperationModel alloc] init];
        _model.operationTypeString = @"downloadOperation";
        _model.maxConcurrentOperationCount = 5;
    }
    return _model;
}

- (void)executeTaskWithResultBlock:(void (^)(void))block
{
    __weak typeof(self) weakSelf = self;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.job.downloadUrl] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:3600];
    NSURLSessionDownloadTask *downloadTask = [self downloadTaskWithRequest:request progress:^(NSProgress *downloadProgress) {
        weakSelf.progress = (float)downloadProgress.completedUnitCount / (float)downloadProgress.totalUnitCount;
        [weakSelf notifiProgressDidChange];
    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        return [NSURL fileURLWithPath:weakSelf.job.targePath];
    } success:^(NSURLResponse *response, NSURL *fileURL) {
        self.operationReslut = response;
        if (block) {
            block();
        }
    } failure:^(NSURLResponse *response, NSError *error) {
        weakSelf.operationError = error;
        if (block) {
            block();
        }
    }];
    downloadTask.priority = NSOperationQueuePriorityLow;
}
```

Finally, you can inherit a subclass **YXQueueDownJobManager** from **YXQueueJobManager**, though there isn't any difference with superclass.

### 2. Creating a Job 

You can create a job like this:

```
YXQueueDownloadJob *job = [[YXQueueDownloadJob alloc] init];
job.downloadUrl = @"https://www.exmaple.mp4";
job.targePath = targetUrl;
[job addDelegate:self];

//command the job to start.
[job doJob];

//command a non-current job to cancel.
[job doCancel];

```

and you can register these delegate methods to recieve change of job's status:

```
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

```

## Demo

YXQueueDemo is a mp4 downloader as a YXQueue's demo provided for you. You can modify the mp4 URL to download different video, and the default max concorrent download count is **5**, it's set in **YXQueueDownloadOperation**'s method **operationModel**.

![](http://www.jacklandrin.com/wp-content/uploads/2018/05/download-demo.png)

## License

MIT License