//
//  UIDevice+DeviceType.h
//  Saltside
//
//  Created by Sandeep G S on 21/11/15.
//  Copyright © 2015 Saltside Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (DeviceType)

/**
 *  Helper to check the device is iPhone(phone,pod)/iPad
 */
+ (BOOL) isCurrentDevicePhone;

@end
