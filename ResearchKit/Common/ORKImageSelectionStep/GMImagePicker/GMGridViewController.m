//
//  File.swift
//  Living Legacy Prototype
//
//  Created by Yvette Zhukovsky on 2/23/22.

#import "GMGridViewController.h"
#import "GMImagePickerController.h"
#import "GMAlbumsViewController.h"
#import "GMGridViewCell.h"

@import Photos;


//Helper methods
@implementation NSIndexSet (Convenience)
- (NSArray *)aapl_indexPathsFromIndexesWithSection:(NSUInteger)section {
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
    }];
    return indexPaths;
}
@end

@implementation UICollectionView (Convenience)
- (NSArray *)aapl_indexPathsForElementsInRect:(CGRect)rect {
    NSArray *allLayoutAttributes = [self.collectionViewLayout layoutAttributesForElementsInRect:rect];
    if (allLayoutAttributes.count == 0) { return nil; }
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:allLayoutAttributes.count];
    for (UICollectionViewLayoutAttributes *layoutAttributes in allLayoutAttributes) {
        NSIndexPath *indexPath = layoutAttributes.indexPath;
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}
@end



@interface GMImagePickerController ()

- (void)finishPickingAssets:(id)sender;
- (void)dismiss:(id)sender;
- (NSString *)toolbarTitle;
- (UIView *)noAssetsView;

@end


@interface GMGridViewController () <PHPhotoLibraryChangeObserver>

@property (nonatomic, weak) GMImagePickerController *picker;
@property (strong) PHCachingImageManager *imageManager;
@property CGRect previousPreheatRect;

@end

static CGSize AssetGridThumbnailSize;
NSString * const GMGridViewCellIdentifier = @"GMGridViewCellIdentifier";

@implementation GMGridViewController

-(id)initWithPicker:(GMImagePickerController *)picker
{
    //Custom init. The picker contains custom information to create the FlowLayout
    self.picker = picker;

    UICollectionViewFlowLayout *layout = self.updatedCollectionViewFlowLayout;
    if (self = [super initWithCollectionViewLayout:layout])
    {
        //Compute the thumbnail pixel size:
        CGFloat scale = [UIScreen mainScreen].scale;
        //NSLog(@"This is @%fx scale device", scale);
        AssetGridThumbnailSize = CGSizeMake(layout.itemSize.width * scale, layout.itemSize.height * scale);

        self.collectionView.allowsMultipleSelection = picker.allowsMultipleSelection;

        [self.collectionView registerClass:GMGridViewCell.class
                forCellWithReuseIdentifier:GMGridViewCellIdentifier];

        self.preferredContentSize = kPopoverContentSize;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViews];

    // Navigation bar customization
    if (self.picker.customNavigationBarPrompt) {
        self.navigationItem.prompt = self.picker.customNavigationBarPrompt;
    }

    self.imageManager = [[PHCachingImageManager alloc] init];
    [self resetCachedAssets];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self setupButtons];
    [self setupToolbar];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateCachedAssets];
}

- (void)dealloc
{
    [self resetCachedAssets];
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.picker.pickerStatusBarStyle;
}


#pragma mark - Rotation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    dispatch_async(dispatch_get_main_queue(), ^{

        UICollectionViewFlowLayout *layout = self.updatedCollectionViewFlowLayout;

        //Update the AssetGridThumbnailSize:
        CGFloat scale = [UIScreen mainScreen].scale;
        AssetGridThumbnailSize = CGSizeMake(layout.itemSize.width * scale, layout.itemSize.height * scale);

        [self resetCachedAssets];
        //This is optional. Reload visible thumbnails:
        for (GMGridViewCell *cell in [self.collectionView visibleCells]) {
            NSInteger currentTag = cell.tag;
            [self.imageManager requestImageForAsset:cell.asset
                                         targetSize:AssetGridThumbnailSize
                                        contentMode:PHImageContentModeAspectFill
                                            options:nil
                                      resultHandler:^(UIImage *result, NSDictionary *info)
             {
                 // Only update the thumbnail if the cell tag hasn't changed. Otherwise, the cell has been re-used.
                 if (cell.tag == currentTag) {
                     [cell.imageView setImage:result];
                 }
             }];
        }

        [self.collectionView setCollectionViewLayout:layout animated:YES];
    });
}


#pragma mark - Setup

- (void)setupViews
{
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [self.picker pickerBackgroundColor];
}

