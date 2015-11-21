//
//  SSTHomeViewController.m
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import "SSTHomeViewController.h"
#import "SSTImageCollectionViewCell.h"
#import "SSTCollectionViewFlowLayout.h"

#import "SSTImageDetailViewController.h"

#import "SSTAPIService+Images.h"
#import "SSTImagesFeed.h"

static CGFloat const kItemSpacing = 5.0;
static CGFloat const kSectionInsetiPad = 10.0;
static CGFloat const kSectionInsetiPhone = 5.0;

#define kSSTImageCellID @"SSTImageCellID"

@interface SSTHomeViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) SSTImagesFeed *imageFeed; // holds the response
@property (nonatomic, strong) NSURLSessionDataTask *imageTask; // used when cancelling task
@property (nonatomic, strong) NSMutableDictionary *itemHeightsDict;

	// Outlets
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) SSTImageCollectionViewCell *prototypeCell; // Used to calculate the cell height dynamically

@property (nonatomic) UIEdgeInsets sectionInset;

@end

@implementation SSTHomeViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		[self customInitialization];
	}
	return self;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		[self customInitialization];
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
		// Navigation Bar Title
	self.title = NSLocalizedString(@"Home", nil);
	
		// Configure collection view
	[self setupCollectionView];
	
		// API Request to fetch image list
	[self fetchImages];
	
	if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)]) {
		[self setAutomaticallyAdjustsScrollViewInsets:NO];
	}
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	
		// Clear any saved data
	[self clearCachedCellHeights];
}

- (void) viewWillLayoutSubviews
{
	[super viewWillLayoutSubviews];
	
		// This is used to readjust the items in the collectionview
	[_collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark -
#pragma mark - Instance Methods

- (void) customInitialization
{
	_prototypeCell = [SSTImageCollectionViewCell loadFromNib];
	CGFloat inset = [UIDevice isCurrentDevicePhone] ? kSectionInsetiPhone : kSectionInsetiPad;
	_sectionInset =  UIEdgeInsetsMake(inset, inset, inset, inset);
	_itemHeightsDict = [NSMutableDictionary new];
}

- (void) setupCollectionView
{
	_collectionView.dataSource = self;
	_collectionView.delegate = self;
	_collectionView.alwaysBounceVertical = YES;
	_collectionView.alwaysBounceHorizontal = NO;
	_collectionView.backgroundColor =  [UIColor colorWithRed:232/255.0 green:237/255.0 blue:239/255.0 alpha:1.0];
	
		// Register cell
	[_collectionView registerNib:[SSTImageCollectionViewCell nib] forCellWithReuseIdentifier:kSSTImageCellID];
	
		// Layout properties
	SSTCollectionViewFlowLayout *layout = [[SSTCollectionViewFlowLayout alloc] init];
	layout.itemSpacing = kItemSpacing;
	[_collectionView setCollectionViewLayout:layout];
}

- (void) fetchImages
{
	__weak typeof(self) blockSelf = self;
	SSTAPIService *service = [SSTAPIService sharedService];
	[service fetchImagesFeed:^(SSTImagesFeed *result, BOOL isCached, NSError *error) {
		
		if (result) {
			blockSelf.imageFeed = result;
			
			NSLog(@"images feed:%@", result);
			
				// Clear saved task when completed
			if (!isCached) {
				blockSelf.imageTask = nil;
			}
			
			[blockSelf.collectionView reloadData];
		}
		else {
			[SSTUtilities showAlertWithError:error];
		}
		
	} withTaskCompletion:^(NSURLSessionDataTask *task) {
		
		blockSelf.imageTask = task;
	}];
}

- (void) clearCachedCellHeights
{
	[_itemHeightsDict removeAllObjects];
}

#pragma mark -
#pragma mark - UICollectionView Datasource/Delegate methods

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return _imageFeed.images.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	SSTImageCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kSSTImageCellID forIndexPath:indexPath];
	
	SSTImage *image = _imageFeed.images[indexPath.item];
	[cell configureCellData:image];
	
	return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	[collectionView deselectItemAtIndexPath:indexPath animated:YES];
	
	SSTImageDetailViewController *detailsVC = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"ImageDetails"];
	detailsVC.selectedImage = _imageFeed.images[indexPath.item];
	[self presentViewController:detailsVC animated:YES completion:^{
		
	}];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(SSTCollectionViewFlowLayout *) layout insetForSectionAtIndex:(NSInteger)section
{
	return _sectionInset;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(SSTCollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	SSTImage *image = _imageFeed.images[indexPath.item];

	CGSize size;
	
	NSNumber *identifier = @(indexPath.item);
	NSMutableDictionary *heights = [_itemHeightsDict objectForKey:identifier];
	if (!heights) {
		heights = [NSMutableDictionary dictionary];
		[_itemHeightsDict setObject:heights forKey:identifier];
	}

	if ([UIDevice isCurrentDevicePhone]) {
		size.width = collectionView.frame.size.width - (_sectionInset.left + _sectionInset.right);
	}
	else {
		if (UIDeviceOrientationIsLandscape([UIDevice interfaceOrientation])) {
			/**
			 *  we will have 3 items in a row
			 */
			size.width = (collectionView.frame.size.width - (_sectionInset.left + _sectionInset.right + (2 * collectionViewLayout.itemSpacing)))/3;
		}
		else {
			/**
			 *  we will have 2 items in a row
			 */
			size.width = (collectionView.frame.size.width - (_sectionInset.left + _sectionInset.right + collectionViewLayout.itemSpacing))/2;
		}
	}
	
	NSNumber *height = [heights objectForKey:@(size.width)];
	
	if (!height) {
		[_prototypeCell configureCellData:image];
		size.height = [_prototypeCell sizeThatFits:CGSizeMake(size.width, CGFLOAT_MAX)].height;
		
		/**
		 *  Cache the height for later use
		 */
		[heights setObject:@(size.height) forKey:@(size.width)];
	}
	else {
		size.height = height.floatValue;
	}
	
	return size;
}

#pragma mark -
#pragma mark - Dealloc

- (void)dealloc
{
	
}

@end
