//
//  ORKImagePickerStep.m
//  BitmarkDataDonation
//
//  Created by Anh Nguyen on 9/12/17.
//  Copyright © 2017 Bitmark. All rights reserved.
//

#import "ORKImagePickerStep.h"
#import "ORKImagePickerStepViewController.h"

@implementation ORKImagePickerStep

+ (Class)stepViewControllerClass {
  return [ORKImagePickerStepViewController class];
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
  self = [super initWithIdentifier:identifier];
  if (self) {
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
//    ORK_DECODE_IMAGE(aDecoder, templateImage);
//    ORK_DECODE_UIEDGEINSETS(aDecoder, templateImageInsets);
//    ORK_DECODE_OBJ(aDecoder, accessibilityHint);
//    ORK_DECODE_OBJ(aDecoder, accessibilityInstructions);
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
//  ORK_ENCODE_IMAGE(aCoder, templateImage);
//  ORK_ENCODE_UIEDGEINSETS(aCoder, templateImageInsets);
//  ORK_ENCODE_OBJ(aCoder, accessibilityHint);
//  ORK_ENCODE_OBJ(aCoder, accessibilityInstructions);
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

//- (instancetype)copyWithZone:(NSZone *)zone {
//  ORKImageCaptureStep *step = [super copyWithZone:zone];
//  step.templateImage = self.templateImage;
//  step.templateImageInsets = self.templateImageInsets;
//  step.accessibilityHint = self.accessibilityHint;
//  step.accessibilityInstructions = self.accessibilityInstructions;
//  return step;
//}

//- (BOOL)isEqual:(id)object {
//  BOOL isParentSame = [super isEqual:object];
//  
//  __typeof(self) castObject = object;
//  return isParentSame && ORKEqualObjects(self.templateImage, castObject.templateImage)
//  && UIEdgeInsetsEqualToEdgeInsets(self.templateImageInsets, castObject.templateImageInsets)
//  && ORKEqualObjects(self.accessibilityHint, castObject.accessibilityHint)
//  && ORKEqualObjects(self.accessibilityInstructions, castObject.accessibilityInstructions);
//}

@end
