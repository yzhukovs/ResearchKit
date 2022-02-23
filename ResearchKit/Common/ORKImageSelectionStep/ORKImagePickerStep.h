//
//  File.swift
//  Living Legacy Prototype
//
//  Created by Yvette Zhukovsky on 2/23/22.


@import Foundation;
#import <UIKit/UIKit.h>
#import <ResearchKit/ORKStep.h>

NS_ASSUME_NONNULL_BEGIN

ORK_CLASS_AVAILABLE

@interface ORKImagePickerStep : ORKStep

@property (nonatomic, strong) UIImage *buttonImage;
@property (nonatomic, strong) NSString *selectImageMessage;

@end

NS_ASSUME_NONNULL_END



