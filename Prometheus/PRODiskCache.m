//
//  CZDiskCache.m
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

#import "PRODiskCache.h"


#pragma mark - Constants

static NSString * const PRODiskCacheDirectoryPrefix = @"PRODiskCache";
static NSString * const PRODiskCacheDirectoryComponentSeparator = @"-";
static NSString * const PRODiskCacheSharedQueueName = @"com.prometheus.PRODiskCache";


#pragma mark - PRODiskCache Class Extension

@interface PRODiskCache ()

@property (readonly) NSURL *cacheDirectoryURL;
@property (readonly) dispatch_queue_t queue;
@property (readonly) NSMutableDictionary *reads;

@end
#pragma mark - Constants

typedef NS_ENUM(NSUInteger, PRODiskCacheVersion) {
    PRODiskCacheVersionUnknown  = 0,
    PRODiskCacheVersionOne      = 1
};


#pragma mark - PRODiskCache Implementation

@implementation PRODiskCache

#pragma mark Creating a Disk Cache

- (instancetype)initWithDiskCapacity:(NSUInteger)diskCapacity
                            diskPath:(NSString *)diskPath
{
    if (self = [super init]) {
        _diskPath = diskPath;
        _diskCapacity = diskCapacity;
        _queue = [PRODiskCache sharedQueue];
        _reads = [NSMutableDictionary new];
        
        PRODiskCacheVersion version = [PRODiskCache discoverLatestDiskCacheVersionAtDiskPath:diskPath];
        if (version == PRODiskCacheVersionUnknown) {
            // TODO: create cache directory
        } else if (version == PRODiskCacheVersionOne) {
            // TODO: use cache directory
        }
    }
    return self;
}

- (void)createCacheDirectoryAtDiskPath:(NSString *)diskPath
{
    
}

+ (PRODiskCacheVersion)discoverLatestDiskCacheVersionAtDiskPath:(NSString *)diskPath
{
    NSError *error;
    NSArray *directories = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:diskPath
                                                                              error:&error];
    PRODiskCacheVersion highestVersion = PRODiskCacheVersionUnknown;
    if (directories) {
        for (NSString *directory in directories) {
            NSArray *components = [directory componentsSeparatedByString:PRODiskCacheDirectoryComponentSeparator];
            @try {
                // TODO: logic here needs to change if we ever add more versions
                NSString *versionComponent = components[1];
                PRODiskCacheVersion version = [versionComponent integerValue];
                if (version == PRODiskCacheVersionOne) {
                    highestVersion = version;
                }
            } @catch (NSException *exception) {
                continue; // nothing to do
            }
        }
    } else if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    return highestVersion;
}


+ (dispatch_queue_t)sharedQueue
{
    static dispatch_queue_t sharedQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedQueue = dispatch_queue_create([PRODiskCacheSharedQueueName UTF8String], DISPATCH_QUEUE_SERIAL);
    });
    return sharedQueue;
}

#pragma mark Getting and Storing Cached Objects

- (void)cachedDataForKey:(NSString *)key
              completion:(PROCacheReadWriteCompletion)completion
{
    
}

- (void)storeCachedData:(PROCachedData *)data
                 forKey:(NSString *)key
             completion:(PROCacheReadWriteCompletion)completion
{
    
}

- (PROCachedData *)cachedDataForKey:(NSString *)key
{
    return nil;
}

- (BOOL)storeCachedData:(PROCachedData *)data forKey:(NSString *)key
{
    return NO;
}

#pragma mark Removing Cached Objects

- (void)removeAllCachedDataWithCompletion:(PROCacheOperationCompletion)completion
{
    
}

- (void)removeCachedDataForKey:(NSString *)key
                    completion:(PROCacheReadWriteCompletion)completion
{
    
}


- (void)removeAllCachedData
{
    
}

- (void)removeCachedDataForKey:(NSString *)key
{
    
}

@end
