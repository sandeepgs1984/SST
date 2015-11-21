//
//  SSTURLCache.h
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SSTCachedResponse;

/**
 *  This class provides helper methods to store and retrieve the url responses to/from the cache for the specific url or task object
 *	Provides methods to clear cache for specific url
 */

#pragma mark -
#pragma mark - CBZURLCache

@interface SSTURLCache : NSObject

- (instancetype) initWithPath:(NSString *) path;
- (void) cacheResponse:(id) response forDataTask:(NSURLSessionDataTask *)dataTask;
- (void) cachedResponseForURLString:(NSString *) urlStr completion:(void (^)(SSTCachedResponse *responseObject))completionHandler;
- (void) removeAllCachedResponses;

@end

#pragma mark -
#pragma mark - SSTCachedResponseObject

@interface SSTCachedResponseObject : NSObject<NSCoding, NSCopying>

@property (nonatomic, strong) id responseObject;

@end

#pragma mark -
#pragma mark - SSTCachedDataTask

/**
 *  WARNING -- THIS IS A SUBCLASS OF NSURLSessionDataTask THAT IS USED SOLELY TO IMPLEMENT NSCoding PROTOCOL AND HENCE MAKING IT FEASIBLE TO CACHE AND WRITE TO A FILE. DO NOT USE THIS CLASS TO PERFORM ANY OPERATIONS. ONLY USE IT TO RETRIEVE THE INFORMATION.
 *
 *  Following Properties can be accessed (No other properties apart from these are saved when written to the file)
 *  taskIdentifier;
 *  originalRequest;
 *  currentRequest;
 *  response;
 *  state;
 *  error;
 *
 */
@interface SSTCachedDataTask : NSURLSessionDataTask <NSCoding>

@end

#pragma mark -
#pragma mark - SSTCachedResponse

@interface SSTCachedResponse : NSObject<NSCoding, NSCopying>

@property (nonatomic, strong) SSTCachedDataTask *task;
@property (nonatomic, strong) SSTCachedResponseObject *responseObject;

@end
