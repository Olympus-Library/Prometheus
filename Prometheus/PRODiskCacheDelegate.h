//
//  PRODiskCacheDelegate.h
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


#pragma mark - Forward Declarations

@class PROCachedData;


#pragma mark - PRODiskCacheDelegate Protocol

/**
 */
@protocol PRODiskCacheDelegate <NSObject>

@optional

/**
 */
- (PROCacheEvictExpiredDataDecision)cache:(__weak id<PRODiskCaching>)cache
           shouldEvictExpiredDataFromDisk:(PROCachedData *)data;

/**
 */
- (PROCacheEvictLRUDataDecision)cache:(__weak id<PRODiskCaching>)cache
           shouldEvictLRUDataFromDisk:(PROCachedData *)data;

/**
 */
- (void)cache:(__weak id<PRODiskCaching>)cache willEvictExpiredDataFromDisk:(PROCachedData *)data;

/**
 */
- (void)cache:(__weak id<PRODiskCaching>)cache didEvictExpiredDataFromDisk:(PROCachedData *)data;

/**
 */
- (void)cache:(__weak id<PRODiskCaching>)cache willEvictLRUDataFromDisk:(PROCachedData *)data;

/**
 */
- (void)cache:(__weak id<PRODiskCaching>)cache didEvictLRUDataFromDisk:(PROCachedData *)data;

/**
 Determines whether the cache should use the cached data on disk for the given
 version.
 */
- (BOOL)cache:(id<PRODiskCaching>)cache shouldUseDiskCacheVersion:(NSString *)version;

/**
 Migrates the disk cache from the given version.
 */
- (void)cache:(id<PRODiskCaching>)cache migrateFromDiskCacheVersion:(NSString *)version;

@end
