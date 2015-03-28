//
//  PROMemoryCache.m
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

#import "PROMemoryCache.h"
#import "PROCachedData.h"
#import "PROCacheKey.h"


#pragma mark - Constants

static NSString * const PROMemoryCacheQueueNamePrefix = @"com.prometheus.PROMemoryCache";


#pragma mark - PROMemoryCache Class Extension

@interface PROMemoryCache ()

@property (readonly) NSMutableDictionary    *reads;
@property (readonly) NSMutableDictionary    *cache;

@end


#pragma mark - PROMemoryCache Implementation

@implementation PROMemoryCache

#pragma mark Creating a Memory Cache

- (instancetype)initWithMemoryCapacity:(NSUInteger)memoryCapacity
{
    if (self = [super init]) {
        NSString *queueName = [NSString stringWithFormat:@"%@.%p", PROMemoryCacheQueueNamePrefix, self];
        _queue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_CONCURRENT);
        _currentMemoryUsage = 0;
        _memoryCapacity = memoryCapacity;
        _cache = [NSMutableDictionary new];
        _reads = [NSMutableDictionary new];
    }
    return self;
}

// -----
// @name Getting and Storing Cached Objects
// -----

#pragma mark Getting and Storing Cached Objects

- (void)cachedDataForKey:(PROCacheKey *)key
              completion:(PROCacheReadWriteCompletion)completion
{
    if (!key || !completion) {
        return;
    }
    NSDate *date = [NSDate date];
    __weak PROMemoryCache *weak = self;
    dispatch_async(_queue, ^{
        PROMemoryCache *strong = weak;
        if (!strong) {
            return;
        }
        PROCachedData *data = [strong.cache objectForKey:key];
        if (data) {
            if (data.expiration && [date timeIntervalSinceDate:data.expiration] >= 0) {
                [strong removeCachedDataForKey:key completion:nil];
                completion(key, nil);
            } else {
                __weak PROMemoryCache *weak = strong;
                dispatch_barrier_async(strong.queue, ^{
                    PROMemoryCache *strong = weak;
                    if (strong) {
                        [strong.reads setObject:date forKey:key];
                    }
                });
                completion(key, data);
            }
        } else {
            completion(key, nil);
        }
    });
}

- (void)storeCachedData:(PROCachedData *)data
                 forKey:(PROCacheKey *)key
             completion:(PROCacheReadWriteCompletion)completion
{
    if (!key || !data) {
        return;
    }
    NSDate *date = [NSDate date];
    __weak PROMemoryCache *weak = self;
    dispatch_barrier_async(_queue, ^{
        PROMemoryCache *strong = weak;
        if (!strong) {
            return;
        }
        
        [strong.cache setObject:data forKey:key];
        [strong.reads setObject:date forKey:key];
        
        _currentMemoryUsage += data.data.length;
        if (_currentMemoryUsage > _memoryCapacity) {
            // TODO: trim size of cache
        }
        
        if (completion) {
            __weak PROMemoryCache *weak = strong;
            dispatch_async(strong.queue, ^{
                PROMemoryCache *strong = weak;
                if (strong) {
                    completion(key, data);
                }
            });
        }
    });
}

#pragma mark Removing Cached Objects

- (void)removeAllCachedDataWithCompletion:(PROCacheOperationCompletion)completion
{
    __weak PROMemoryCache *weak = self;
    dispatch_barrier_async(_queue, ^{
        PROMemoryCache *strong = weak;
        if (!strong) {
            return;
        }
        
        [strong.cache removeAllObjects];
        [strong.reads removeAllObjects];
        strong->_currentMemoryUsage = 0;
        
        
    });
}

- (void)removeCachedDataForKey:(PROCacheKey *)key
                    completion:(PROCacheReadWriteCompletion)completion
{
    
}

@end
