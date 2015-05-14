//
//  BDHost.h
//  linphone
//
//  Created by lalit on 12/19/14.
//
//

#import <Foundation/Foundation.h>

@interface BDHost : NSObject
+ (NSString *)addressForHostname:(NSString *)hostname;
+ (NSArray *)addressesForHostname:(NSString *)hostname;
+ (NSString *)hostnameForAddress:(NSString *)address;
+ (NSArray *)hostnamesForAddress:(NSString *)address;
+ (NSArray *)ipAddresses;
+ (NSArray *)ethernetAddresses;

@end
