//
//  SSTURLCache.m
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import "SSTURLCache.h"

////////////  SSTCachedResponseObject ////////////

#pragma mark -
#pragma mark - Implementation of SSTCachedResponseObject

@implementation SSTCachedResponseObject

- (instancetype) initWithResponse:(id) response
{
	self = [super init];
	if (self) {
		_responseObject = response;
	}
	return self;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
	self = [self init];
	if (self) {
		self.responseObject = [aDecoder decodeObjectForKey:@"originalResponseObject"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.responseObject forKey:@"originalResponseObject"];
}

- (id) copyWithZone:(NSZone *)zone
{
	SSTCachedResponseObject *copy = [super init];
	copy.responseObject = _responseObject;
	return copy;
}

@end

////////////  SSTCachedDataTask ////////////

#pragma mark -
#pragma mark - Implementation of SSTCachedDataTask

@interface SSTCachedDataTask()

@property (readwrite) NSUInteger taskIdentifier;
@property (readwrite, copy) NSURLRequest *originalRequest;
@property (readwrite, copy) NSURLRequest *currentRequest;
@property (readwrite, copy) NSURLResponse *response;
@property (readwrite) NSURLSessionTaskState state;
@property (readwrite, copy) NSError *error;

@end

@implementation SSTCachedDataTask

@synthesize taskIdentifier = _taskIdentifier, originalRequest = _originalRequest, currentRequest = _currentRequest, response = _response, state = _state, error = _error;

- (instancetype) initWithTask:(NSURLSessionDataTask *) task
{
	self = [super init];
	if (self) {
		_taskIdentifier = task.taskIdentifier;
		_originalRequest = task.originalRequest;
		_currentRequest = task.currentRequest;
		_response = task.response;
		_state = task.state;
		_error = task.error;
	}
	return self;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	self.taskIdentifier = [aDecoder decodeIntegerForKey:@"SSTTaskIdentifier"];
	self.originalRequest = [aDecoder decodeObjectForKey:@"SSTOriginalRequest"];
	self.currentRequest = [aDecoder decodeObjectForKey:@"SSTCurrentRequest"];
	self.response = [aDecoder decodeObjectForKey:@"SSTResponse"];
	self.state = [aDecoder decodeIntegerForKey:@"SSTState"];
	self.error = [aDecoder decodeObjectForKey:@"SSTError"];
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeInteger:_taskIdentifier forKey:@"SSTTaskIdentifier"];
	[aCoder encodeObject:_originalRequest forKey:@"SSTOriginalRequest"];
	[aCoder encodeObject:_currentRequest forKey:@"SSTCurrentRequest"];
	[aCoder encodeObject:_response forKey:@"SSTResponse"];
	[aCoder encodeInteger:_state forKey:@"SSTState"];
	[aCoder encodeObject:_error forKey:@"SSTError"];
}

@end

////////////  SSTCachedResponse ////////////

#pragma mark -
#pragma mark - Implementation of SSTCachedResponse

@implementation SSTCachedResponse

- (instancetype) initWithTask:(NSURLSessionDataTask *) task andresponse:(id) response
{
	self = [super init];
	if (self) {
		_task = [[SSTCachedDataTask alloc] initWithTask:task];
		_responseObject = [[SSTCachedResponseObject alloc] initWithResponse:response];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.task forKey:@"dataTask"];
	[aCoder encodeObject:self.responseObject forKey:@"responseObject"];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [self init];
	if (self) {
		self.task = [aDecoder decodeObjectForKey:@"dataTask"];
		self.responseObject = [aDecoder decodeObjectForKey:@"responseObject"];
	}
	return self;
}

- (id) copyWithZone:(NSZone *)zone
{
	SSTCachedResponse *copy = [[SSTCachedResponse alloc] init];
	copy.task = _task;
	copy.responseObject = _responseObject;
	return copy;
}

@end

	///////////////////////////////////////////// SSTURLCache ////////////////////////////////////////////////////////

