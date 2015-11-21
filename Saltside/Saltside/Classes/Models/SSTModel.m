//
//  SSTModel.m
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import "SSTModel.h"

@implementation SSTModel

+ (instancetype) modelObjectWithArray:(NSArray *) array
{
	id result = [[[self class] alloc] initWithArray:array];
	return result;
}

- (instancetype) initWithArray:(NSArray *) array
{
	return [super init];
}

+ (instancetype) modelObjectWithDictionary:(NSDictionary *) dict
{
	id result = [[[self class] alloc] initWithDictionary:dict];
	return result;
}

- (instancetype) initWithDictionary:(NSDictionary *) dict
{
	return [super init];
}

#pragma mark - Helper Method

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict
{
	id object = [dict objectForKey:aKey];
	return [object isEqual:[NSNull null]] ? nil : object;
}

- (NSDictionary *) dictionaryRepresentation
{
	return [NSDictionary dictionary];
}

#pragma mark -
#pragma mark - NSCoding Protocol

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super init];
	if (self) {
			// Subclasses will implement
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
		// Subclasses will implement
}

#pragma mark -
#pragma mark - Copy methods

- (id) copyWithZone:(NSZone *)zone
{
	SSTModel *object = [[[self class] allocWithZone:zone] init];
	return object;
}

@end
