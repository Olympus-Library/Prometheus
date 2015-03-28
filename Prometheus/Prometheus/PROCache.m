//
//  PROCache.m
//  Prometheus
//
//  Copyright (c) 2015 Comyar Zaheri. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//


#pragma mark - Imports

#import "PROCache.h"
#import "PRODiskCache.h"
#import "PROMemoryCache.h"


#pragma mark - PROCache Class Extension

@interface PROCache ()

@property (readonly) PRODiskCache    *diskCache;
@property (readonly) PROMemoryCache  *memoryCache;

@end


#pragma mark - PROCache Implementation

@implementation PROCache

#pragma mark Creating an Prometheus Cache

- (instancetype)initWithMemoryCapacity:(NSUInteger)memoryCapacity
                          diskCapacity:(NSUInteger)diskCapacity
                              diskPath:(NSString *)path
{
    if (self = [super init]) {
        
    }
    return self;
}


#pragma mark Getting and Storing Cached Objects

- (void)cachedDataForKey:(PROCacheKey *)key
              completion:(PROCacheReadWriteCompletion)completion
{
    
}

- (void)storeCachedData:(PROCachedData *)data
                 forKey:(PROCacheKey *)key
             completion:(PROCacheReadWriteCompletion)completion
{
    
}

#pragma mark Removing Cached Objects

- (void)removeAllCachedDataWithCompletion:(PROCacheOperationCompletion)completion
{
    
}

- (void)removeCachedDataForKey:(PROCacheKey *)key
                    completion:(PROCacheReadWriteCompletion)completion
{
    
}

@end
