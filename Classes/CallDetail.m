//
//  CallDetail.m
//
//  Created by lalit  on 1/12/15
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import "CallDetail.h"


NSString *const kBaseClassDebit = @"debit";
NSString *const kBaseClassCallerip = @"callerip";
NSString *const kBaseClassCallednum = @"callednum";
NSString *const kBaseClassCallstart = @"callstart";
NSString *const kBaseClassBillseconds = @"billseconds";


@interface CallDetail ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation CallDetail

@synthesize debit = _debit;
@synthesize callerip = _callerip;
@synthesize callednum = _callednum;
@synthesize callstart = _callstart;
@synthesize billseconds = _billseconds;


+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict
{
    return [[self alloc] initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    
    // This check serves to make sure that a non-NSDictionary object
    // passed into the model class doesn't break the parsing.
    if(self && [dict isKindOfClass:[NSDictionary class]]) {
            self.debit = [self objectOrNilForKey:kBaseClassDebit fromDictionary:dict];
            self.callerip = [self objectOrNilForKey:kBaseClassCallerip fromDictionary:dict];
            self.callednum = [self objectOrNilForKey:kBaseClassCallednum fromDictionary:dict];
            self.callstart = [self objectOrNilForKey:kBaseClassCallstart fromDictionary:dict];
            self.billseconds = [self objectOrNilForKey:kBaseClassBillseconds fromDictionary:dict];

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.debit forKey:kBaseClassDebit];
    [mutableDict setValue:self.callerip forKey:kBaseClassCallerip];
    [mutableDict setValue:self.callednum forKey:kBaseClassCallednum];
    [mutableDict setValue:self.callstart forKey:kBaseClassCallstart];
    [mutableDict setValue:self.billseconds forKey:kBaseClassBillseconds];

    return [NSDictionary dictionaryWithDictionary:mutableDict];
}

- (NSString *)description 
{
    return [NSString stringWithFormat:@"%@", [self dictionaryRepresentation]];
}

#pragma mark - Helper Method
- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict
{
    id object = [dict objectForKey:aKey];
    return [object isEqual:[NSNull null]] ? nil : object;
}


#pragma mark - NSCoding Methods

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];

    self.debit = [aDecoder decodeObjectForKey:kBaseClassDebit];
    self.callerip = [aDecoder decodeObjectForKey:kBaseClassCallerip];
    self.callednum = [aDecoder decodeObjectForKey:kBaseClassCallednum];
    self.callstart = [aDecoder decodeObjectForKey:kBaseClassCallstart];
    self.billseconds = [aDecoder decodeObjectForKey:kBaseClassBillseconds];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_debit forKey:kBaseClassDebit];
    [aCoder encodeObject:_callerip forKey:kBaseClassCallerip];
    [aCoder encodeObject:_callednum forKey:kBaseClassCallednum];
    [aCoder encodeObject:_callstart forKey:kBaseClassCallstart];
    [aCoder encodeObject:_billseconds forKey:kBaseClassBillseconds];
}

- (id)copyWithZone:(NSZone *)zone
{
    CallDetail *copy = [[CallDetail alloc] init];
    
    if (copy) {

        copy.debit = [self.debit copyWithZone:zone];
        copy.callerip = [self.callerip copyWithZone:zone];
        copy.callednum = [self.callednum copyWithZone:zone];
        copy.callstart = [self.callstart copyWithZone:zone];
        copy.billseconds = [self.billseconds copyWithZone:zone];
    }
    
    return copy;
}


@end
