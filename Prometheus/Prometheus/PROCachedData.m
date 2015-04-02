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

static const NSUInteger HashPrime                   = 17;
const NSTimeInterval PROCachedDataLifetimeInfinity  = DBL_MAX;


#pragma mark - PROCachedData Implementation

@implementation PROCachedData

#pragma mark Creating Cached Data

- (instancetype)initWithData:(NSData *)data
                    lifetime:(NSTimeInterval)lifetime
{
    return [self initWithData:data
                     lifetime:lifetime
                timestamp:[NSDate date]];
}

- (instancetype)initWithData:(NSData *)data
                    lifetime:(NSTimeInterval)lifetime
                   timestamp:(NSDate *)timestamp
{
    if (self = [super init]) {
        if (!data || !timestamp) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:@"nil arguments"
                                         userInfo:nil];
        }
        _data           = [data copy];
        _lifetime       = lifetime;
        _timestamp      = [timestamp copy];
        if (_lifetime > 0) {
            _expiration = [_timestamp dateByAddingTimeInterval:_lifetime];
        } else {
            _expiration = nil;
        }
        _size = [PROCachedData sizeWithData:_data];
        self.storagePolicy  = PROCacheStoragePolicyAllowed;
    }
    return self;
}

+ (PROCachedData *)cachedDataWithData:(NSData *)data lifetime:(NSTimeInterval)lifetime
{
    return [[PROCachedData alloc]initWithData:data lifetime:lifetime];
}

+ (PROCachedData *)cachedDataWithData:(NSData *)data
                            lifetime:(NSTimeInterval)lifetime
                           timestamp:(NSDate *)timestamp
{
    return [[PROCachedData alloc]initWithData:data
                                    lifetime:lifetime
                                   timestamp:timestamp];
}

#pragma mark Adding to Lifetime

- (PROCachedData *)cachedDataByAddingLifetime:(NSTimeInterval)lifetime
{
    NSTimeInterval copyLifetime = self.lifetime + lifetime;
    PROCachedData *copy = [[PROCachedData alloc]initWithData:self.data
                                                    lifetime:copyLifetime
                                                   timestamp:self.timestamp];
    copy.storagePolicy = self.storagePolicy;
    return copy;
}

#pragma mark Private

+ (NSUInteger)sizeWithData:(NSData *)data
{
    static NSUInteger dateSize = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateSize = [NSKeyedArchiver archivedDataWithRootObject:[NSDate date]].length;
    });
    //  data + 2 NSDates (timestamp, expiration) + lifetime + storagePolicy
    return data.length + (2 * dateSize) + sizeof(NSTimeInterval) + sizeof(PROCacheStoragePolicy);
}

#pragma mark NSObject

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[PROCachedData class]]) {
        PROCachedData *other = (PROCachedData *)object;
        if (other.size == self.size &&
            other.storagePolicy == self.storagePolicy &&
            other.lifetime == self.lifetime &&
            [other.timestamp isEqualToDate:self.timestamp] &&
            [other.data isEqualToData:self.data]) {
            return YES;
        }
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
    if (self = [super init]) {
        _size           = [aDecoder decodeIntegerForKey:@"size"];
        _lifetime       = [aDecoder decodeDoubleForKey:@"lifetime"];
        _storagePolicy  = [aDecoder decodeIntegerForKey:@"storagePolicy"];
        _data           = [aDecoder decodeObjectOfClass:[NSData class] forKey:@"data"];
        _timestamp      = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"timestamp"];
        _expiration     = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"expiration"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.data forKey:@"data"];
    [aCoder encodeInteger:self.size forKey:@"size"];
    [aCoder encodeDouble:self.lifetime forKey:@"lifetime"];
    [aCoder encodeObject:self.timestamp forKey:@"timestamp"];
    [aCoder encodeObject:self.expiration forKey:@"expiration"];
    [aCoder encodeInteger:self.storagePolicy forKey:@"storagePolicy"];
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    PROCachedData *copy = [PROCachedData cachedDataWithData:self.data
                                                   lifetime:self.lifetime
                                                  timestamp:self.timestamp];
    copy.storagePolicy = self.storagePolicy;
    return copy;
}

#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

@end
