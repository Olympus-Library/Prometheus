//
//  PROCachedData.m
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

#import "PROCachedData.h"


#pragma mark - Constants

NSTimeInterval PROCachedDataMaxExpiration    = -1.0;
static const NSUInteger HashPrime           = 17;


#pragma mark - PROCachedData Implementation

@implementation PROCachedData

#pragma mark Creating Cached Data

- (instancetype)initWithData:(NSData *)data
                    lifetime:(NSTimeInterval)lifetime
{
    return [self initWithData:data
                     lifetime:lifetime
                storagePolicy:CZCacheStoragePolicyAllowed];
}

- (instancetype)initWithData:(NSData *)data
                    lifetime:(NSTimeInterval)lifetime
               storagePolicy:(CZCacheStoragePolicy)storagePolicy
{
    return [self initWithData:data
                     lifetime:lifetime
                storagePolicy:storagePolicy
                    timestamp:[NSDate date]];
}

- (instancetype)initWithData:(NSData *)data
                    lifetime:(NSTimeInterval)lifetime
               storagePolicy:(CZCacheStoragePolicy)storagePolicy
                   timestamp:(NSDate *)timestamp
{
    if (self = [super init]) {
        _data           = [data copy];
        _lifetime       = lifetime;
        _storagePolicy  = storagePolicy;
        _timestamp      = [timestamp copy];
        if (_lifetime > 0) {
            _expiration = [_timestamp dateByAddingTimeInterval:_lifetime];
        } else {
            _expiration = nil;
        }
    }
    return self;
}

+ (PROCachedData *)cachedDataWithData:(NSData *)data lifetime:(NSTimeInterval)lifetime
{
    return [[PROCachedData alloc]initWithData:data lifetime:lifetime];
}

+ (PROCachedData *)cachedDataWithData:(NSData *)data
                            lifetime:(NSTimeInterval)lifetime
                       storagePolicy:(CZCacheStoragePolicy)storagePolicy
{
    return [[PROCachedData alloc]initWithData:data
                                    lifetime:lifetime
                               storagePolicy:storagePolicy];
}

+ (PROCachedData *)cachedDataWithData:(NSData *)data
                            lifetime:(NSTimeInterval)lifetime
                       storagePolicy:(CZCacheStoragePolicy)storagePolicy
                           timestamp:(NSDate *)timestamp
{
    return [[PROCachedData alloc]initWithData:data
                                    lifetime:lifetime
                               storagePolicy:storagePolicy
                                   timestamp:timestamp];
}

#pragma mark NSObject

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[PROCachedData class]]) {
        PROCachedData *other = (PROCachedData *)object;
        return ([other.data isEqualToData:self.data] &&
                other.storagePolicy == self.storagePolicy &&
                other.lifetime == self.lifetime &&
                [other.timestamp isEqualToDate:self.timestamp] &&
                [other.expiration isEqualToDate:self.expiration]);
    }
    return NO;
}

- (NSUInteger)hash
{
    return HashPrime * [self.data hash] *
    ([self.expiration hash] ^ [self.timestamp hash] ^ self.storagePolicy);
}

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    NSData *data = [aDecoder decodeObjectOfClass:[NSData class] forKey:@"data"];
    NSTimeInterval lifetime = [aDecoder decodeDoubleForKey:@"lifetime"];
    CZCacheStoragePolicy storagePolicy = [aDecoder decodeIntegerForKey:@"storagePolicy"];
    self = [self initWithData:data lifetime:lifetime storagePolicy:storagePolicy];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.data forKey:@"data"];
    [aCoder encodeInteger:self.storagePolicy forKey:@"storagePolicy"];
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [PROCachedData cachedDataWithData:self.data
                                   lifetime:self.lifetime
                              storagePolicy:self.storagePolicy];
}

#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

@end