#pragma mark -
#pragma mark - Implementation of SSTURLCache

@interface SSTURLCache()

@property (nonatomic, strong) NSOperationQueue *cacheOperationQueue;
@property  (nonatomic, strong) NSString *cacheRootPath;

@end

@implementation SSTURLCache

#pragma mark -
#pragma mark - Init

- (instancetype) initWithPath:(NSString *)path
{
	self = [super init];
	if (self) {
		_cacheRootPath = path;
		
		/**
		 *  Lets create a directory at our cache path
		 */
		NSError *error;
		[[NSFileManager defaultManager] createDirectoryAtPath:_cacheRootPath withIntermediateDirectories:YES attributes:nil error:&error];
		if (error) {
			NSLog(@"Failed to create Cache Directory :  %@",error);
		}
		else {
			NSLog(@"Created Caches Directory At : %@", _cacheRootPath);
		}
		
		_cacheOperationQueue = [[NSOperationQueue alloc] init];
		
	}
	return self;
}

- (void) cacheResponse:(id)response forDataTask:(NSURLSessionDataTask *)dataTask
{
	if (!dataTask || !response) {
		NSLog(@"Nothing to cache : %@ ::: for Request %@",response, dataTask);
		return;
	}
	
	__weak typeof(self) blockSelf = self;
	NSBlockOperation *storeOperation = [NSBlockOperation blockOperationWithBlock:^{
		
		SSTCachedResponse *cachedresponse = [[SSTCachedResponse alloc] initWithTask:dataTask andresponse:response];
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *cachePath = [blockSelf cachePathForURLString:dataTask.originalRequest.URL.absoluteString];
		
		NSError *error;
		BOOL isDir = NO;
		if ([fileManager fileExistsAtPath:cachePath isDirectory:&isDir]) {
			[fileManager removeItemAtPath:cachePath error:&error];
			
			if (error) {
				NSLog(@"Failed to delete Old cache file :  %@", error);
			}
		}
		
		[NSKeyedArchiver archiveRootObject:cachedresponse toFile:cachePath];
	}];
	
	[_cacheOperationQueue addOperation:storeOperation];
}

- (void) cachedResponseForURLString:(NSString *)urlStr completion:(void (^)(SSTCachedResponse *))completionHandler
{
	__block SSTCachedResponse *cachedResponse = nil;
	
	__weak typeof(self) blockSelf = self;
	
	void (^CacheOpertionBlock)() = ^(void){
		NSString *cachePath = [blockSelf cachePathForURLString:urlStr];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		if ([fileManager fileExistsAtPath:cachePath]) {
			cachedResponse = [NSKeyedUnarchiver unarchiveObjectWithFile:cachePath];
		}
	};
	
	NSBlockOperation *cacheOperation = [NSBlockOperation blockOperationWithBlock:CacheOpertionBlock];
	
	[cacheOperation setCompletionBlock:^{
		if (completionHandler) {
			completionHandler(cachedResponse);
		}
	}];
	
	[_cacheOperationQueue addOperation:cacheOperation];
}

- (void) removeAllCachedResponses
{
	NSError *error;
	[[NSFileManager defaultManager] removeItemAtPath:_cacheRootPath error:&error];
	
	/**
	 *  Lets reCreate the Cache Folder.
	 */
	[[NSFileManager defaultManager] createDirectoryAtPath:_cacheRootPath withIntermediateDirectories:YES attributes:nil error:&error];
	
	if (error) {
		NSLog(@"failed To Remove All Cache : %@",error);
	}
}

- (NSString *) cachePathForURLString:(NSString *) urlStr
{
	NSMutableString *fileName = [NSMutableString string];
	
	NSArray *components = [[NSURL URLWithString:urlStr] pathComponents];
	[components enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
		if (![obj isEqualToString:@"/"]) {
			[fileName appendFormat:@"_%@",obj];
		}
	}];
	
	return [[_cacheRootPath stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"cache"];
}

@end
