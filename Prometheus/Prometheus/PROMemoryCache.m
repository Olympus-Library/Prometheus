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
#if TARGET_OS_IPHONE
@import UIKit;
#endif


#pragma mark - Constants

static NSString * const PROMemoryCacheQueueNamePrefix = @"com.prometheus.memory";


#pragma mark - PROMemoryCache Class Extension

@interface PROMemoryCache ()

@property (readonly) dispatch_queue_t       queue;
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

- (void)dispatchAsync:(void (^)(PROMemoryCache *strong))block
{
    __weak PROMemoryCache *weak = self;
    dispatch_async(_queue, ^{
        PROMemoryCache *strong = weak;
        if (strong) {
            block(strong);
        }
    });
}

- (void)dispatchBarrierAsync:(void (^)(PROMemoryCache *strong))block
{
    __weak PROMemoryCache *weak = self;
    dispatch_barrier_async(_queue, ^{
        PROMemoryCache *strong = weak;
        if (strong) {
            block(strong);
        }
    });
}

// Note: potential deadlock if block targets the same queue, use carefully
- (void)dispatchBarrierSync:(void (^)(PROMemoryCache *strong))block
{
    __weak PROMemoryCache *weak = self;
    dispatch_barrier_sync(_queue, ^{
        PROMemoryCache *strong = weak;
        if (strong) {
            block(strong);
        }
    });
}

#pragma mark Getting and Storing Cached Objects

- (void)cachedDataForKey:(NSString *)key
              completion:(PROCacheReadWriteCompletion)completion
{
    if (!key || !completion) {
        return;
    }
    
    NSDate *date = [NSDate date];
    
    [self dispatchAsync:^(PROMemoryCache *strong) {
        PROCachedData *data = [strong.cache objectForKey:key];
        if (data) {
            if (data.expiration && [date timeIntervalSinceDate:data.expiration] >= 0) {
                [strong removeCachedDataForKey:key completion:nil];
                completion(key, nil);
            } else {
                [strong dispatchBarrierAsync:^(PROMemoryCache *strong) {
                    [strong.reads setObject:date forKey:key];
                }];
                completion(key, data);
            }
        } else {
            completion(key, nil);
        }
    }];
}

- (void)storeCachedData:(PROCachedData *)data
                 forKey:(NSString *)key
             completion:(PROCacheReadWriteCompletion)completion
{
    if (!key || !data ||
        data.storagePolicy == PROCacheStoragePolicyNotAllowed) {
        return;
    }
    
    NSDate *date = [NSDate date];
    
    [self dispatchAsync: ^(PROMemoryCache *strong) {
        strong.cache[key] = data;
        strong.reads[key] = date;
        
        strong->_currentMemoryUsage += data.size;
        if (strong.currentMemoryUsage > strong.memoryCapacity) {
            // TODO: trim size of cache
        }
        
        if (completion) {
            [strong dispatchAsync:^(PROMemoryCache *strong) {
                completion(key, data);
            }];
        }
    }];
}

- (PROCachedData *)cachedDataForKey:(NSString *)key
{
    if (!key) {
        return nil;
    }
    
    NSDate *date = [NSDate date];
    
    __block PROCachedData *data = nil;
    [self dispatchBarrierSync:^(PROMemoryCache *strong) {
        data = strong.cache[key];
        strong.reads[key] = date;
    }];
    
    return data;
}

- (void)storeCachedData:(PROCachedData *)data forKey:(NSString *)key
{
    if (!key || !data ||
        data.storagePolicy == PROCacheStoragePolicyNotAllowed) {
        return;
    }
    
    NSDate *date = [NSDate date];
    
    [self dispatchBarrierSync:^(PROMemoryCache *strong) {
        strong.cache[key] = data;
        strong.reads[key] = date;
        strong->_currentMemoryUsage += data.size;
        
        if (strong.currentMemoryUsage > strong.memoryCapacity) {
            // TODO: trim size of cache
        }
    }];
}

#pragma mark Removing Cached Objects

- (void)removeAllCachedDataWithCompletion:(PROCacheOperationCompletion)completion
{
    [self dispatchBarrierAsync:^(PROMemoryCache *strong) {
        [strong.cache removeAllObjects];
        [strong.reads removeAllObjects];
        strong->_currentMemoryUsage = 0;
        
        if (completion) {
            [strong dispatchAsync:^(PROMemoryCache *strong) {
                completion(strong, YES);
            }];
        }
    }];
}

- (void)removeCachedDataForKey:(NSString *)key
                    completion:(PROCacheReadWriteCompletion)completion
{
    [self dispatchBarrierAsync:^(PROMemoryCache *strong) {
        PROCachedData *data = strong.cache[key];
        [strong.cache removeObjectForKey:key];
        [strong.reads removeObjectForKey:key];
        strong->_currentMemoryUsage -= data.size;
        
        if (completion) {
            [strong dispatchAsync:^(PROMemoryCache *strong) {
                completion(key, nil);
            }];
        }
    }];
}

- (void)removeAllCachedData
{
    [self dispatchBarrierSync:^(PROMemoryCache *strong) {
        [strong.cache removeAllObjects];
        [strong.reads removeAllObjects];
        strong->_currentMemoryUsage = 0;
    }];
}

- (void)removeCachedDataForKey:(NSString *)key
{
    [self dispatchBarrierSync:^(PROMemoryCache *strong) {
        PROCachedData *data = strong.cache[key];
        [strong.cache removeObjectForKey:key];
        [strong.reads removeObjectForKey:key];
        strong->_currentMemoryUsage -= data.size;
    }];
}

@end
