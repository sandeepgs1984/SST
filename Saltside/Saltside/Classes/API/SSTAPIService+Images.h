//
//  SSTAPIService+Images.h
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import "SSTAPIService.h"
#import "SSTImagesFeed.h"

@interface SSTAPIService (Images)

/**
 *  API method to fetch images and returns the task
 */
- (void) fetchImagesFeed:(SSTServiceCompletionBlock) completionBlock withTaskCompletion:(void(^)(NSURLSessionDataTask *)) taskCompletionBlock;

@end