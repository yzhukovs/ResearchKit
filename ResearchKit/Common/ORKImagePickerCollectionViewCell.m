//
//  ORKImagePickerCollectionViewCell.m
//  BitmarkDataDonation
//
//  Created by Anh Nguyen on 9/22/17.
//  Copyright © 2017 Bitmark. All rights reserved.
//

#import "ORKImagePickerCollectionViewCell.h"
#import <Photos/Photos.h>

@interface ORKImagePickerCollectionViewCell()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *videoIconImageView;

@end

@implementation ORKImagePickerCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  
  if (self) {
    _imageView = [[UIImageView alloc] initWithFrame:frame];
    _videoIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"GMVideoIcon.png"]];
    
    [self addSubview:_imageView];
    [self addSubview:_videoIconImageView];
  }
  
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  self.imageView.frame = self.bounds;
  self.videoIconImageView.frame = CGRectMake(self.frame.size.width - self.videoIconImageView.frame.size.width,
                                             self.frame.size.height - self.videoIconImageView.frame.size.height,
                                             self.videoIconImageView.frame.size.width,
                                             self.videoIconImageView.frame.size.height);
}

- (void)setAsset:(PHAsset *)asset {
  _asset = asset;
}

@end
