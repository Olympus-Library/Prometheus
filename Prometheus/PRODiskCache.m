//
//  CZDiskCache.m
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

#import "PRODiskCache.h"


#pragma mark - Constants

static NSString * const PRODiskCacheSharedQueueName = @"com.prometheus.disk";


#pragma mark - PRODiskCache Class Extension

@interface PRODiskCache ()

@property (readonly) dispatch_queue_t queue;

@end


#pragma mark - PRODiskCache Implementation

@implementation PRODiskCache

#pragma mark Creating a Disk Cache

- (instancetype)initWithDiskCapacity:(NSUInteger)diskCapacity
                            diskPath:(NSString *)diskPath
{
    if (self = [super init]) {
        _diskPath = diskPath;
        _diskCapacity = diskCapacity;
        _queue = [PRODiskCache sharedQueue];
    }
    return self;
}

+ (dispatch_queue_t)sharedQueue
{
    static dispatch_queue_t sharedQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedQueue = dispatch_queue_create([PRODiskCacheSharedQueueName UTF8String], DISPATCH_QUEUE_SERIAL);
    });
    return sharedQueue;
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

@end
