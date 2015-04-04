//
//  PROMemoryCache.m
//  Prometheus
//
//  Copyright (c) 2015 Comyar Zaheri. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//


#pragma mark - Imports

#import "PROMemoryCache.h"
#import "PROCachedData.h"
#if TARGET_OS_IPHONE
@import UIKit;
#endif


#pragma mark - Constants

static NSString * const PROMemoryCacheQueueNamePrefix = @"com.prometheus.memory";


#pragma mark - PROMemoryCache Class Extension

@interface PROMemoryCache ()

@property (readonly) dispatch_queue_t       queue;
@property (readonly) dispatch_semaphore_t   semaphore;
@property (readonly) NSMutableDictionary    *reads;
@property (readonly) NSMutableDictionary    *cache;

@end


#pragma mark - PROMemoryCache Implementation

@implementation PROMemoryCache

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark Creating a Memory Cache

- (instancetype)initWithMemoryCapacity:(NSUInteger)memoryCapacity
{
    if (self = [super init]) {
        NSString *queueName = [NSString stringWithFormat:@"%@.%p", PROMemoryCacheQueueNamePrefix, self];
        _queue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_CONCURRENT);
        _semaphore = dispatch_semaphore_create(1);
        _currentMemoryUsage = 0;
        _memoryCapacity = memoryCapacity;
        _cache = [NSMutableDictionary new];
        _reads = [NSMutableDictionary new];
        _removesAllCachedDataOnMemoryWarning = YES;
        _removesAllCachedDataOnEnteringBackground = YES;
#if TARGET_OS_IPHONE
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(didObserveNotification:)
                                                    name:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:[UIApplication sharedApplication]];
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(didObserveNotification:)
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:[UIApplication sharedApplication]];
#endif
    }
    return self;
}

#pragma mark Notifications

- (void)didObserveNotification:(NSNotification *)notification
{
#if TARGET_OS_IPHONE
    if ([notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification] &&
        self.removesAllCachedDataOnEnteringBackground) {
        [self removeAllCachedDataWithCompletion:nil];
    } else if ([notification.name isEqualToString:UIApplicationDidReceiveMemoryWarningNotification] &&
               self.removesAllCachedDataOnMemoryWarning) {
        [self removeAllCachedDataWithCompletion:nil];
    }
#endif
}

#pragma mark Private

// @warning not thread safe
- (void)reapExpiredCachedData:(PROCachedData *)data forKey:(NSString *)key
{
    __weak id<PROCaching> weak = self;
    if ([_delegate conformsToProtocol:@protocol(PROMemoryCacheDelegate)] &&
        [_delegate respondsToSelector:@selector(cache:willEvictExpiredDataFromMemory:)]) {
        [_delegate cache:weak didEvictExpiredDataFromMemory:data];
    }
    
    [_cache removeObjectForKey:key];
    [_reads removeObjectForKey:key];
    _currentMemoryUsage -= data.size;
    
    if ([_delegate conformsToProtocol:@protocol(PROMemoryCacheDelegate)] &&
        [_delegate respondsToSelector:@selector(cache:didEvictExpiredDataFromMemory:)]) {
        [_delegate cache:weak didEvictExpiredDataFromMemory:data];
    }
}

// @warning not thread safe
- (void)reapExpiredCachedData
{
    __weak id<PROCaching> weak = self;
    NSDate *date = [NSDate date];
    NSArray *keysSortedByDate = [_reads keysSortedByValueUsingSelector:@selector(compare:)];
    for (NSString *key in keysSortedByDate) {
        PROCachedData *data = _cache[key];
        if ([date timeIntervalSinceDate:data.expiration] >= 0) {
            if ([_delegate conformsToProtocol:@protocol(PROMemoryCacheDelegate)] &&
                [_delegate respondsToSelector:@selector(cache:shouldEvictExpiredDataFromMemory:)]) {
                PROCacheEvictExpiredDataDecision decision = [_delegate cache:weak
                                        shouldEvictExpiredDataFromMemory:data];
                if (decision == PROCacheEvictExpiredDataDecisionAffirm) {
                    [self reapExpiredCachedData:data forKey:key];
                } else if (decision == PROCacheEvictExpiredDataDecisionDeferByLifetime) {
                    _cache[key] = [data cachedDataByAddingLifetime:data.lifetime];
                    _reads[key] = date;
                }
            } else {
                [self reapExpiredCachedData:data forKey:key];
            }
        } else {
            break;
        }
    }
}



