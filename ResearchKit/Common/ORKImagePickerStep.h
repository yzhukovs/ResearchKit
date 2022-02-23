//
//  ORKImagePickerStep.h
//  BitmarkDataDonation
//
//  Created by Anh Nguyen on 9/12/17.
//  Copyright © 2017 Bitmark. All rights reserved.
//

@import Foundation;
#import <ResearchKit/ORKStep.h>

NS_ASSUME_NONNULL_BEGIN

ORK_CLASS_AVAILABLE

@interface ORKImagePickerStep : ORKStep

@property (nonatomic, strong) UIImage *buttonImage;
@property (nonatomic, strong) NSString *selectImageMessage;

@end

NS_ASSUME_NONNULL_END



