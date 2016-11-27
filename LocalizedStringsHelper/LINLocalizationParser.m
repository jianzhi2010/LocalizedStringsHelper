//
//  LINLocalizationParser.m
//  Lin
//
//  Created by Katsuma Tanaka on 2015/02/06.
//  Copyright (c) 2015年 Katsuma Tanaka. All rights reserved.
//

#import "LINLocalizationParser.h"
#import "LINLocalization.h"

static NSString * const kRegularExpressionPattern = @"(\"(\\S+.*\\S+)\"|(\\S+.*\\S+))\\s*=\\s*\"(.*)\";$";

@implementation LINLocalizationParser

#pragma mark - Parsing Localizations


+ (NSArray *)localizationsFromTextString:(NSString *)string
{
    
    // Parse localizations
    NSMutableArray *localizations = [NSMutableArray array];
    
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:kRegularExpressionPattern
                                                                                       options:0
                                                                                         error:nil];
    
    __block NSInteger lineOffset = 0;
    
    [string enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        NSRange keyRange;
        NSRange valueRange;
        NSString *key = nil;
        NSString *value = nil;
        
        // Find definition
        NSTextCheckingResult *result = [regularExpression firstMatchInString:line
                                                                     options:0
                                                                       range:NSMakeRange(0, line.length)];
        
        if (result.range.location != NSNotFound && result.numberOfRanges == 5) {
            keyRange = [result rangeAtIndex:2];
            if (keyRange.location == NSNotFound) keyRange = [result rangeAtIndex:3];
            
            valueRange = [result rangeAtIndex:4];
            
            key = [line substringWithRange:keyRange];
            value = [line substringWithRange:valueRange];
        }
        
        // Move offset
        NSRange lineRange = [string lineRangeForRange:NSMakeRange(lineOffset, 0)];
        lineOffset += lineRange.length;

        // Create localization
        LINLocalization *localization;
        if (key && value) {
            localization = [[LINLocalization alloc] initWithKey:key
                                                        value:value
                                                    lineRange:lineRange];
            [localizations addObject:localization];
        }
    }];
    
    return localizations;
}


@end
