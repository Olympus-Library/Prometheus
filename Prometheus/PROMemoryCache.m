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
#import "PrometheusInternal.h"
#import "PROCachedData.h"
#import <Chronos/Chronos.h>

#if TARGET_OS_IPHONE
@import UIKit;
#endif


#pragma mark - Constants

static const float PROMaxPressureFactor                 = 0.875;
static NSString * const PROQueueNamePrefix              = @"com.prometheus.PROMemoryCache";
static const NSTimeInterval PROGarbageCollectInterval   = 60.0;


#pragma mark - PROMemoryCache Class Extension

@interface PROMemoryCache ()

@property (NS_NONATOMIC_IOSONLY) dispatch_queue_t queue;
@property (NS_NONATOMIC_IOSONLY) dispatch_semaphore_t semaphore;
@property (NS_NONATOMIC_IOSONLY) NSMutableDictionary *reads;
@property (NS_NONATOMIC_IOSONLY) NSMutableDictionary *cache;
@property (NS_NONATOMIC_IOSONLY) CHRDispatchTimer *timer;
@property (assign) NSUInteger maxMemoryPressure;
@property (assign) NSUInteger currentMemoryUsage;
@property (assign) NSUInteger memoryCapacity;

@end


#pragma mark - PROMemoryCache Implementation

@implementation PROMemoryCache

- (void)dealloc
{
    [_timer cancel];
}

#pragma mark Creating a Memory Cache

- (instancetype)initWithMemoryCapacity:(NSUInteger)memoryCapacity
{
    if (self = [super init]) {
        self.currentMemoryUsage = 0;
        self.memoryCapacity = memoryCapacity;
        self.cache = [NSMutableDictionary new];
        self.reads = [NSMutableDictionary new];
        self.maxMemoryPressure = (NSUInteger) ceilf(PROMaxPressureFactor * self.memoryCapacity);
        self.semaphore = dispatch_semaphore_create(1);
        
        NSString *name = [NSString stringWithFormat:@"%@.%p", PROQueueNamePrefix, self];
        self.queue = dispatch_queue_create([name UTF8String], DISPATCH_QUEUE_CONCURRENT);
        
#if TARGET_OS_IPHONE
        self.removesAllCachedDataOnMemoryWarning = YES;
        self.removesAllCachedDataOnEnteringBackground = YES;
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(didReceiveMemoryWarningNotification)
                                                    name:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(didEnterBackgroundNotification)
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
#endif
        
        // TODO Issue #1: This could be replaced with a variable timer that
        // allows for the window between GCs to be scaled.
        __weak PROMemoryCache *weak = self;
        _timer = [CHRDispatchTimer timerWithInterval:PROGarbageCollectInterval
                                      executionBlock:^(CHRDispatchTimer *__weak timer,
                                                       NSUInteger invocation) {
                                          [weak garbageCollect];
                                      }];
    }
    return self;
}

#pragma mark Memory Warning

- (void)didReceiveMemoryWarningNotification
{
#if TARGET_OS_IPHONE
    BOOL removes = self.removesAllCachedDataOnMemoryWarning;
    if (removes) {
        [self removeAllCachedDataWithCompletion:nil];
    }
#endif
}

#pragma mark Entering Background

- (void)didEnterBackgroundNotification
{
#if TARGET_OS_IPHONE
    BOOL removes = self.removesAllCachedDataOnEnteringBackground;
    if (removes) {
        [self removeAllCachedDataWithCompletion:nil];
    }
#endif
}

#pragma mark Garbage Collection

- (void)garbageCollect
{
    NSDate *date = [NSDate date];
    
    __weak PROMemoryCache *weak = self;
    dispatch_async(self.queue, ^{
        PROMemoryCache *strong = weak;
        [strong garbageCollectWithDate:date];
    });
}

- (void)garbageCollectWithDate:(NSDate *)date
{
    __block NSArray *keysSortedByDate = nil;
    [self lock:^{
        keysSortedByDate = [self.reads keysSortedByValueUsingSelector:@selector(compare:)];
    }];
    
    for (NSString *key in keysSortedByDate) {
        
        __block PROCachedData *data = nil;
        [self lock:^{
            data = self.cache[key];
        }];
        
        // remove expired data
        if ([date timeIntervalSinceDate:data.expiration] >= 0) {
            if ([self shouldEvictExpiredCachedData:data forKey:key]) {
                [self evictExpiredCachedData:data forKey:key];
                
            }
        }
        
        __block NSUInteger currentMemoryUsage = 0;
        [self lock:^{
            currentMemoryUsage = self.currentMemoryUsage;
        }];
        
        // remove LRU
        if (currentMemoryUsage >= self.maxMemoryPressure) {
            if ([self shouldEvictLRUCachedData:data forKey:key]) {
                [self evictLRUCachedData:data forKey:key];
            }
        }
    }
}

#pragma mark Evicting Least Recently Used Cache Data

