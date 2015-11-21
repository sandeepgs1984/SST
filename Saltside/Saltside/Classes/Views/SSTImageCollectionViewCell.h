//
//  SSTImageCollectionViewCell.h
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SSTImage;

@interface SSTImageCollectionViewCell : UICollectionViewCell

+ (UINib *) nib;
+ (SSTImageCollectionViewCell *) loadFromNib;

#pragma mark -
#pragma mark - Instance Methods

- (void) configureCellData:(SSTImage *) image;

@end