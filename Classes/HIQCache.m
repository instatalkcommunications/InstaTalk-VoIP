//
//  HIQCache.m
//  IndianRailways
//
//  Created by lalit on 12/29/14.
//
//

#import "HIQCache.h"
#import "OrderedDictionaryIR.h"

@implementation HIQCache



-(void)RemoveAllObjects
{
    [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"URLData"];
}

- (OrderedDictionaryIR*)GetCacheDictionary
{
    NSMutableDictionary *dict = [[[NSUserDefaults standardUserDefaults] valueForKey:@"URLData"] mutableCopy];
    NSMutableArray *dictArr = [[[NSUserDefaults standardUserDefaults] valueForKey:@"URLDataArr"] mutableCopy];
    
    if(orderedDict==nil)
    {
        if(dict==nil)
            orderedDict = [[OrderedDictionaryIR alloc]init];
        else
        {
            orderedDict = [[OrderedDictionaryIR alloc] initWithObject:dict withArray:dictArr];
        }
    }
    
    return orderedDict;
}

- (void)cacheURLData:(NSString*)key :(NSString*)value
{
    orderedDict = [self GetCacheDictionary];
    
    if([orderedDict count]==10)
    {//fifo  //remove first item
        
        for(int i=0; i<[orderedDict count]-1; i++)
        {
            //NSLog(@"%d - %d",i+1,i);
            [orderedDict moveFromIndex:i+1 To:i];
        }
        
        [orderedDict removeObjectAtIndex:[orderedDict count]-1];
    }
    
    [orderedDict insertObject:value forKey:key atIndex:[orderedDict count]];
    NSMutableDictionary *tmpDict = [orderedDict getDictionay];
    NSMutableArray *tmpArr = [orderedDict getArray];
    
    [[NSUserDefaults standardUserDefaults] setValue:tmpDict forKey:@"URLData"];
    [[NSUserDefaults standardUserDefaults] setValue:[orderedDict getArray] forKey:@"URLDataArr"];
}

- (NSString*)GetCacheDataForKey:(NSString*)key
{
    orderedDict = [self GetCacheDictionary];
    
    return [orderedDict objectForKey:key];
}
@end