- (BOOL)shouldEvictLRUCachedData:(PROCachedData *)data forKey:(NSString *)key
{
    if ([self.delegate conformsToProtocol:@protocol(PROMemoryCacheDelegate)] &&
        [self.delegate respondsToSelector:@selector(cache:shouldEvictLRUDataFromMemory:)]) {
        __weak PROMemoryCache *weak = self;
        PROCacheEvictLRUDataDecision decision = [self.delegate cache:weak
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
    if ([self.delegate conformsToProtocol:@protocol(PROMemoryCacheDelegate)] &&
        [self.delegate respondsToSelector:@selector(cache:willEvictLRUDataFromMemory:)]) {
        [self.delegate cache:weak willEvictLRUDataFromMemory:data];
    }
    
    [self removeCachedDataForKey:key];
    
    if ([self.delegate conformsToProtocol:@protocol(PROMemoryCacheDelegate)] &&
        [self.delegate respondsToSelector:@selector(cache:didEvictLRUDataFromMemory:)]) {
        [self.delegate cache:weak didEvictLRUDataFromMemory:data];
    }
}


#pragma mark Evicting Expired Cached Data

- (BOOL)shouldEvictExpiredCachedData:(PROCachedData *)data forKey:(NSString *)key
{
    if ([self.delegate conformsToProtocol:@protocol(PROMemoryCacheDelegate)] &&
        [self.delegate respondsToSelector:@selector(cache:shouldEvictExpiredDataFromMemory:)]) {
        __weak PROMemoryCache *weak = self;
        PROCacheEvictExpiredDataDecision decision = [self.delegate cache:weak
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
    __weak id<PROMemoryCaching> weak = self;
    if ([self.delegate conformsToProtocol:@protocol(PROMemoryCacheDelegate)] &&
        [self.delegate respondsToSelector:@selector(cache:willEvictExpiredDataFromMemory:)]) {
        [self.delegate cache:weak willEvictExpiredDataFromMemory:data];
    }
    
    [self removeCachedDataForKey:key];
    
    if ([self.delegate conformsToProtocol:@protocol(PROMemoryCacheDelegate)] &&
        [self.delegate respondsToSelector:@selector(cache:didEvictExpiredDataFromMemory:)]) {
        [self.delegate cache:weak didEvictExpiredDataFromMemory:data];
    }
}

#pragma mark Getting and Storing Cached Objects

- (void)cachedDataForKey:(NSString *)key
              completion:(PROCacheReadWriteCompletion)completion
{
    key = [key copy];
    
    __weak PROMemoryCache *weak = self;
    if (!completion) {
        return;
    } else if (!key) {
        completion(weak, key, nil);
        return;
    }
                   
    dispatch_async(self.queue, ^{
        PROMemoryCache *strong = weak;
        PROCachedData *data = [strong cachedDataForKey:key];
        completion(weak, key, data);
    });
}

- (void)storeCachedData:(PROCachedData *)data
                 forKey:(NSString *)key
             completion:(PROCacheReadWriteCompletion)completion
{
    key = [key copy];
    
    __weak PROMemoryCache *weak = self;
    if (!key || !data) {
        if (completion) {
            completion(weak, key, nil);
        }
        return;
    }
    
    if (data.storagePolicy == PROCacheStoragePolicyNotAllowed ||
        [data.expiration timeIntervalSinceNow] <= 0) {
        completion(weak, key, nil);
        return;
    }
    
    dispatch_async(self.queue, ^{
        PROMemoryCache *strong = weak;
        BOOL success = [strong storeCachedData:data forKey:key];
        if (completion) {
            completion(weak, key, success ? data : nil);
        }
    });
}

- (PROCachedData *)cachedDataForKey:(NSString *)key
{
    key = [key copy];
    
    if (!key) {
        return nil;
    }
    
    NSDate *date = [NSDate date];
    
    __block PROCachedData *data = nil;
    [self lock:^{
        data = self.cache[key];
    }];
    
    if (data) {
        // make sure data isn't expired, we won't return expired data
        if ([data.expiration timeIntervalSinceDate:date] <= 0) {
            [self removeCachedDataForKey:key // async remove the expired data
                              completion:nil];
            data = nil;
        } else {
            [self lock:^{
                self.reads[key] = date;
            }];
        }
    }
    
    return data;
}

- (BOOL)storeCachedData:(PROCachedData *)data forKey:(NSString *)key
{
    key = [key copy];
    
    if (!key || !data) {
        return NO;
    }
    
    if (data.storagePolicy == PROCacheStoragePolicyNotAllowed ||
        [data.expiration timeIntervalSinceNow] <= 0) {
        return NO;
    }
    
    // cannot put any items in cache that exceed the size of the cache!
    if (data.size > self.memoryCapacity) {
        return NO;
    }
    
    NSDate *date = [NSDate date];
    
    __block NSUInteger currentMemoryUsage = 0;
    [self lock:^{
        self.cache[key] = data;
        self.reads[key] = date;
        self.currentMemoryUsage += data.size;
        currentMemoryUsage = self.currentMemoryUsage;
    }];
    
    // if new data pushed usage above pressure, we garbage collect
    if (currentMemoryUsage > self.maxMemoryPressure) {
        [self garbageCollect];
    }
    
    return YES;
}

#pragma mark Removing Cached Objects

- (void)removeAllCachedDataWithCompletion:(PROCacheOperationCompletion)completion
{
    __weak PROMemoryCache *weak = self;
    dispatch_async(self.queue, ^{
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
    key = [key copy];
    
    __weak PROMemoryCache *weak = self;
    if (!key) {
        if (completion) {
            completion(weak, key, nil);
        }
        return;
    }
                       
    dispatch_async(self.queue, ^{
        PROMemoryCache *strong = weak;
        [strong removeCachedDataForKey:key];
        if (completion) {
            completion(weak, key, nil);
        }
    });
}

- (void)removeAllCachedData
{
    [self lock:^{
        [self.cache removeAllObjects];
        [self.reads removeAllObjects];
        self.currentMemoryUsage = 0;
    }];
}

- (void)removeCachedDataForKey:(NSString *)key
{
    key = [key copy];
    
    if (!key) {
        return;
    }
    
    [self lock:^{
        PROCachedData *data = self.cache[key];
        [self.cache removeObjectForKey:key];
        [self.reads removeObjectForKey:key];
        self.currentMemoryUsage -= data.size;
    }];
}

#pragma mark Locking

- (void)lock:(void (^)(void))block
{
    if (!block) {
        return;
    }
    
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    block();
    dispatch_semaphore_signal(self.semaphore);
}

@end
