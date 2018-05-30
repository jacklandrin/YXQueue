//
//  ImageTableViewCell.m
//  YXQueueDemo
//
//  Created by jack on 2018/5/24.
//  Copyright © 2018年 JackLiu. All rights reserved.
//

#import "ImageTableViewCell.h"

@implementation ImageTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.fileNameLabel = [[UILabel alloc] init];
        [self addSubview:self.fileNameLabel];
        
        self.progressLabel = [[UILabel alloc] init];
        [self addSubview:self.progressLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.fileNameLabel.frame = CGRectMake(0, 0, 200, 44);
    self.progressLabel.frame = CGRectMake(self.frame.size.width - 80, 0, 70, 44);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