- (void)setupButtons
{
    if (self.picker.allowsMultipleSelection) {
        NSString *doneTitle = self.picker.customDoneButtonTitle ? self.picker.customDoneButtonTitle : NSLocalizedStringFromTableInBundle(@"picker.navigation.done-button",  @"GMImagePicker", [NSBundle bundleForClass:GMImagePickerController.class], @"Done");
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:doneTitle
                                                                                  style:UIBarButtonItemStyleDone
                                                                                 target:self.picker
                                                                                 action:@selector(finishPickingAssets:)];
        self.navigationItem.rightBarButtonItem.tintColor = UIColor.systemBlueColor;
        self.navigationItem.rightBarButtonItem.enabled = (self.picker.autoDisableDoneButton ? self.picker.selectedAssets.count > 0 : YES);
    } else {
        NSString *cancelTitle = self.picker.customCancelButtonTitle ? self.picker.customCancelButtonTitle : NSLocalizedStringFromTableInBundle(@"picker.navigation.cancel-button",  @"GMImagePicker", [NSBundle bundleForClass:GMImagePickerController.class], @"Cancel");
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:cancelTitle
                                                                                  style:UIBarButtonItemStyleDone
                                                                                 target:self.picker
                                                                                 action:@selector(dismiss:)];
    }
    if (self.picker.useCustomFontForNavigationBar) {
        if (self.picker.useCustomFontForNavigationBar) {
            NSDictionary* barButtonItemAttributes = @{NSFontAttributeName: [UIFont fontWithName:self.picker.pickerFontName size:self.picker.pickerFontHeaderSize]};
            [self.navigationItem.rightBarButtonItem setTitleTextAttributes:barButtonItemAttributes forState:UIControlStateNormal];
            [self.navigationItem.rightBarButtonItem setTitleTextAttributes:barButtonItemAttributes forState:UIControlStateSelected];
        }
    }

}

- (void)setupToolbar
{
    self.toolbarItems = self.picker.toolbarItems;
}


#pragma mark - Collection View Layout

- (UICollectionViewFlowLayout *)updatedCollectionViewFlowLayout
{
    CGFloat totalWidth = self.picker.view.bounds.size.width;
    NSUInteger numberOfColumns = floor((totalWidth + self.picker.minimumInteritemSpacing) / (self.picker.minimumThumbnailWidth + self.picker.minimumInteritemSpacing));
    CGFloat itemWidth = (totalWidth - (numberOfColumns - 1)*self.picker.minimumInteritemSpacing) / (CGFloat)numberOfColumns;

    UICollectionViewFlowLayout* layout = UICollectionViewFlowLayout.new;
    layout.minimumInteritemSpacing = self.picker.minimumInteritemSpacing;
    layout.minimumLineSpacing = self.picker.minimumInteritemSpacing;
    layout.itemSize = CGSizeMake(itemWidth, itemWidth);
    return layout;
}


#pragma mark - Collection View Data Source

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    GMGridViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:GMGridViewCellIdentifier
                                                             forIndexPath:indexPath];

    // Increment the cell's tag
    NSInteger currentTag = cell.tag + 1;
    cell.tag = currentTag;

    PHAsset *asset = self.assetsFetchResults[indexPath.item];

    //NSLog(@"Image manager: Requesting FILL image for iPhone");
    [self.imageManager requestImageForAsset:asset
                                 targetSize:AssetGridThumbnailSize
                                contentMode:PHImageContentModeAspectFill
                                    options:nil
                              resultHandler:^(UIImage *result, NSDictionary *info) {

                                  // Only update the thumbnail if the cell tag hasn't changed. Otherwise, the cell has been re-used.
                                  if (cell.tag == currentTag) {
                                      [cell.imageView setImage:result];
                                  }
                              }];

    [cell bind:asset];

    cell.shouldShowSelection = self.picker.allowsMultipleSelection;

    // Optional protocol to determine if some kind of assets can't be selected (pej long videos, etc...)
    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:shouldEnableAsset:)]) {
        cell.enabled = [self.picker.delegate assetsPickerController:self.picker shouldEnableAsset:asset];
    } else {
        cell.enabled = YES;
    }

    // Setting `selected` property blocks further deselection. Have to call selectItemAtIndexPath too. ( ref: http://stackoverflow.com/a/17812116/1648333 )
    if ([self.picker.selectedAssets containsObject:asset]) {
        cell.selected = YES;
        // If we call it right away a different cell will get selected
        dispatch_async(dispatch_get_main_queue(), ^{
            [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        });
    } else {
        cell.selected = NO;
    }

    return cell;
}


