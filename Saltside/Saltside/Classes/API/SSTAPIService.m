//
//  SSTAPIService.m
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import "SSTAPIService.h"
#import "SSTUtilities.h"
#import "SSTURLCache.h"
#import "SSTModel.h"

NSString *const kSSTServiceErrorDomain = @"SSTServiceErrorDomain";
NSString *const kSSTGETRequestType = @"GET";
NSString *const kSSTPOSTRequestType = @"POST";

/**
 *  Internal task completion blocks to handle response from the server for the url
 */
typedef void (^SSTServiceSessionSuccessBlock) (NSURLSessionDataTask *task, id responseObject);
typedef void (^SSTServiceSessionFailureBlock) (NSURLSessionDataTask *task, NSError *error);

@interface SSTAPIService ()

@property (nonatomic, strong) SSTURLCache *urlCache; // Object used to create cache and retrieve for tasks
@property (nonatomic, strong) NSMutableDictionary *taskIdsToCompletionBlocks; // Holds completion blocks for different tasks, used to get completion block whenever task has finished requesting
@property (nonatomic, strong) NSOperationQueue *dataProcessingQueue; // Queue which is used to schedule different tasks

- (NSError *)parsingErrorForPath:(NSString *)path;
- (BOOL) takeCareIfDuplicateCall:(NSString *) path withItsCompletionBlock:(SSTServiceCompletionBlock) completion;
- (void) clearOutSavedUpCompletionBlocksForTask:(NSURLSessionDataTask *) task result:(id) result isCached:(BOOL) isCached error:(NSError *) error;

@end

@implementation SSTAPIService (BlockConversion)

- (SSTServiceSessionSuccessBlock) sessionSuccessCompletionBlockFromServiceBlock:(SSTServiceCompletionBlock)block modelClass:(__unsafe_unretained Class)modelClass
{
	__weak typeof(self) blockSelf = self;
	SSTServiceSessionSuccessBlock successCompletionBlock = ^(NSURLSessionDataTask *completedTask, id responseObject) {
		
		id actualResponse = responseObject;
		
		BOOL isCached = NO;
		if ([responseObject isKindOfClass:[SSTCachedResponseObject class]]) {
			isCached = YES;
			actualResponse = [responseObject responseObject];
		}
		
		__block id result = nil;
		__block NSError *error = nil;
		
		NSBlockOperation *responseProcessingOP = [NSBlockOperation blockOperationWithBlock:^{
			
			/**
			 *  Handover the response to the respective model class to parse and assign values
			 *	NOTE ::: Write and implement parser methods for different type of response
			 *           Currently, implemented the method to parse JSON response (array) as per the API provided,
						 Write different methods in future if the response type differs
			 */
			if (Nil != modelClass && [actualResponse isKindOfClass:[NSArray class]]) {
				result = [modelClass modelObjectWithArray:actualResponse];
			}
			else if (Nil != modelClass && [actualResponse isKindOfClass:[NSDictionary class]]) {
				result = [modelClass modelObjectWithDictionary:actualResponse];
			}
			else {
				result = actualResponse;
			}
			
				// If request is not successful and there is no response, create an error for the request
			NSHTTPURLResponse *completedResponse = (NSHTTPURLResponse *)completedTask.response;
			if (!actualResponse && (completedResponse.statusCode != 200)) {
				error = [blockSelf parsingErrorForPath:completedTask.originalRequest.URL.absoluteString];
			}
		}];
		
		[responseProcessingOP setCompletionBlock:^{
			
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				if (block) {
					block(result,isCached,error);
				}
				
				[blockSelf clearOutSavedUpCompletionBlocksForTask:completedTask result:result isCached:isCached error:error];
			}];
		}];
		
		[blockSelf.dataProcessingQueue addOperation:responseProcessingOP];
	};
	
	return successCompletionBlock;
}

