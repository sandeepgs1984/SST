//
//  SSTUtilities.m
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import "SSTUtilities.h"

@implementation SSTUtilities

+ (NSString *) cacheDirectoryPathWithName:(NSString *) name
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = paths[0];
	NSString *cacheDirectoryName = [documentsDirectory stringByAppendingPathComponent:name];
	return cacheDirectoryName;
}

@end
