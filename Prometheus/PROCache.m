//
//  PROCache.m
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

#import "PROCache.h"
#import "PRODiskCache.h"
#import "PROMemoryCache.h"


#pragma mark - Constants

NSString * const PROCacheSharedDiskPath         = @""; // TODO
const NSUInteger PROCacheSharedDiskCapacity     = 16000000; // 16MiB
const NSUInteger PROCacheSharedMemoryCapacity   = 4000000;  // 4MiB


#pragma mark - PROCache Class Extension

@interface PROCache ()

@end


#pragma mark - PROCache Implementation

@implementation PROCache

#pragma mark Getting the Shared Cache

+ (PROCache *)sharedCache
{
    static PROCache *sharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[PROCache alloc]initWithMemoryCapacity:PROCacheSharedMemoryCapacity
                                                 diskCapacity:PROCacheSharedDiskCapacity
                                                     diskPath:PROCacheSharedDiskPath];
    });
    return sharedCache;
}


#pragma mark Creating a Cache

- (instancetype)initWithMemoryCapacity:(NSUInteger)memoryCapacity
                          diskCapacity:(NSUInteger)diskCapacity
                              diskPath:(NSString *)diskPath
{
    if (self = [super init]) {
        _memoryCache    = [[PROMemoryCache alloc]initWithMemoryCapacity:memoryCapacity];
        _diskCache      = [[PRODiskCache alloc]initWithDiskCapacity:diskCapacity
                                                           diskPath:diskPath];
    }
    return self;
}

- (instancetype)initWithMemoryCache:(id<PROMemoryCaching>)memoryCache
                          diskCache:(id<PRODiskCaching>)diskCache
{
    if (self = [super init]) {
        _diskCache      = diskCache;
        _memoryCache    = memoryCache;
    }
    return self;
}


#pragma mark Getting and Storing Cached Objects

- (void)cachedDataForKey:(NSString *)key
              completion:(PROCacheReadWriteCompletion)completion
{
    
}

- (void)storeCachedData:(PROCachedData *)data
                 forKey:(NSString *)key
             completion:(PROCacheReadWriteCompletion)completion
{
    
}

- (PROCachedData *)cachedDataForKey:(NSString *)key
{
    return nil;
}

- (void)storeCachedData:(PROCachedData *)data forKey:(NSString *)key
{
    
}

#pragma mark Removing Cached Objects

- (void)removeAllCachedDataWithCompletion:(PROCacheOperationCompletion)completion
{
    
}

- (void)removeCachedDataForKey:(NSString *)key
                    completion:(PROCacheReadWriteCompletion)completion
{
    
}

- (void)removeAllCachedData
{
    
}

- (void)removeCachedDataForKey:(NSString *)key
{
    
}

#pragma mark Setters

- (void)setRemovesAllCachedDataOnMemoryWarning:(BOOL)removesAllCachedDataOnMemoryWarning
{
    self.memoryCache.removesAllCachedDataOnMemoryWarning = removesAllCachedDataOnMemoryWarning;
}

#pragma mark Getters

- (NSUInteger)currentMemoryUsage
{
    return self.memoryCache.currentMemoryUsage;
}

- (NSUInteger)memoryCapacity
{
    return self.memoryCache.memoryCapacity;
}

- (NSUInteger)currentDiskUsage
{
    return self.diskCache.currentDiskUsage;
}

- (NSUInteger)diskCapacity
{
    return self.diskCache.diskCapacity;
}

- (NSString *)diskPath
{
    return self.diskCache.diskPath;
}

@end
