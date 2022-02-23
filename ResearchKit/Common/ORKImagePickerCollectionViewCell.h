//
//  ORKImagePickerCollectionViewCell.h
//  BitmarkDataDonation
//
//  Created by Anh Nguyen on 9/22/17.
//  Copyright © 2017 Bitmark. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PHAsset;

@interface ORKImagePickerCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) PHAsset *asset;

@end
