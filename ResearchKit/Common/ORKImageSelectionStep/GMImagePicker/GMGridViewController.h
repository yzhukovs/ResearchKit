//
//  File.swift
//  Living Legacy Prototype
//
//  Created by Yvette Zhukovsky on 2/23/22.


#import "GMImagePickerController.h"
@import UIKit;
@import Photos;


@interface GMGridViewController : UICollectionViewController

@property (strong) PHFetchResult *assetsFetchResults;

-(id)initWithPicker:(GMImagePickerController *)picker;
    
@end;
