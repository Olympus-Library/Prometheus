//
//  PROCacheKey.h
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

extern NSString * const PROCacheKeyDefaultNameSpace;


#pragma mark - PROCacheKey Interface

/**
 A PROCacheKey object represents a key that maps to a cached data object. A 
 PROCacheKey object may be used to retrieve objects from a cache.
 */
@interface PROCacheKey : NSObject <NSCoding, NSCopying, NSSecureCoding>

- (instancetype)init NS_UNAVAILABLE;

// -----
// @name Creating a Cache Key
// -----

#pragma mark Creating a Cache Key

/**
 Initializes a PROCacheKey object.
 
 The namespace is set to the default namespace.
 
 @param     key
            The key used for cached data.
 @return    The initialized PROCacheKey object.
 */
- (instancetype)initWithKey:(NSString *)key;


/**
 Initializes a PROCacheKey object given the specified values.
 
 @param     key
            THe key used for cached data.
 @param     nameSpace
            The namespace in which the key exists.
 @return    The initialized PROCacheKey object.
 */
- (instancetype)initWithKey:(NSString *)key
                  nameSpace:(NSString *)nameSpace
                  NS_DESIGNATED_INITIALIZER;

/**
 Creates and returns an initialized PROCacheKey.
 
 The namespace is set to the default namespace.
 
 @param     key
            The key used for cached data.
 @return    The newly created PROCacheKey.
 */
+ (PROCacheKey *)cacheKeyForKey:(NSString *)key;

/**
 Creates and returns an initialized CZCachedKey with the specified values.
 
 @param     key
            The key used for cached data.
 @param     nameSpace
            The namespace in which the key exists.
 @return    The newly created PROCacheKey.
 */
+ (PROCacheKey *)cacheKeyForKey:(NSString *)key
                   nameSpace:(NSString *)nameSpace;

// -----
// @name Properties
// -----

#pragma mark Properties

/**
 The receiver's key.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *key;

/**
 The receiver's namespace.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *nameSpace;

@end
