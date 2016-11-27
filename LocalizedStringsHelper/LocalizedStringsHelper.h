//
//  LocalizedStringsHelper.h
//  LocalizedStringsHelper
//
//  Created by liang on 16/11/27.
//  Copyright © 2016年 liang. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface LocalizedStringsHelper : NSObject

+ (instancetype)sharedPlugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end