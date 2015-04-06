//
//  PROMemoryCache.h
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
#import "PROMemoryCaching.h"
#import "PROMemoryCacheDelegate.h"


#pragma mark - PROMemoryCache Interface

/**
 */
@interface PROMemoryCache : NSObject <PROCaching, PROMemoryCaching>

- (instancetype)init NS_UNAVAILABLE;

// -----
// @name Creating a Memory Cache
// -----

#pragma mark Creating a Memory Cache

/**
 */
- (instancetype)initWithMemoryCapacity:(NSUInteger)memoryCapacity
                NS_DESIGNATED_INITIALIZER;

// -----
// @name Properties
// -----

#pragma mark Properties

/**
 */
@property (weak, NS_NONATOMIC_IOSONLY) id<PROMemoryCacheDelegate> delegate;

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
@property (assign, NS_NONATOMIC_IOSONLY) BOOL removesAllCachedDataOnMemoryWarning;

/**
 Indicates whether the cache remove all of its cached data when it enters the
 background.
 
 The default is YES.
 */
@property (assign, NS_NONATOMIC_IOSONLY) BOOL removesAllCachedDataOnEnteringBackground;

@end
