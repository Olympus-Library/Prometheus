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


#pragma mark - Constants and Functions

static NSTimeInterval DefaultAsyncTestTimeout = 5.0;
static inline dispatch_time_t timeout(NSTimeInterval seconds) {
    return dispatch_time(DISPATCH_TIME_NOW, (int64_t) seconds * NSEC_PER_SEC);
}


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
    PROMemoryCache *cache = [[PROMemoryCache alloc]initWithMemoryCapacity:1000];
    XCTAssertEqual(1000, cache.memoryCapacity);
    XCTAssertEqual(0, cache.currentMemoryUsage);
    XCTAssertEqual(YES, cache.removesAllCachedDataOnMemoryWarning);
    XCTAssertEqual(YES, cache.removesAllCachedDataOnEnteringBackground);
}

#pragma mark Asynchronous Test

- (void)testCachedDataForKeyCompletion
{
    PROMemoryCache *cache = [[PROMemoryCache alloc]initWithMemoryCapacity:1000];
    PROCachedData *expected = [self randomCachedDataWithLifetime:10];
    [cache storeCachedData:expected forKey:@"test"];
    
    __block PROCachedData *actual = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [cache cachedDataForKey:@"test" completion:^(NSString *key, PROCachedData *data) {
        actual = data;
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, timeout(DefaultAsyncTestTimeout));
    
    XCTAssertEqualObjects(expected, actual);
    XCTAssertNotNil(cache.reads[@"test"]);
}

- (void)testStoreCachedDataForKeyCompletion
{
    PROMemoryCache *cache = [[PROMemoryCache alloc]initWithMemoryCapacity:1000];
    PROCachedData *expectedData = [self randomCachedDataWithLifetime:10];
    NSString *expectedKey = @"test";
    
    __block NSString *actualKey = nil;
    __block PROCachedData *actualData = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [cache storeCachedData:expectedData forKey:@"test" completion:^(NSString *key, PROCachedData *data) {
        actualKey = key;
        actualData = data;
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, timeout(DefaultAsyncTestTimeout));
    
    XCTAssertNotNil(cache.reads[expectedKey]);
    XCTAssertEqualObjects(expectedKey, actualKey);
    XCTAssertEqualObjects(expectedData, actualData);
    XCTAssertEqualObjects(expectedData, cache.cache[expectedKey]);
}

- (void)testRemoveAllCachedDataWithCompletion
{
    PROMemoryCache *cache = [[PROMemoryCache alloc]initWithMemoryCapacity:256000];
    NSMutableArray *keys = [NSMutableArray new];
    for (int i = 0; i < 1000; ++i) {
        NSString *key = [NSString stringWithFormat:@"test%d", i];
        PROCachedData *data = [self randomCachedDataWithLifetime:60];
        [cache storeCachedData:data forKey:key];
        [keys addObject:key];
    }
    
    __block id<PROCaching> actualCache = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [cache removeAllCachedDataWithCompletion:^(id<PROCaching> cache, BOOL success) {
        actualCache = cache;
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, timeout(DefaultAsyncTestTimeout));
    
    XCTAssertEqual(cache, actualCache);
    XCTAssertEqual(0, cache.currentMemoryUsage);
    for (NSString *key in keys) {
        XCTAssertNil(cache.cache[key]);
        XCTAssertNil(cache.reads[key]);
    }
}

- (void)testRemoveCachedDataForKeyCompletion
{
    PROMemoryCache *cache = [[PROMemoryCache alloc]initWithMemoryCapacity:1000];
    PROCachedData *data = [self randomCachedDataWithLifetime:10];
    [cache storeCachedData:data forKey:@"test"];
    
    __block NSString *actualKey = nil;
    __block PROCachedData *actualData = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [cache removeCachedDataForKey:@"test" completion:^(NSString *key, PROCachedData *data) {
        actualKey = key;
        actualData = data;
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, timeout(DefaultAsyncTestTimeout));
    
    XCTAssertNil(actualData);
    XCTAssertEqualObjects(@"test", actualKey);
    XCTAssertEqual(0, cache.currentMemoryUsage);
}

#pragma mark Synchronous Tests

- (void)testCachedDataForKey
{
    PROMemoryCache *cache = [[PROMemoryCache alloc]initWithMemoryCapacity:1000];
    PROCachedData *expected = [self randomCachedDataWithLifetime:10];
    [cache storeCachedData:expected forKey:@"test"];
    
    PROCachedData *actual = [cache cachedDataForKey:@"test"];
    
    XCTAssertEqualObjects(expected, actual);
    XCTAssertNotNil(cache.reads[@"test"]);
}

- (void)testStoreCachedDataForKey
{
    PROMemoryCache *cache = [[PROMemoryCache alloc]initWithMemoryCapacity:1000];
    PROCachedData *expected = [self randomCachedDataWithLifetime:10];
    
    [cache storeCachedData:expected forKey:@"test"];
    
    PROCachedData *actual = [cache.cache objectForKey:@"test"];
    XCTAssertEqual(expected.size, cache.currentMemoryUsage);
    XCTAssertEqualObjects(expected, actual);
    XCTAssertNotNil(cache.reads[@"test"]);
}

- (void)testRemoveAllCachedData
{
    PROMemoryCache *cache = [[PROMemoryCache alloc]initWithMemoryCapacity:256000];
    NSMutableArray *keys = [NSMutableArray new];
    for (int i = 0; i < 1000; ++i) {
        NSString *key = [NSString stringWithFormat:@"test%d", i];
        PROCachedData *data = [self randomCachedDataWithLifetime:60];
        [cache storeCachedData:data forKey:key];
        [keys addObject:key];
    }
    
    [cache removeAllCachedData];
    
    XCTAssertEqual(0, cache.currentMemoryUsage);
    for (NSString *key in keys) {
        XCTAssertNil(cache.cache[key]);
        XCTAssertNil(cache.reads[key]);
    }
}

- (void)testRemoveCachedDataForKey
{
    PROMemoryCache *cache = [[PROMemoryCache alloc]initWithMemoryCapacity:1000];
    PROCachedData *expected = [self randomCachedDataWithLifetime:10];
    [cache storeCachedData:expected forKey:@"test"];
    
    [cache removeCachedDataForKey:@"test"];
    
    XCTAssertNil(cache.cache[@"test"]);
    XCTAssertNil(cache.reads[@"test"]);
    XCTAssertEqual(0, cache.currentMemoryUsage);
}

#pragma mark Deadlock Tests

- (void)testForDeadlock
{
    PROMemoryCache *cache = [[PROMemoryCache alloc]initWithMemoryCapacity:2560000];
    PROCachedData *expected = [self randomCachedDataWithLifetime:10];
    
    [cache storeCachedData:expected forKey:@"test"];
    
    dispatch_queue_t queue = dispatch_queue_create("test.prometheus.memory", DISPATCH_QUEUE_CONCURRENT);
    
    int numFetches = 10000;
    __block NSUInteger completedFetches = 0;
    NSLock *fetchLock = [NSLock new];
    dispatch_group_t group = dispatch_group_create();
    for (int i = 0; i < numFetches; ++i) {
        dispatch_group_async(group, queue, ^{
            [cache cachedDataForKey:@"test"];
            [fetchLock lock];
            completedFetches++;
            [fetchLock unlock];
        });
    }
    
    dispatch_group_wait(group, timeout(DefaultAsyncTestTimeout));
    XCTAssertTrue(numFetches == completedFetches, @"didn't complete fetches, possibly due to deadlock.");
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
