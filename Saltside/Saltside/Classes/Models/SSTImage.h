//
//  SSTImage.h
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import "SSTModel.h"

@interface SSTImage : SSTModel

@property (nonatomic, strong) NSString *image; // contains image path
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSString *title;

@property (nonatomic, strong) NSAttributedString *attributedContentString; // Construct attributed string from the title and description at the time of object creation itself as to avoid creating multiple times everytime cell has reused

@end