// @warning not thread safe
- (void)reapLeastRecentlyUsed
{
    __weak id<PROCaching> weak = self;
    NSArray *keysSortedByDate = [_reads keysSortedByValueUsingSelector:@selector(compare:)];
    for (NSString *key in keysSortedByDate) {
        PROCachedData *data = _cache[key];
        
        if ([_delegate conformsToProtocol:@protocol(PROMemoryCacheDelegate)] &&
            [_delegate respondsToSelector:@selector(cache:willFreeUsageByEvictingFromMemory:)]) {
            [_delegate cache:weak willFreeUsageByEvictingFromMemory:data];
        }
        
        [_cache removeObjectForKey:key];
        [_reads removeObjectForKey:key];
        _currentMemoryUsage -= data.size;
        
        if ([_delegate conformsToProtocol:@protocol(PROMemoryCacheDelegate)] &&
            [_delegate respondsToSelector:@selector(cache:didFreeUsageByEvictingFromMemory:)]) {
            [_delegate cache:weak didFreeUsageByEvictingFromMemory:data];
        }
        
        if (_currentMemoryUsage < _memoryCapacity) {
            break;
        }
    }
}

#pragma mark Getting and Storing Cached Objects

- (void)cachedDataForKey:(NSString *)key
              completion:(PROCacheReadWriteCompletion)completion
{
    if (!completion) {
        return;
    }
    
    __weak PROMemoryCache *weak = self;
    dispatch_async(_queue, ^{
        PROMemoryCache *strong = weak;
        PROCachedData *data = [strong cachedDataForKey:key];
        completion(weak, key, data);
    });
}

- (void)storeCachedData:(PROCachedData *)data
                 forKey:(NSString *)key
             completion:(PROCacheReadWriteCompletion)completion
{
    __weak PROMemoryCache *weak = self;
    dispatch_async(_queue, ^{
        PROMemoryCache *strong = weak;
        [strong storeCachedData:data forKey:key];
        if (completion) {
            completion(weak, key, data);
        }
    });
}

- (PROCachedData *)cachedDataForKey:(NSString *)key
{
    if (!key) {
        return nil;
    }
    
    NSDate *date = [NSDate date];
    
    PROCachedData *data = nil;
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    data = _cache[key];
    dispatch_semaphore_signal(_semaphore);
    
    if (data) {
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        _reads[key] = date;
        dispatch_semaphore_signal(_semaphore);
    }
    
    return data;
}

- (void)storeCachedData:(PROCachedData *)data forKey:(NSString *)key
{
    if (!key || !data ||
        data.storagePolicy == PROCacheStoragePolicyNotAllowed) {
        return;
    }
    
    NSDate *date = [NSDate date];
    
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    _cache[key] = data;
    _reads[key] = date;
    _currentMemoryUsage += data.size;
    dispatch_semaphore_signal(_semaphore);
    
    if (_currentMemoryUsage > _memoryCapacity) {
        // TODO: trim size of cache
    }
}

#pragma mark Removing Cached Objects

- (void)removeAllCachedDataWithCompletion:(PROCacheOperationCompletion)completion
{
    __weak PROMemoryCache *weak = self;
    dispatch_async(_queue, ^{
        PROMemoryCache *strong = weak;
        [strong removeAllCachedData];
        if (completion) {
            completion(weak, YES);
        }
    });
}

- (void)removeCachedDataForKey:(NSString *)key
                    completion:(PROCacheReadWriteCompletion)completion
{
    __weak PROMemoryCache *weak = self;
    dispatch_async(_queue, ^{
        PROMemoryCache *strong = weak;
        [strong removeCachedDataForKey:key];
        if (completion) {
            completion(weak, key, nil);
        }
    });
}

- (void)removeAllCachedData
{
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    [_cache removeAllObjects];
    [_reads removeAllObjects];
    _currentMemoryUsage = 0;
    dispatch_semaphore_signal(_semaphore);
}

- (void)removeCachedDataForKey:(NSString *)key
{
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    PROCachedData *data = _cache[key];
    [_cache removeObjectForKey:key];
    [_reads removeObjectForKey:key];
    _currentMemoryUsage -= data.size;
    dispatch_semaphore_signal(_semaphore);
}

@end
