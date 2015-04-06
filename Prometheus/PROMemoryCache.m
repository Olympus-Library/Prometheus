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
#import <Chronos/Chronos.h>
#if TARGET_OS_IPHONE
@import UIKit;
#endif


#pragma mark - Constants

static const float PROMemoryCacheMaxPressureFactor                  = 0.875;
static NSString * const PROMemoryCacheQueueNamePrefix               = @"com.prometheus.PROMemoryCache";
static const NSTimeInterval PROMemoryCacheGarbageCollectInterval    = 180.0; // 3 minutes


#pragma mark - PROMemoryCache Class Extension

@interface PROMemoryCache ()

@property (readonly) dispatch_queue_t       queue;
@property (readonly) dispatch_semaphore_t   semaphore;
@property (readonly) NSMutableDictionary    *reads;
@property (readonly) NSMutableDictionary    *cache;
@property (readonly) CHRDispatchTimer       *timer;
@property (readonly) NSUInteger             maxMemoryPressure;

@end


#pragma mark - PROMemoryCache Implementation

@implementation PROMemoryCache

- (void)dealloc
{
    [_timer cancel];
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
        _maxMemoryPressure = (NSUInteger) ceilf(PROMemoryCacheMaxPressureFactor * _memoryCapacity);
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
        __weak PROMemoryCache *weak = self;
        _timer = [CHRDispatchTimer timerWithInterval:PROMemoryCacheGarbageCollectInterval
                                      executionBlock:^(CHRDispatchTimer *__weak timer,
                                                       NSUInteger invocation) {
                                          dispatch_async(_queue, ^{
                                              [weak garbageCollect];
                                          });
                                      }];
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

#pragma mark Garbage Collection

- (void)garbageCollect
{
    NSDate *date = [NSDate date];
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    NSArray *keysSortedByDate = [_reads keysSortedByValueUsingSelector:@selector(compare:)];
    dispatch_semaphore_signal(_semaphore);
    for (NSString *key in keysSortedByDate) {
        PROCachedData *data = [self cachedDataForKey:key];
        if ([date timeIntervalSinceDate:data.expiration] >= 0) {
            if ([self shouldEvictExpiredCachedData:data forKey:key]) {
                [self evictExpiredCachedData:data forKey:key];
            }
        } else if (_currentMemoryUsage >= _maxMemoryPressure) {
            if ([self shouldEvictLRUCachedData:data forKey:key]) {
                [self evictLRUCachedData:data forKey:key];
            }
        }
    }
}

#pragma mark Evicting Least Recently Used Cache Data

- (BOOL)shouldEvictLRUCachedData:(PROCachedData *)data forKey:(NSString *)key
{
    if ([_delegate conformsToProtocol:@protocol(PROMemoryCacheDelegate)] &&
        [_delegate respondsToSelector:@selector(cache:shouldEvictLRUDataFromMemory:)]) {
        __weak PROMemoryCache *weak = self;
        PROCacheEvictLRUDataDecision decision = [_delegate cache:weak
                                    shouldEvictLRUDataFromMemory:data];
        if (decision == PROCacheEvictLRUDataDecisionReject) {
            return NO;
        }
    }
    return YES;
}

- (void)evictLRUCachedData:(PROCachedData *)data forKey:(NSString *)key
{
    __weak id<PROMemoryCaching> weak = self;
    if ([_delegate conformsToProtocol:@protocol(PROMemoryCacheDelegate)] &&
        [_delegate respondsToSelector:@selector(cache:willEvictLRUDataFromMemory:)]) {
        [_delegate cache:weak willEvictLRUDataFromMemory:data];
    }
    
    [self removeCachedDataForKey:key];
    
    if ([_delegate conformsToProtocol:@protocol(PROMemoryCacheDelegate)] &&
        [_delegate respondsToSelector:@selector(cache:didEvictLRUDataFromMemory:)]) {
        [_delegate cache:weak didEvictLRUDataFromMemory:data];
    }
}


#pragma mark Evicting Expired Cached Data

- (BOOL)shouldEvictExpiredCachedData:(PROCachedData *)data forKey:(NSString *)key
{
    if ([_delegate conformsToProtocol:@protocol(PROMemoryCacheDelegate)] &&
        [_delegate respondsToSelector:@selector(cache:shouldEvictExpiredDataFromMemory:)]) {
        __weak PROMemoryCache *weak = self;
        PROCacheEvictExpiredDataDecision decision = [_delegate cache:weak
                                    shouldEvictExpiredDataFromMemory:data];
        if (decision == PROCacheEvictExpiredDataDecisionDeferByLifetime) {
            PROCachedData *extendedData = [data cachedDataByAddingLifetime:data.lifetime];
            [self storeCachedData:extendedData forKey:key];
            return NO;
        }
    }
    return YES;
}

- (void)evictExpiredCachedData:(PROCachedData *)data forKey:(NSString *)key
{
    __weak id<PROCaching> weak = self;
    if ([_delegate conformsToProtocol:@protocol(PROMemoryCacheDelegate)] &&
        [_delegate respondsToSelector:@selector(cache:willEvictExpiredDataFromMemory:)]) {
        [_delegate cache:weak willEvictExpiredDataFromMemory:data];
    }
    
    [self removeCachedDataForKey:key];
    
    if ([_delegate conformsToProtocol:@protocol(PROMemoryCacheDelegate)] &&
        [_delegate respondsToSelector:@selector(cache:didEvictExpiredDataFromMemory:)]) {
        [_delegate cache:weak didEvictExpiredDataFromMemory:data];
    }
}

#pragma mark Getting and Storing Cached Objects

- (void)cachedDataForKey:(NSString *)key
              completion:(PROCacheReadWriteCompletion)completion
{
    __weak PROMemoryCache *weak = self;
    if (!completion) {
        return;
    } else if (!key) {
        completion(weak, key, nil);
        return;
    }
                   
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
    if (!key || !data ||
        data.storagePolicy == PROCacheStoragePolicyNotAllowed) {
        if (completion) {
            completion(weak, key, nil);
        }
        return;
    }
    
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
        if ([date timeIntervalSinceDate:data.expiration] >= 0) {
            data = nil;
            [self removeCachedDataForKey:key];
        } else {
            dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
            _reads[key] = date;
            dispatch_semaphore_signal(_semaphore);
        }
    }
    
    return data;
}

- (void)storeCachedData:(PROCachedData *)data forKey:(NSString *)key
{
    if (!key || !data ||
        data.storagePolicy == PROCacheStoragePolicyNotAllowed) {
        return;
    }
    
    if (data.size > _memoryCapacity) {
        return;
    }
    
    NSDate *date = [NSDate date];
    
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    if (_currentMemoryUsage == 0) {
        [_timer start:NO];
    }
    _cache[key] = data;
    _reads[key] = date;
    _currentMemoryUsage += data.size;
    dispatch_semaphore_signal(_semaphore);
    
    if (_currentMemoryUsage > _memoryCapacity) {
        [self garbageCollect];
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
    if (!key) {
        return;
    }
    
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
    [_timer pause];
    dispatch_semaphore_signal(_semaphore);
}

- (void)removeCachedDataForKey:(NSString *)key
{
    if (!key) {
        return;
    }
    
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    PROCachedData *data = _cache[key];
    [_cache removeObjectForKey:key];
    [_reads removeObjectForKey:key];
    _currentMemoryUsage -= data.size;
    if (_currentMemoryUsage == 0) {
        [_timer start:NO];
    }
    dispatch_semaphore_signal(_semaphore);
}

@end
