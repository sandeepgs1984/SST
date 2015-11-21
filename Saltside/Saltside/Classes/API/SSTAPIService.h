//
//  SSTAPIService.h
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import <AFNetworking/AFHTTPSessionManager.h>

/**
 *  @description Completion block which executes when task has been completed
 *	Returns with 3 values: 1. result - parsed response object of url response
						   2. isCahed - determines whether response is from the server/internal cache
						   3. error - contains error information when task has failed
 */
typedef void (^SSTServiceCompletionBlock)(id result, BOOL isCached, NSError *error);

/**
 *  Service related constants
 */
extern NSString *const kSSTServiceErrorDomain;
extern NSString *const kSSTGETRequestType;
extern NSString *const kSSTPOSTRequestType;

@interface SSTAPIService : AFHTTPSessionManager

/**
 *  Shared service for API requests
 */
+ (SSTAPIService *) sharedService;

#pragma mark -
#pragma mark - Instance Methods

/*
 @description Creates the new session task and returns for future use
 @param path - url path to fetch
 @param parameters - parameters for the request
 @param type - request type (GET/POST..)
 @param modelClass - class name indicates the response will converted to this class
 @param taskEnqueuCompletion - completion block which returns the task
 */
- (void) dataTaskWithPath:(NSString *) path
					 prarmeters:(NSDictionary *) parameters
					requestType:(NSString *) type
					 modelClass:(Class) modelClass
					 completion:(SSTServiceCompletionBlock) completion
			taskEnqueCompletion:(void(^)(NSURLSessionDataTask *)) taskEnqueuCompletion;

@end
