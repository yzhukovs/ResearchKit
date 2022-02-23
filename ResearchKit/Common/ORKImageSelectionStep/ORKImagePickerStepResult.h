//
//  File.swift
//  Living Legacy Prototype
//
//  Created by Yvette Zhukovsky on 2/23/22.


#import <ResearchKit/ResearchKit.h>
#import <Photos/Photos.h>


NS_ASSUME_NONNULL_BEGIN

ORK_CLASS_AVAILABLE

@interface ORKImagePickerStepResult : ORKStepResult

@property (nonatomic, strong) NSArray<PHAsset *> *assets;

@end

NS_ASSUME_NONNULL_END
