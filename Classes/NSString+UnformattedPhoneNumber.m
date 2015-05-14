//
//  NSString+UnformattedPhoneNumber.m
//  linphone
//
//  Created by lalit on 1/14/15.
//
//

#import "NSString+UnformattedPhoneNumber.h"

@implementation NSString (UnformattedPhoneNumber)

- (NSString *)unformattedPhoneNumber {
    NSCharacterSet *toExclude = [NSCharacterSet characterSetWithCharactersInString:@"/.()- "];
    return [[self componentsSeparatedByCharactersInSet:toExclude] componentsJoinedByString: @""];
}

@end