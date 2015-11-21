//
//  SSTImageCollectionViewCell.m
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import "SSTImageCollectionViewCell.h"
#import "SSTImage.h"

#import <AFNetworking/UIImageView+AFNetworking.h>

@interface SSTImageCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *contentLabel;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *imageWidth;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *imageHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *imageLeftSpace;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *imageLabelHorizontalSpace;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *topSpace;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *trailingSpace;

@end

@implementation SSTImageCollectionViewCell

+ (UINib *) nib
{
	return [UINib nibWithNibName:NSStringFromClass(self) bundle:[NSBundle mainBundle]];
}

+ (SSTImageCollectionViewCell *) loadFromNib
{
	return [[[self nib] instantiateWithOwner:self options:nil] firstObject];
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	_imageView.contentMode = UIViewContentModeScaleToFill;
	self.contentView.backgroundColor = [UIColor whiteColor];
}

- (CGSize)sizeThatFits:(CGSize)size
{
	CGSize fittingSize = CGSizeMake(size.width, 0);
	
	fittingSize.height = _topSpace.constant; // top padding
	
	CGSize constrainedSize = CGSizeMake(size.width - _imageLeftSpace.constant - _imageWidth.constant - _imageLabelHorizontalSpace.constant - _trailingSpace.constant, CGFLOAT_MAX);
	
	CGFloat titleHeight = [_contentLabel sizeThatFits:constrainedSize].height;
	fittingSize.height += titleHeight > _imageHeight.constant ? titleHeight : _imageHeight.constant;
	
	fittingSize.height += _topSpace.constant; // bottom padding
	
	return fittingSize;
}

#pragma mark -
#pragma mark - Instance Methods

- (void) configureCellData:(SSTImage *) image
{
	_imageView.image = [UIImage imageNamed:@"sst_placeholder"];
	if (image.image.length > 0) {
//		[_imageView setImageWithURL:[NSURL URLWithString:image.image] placeholderImage:nil];
	}
	
	_contentLabel.attributedText = image.attributedContentString;
}

#pragma mark -
#pragma mark - Dealloc

- (void)dealloc
{
	[_imageView cancelImageRequestOperation];
	[_imageView setImage:nil];
}

@end
