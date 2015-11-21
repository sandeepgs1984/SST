//
//  SSTImage.m
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import "SSTImage.h"

NSString *const kImage = @"image";
NSString *const kDescription = @"description";
NSString *const kTitle = @"title";

@implementation SSTImage

+ (SSTImage *)modelObjectWithDictionary:(NSDictionary *)dict
{
	SSTImage *instance = [[SSTImage alloc] initWithDictionary:dict];
	return instance;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
	self = [super init];
	
		// This check serves to make sure that a non-NSDictionary object
		// passed into the model class doesn't break the parsing
	if ([dict isKindOfClass:[NSDictionary class]]) {
		_image = [self objectOrNilForKey:kImage fromDictionary:dict];
		_desc = [self objectOrNilForKey:kDescription fromDictionary:dict];
		_title = [self objectOrNilForKey:kTitle fromDictionary:dict];
	}
	
	return self;
}

- (NSDictionary *)dictionaryRepresentation
{
	NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
	[mutableDict setValue:_image forKey:kImage];
	[mutableDict setValue:_desc forKey:kDescription];
	[mutableDict setValue:_title forKey:kTitle];
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
	self.image = [aDecoder decodeObjectForKey:kImage];
	self.desc = [aDecoder decodeObjectForKey:kDescription];
	self.title = [aDecoder decodeObjectForKey:kTitle];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:_image forKey:kImage];
	[aCoder encodeObject:_desc forKey:kDescription];
	[aCoder encodeObject:_title forKey:kTitle];
}

- (id) copyWithZone:(NSZone *)zone
{
	SSTImage *image = [super copyWithZone:zone];
	image.image = _image;
	image.desc = _desc;
	image.title = _title;
	return image;
}

@end