- (SSTServiceSessionFailureBlock) sessionFailureBlockFromServiceBlock:(SSTServiceCompletionBlock)block modelClass:(__unsafe_unretained Class)modelClass
{
	__weak typeof(self) blockSelf = self;
	SSTServiceSessionFailureBlock failureBlock = ^(NSURLSessionDataTask *completedTask, NSError *error) {
		NSLog(@"Network Error :  %@",error);
		
		/**
		 *  Check for task cancellation error
		 */
		if (error.code != NSURLErrorCancelled) {
			if (block) {
				block(nil, NO, error);
			}
		}
		
		[blockSelf clearOutSavedUpCompletionBlocksForTask:completedTask result:nil isCached:NO error:error];
	};
	
	return failureBlock;
}

@end

@implementation SSTAPIService

+ (SSTAPIService *) sharedService
{
	static SSTAPIService *sharedInstance = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[SSTAPIService alloc] initWithSessionConfiguration:[self sessionConfigurations]];
	});
	
	return sharedInstance;
}

+ (NSURLSessionConfiguration *) sessionConfigurations
{
	NSURLCache *afNetworkingCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:[SSTUtilities cacheDirectoryPathWithName:@"AFNetworkinCache"]];
	
	NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
	config.URLCache = afNetworkingCache;
	config.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
	return config;
}

