//
//  ORKImagePickerStepResult.h
//  BitmarkDataDonation
//
//  Created by Anh Nguyen on 9/12/17.
//  Copyright © 2017 Bitmark. All rights reserved.
//

#import <ResearchKit/ResearchKit.h>
#import <Photos/Photos.h>

@interface ORKImagePickerStepResult : ORKStepResult

@property (nonatomic, strong) NSArray<PHAsset *> *assets;

@end
