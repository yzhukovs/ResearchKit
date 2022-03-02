//
//  File.swift
//  Living Legacy Prototype
//
//  Created by Yvette Zhukovsky on 2/23/22.


#import "ORKImagePickerStepViewController.h"
#import "ORKImagePickerStep.h"
#import "ORKImagePickerStepResult.h"
#import "GMImagePickerController.h"
#import "GMGridViewCell.h"
#import <ResearchKit/ORKStep.h>
@import UIKit;

static NSString *const kGMGridViewCellIdentifier = @"GMGridViewCellIdentifier";
static CGSize const kAssetGridThumbnailSize = {100, 100};

@interface ORKImagePickerStepViewController () <GMImagePickerControllerDelegate, UICollectionViewDataSource, UITextViewDelegate,  UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UIButton *skipQuestionButton;
@property (weak, nonatomic) IBOutlet UIButton *chooseImageButton;
@property (weak, nonatomic) IBOutlet UIView *continueView;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (nonatomic, strong) PHCachingImageManager *imageManager;

@property (nonatomic, strong) GMImagePickerController *imagePickerController;
@property (nonatomic, strong) NSArray<PHAsset *> *assets;

@end

@implementation ORKImagePickerStepViewController


- (instancetype)initWithStep:(ORKStep *)step result:(ORKResult *)result {
    self = [super initWithStepAndNib:step nib:@"ORKImagePickerStepViewController"];
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

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    return self;
}



- (instancetype)initWithStep:(ORKStep *)step {
    self = [super initWithStepAndNib:step nib:@"ORKImagePickerStepViewController"];
    //self = [super initWithNibName:@"ORKImagePickerStepViewController" bundle:nil];
    if (self) {
        NSParameterAssert([step isKindOfClass:[ORKImagePickerStep class]]);
        [self setStep:step];
    }
    return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
    [_textView setDelegate:self];
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

#define kOFFSET_FOR_KEYBOARD 80.0

-(void)keyboardWillShow {
    // Animate the current view out of the way
    if (self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
    else if (self.view.frame.origin.y < 0)
    {
        [self setViewMovedUp:NO];
    }
}

-(void)keyboardWillHide {
    if (self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
    else if (self.view.frame.origin.y < 0)
    {
        [self setViewMovedUp:NO];
    }
}

-(void)textFieldDidBeginEditing:(UITextView *)sender
{
    if ([sender isEqual:self])
    {
        //move the main view, so that the keyboard does not hide it.
        if  (self.view.frame.origin.y >= 0)
        {
            [self setViewMovedUp:YES];
        }
    }
}

//method to move the view up/down whenever the keyboard is shown/dismissed
-(void)setViewMovedUp:(BOOL)movedUp
{
    [UIView animateWithDuration:0.25 animations:^{

    CGRect rect = self.view.frame;
    if (movedUp)
    {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y -= kOFFSET_FOR_KEYBOARD;
        rect.size.height += kOFFSET_FOR_KEYBOARD;
    }
    else
    {
        // revert back to the normal state.
        rect.origin.y += kOFFSET_FOR_KEYBOARD;
        rect.size.height -= kOFFSET_FOR_KEYBOARD;
    }
    self.view.frame = rect;

    } completion:^(BOOL finished){
    }];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(keyboardWillShow)
                                             name:UIKeyboardWillShowNotification
                                           object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(keyboardWillHide)
                                             name:UIKeyboardWillHideNotification
                                           object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                             name:UIKeyboardWillShowNotification
                                           object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                             name:UIKeyboardWillHideNotification
                                           object:nil];
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {

    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }

    return YES;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  return kAssetGridThumbnailSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
  return 10;
}

@end
