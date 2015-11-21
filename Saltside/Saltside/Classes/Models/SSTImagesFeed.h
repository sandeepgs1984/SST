//
//  SSTImagesFeed.h
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import "SSTModel.h"
#import "SSTImage.h"

@interface SSTImagesFeed : SSTModel

@property (nonatomic, strong) NSArray *images; // contains list of SSTImage objects

@end