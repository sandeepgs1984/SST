//
//  SSTImagesFeed.m
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import "SSTImagesFeed.h"

#define kImages @"images"

@implementation SSTImagesFeed

+ (SSTImagesFeed *)modelObjectWithArray:(NSArray *)array
{
	SSTImagesFeed *instance = [[SSTImagesFeed alloc] initWithArray:array];
	return instance;
}

- (id)initWithArray:(NSArray *)array
{
	self = [super initWithArray:array];
	
		// This check serves to make sure that a non-NSArray object
		// passed into the model class doesn't break the parsing
	if ([array isKindOfClass:[NSArray class]]) {
		
		NSMutableArray *images = [NSMutableArray array];
		
		[array enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
			
			if ([obj isKindOfClass:[NSDictionary class]]) {
				[images addObject:[SSTImage modelObjectWithDictionary:obj]];
			}
		}];
		
		self.images = [NSArray arrayWithArray:images];
	}
	
	return self;
}

- (NSDictionary *)dictionaryRepresentation
{
	NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
	[mutableDict setValue:_images forKey:kImages];
	return [NSDictionary dictionaryWithDictionary:mutableDict];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@", [self dictionaryRepresentation]];
}

#pragma mark - NSCoding Methods

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	self.images = [aDecoder decodeObjectForKey:kImages];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:_images forKey:kImages];
}

- (id) copyWithZone:(NSZone *)zone
{
	SSTImagesFeed *image = [super copyWithZone:zone];
	image.images = _images;
	return image;
}

@end