- (id) initWithSessionConfiguration:(NSURLSessionConfiguration *) configuration
{
	self = [super initWithSessionConfiguration:configuration];
	
	if (self) {
		
			// Customize the response serializer (currently the response if JSON)
		self.responseSerializer = [AFJSONResponseSerializer serializer];
		
			// Content type configuration
		self.responseSerializer.acceptableContentTypes = [self.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
		
			// Customize the request serializer
		self.requestSerializer = [AFHTTPRequestSerializer serializer];
		
			// Create cache path
		SSTURLCache *apiCache = [[SSTURLCache alloc] initWithPath:[SSTUtilities cacheDirectoryPathWithName:@"SSTAPICache"]];
		[self setUrlCache:apiCache];
		
		_dataProcessingQueue = [[NSOperationQueue alloc] init];
		_taskIdsToCompletionBlocks = [NSMutableDictionary dictionary];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	}
	
	return self;
}

#pragma mark -
#pragma mark - Instance Methods

- (void) dataTaskWithPath:(NSString *) path
					 prarmeters:(NSDictionary *) parameters
					requestType:(NSString *) type
					 modelClass:(Class) modelClass
					 completion:(SSTServiceCompletionBlock) completion
			taskEnqueCompletion:(void(^)(NSURLSessionDataTask *)) taskEnqueuCompletion
{
	SSTServiceSessionSuccessBlock successBlock = [self sessionSuccessCompletionBlockFromServiceBlock:completion modelClass:modelClass];
	
	SSTServiceSessionFailureBlock failureBlock = [self sessionFailureBlockFromServiceBlock:completion modelClass:modelClass];
	
	BOOL isDuplicate = [self takeCareIfDuplicateCall:path withItsCompletionBlock:completion];
	
	if (!isDuplicate) {
		
		NSURL *url = [NSURL URLWithString:path];
		
		if (!url || (path.length == 0)) {
			
			NSLog(@"URL is Nil for Path : %@",path);
			if (taskEnqueuCompletion) {
				taskEnqueuCompletion(nil);
			}
		}
		
		NSURLSessionDataTask *task = nil;
		
		if ([type isEqualToString:kSSTGETRequestType]) {
			task = [self GET:path parameters:parameters success:successBlock failure:failureBlock];
		}
		else if ([type isEqualToString:kSSTPOSTRequestType]) {
			task = [self POST:path parameters:parameters success:successBlock failure:failureBlock];
		}

			// Call the completion block with task created
		if (taskEnqueuCompletion) {
			taskEnqueuCompletion(task);
		}
	}
}

- (NSError *) parsingErrorForPath:(NSString *) path
{
	NSString *description = [NSString stringWithFormat:@"Unable to parse response feed for the path:%@", path];
	NSDictionary *info = @{NSLocalizedDescriptionKey: description};
	
	return [NSError errorWithDomain:kSSTServiceErrorDomain
							   code:100 userInfo:info];
}

- (BOOL) takeCareIfDuplicateCall:(NSString *) path withItsCompletionBlock:(SSTServiceCompletionBlock) completion
{
	BOOL isDuplicate = NO;
	
	/**
	 *  Lets check if the call to the URL is already happening
	 */
	NSURLSessionDataTask *currentlyExecutingTask = [self currentlyExecutingTaskForPath:path];
	if (currentlyExecutingTask) {
		
		isDuplicate = YES;
		
		NSLog(@"Found Duplicate Call -- Saving up Completion block : %@",path);
		
		NSString *urlPath = currentlyExecutingTask.originalRequest.URL.absoluteString;
		if (urlPath) {
			NSMutableArray *completionBlocks = [_taskIdsToCompletionBlocks objectForKey:urlPath];
			
			if(!completionBlocks) {
				completionBlocks = [NSMutableArray array];
				
				@synchronized (_taskIdsToCompletionBlocks) {
					[_taskIdsToCompletionBlocks setObject:completionBlocks forKey:urlPath];
				}
			}
			
			if (completion) {
				@synchronized (completionBlocks) {
					[completionBlocks addObject:completion];
				}
			}
		}
	}
	
	return isDuplicate;
}

- (void) clearOutSavedUpCompletionBlocksForTask:(NSURLSessionDataTask *) task result:(id) result isCached:(BOOL) isCached error:(NSError *) error
{
	if (!task) {
		return;
	}
	
	NSString *urlPath = task.originalRequest.URL.absoluteString;
	if (urlPath) {
		NSMutableArray *completionBlocks = [_taskIdsToCompletionBlocks objectForKey:urlPath];
		if(completionBlocks) {
			
			NSArray *copiedComletionBlocks = [NSArray arrayWithArray:completionBlocks];
			for (SSTServiceCompletionBlock aBlock in copiedComletionBlocks) {
				if (!error || error.code != NSURLErrorCancelled) {
					aBlock(result,isCached,error);
				}
			}
			copiedComletionBlocks = nil;
			
			@synchronized (_taskIdsToCompletionBlocks) {
				[_taskIdsToCompletionBlocks removeObjectForKey:urlPath];
			}
		}
	}
}

- (NSURLSessionDataTask *) currentlyExecutingTaskForPath:(NSString *) path
{
	__block NSURLSessionDataTask *task = nil;
	
	[self.tasks enumerateObjectsUsingBlock:^(NSURLSessionDataTask *obj, NSUInteger idx, BOOL *stop)
	 {
		 if ([obj.originalRequest.URL.absoluteString isEqualToString:path])
		 {
			 task = obj;
			 *stop = YES;
		 }
	 }];
	
	return task;
}

- (void) cleanup
{
	/**
	 *  We don't wanna keep any old completion blocks.
	 */
	@synchronized (_taskIdsToCompletionBlocks) {
		[_taskIdsToCompletionBlocks removeAllObjects];
	}
	
	[_dataProcessingQueue cancelAllOperations];
	[_urlCache removeAllCachedResponses];
}

/**
 *  Overriding the GET method to cache the response and return the cache response before calling the server
 */
- (NSURLSessionDataTask *) GET:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *, id))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
	/**
	 *  Lets check if we have cached Data, if we do, lets call the completionBlock once with cached Data
	 */
	[_urlCache cachedResponseForURLString:URLString completion:^(SSTCachedResponse *responseObject) {
		if (responseObject && success) {
			dispatch_async(dispatch_get_main_queue(), ^{
				success(responseObject.task, responseObject.responseObject);
			});
		}
	}];
	
	/**
	 *  Lets modify the Success block so that we cache the data when we get a successfull response
	 */
	__weak typeof(self) blockSelf = self;
	void (^successBlock)(NSURLSessionDataTask *, id) = ^(NSURLSessionDataTask *task, id response) {
		[blockSelf.urlCache cacheResponse:response forDataTask:task];
		
		if (success) {
			success(task,response);
		}
	};
	
	return [super GET:URLString parameters:parameters success:successBlock failure:failure];
}

#pragma mark -
#pragma mark - Notification observer Methods

- (void) applicationDidReceiveMemoryWarning:(NSNotification *) notitfication
{
	[self cleanup];
}

#pragma mark -
#pragma mark - Dealloc

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
