//
//  PROCaching.h
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


#pragma mark - Forward Declarations

@class PROCachedData;
@protocol PROCaching;


#pragma mark - Type Definitions

/**
 */
typedef void (^PROCacheOperationCompletion)(id<PROCaching> cache, BOOL success);

/**
 */
typedef void (^PROCacheReadWriteCompletion)(NSString *key, PROCachedData *data);


#pragma mark - PROCaching Protocol

@protocol PROCaching <NSObject>

@required

// -----
// @name Getting and Storing Cached Objects
// -----

#pragma mark Getting and Storing Cached Objects

/**
 Asynchronously teturns the cached data in the cache for the specified cache key.
 
 @param     key
            The cache key whose data is desired.
 @param     completion
            The completion handler to be executed when the desired cached data
            is available.
 */
- (void)cachedDataForKey:(NSString *)key
              completion:(PROCacheReadWriteCompletion)completion;

/**
 Asynchronously stores cached data for a specified key.
 
 @param     data
            The cached data to store.
 @param     key
            The cache key for which the cached data is being stored.
 @para      completion
            The completion handler to be executed when the given cached data
            has been stored in the cache.
 */
- (void)storeCachedData:(PROCachedData *)data
                 forKey:(NSString *)key
             completion:(PROCacheReadWriteCompletion)completion;

/**
 Synchronously returns the cached data in the cache for the specified cache key.
 
 @param     key
            The cache key whose data is desired.
 @return    The cached data for key, or nil if no data has been cached.
 */
- (PROCachedData *)cachedDataForKey:(NSString *)key;

/**
 Synchronously stores cached data for a specified key.
 
 @param     data
            The cached data to store.
 @param     key
            The cache key for which the cached data is being stored.
 */
- (void)storeCachedData:(PROCachedData *)data forKey:(NSString *)key;

// -----
// @name Removing Cached Objects
// -----

#pragma mark Removing Cached Objects

/**
 Asynchronously clears the receiver's cache, removing all stored cached data.
 
 @param     completion
 
 */
- (void)removeAllCachedDataWithCompletion:(PROCacheOperationCompletion)completion;

/**
 Asychronously removes the cached data for a specified cache key.
 
 @param     key
            The cache key whose cache data should be removed. If there is no
            corresponding cached data, no action is taken.
 @param     completion
 
 */
- (void)removeCachedDataForKey:(NSString *)key
                    completion:(PROCacheReadWriteCompletion)completion;

/**
 Synchrously clears the receiver's cache, removing all stored cached data.
 
 Blocks the calling thread until the cache has been cleared.
 */
- (void)removeAllCachedData;

/**
 Synchronously removes the cached data for a specified cache key. 
 
 Blocks the calling thread until the cached data has been removed.
 
 @param     key
            The cache key whose cache data should be removed. If there is no
            corresponding cached data, no action is taken.
 */
- (void)removeCachedDataForKey:(NSString *)key;

@end
