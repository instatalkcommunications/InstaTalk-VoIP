//
//  CallDetail.h
//
//  Created by lalit  on 1/12/15
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface CallDetail : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *debit;
@property (nonatomic, strong) NSString *callerip;
@property (nonatomic, strong) NSString *callednum;
@property (nonatomic, strong) NSString *callstart;
@property (nonatomic, strong) NSString *billseconds;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
