//
//  SSTHomeViewController.m
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import "SSTHomeViewController.h"

#import "SSTAPIService+Images.h"
#import "SSTImagesFeed.h"

#import "SSTUtilities.h"

@interface SSTHomeViewController ()

@property (nonatomic, strong) SSTImagesFeed *imageFeed; // holds the response
@property (nonatomic, strong) NSURLSessionDataTask *imageTask; // used when cancelling task

@end

@implementation SSTHomeViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
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
		}
		else {
			[SSTUtilities showAlertWithError:error];
		}
		
	} withTaskCompletion:^(NSURLSessionDataTask *task) {
		
		blockSelf.imageTask = task;
	}];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark - Instance Methods


#pragma mark -
#pragma mark - Dealloc

- (void)dealloc
{
	
}

@end
