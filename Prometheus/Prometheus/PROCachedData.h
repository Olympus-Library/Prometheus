//
//  PROCachedData.h
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


#pragma mark - Constants

extern const NSTimeInterval PROCachedDataLifetimeInfinity;


#pragma mark - Type Definitions

/**
 These constants specify the caching strategy used by a PROCachedData object.
 */
typedef NS_ENUM(NSUInteger, PROCacheStoragePolicy) {
    
    /**
     Specifies that storage in a cache is allowed without restriction.
     */
    PROCacheStoragePolicyAllowed            = 0,
    
    /**
     Specifies that storage in a cache is allowed; however storage should
     be restricted to memory only.
     */
    PROCacheStoragePolicyAllowedInMemoryOnly = 1,
    
    /**
     Specifies that storage in a CZAsyncCache is not allowed in any fashion, 
     either in memory or on disk.
     */
    PROCacheStoragePolicyNotAllowed          = 2
};


#pragma mark - PROCachedData Interface

/**
 A PROCachedData object represents a cached NSData object. Its storage policy 
 determines whether the data should be cached on disk, in memory, or not at all.
 */
@interface PROCachedData : NSObject <NSCoding, NSCopying, NSSecureCoding>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

// -----
// @name Creating a Cached Data
// -----

#pragma mark Creating Cached Data

/**
 Initializes a PROCachedData object.
 
 The cache storage policy is set to the default, CZCacheStoragePolicyAllowed, 
 and the timestamp is set to the current time.
 
 @param     data
            The data to cache.
 @param     lifetime
            The time interval the data is considered valid.
 @return    The PROCachedData object, initialized using the given data.
 */
- (instancetype)initWithData:(NSData *)data
                    lifetime:(NSTimeInterval)lifetime;

/**
 Initializes a PROCachedData object.
 
 The cache storage policy is set to the default, CZCacheStoragePolicyAllowed.
 
 @param     data
            The data to cache.
 @param     lifetime
            The time interval the data is considered valid.
 @param     timestamp
            The creation date of the data.
 @return    The PROCachedData object, initialized using the given data.
 */
- (instancetype)initWithData:(NSData *)data
                    lifetime:(NSTimeInterval)lifetime
                   timestamp:(NSDate *)timestamp
                    NS_DESIGNATED_INITIALIZER;


/**
 Creates and returns a PROCachedData object.
 
 The cache storage policy is set to the default, CZCacheStoragePolicyAllowed,
 and the timestamp is set to the current time.
 
 @param     data
            The data to cache.
 @param     lifetime
            The time interval the data is considered valid.
 @return    The newly created PROCachedData object.
 */
+ (PROCachedData *)cachedDataWithData:(NSData *)data
                            lifetime:(NSTimeInterval)lifetime;

/**
 Creates and returns a PROCachedData object.
 
 The cache storage policy is set to the default, CZCacheStoragePolicyAllowed,
 and the timestamp is set to the current time.
 
 @param     data
 The data to cache.
 @param     lifetime
            The time interval the data is considered valid.
 @param     timestamp
            The creation date of the data.
 @return    The newly created PROCachedData object.
 */
+ (PROCachedData *)cachedDataWithData:(NSData *)data
                            lifetime:(NSTimeInterval)lifetime
                           timestamp:(NSDate *)timestamp;

// -----
// @name Adding to Lifetime
// -----

#pragma mark Adding to Lifetime

/**
 Returns a new PROCachedData object whose lifetime is set to a given number of
 seconds relative to the receiver.
 
 @param     lifetime
            The numer of seconds to add to the receiver's lifetime. Use a 
            negative value for the lifetime of the returned object be less than
            that of the receiver.
 @return    A new PROCachedData object whose lifetime is set to lifetime seconds
            relative to the receiver.
 */
- (PROCachedData *)cachedDataByAddingLifetime:(NSTimeInterval)lifetime;

// -----
// @name Properties
// -----

#pragma mark Properties

/**
 The receiver's cache storage policy.
 */
@property (assign, NS_NONATOMIC_IOSONLY) PROCacheStoragePolicy storagePolicy;

/**
 The receiver's size, in bytes.
 */
@property (readonly) NSUInteger size;

/**
 The receiver's lifetime, in seconds.
 */
@property (readonly) NSTimeInterval lifetime;

/**
 The receiver's cached data.
 */
@property (readonly, copy) NSData *data;

/**
 The receiver's expiration date.
 */
@property (readonly, copy) NSDate *expiration;

/**
 The creation date of the receiver's data.
 */
@property (readonly, copy) NSDate *timestamp;

@end
