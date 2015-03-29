//
//  PROMemoryCacheTests.m
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

@import XCTest;
#import "PROMemoryCache.h"
#import "PROCachedData.h"
#import "PROCacheKey.h"


#pragma mark - PROMemoryCache Private Category Interface

@interface PROMemoryCache (Private)

@property (readonly) dispatch_queue_t       queue;
@property (readonly) NSMutableDictionary    *reads;
@property (readonly) NSMutableDictionary    *cache;

@end


#pragma mark - PROMemoryCacheTests Interface

@interface PROMemoryCacheTests : XCTestCase

@end


#pragma mark - PROMemoryCacheTests Implementation

@implementation PROMemoryCacheTests

- (void)testDesignatedInitializer
{
    PROMemoryCache *cache = [[PROMemoryCache alloc]initWithMemoryCapacity:0];
    XCTAssertEqual(0, cache.memoryCapacity);
    XCTAssertEqual(0, cache.currentMemoryUsage);
    XCTAssertEqual(YES, cache.removesAllCachedDataOnMemoryWarning);
    XCTAssertEqual(YES, cache.removesAllCachedDataOnEnteringBackground);
}

#pragma mark Synchronous Tests

- (void)testStoreCachedDataForKey
{
    PROMemoryCache *cache = [[PROMemoryCache alloc]initWithMemoryCapacity:1000];
    PROCachedData *expected = [self randomCachedDataWithLifetime:10];
    PROCacheKey *key = [PROCacheKey cacheKeyForKey:@"test"];
    
    [cache storeCachedData:expected forKey:key];
    
    PROCachedData *actual = [cache.cache objectForKey:key];
    XCTAssertEqual(expected.size, cache.currentMemoryUsage);
    XCTAssertEqualObjects(expected, actual);
    XCTAssertNotNil(cache.reads[key]);
}

- (void)testCachedDataForKey
{
    PROMemoryCache *cache = [[PROMemoryCache alloc]initWithMemoryCapacity:1000];
    PROCachedData *expected = [self randomCachedDataWithLifetime:10];
    PROCacheKey *key = [PROCacheKey cacheKeyForKey:@"test"];
    cache.cache[key] = expected;
    
    PROCachedData *actual = [cache cachedDataForKey:key];
    
    XCTAssertEqualObjects(expected, actual);
    XCTAssertNotNil(cache.reads[key]);
}

- (void)testRemoveAllCachedData
{
    PROMemoryCache *cache = [[PROMemoryCache alloc]initWithMemoryCapacity:256000];
    NSMutableArray *keys = [NSMutableArray new];
    for (int i = 0; i < 1000; ++i) {
        PROCacheKey *key = [PROCacheKey cacheKeyForKey:[NSString stringWithFormat:@"test%d", i]];
        PROCachedData *data = [self randomCachedDataWithLifetime:60];
        cache.cache[key] = data;
        cache.reads[key] = [NSDate date];
        [keys addObject:key];
    }
    
    [cache removeAllCachedData];
    
    XCTAssertEqual(0, cache.currentMemoryUsage);
    for (PROCacheKey *key in keys) {
        XCTAssertNil(cache.cache[key]);
        XCTAssertNil(cache.reads[key]);
    }
}

- (void)testRemoveCachedDataForKey
{
    PROMemoryCache *cache = [[PROMemoryCache alloc]initWithMemoryCapacity:1000];
    
    
    
}

#pragma mark Helper

- (PROCachedData *)randomCachedDataWithLifetime:(NSTimeInterval)lifetime
{
    NSUInteger length = arc4random() % 256;
    // this is pretty sketchy, only use for testing!
    NSMutableData *data = [NSMutableData dataWithBytes:malloc(length)
                                                length:length];
    return [PROCachedData cachedDataWithData:data lifetime:lifetime];
}

@end
