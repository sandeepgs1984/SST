//
//  SSTAPIService+Images.m
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import "SSTAPIService+Images.h"

@implementation SSTAPIService (Images)

- (void) fetchImagesFeed:(SSTServiceCompletionBlock) completionBlock withTaskCompletion:(void(^)(NSURLSessionDataTask *)) taskCompletionBlock
{
	NSString *path = @"https://gist.githubusercontent.com/maclir/f715d78b49c3b4b3b77f/raw/8854ab2fe4cbe2a5919cea97d71b714ae5a4838d/items.json";
	
	[self dataTaskWithPath:path prarmeters:nil requestType:kSSTGETRequestType modelClass:[SSTImagesFeed class] completion:completionBlock taskEnqueCompletion:^(NSURLSessionDataTask *task) {
		
		if (taskCompletionBlock) {
			taskCompletionBlock (task);
		}
	}];
}

@end
