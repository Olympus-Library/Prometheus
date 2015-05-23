//
//  PROCache.h
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

@import Foundation;
#import "PROCaching.h"
#import "PRODiskCaching.h"
#import "PROMemoryCaching.h"
#import "PROCacheDelegate.h"


#pragma mark - Constants

/**
 The path of the shared cache's on-disk cache.
 */
extern NSString * const PROCacheSharedDiskPath;

/**
 The capacity of the shared cache's on-disk cache.
 */
extern const NSUInteger PROCacheSharedDiskCapacity;

/**
 The capacity of the shared cache's in-memory cache.
 */
extern const NSUInteger PROCacheSharedMemoryCapacity;


#pragma mark - PROCache Interface

/**
 The PROCache class implements the caching of generic data by mapping
 PROCacheKey objects to PROCachedData objects. It provides a composite in-memory
 and on-disk cache, and lets you manipulate the sizes of both the in-memory and
 on-disk portions. You can also control the path where cache data is stored
 persistently.
 */
@interface PROCache : NSObject <PROCaching, PRODiskCaching, PROMemoryCaching>

// -----
// @name Getting the Shared Cache
// -----

#pragma mark Getting the Shared Cache

/**
 */
+ (PROCache *)sharedCache;

// -----
// @name Creating a Cache
// -----

#pragma mark Creating an Prometheus Cache

/**
 Initializes a PROCache object with the specified values.
 
 @param     memoryCapacity
            The memory capacity of the cache, in bytes.
 @param     diskCapacity
            The disk capacity of the cache, in bytes.
 @param     diskPath
            The name of a subdirectory of the application's default cache 
            directory in which to store the on-disk cache (the subdirectory is
            created if it does not exist).
 
 */
- (instancetype)initWithMemoryCapacity:(NSUInteger)memoryCapacity
                          diskCapacity:(NSUInteger)diskCapacity
                              diskPath:(NSString *)diskPath
                                NS_DESIGNATED_INITIALIZER;

/**
 Initializes a PROCache object with the specified values.
 
 @param     memoryCache
            The memory cache to use.
 @param     diskCache
            The disk cache to use.
 */
- (instancetype)initWithMemoryCache:(id<PROMemoryCaching>)memoryCache
                          diskCache:(id<PRODiskCaching>)diskCache
                            NS_DESIGNATED_INITIALIZER;

// -----
// @name Properties
// -----

#pragma mark Properties

/**
 The receiver's delegate.
 */
@property (weak, NS_NONATOMIC_IOSONLY) id<PROCacheDelegate> delegate;

/**
 The receiver's on-disk cache.
 */
@property (readonly, NS_NONATOMIC_IOSONLY) id<PRODiskCaching> diskCache;

/**
 The receiver's in-memory cache.
 */
@property (readonly, NS_NONATOMIC_IOSONLY) id<PROMemoryCaching> memoryCache;

/**
 The capacity of the receiver's on-disk cache, in bytes.
 */
@property (readonly) NSUInteger diskCapacity;

/**
 The current size of the receiver's on-disk cache, in bytes.
 */
@property (readonly) NSUInteger currentDiskUsage;

/**
 The path of the receiver's on-disk cache.
 */
@property (readonly, copy) NSString *diskPath;

/**
 The capacity of the receiver's in-memory cache, in bytes.
 */
@property (readonly) NSUInteger memoryCapacity;

/**
 The current size of the receiver's in-memory cache, in bytes.
 */
@property (readonly) NSUInteger currentMemoryUsage;

/**
 Indicates whether the cache removes all of its cached data when it receives
 a memory warning.
 */
@property (assign, NS_NONATOMIC_IOSONLY) BOOL removesAllCachedDataOnMemoryWarning;

/**
 Indicates whether the cache remove all of its cached data when it enters the
 background.
 */
@property (assign, NS_NONATOMIC_IOSONLY) BOOL removesAllCachedDataOnEnteringBackground;

@end
