//
//  PROCacheKeyTests.m
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
#import "PROCacheKey.h"


#pragma mark - PROCacheKeyTests Interface

@interface PROCacheKeyTests : XCTestCase

@end


#pragma mark - PROCacheKeyTests Implementation

@implementation PROCacheKeyTests

- (void)testDesignatedInitializer
{
    NSMutableString *key = [NSMutableString stringWithString:@"key"];
    NSMutableString *nameSpace = [NSMutableString stringWithString:@"nameSpace"];
    PROCacheKey *cacheKey = [[PROCacheKey alloc]initWithKey:key nameSpace:nameSpace];
    [key appendString:@"modification"];
    [nameSpace appendString:@"modification"];
    XCTAssertNotEqual(cacheKey.key, key);
    XCTAssertNotEqual(cacheKey.nameSpace, nameSpace);
    XCTAssertNotEqualObjects(cacheKey.key, key);
    XCTAssertNotEqualObjects(cacheKey.nameSpace, nameSpace);
    XCTAssertEqualObjects([NSMutableString stringWithString:@"key"], cacheKey.key);
    XCTAssertEqualObjects([NSMutableString stringWithString:@"nameSpace"], cacheKey.nameSpace);
}

- (void)testInitWithDefaultNamespace
{
    PROCacheKey *cacheKey = [[PROCacheKey alloc]initWithKey:@"key"];
    XCTAssertEqualObjects(PROCacheKeyDefaultNameSpace, cacheKey.nameSpace);
}

- (void)testNSCopying
{
    PROCacheKey *cacheKey = [[PROCacheKey alloc]initWithKey:@"key"];
    PROCacheKey *copy = [cacheKey copy];
    XCTAssertNotEqual(cacheKey, copy);
    XCTAssertEqualObjects(cacheKey, copy);
}

- (void)testIsEqualsAndHash
{
    PROCacheKey *firstKey = [[PROCacheKey alloc]initWithKey:@"key"];
    PROCacheKey *secondKey = [[PROCacheKey alloc]initWithKey:@"key"];
    XCTAssertEqualObjects(firstKey, secondKey);
    XCTAssertEqual([firstKey hash], [secondKey hash]);
}

- (void)testNSCoding
{
    PROCacheKey *cacheKey = [[PROCacheKey alloc]initWithKey:@"key"];
    NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:cacheKey];
    PROCacheKey *unarchived = [NSKeyedUnarchiver unarchiveObjectWithData:archive];
    XCTAssertEqualObjects(cacheKey, unarchived);
}

@end
