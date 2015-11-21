//
//  SSTCollectionViewFlowLayout.h
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SSTCollectionViewFlowLayout : UICollectionViewFlowLayout

@property (nonatomic) CGFloat itemSpacing;

@end

@protocol SSTCollectionViewDelegateFlowLayout <UICollectionViewDelegate>

@optional
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(SSTCollectionViewFlowLayout *) layout insetForSectionAtIndex:(NSInteger)section;
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(SSTCollectionViewFlowLayout *) layout referenceHeightForHeaderInSection:(NSInteger)section;
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(SSTCollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

@end