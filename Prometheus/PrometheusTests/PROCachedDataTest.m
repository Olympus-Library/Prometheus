//
//  PROCachedDataTest.m
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
#import "PROCachedData.h"


#pragma mark - PROCachedDataTests Interface

@interface PROCachedDataTests : XCTestCase

@end


#pragma mark - PROCachedDataTests Implementation

@implementation PROCachedDataTests

- (void)testDesignatedInitializer
{
    NSMutableData *data = [NSMutableData dataWithData:[@"data" dataUsingEncoding:NSUTF8StringEncoding]];
    PROCachedData *cachedData = [[PROCachedData alloc]initWithData:data
                                                        lifetime:0
                                                   storagePolicy:PROCacheStoragePolicyAllowed];
    [data appendData:[@"modification" dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertNotEqual(cachedData.data, data);
    XCTAssertNotEqualObjects(cachedData.data, data);
    XCTAssertEqual(0, cachedData.lifetime);
    XCTAssertEqual(PROCacheStoragePolicyAllowed, cachedData.storagePolicy);
    XCTAssertEqualObjects([@"data" dataUsingEncoding:NSUTF8StringEncoding], cachedData.data);
}

- (void)testInitWithDefaultStoragePolicy
{
    PROCachedData *cachedData = [[PROCachedData alloc]initWithData:[@"data" dataUsingEncoding:NSUTF8StringEncoding]
                                                        lifetime:0];
    XCTAssertEqual(PROCacheStoragePolicyAllowed, cachedData.storagePolicy);
}

- (void)testNSCopying
{
    PROCachedData *cachedData = [PROCachedData cachedDataWithData:[@"data" dataUsingEncoding:NSUTF8StringEncoding]
                                                       lifetime:0];
    PROCachedData *copy = [cachedData copy];
    XCTAssertNotEqual(cachedData, copy);
    XCTAssertEqualObjects(cachedData, copy);
}

- (void)testIsEqualsAndHash
{
    NSDate *date = [NSDate date];
    PROCachedData *firstData = [[PROCachedData alloc]initWithData:[@"data" dataUsingEncoding:NSUTF8StringEncoding]
                                                       lifetime:0
                                                    storagePolicy:PROCacheStoragePolicyAllowed
                                                        timestamp:date];
    PROCachedData *secondData = [[PROCachedData alloc]initWithData:[@"data" dataUsingEncoding:NSUTF8StringEncoding]
                                                          lifetime:0
                                                     storagePolicy:PROCacheStoragePolicyAllowed
                                                         timestamp:date];
    XCTAssertEqualObjects(firstData, secondData);
    XCTAssertEqual([firstData hash], [secondData hash]);
}

- (void)testNSCoding
{
    PROCachedData *cachedData = [[PROCachedData alloc]initWithData:[@"data" dataUsingEncoding:NSUTF8StringEncoding]
                                                        lifetime:0];
    NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:cachedData];
    PROCachedData *unarchived = [NSKeyedUnarchiver unarchiveObjectWithData:archive];
    XCTAssertEqualObjects(cachedData, unarchived);
}

@end