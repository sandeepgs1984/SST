//
//  UIDevice+DeviceOrientation.m
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import "UIDevice+DeviceOrientation.h"

@implementation UIDevice (DeviceOrientation)

+ (UIDeviceOrientation) interfaceOrientation
{
	return [[UIDevice currentDevice] orientation];
}

@end
