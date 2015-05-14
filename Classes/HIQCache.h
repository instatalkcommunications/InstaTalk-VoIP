//
//  HIQCache.h
//  IndianRailways
//
//  Created by lalit on 12/29/14.
//
//

#import <Foundation/Foundation.h>
#import "OrderedDictionaryIR.h"

@interface HIQCache : NSObject
{
    OrderedDictionaryIR *orderedDict;
}

- (OrderedDictionaryIR*)GetCacheDictionary;
- (NSString*)GetCacheDataForKey:(NSString*)key;
- (void)cacheURLData:(NSString*)key :(NSString*)value;
-(void)RemoveAllObjects;
@end
