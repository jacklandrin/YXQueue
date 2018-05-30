//
//  ViewController.m
//  YXQueueDemo
//
//  Created by jack on 2018/5/23.
//  Copyright © 2018年 JackLiu. All rights reserved.
//

#import "ViewController.h"
#import <YXQueue.h>
#import "DownloadingTask.h"
#import "ImageTableViewCell.h"

@import AVKit;
@import AVFoundation;

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, DownloadingTaskDelegate>

@property (nonatomic, strong) UITableView *downloadListTableView;
@property (nonatomic, strong) UITextField *URLTextField;

@property (nonatomic, strong) NSMutableArray<DownloadingTask*> *dataSource;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataSource = [NSMutableArray array];
    
    UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [downloadButton setTitle:@"Download video" forState:UIControlStateNormal];
    [downloadButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [downloadButton addTarget:self action:@selector(downloadNewImage:) forControlEvents:UIControlEventTouchUpInside];
    downloadButton.frame = CGRectMake(20, 80, 140, 44);
    downloadButton.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:downloadButton];
    
    self.URLTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 130, self.view.bounds.size.width - 40, 44)];
    [self.view addSubview:self.URLTextField];
    self.URLTextField.text = @"http://220.194.236.202/11/g/d/q/h/gdqhwlgumokzehmrhckfiykhoncfyu/sh.yinyuetai.com/68A801629B233A099758504D63451867.mp4";
    self.URLTextField.backgroundColor = [UIColor magentaColor];
    
    self.downloadListTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 180, self.view.bounds.size.width, self.view.bounds.size.height - 180) style:UITableViewStyleGrouped];
    [self.view addSubview:self.downloadListTableView];
    self.downloadListTableView.delegate = self;
    self.downloadListTableView.dataSource = self;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
}

- (void)downloadNewImage:(id)sender
{
    YXQueueDownloadJob *job = [[YXQueueDownloadJob alloc] init];
    job.downloadUrl = self.URLTextField.text;
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"%@.mp4",[self currentTimeStr]];
    NSString *targetUrl = [NSString stringWithFormat:@"%@/%@",path,fileName];
    job.targePath = targetUrl;
    DownloadingTask *task = [[DownloadingTask alloc] init];
    task.fileNameStr = fileName;
    task.filePath = targetUrl;
    task.delegate = self;
    [job addDelegate:task];
    [self.dataSource addObject:task];
    [job doJob];
    [self.downloadListTableView reloadData];
}


- (NSString *)currentTimeStr{
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval time=[date timeIntervalSince1970]*1000;
    NSString *timeString = [NSString stringWithFormat:@"%.0f", time];
    return timeString;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *const cellIdentifier = @"cellIdentifier";
    ImageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[ImageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    DownloadingTask *task = self.dataSource[indexPath.row];
    cell.fileNameLabel.text = task.fileNameStr;
    if (task.downloadStatus == DownloadStatusDownloading) {
        cell.progressLabel.textColor = [UIColor grayColor];
        cell.progressLabel.text = [NSString stringWithFormat:@"%.2f%%",task.progress * 100];
    } else if (task.downloadStatus == DownloadStatusFailure) {
        cell.progressLabel.textColor = [UIColor redColor];
        cell.progressLabel.text = @"Failed";
    } else if (task.downloadStatus == DownloadStatusDone){
        cell.progressLabel.textColor = [UIColor grayColor];
        cell.progressLabel.text = @"Done";
    } else {
        cell.progressLabel.textColor = [UIColor grayColor];
        cell.progressLabel.text = @"waiting";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DownloadingTask *selectedTask = [self.dataSource objectAtIndex:indexPath.row];
    if (selectedTask.downloadStatus != DownloadStatusDone) {
        return;
    }
    NSString *videoPath = selectedTask.filePath;
    NSURL *url = [NSURL fileURLWithPath:videoPath];
    AVPlayer *player = [AVPlayer playerWithURL:url];
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
    playerViewController.player = player;
    [self presentViewController:playerViewController animated:YES completion:nil];
    [playerViewController.player play];
}

#pragma mark - DownloadingTaskDelegate
- (void)downloadingTaskDidChanged:(DownloadingTask *)task
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.downloadListTableView reloadData];
    });
}

@end
