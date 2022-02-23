//
//  ORKImagePickerStepViewController.m
//  BitmarkDataDonation
//
//  Created by Anh Nguyen on 9/12/17.
//  Copyright © 2017 Bitmark. All rights reserved.
//

#import "ORKImagePickerStepViewController.h"
#import "ORKImagePickerStep.h"
#import "ORKImagePickerStepResult.h"
#import "GMImagePickerController.h"
#import "GMGridViewCell.h"

#import "ORKStepViewController_Internal.h"

#import "ORKStepViewController_Internal.h"
#import "ORKTaskViewController_Internal.h"

#import "ORKCollectionResult.h"
#import "ORKReviewStep_Internal.h"

#import "ORKNavigationContainerView.h"

#import "ORKHelpers_Internal.h"
#import "ORKStepContentView.h"

static NSString *const kGMGridViewCellIdentifier = @"GMGridViewCellIdentifier";
static CGSize const kAssetGridThumbnailSize = {100, 100};

@interface ORKImagePickerStepViewController () <GMImagePickerControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UIButton *skipQuestionButton;
@property (weak, nonatomic) IBOutlet UIButton *chooseImageButton;
@property (weak, nonatomic) IBOutlet UIView *continueView;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) PHCachingImageManager *imageManager;

@property (nonatomic, strong) GMImagePickerController *imagePickerController;
@property (nonatomic, strong) NSArray<PHAsset *> *assets;

@end

@implementation ORKImagePickerStepViewController

- (instancetype)initWithStep:(ORKStep *)step result:(ORKResult *)result {
  self = [self initWithStep:step];
  if (self) {
    ORKStepResult *stepResult = (ORKStepResult *)result;
    if (stepResult && [stepResult results].count > 0) {
      
      ORKImagePickerStepResult *results =(ORKImagePickerStepResult *)[stepResult results].firstObject;
      
      if (results.assets) {
        self.assets = results.assets;
      }
    }
    
    [self updateUI];
  }
  return self;
}

//- (instancetype)initWithStep:(ORKStep *)step {
//  self = [super initWithNibName:@"ORKImagePickerStepViewController" bundle:nil];
//  if (self) {
//    NSParameterAssert([step isKindOfClass:[ORKImagePickerStep class]]);
//    [self setStep:step];
//  }
//  return self;
//}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self.collectionView registerClass:GMGridViewCell.class
          forCellWithReuseIdentifier:kGMGridViewCellIdentifier];
  
  [self setupUIWithStep:(ORKImagePickerStep *)self.step];
}

- (void)setupUIWithStep:(ORKImagePickerStep *)step {
  self.titleLabel.text = step.title;
  self.textLabel.text = step.text;
  self.skipQuestionButton.hidden = !step.isOptional;
  
  self.nextButton.layer.borderWidth = 1.0f;
  self.nextButton.layer.cornerRadius = 5.0f;
  
  [self updateUI];
}

- (IBAction)selectImageClicked:(id)sender {
  [self presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (void)assetsPickerController:(GMImagePickerController *)picker didFinishPickingAssets:(NSArray *)assetArray
{
  [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
  
  self.assets = assetArray;
  [self updateUI];
}

- (BOOL)assetsPickerController:(GMImagePickerController *)picker shouldSelectAsset:(PHAsset *)asset {
  return picker.selectedAssets.count < 10;
}

- (IBAction)nextButtonClicked:(id)sender {
  [self goForward];
}

- (IBAction)skipButtonClicked:(id)sender {
  [self goForward];
}

- (ORKStepResult *)result {
  ORKStepResult *stepResult = [super result];
  
  if (self.assets) {
    ORKImagePickerStepResult *result = [[ORKImagePickerStepResult alloc] initWithIdentifier:self.step.identifier];
    result.assets = self.assets;
    result.startDate = stepResult.startDate;
    result.endDate = stepResult.endDate;
    stepResult.results = @[result];
  }
  
  return stepResult;
}

#pragma mark - Private methods

- (GMImagePickerController *)imagePickerController {
  if (!_imagePickerController) {
    _imagePickerController = [[GMImagePickerController alloc] init];
    _imagePickerController.delegate = self;
    _imagePickerController.title = @"Select images";
    _imagePickerController.mediaTypes = @[@(PHAssetMediaTypeImage)];
    _imagePickerController.showCameraButton = YES;
    _imagePickerController.autoSelectCameraImages = NO;
  }
  
  return _imagePickerController;
}

- (PHCachingImageManager *)imageManager {
  if (!_imageManager) {
    _imageManager = [PHCachingImageManager new];
  }
  
  return _imageManager;
}

- (void)updateUI {
  [self setNextButtonEnabled:(self.assets != nil)];
  [self.collectionView reloadData];
}

- (void)setNextButtonEnabled:(BOOL)enabled {
  self.nextButton.enabled = enabled;
  self.nextButton.layer.borderColor = self.nextButton.titleLabel.textColor.CGColor;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return self.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  GMGridViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kGMGridViewCellIdentifier forIndexPath:indexPath];
  
  if (cell != nil) {
    // Increment the cell's tag
    NSInteger currentTag = cell.tag + 1;
    cell.tag = currentTag;
    
    PHAsset *asset = self.assets[indexPath.item];
    [cell bind:asset];
    
    [self.imageManager requestImageForAsset:asset
                                 targetSize:kAssetGridThumbnailSize
                                contentMode:PHImageContentModeAspectFill
                                    options:nil
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                
                                // Only update the thumbnail if the cell tag hasn't changed. Otherwise, the cell has been re-used.
                                if (cell.tag == currentTag) {
                                  [cell.imageView setImage:result];
                                }
                              }];
    cell.shouldShowSelection = NO;
  }
  
  return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  return kAssetGridThumbnailSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
  return 10;
}

@end
