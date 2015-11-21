//
//  SSTUtilities.h
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SSTUtilities : NSObject

/**
 *  Returns the directory path for the specific name provided
 */
+ (NSString *) cacheDirectoryPathWithName:(NSString *) name;
