//
//  SSTModel.h
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SSTModel : NSObject <NSCopying, NSCoding>

	// Methods to parse response and assign values (currently only json response with type array/dictionary)
	// Write different method if response is different type
+ (instancetype) modelObjectWithArray:(NSArray *) array;
- (instancetype) initWithArray:(NSArray *) array;

+ (instancetype) modelObjectWithDictionary:(NSDictionary *) dict;
- (instancetype) initWithDictionary:(NSDictionary *) dict;

	// Helper method to check nil value
- (id) objectOrNilForKey:(id) aKey fromDictionary:(NSDictionary *) dict;

	// Used when logging objects
- (NSDictionary *) dictionaryRepresentation;

@end