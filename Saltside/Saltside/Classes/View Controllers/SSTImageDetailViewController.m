//
//  SSTImageDetailViewController.m
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import "SSTImageDetailViewController.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface SSTImageDetailViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *contentLabel;

- (IBAction)close:(id)sender;

@end

@implementation SSTImageDetailViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
		// Control values
	if (_selectedImage.image.length > 0) {
		[_imageView setImageWithURL:[NSURL URLWithString:_selectedImage.image] placeholderImage:[UIImage imageNamed:@"sst_placeholder"]];
	}
	_contentLabel.attributedText = _selectedImage.attributedContentString;
}

#pragma mark -
#pragma mark - Action Methods

- (IBAction)close:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark - Dealloc

- (void)dealloc
{
	[_imageView cancelImageRequestOperation];
	_imageView.image = nil;
}

@end