#pragma mark - Collection View Delegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PHAsset *asset = self.assetsFetchResults[indexPath.item];

    GMGridViewCell *cell = (GMGridViewCell *)[collectionView cellForItemAtIndexPath:indexPath];

    if (!cell.isEnabled) {
        return NO;
    } else if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:shouldSelectAsset:)]) {
        return [self.picker.delegate assetsPickerController:self.picker shouldSelectAsset:asset];
    } else {
        return YES;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PHAsset *asset = self.assetsFetchResults[indexPath.item];

    [self.picker selectAsset:asset];

    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:didSelectAsset:)]) {
        [self.picker.delegate assetsPickerController:self.picker didSelectAsset:asset];
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PHAsset *asset = self.assetsFetchResults[indexPath.item];

    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:shouldDeselectAsset:)]) {
        return [self.picker.delegate assetsPickerController:self.picker shouldDeselectAsset:asset];
    } else {
        return YES;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PHAsset *asset = self.assetsFetchResults[indexPath.item];

    [self.picker deselectAsset:asset];

    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:didDeselectAsset:)]) {
        [self.picker.delegate assetsPickerController:self.picker didDeselectAsset:asset];
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    PHAsset *asset = self.assetsFetchResults[indexPath.item];

    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:shouldHighlightAsset:)]) {
        return [self.picker.delegate assetsPickerController:self.picker shouldHighlightAsset:asset];
    } else {
        return YES;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    PHAsset *asset = self.assetsFetchResults[indexPath.item];

    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:didHighlightAsset:)]) {
        [self.picker.delegate assetsPickerController:self.picker didHighlightAsset:asset];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    PHAsset *asset = self.assetsFetchResults[indexPath.item];

    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:didUnhighlightAsset:)]) {
        [self.picker.delegate assetsPickerController:self.picker didUnhighlightAsset:asset];
    }
}



#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = self.assetsFetchResults.count;
    return count;
}


#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    // Call might come on any background queue. Re-dispatch to the main queue to handle it.
    dispatch_async(dispatch_get_main_queue(), ^{

        // check if there are changes to the assets (insertions, deletions, updates)
        PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.assetsFetchResults];
        if (collectionChanges) {

            // get the new fetch result
            self.assetsFetchResults = [collectionChanges fetchResultAfterChanges];

            UICollectionView *collectionView = self.collectionView;

            if (![collectionChanges hasIncrementalChanges] || [collectionChanges hasMoves]) {
                // we need to reload all if the incremental diffs are not available
                [collectionView reloadData];

            } else {
                // if we have incremental diffs, tell the collection view to animate insertions and deletions
                [collectionView performBatchUpdates:^{
                    NSIndexSet *removedIndexes = [collectionChanges removedIndexes];
                    if ([removedIndexes count]) {
                        [collectionView deleteItemsAtIndexPaths:[removedIndexes aapl_indexPathsFromIndexesWithSection:0]];
                    }
                    NSIndexSet *insertedIndexes = [collectionChanges insertedIndexes];
                    if ([insertedIndexes count]) {
                        [collectionView insertItemsAtIndexPaths:[insertedIndexes aapl_indexPathsFromIndexesWithSection:0]];
                    }
                } completion:^(BOOL finished) {
                    if (finished) {
                        // Puting this after removes and inserts indexes fixes a crash of deleting and reloading at the same time.
                        // From docs: When updating your app’s interface, apply changes after removals and insertions and before moves.
                        NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
                        if ([changedIndexes count]) {
                            [collectionView reloadItemsAtIndexPaths:[changedIndexes aapl_indexPathsFromIndexesWithSection:0]];
                        }
                    }
                }];
            }

            [self resetCachedAssets];
        }
    });
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateCachedAssets];
}


#pragma mark - Asset Caching

- (void)resetCachedAssets
{
    [self.imageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets
{
    BOOL isViewVisible = [self isViewLoaded] && [[self view] window] != nil;
    if (!isViewVisible) { return; }

    // The preheat window is twice the height of the visible rect
    CGRect preheatRect = self.collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0f, -0.5f * CGRectGetHeight(preheatRect));

    // If scrolled by a "reasonable" amount...
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    if (delta > CGRectGetHeight(self.collectionView.bounds) / 3.0f) {

        // Compute the assets to start caching and to stop caching.
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];

        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self.collectionView aapl_indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        } addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [self.collectionView aapl_indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        }];

        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];

        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.synchronous = NO;
        options.networkAccessAllowed = YES;

        [self.imageManager startCachingImagesForAssets:assetsToStartCaching
                                            targetSize:AssetGridThumbnailSize
                                           contentMode:PHImageContentModeAspectFill
                                               options:options];
        [self.imageManager stopCachingImagesForAssets:assetsToStopCaching
                                           targetSize:AssetGridThumbnailSize
                                          contentMode:PHImageContentModeAspectFill
                                              options:options];

        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler
{
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths
{
    if (indexPaths.count == 0) { return nil; }

    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        PHAsset *asset = self.assetsFetchResults[indexPath.item];
        [assets addObject:asset];
    }
    return assets;
}


@end