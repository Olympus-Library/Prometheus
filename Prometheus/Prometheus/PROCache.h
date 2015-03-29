//
//  PROCache.h
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

@import Foundation;
#import "PROCaching.h"
#import "PRODiskCaching.h"
#import "PROMemoryCaching.h"
#import "PROCacheDelegate.h"


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
// @name Creating an Prometheus Cache
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
                              diskPath:(NSString *)path
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
 */
@property (NS_NONATOMIC_IOSONLY, weak) id<PROCacheDelegate> delegate;

/**
 The capacity of the receiver's on-disk cache, in bytes.
 */
@property (readonly) NSUInteger diskCapacity;

/**
 The current size of the receiver's on-disk cache, in bytes.
 */
@property (readonly) NSUInteger currentDiskUsage;

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
 
 The default is YES.
 */
@property (assign) BOOL removesAllCachedDataOnMemoryWarning;

/**
 Indicates whether the cache remove all of its cached data when it enters the
 background.
 
 The default is YES.
 */
@property (assign) BOOL removesAllCachedDataOnEnteringBackground;

@end
