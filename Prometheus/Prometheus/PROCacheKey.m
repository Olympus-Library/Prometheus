//
//  PROCacheKey.m
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

#import "PROCacheKey.h"


#pragma mark - Constants

static const NSUInteger HashPrime           = 31;
NSString * const PROCacheKeyDefaultNameSpace = @"com.prometheus.cache";


#pragma mark - PROCacheKey Implementation

@implementation PROCacheKey

#pragma mark Creating a Cache Key

- (instancetype)initWithKey:(NSString *)key
{
    return [self initWithKey:key nameSpace:PROCacheKeyDefaultNameSpace];
}

- (instancetype)initWithKey:(NSString *)key
                  nameSpace:(NSString *)nameSpace
{
    if (self = [super init]) {
        _key        = [key copy];
        _nameSpace  = [nameSpace copy];
    }
    return self;
}

+ (PROCacheKey *)cacheKeyForKey:(NSString *)key
{
    return [[PROCacheKey alloc]initWithKey:key];
}

+ (PROCacheKey *)cacheKeyForKey:(NSString *)key
                     nameSpace:(NSString *)nameSpace
{
    return [[PROCacheKey alloc]initWithKey:key nameSpace:nameSpace];
}

#pragma mark NSObject

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[PROCacheKey class]]) {
        PROCacheKey *other = (PROCacheKey *)object;
        return ([other.key isEqualToString:self.key] &&
                [other.nameSpace isEqualToString:self.nameSpace]);
    }
    return NO;
}

- (NSUInteger)hash
{
    return HashPrime * [self.key hash] * [self.nameSpace hash];
}

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    NSString *key       = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"key"];
    NSString *nameSpace = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"nameSpace"];
    self = [self initWithKey:key nameSpace:nameSpace];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.key forKey:@"key"];
    [aCoder encodeObject:self.nameSpace forKey:@"nameSpace"];
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [PROCacheKey cacheKeyForKey:self.key nameSpace:self.nameSpace];
}

#pragma mark NSSecondCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

@end
