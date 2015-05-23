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
#if TARGET_OS_IPHONE
@import UIKit;
#endif


#pragma mark Type Definitions

typedef NS_ENUM(NSUInteger, PRODiskCacheVersion) {
    PRODiskCacheVersionNotFound     = 0,
    PRODiskCacheVersionOne          = 1
};


#pragma mark - Constants and Functions

NSString * const PRODiskCacheDefaultDiskPath = @"";
static NSString * const PRODiskCacheDirectoryPrefix = @"PRODiskCache";
static NSString * const PRODiskCacheDirectoryComponentSeparator = @"-";
static NSString * const PRODiskCacheSharedQueueName = @"com.prometheus.PRODiskCache";

static inline PRODiskCacheVersion PRODiskCacheCurrentVersion() {
    return PRODiskCacheVersionOne;
}

static const CFStringRef PRODiskCacheEscapeCharacters = (__bridge CFStringRef)@".:/";
static inline NSString * PRODiskCacheDirectoryName(PRODiskCacheVersion version) {
    return [NSString stringWithFormat:@"%@-%lu", PRODiskCacheDirectoryPrefix, version];
}

static inline NSString * encodeString(NSString *string) {
    if (!string) {
        return nil;
    } else if (!string.length) {
        return @"";
    }
    return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                     (__bridge CFStringRef)string, NULL,
                                                                     PRODiskCacheEscapeCharacters,
                                                                     kCFStringEncodingUTF8));
}

static inline NSString * decodeString(NSString *string) {
    if (!string) {
        return nil;
    } else if (!string.length) {
        return @"";
    }
    return CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                     (__bridge CFStringRef)string,
                                                                                     (__bridge CFStringRef)@"",
                                                                                     kCFStringEncodingUTF8));
}


#pragma mark - PRODiskCache Class Extension

@interface PRODiskCache ()

@property (readonly) NSURL *cacheDirectoryURL;
@property (readonly) dispatch_queue_t queue;
@property (readonly) NSMutableDictionary *sizes;
@property (readonly) NSMutableDictionary *reads;

@end


#pragma mark - PRODiskCache Implementation

@implementation PRODiskCache

+ (dispatch_queue_t)sharedQueue
{
    static dispatch_queue_t sharedQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedQueue = dispatch_queue_create([PRODiskCacheSharedQueueName UTF8String], DISPATCH_QUEUE_SERIAL);
    });
    return sharedQueue;
}

#pragma mark Creating a Disk Cache

- (instancetype)initWithDiskCapacity:(NSUInteger)diskCapacity
                            diskPath:(NSString *)diskPath
{
    if (self = [super init]) {
        _diskPath = diskPath;
        _diskCapacity = diskCapacity;
        _queue = [PRODiskCache sharedQueue];
        _reads = [NSMutableDictionary new];
        
        __weak PRODiskCache *weak = self;
        dispatch_async(_queue, ^{
            PRODiskCache *strong = weak;
            strong->_cacheDirectoryURL = [strong createDirectoryIfNecessaryAtDiskPath:diskPath];
            if (strong.cacheDirectoryURL) {
                [strong loadCacheState];
            }
        });
    }
    return self;
}

#pragma mark Creating Key

- (NSString *)keyForFileURL:(NSURL *)fileURL
{
    return decodeString([fileURL lastPathComponent]);
}

- (NSURL *)fileURLForKey:(NSString *)key
{
    return [self.cacheDirectoryURL URLByAppendingPathComponent:encodeString(key)];
}

#pragma mark Initializing State

- (NSURL *)createDirectoryIfNecessaryAtDiskPath:(NSString *)diskPath
{
    
    NSArray *directoryURLs = [[NSFileManager defaultManager]URLsForDirectory:NSCachesDirectory
                                                                 inDomains:NSUserDomainMask];
    if ([directoryURLs count] == 0){
        return nil;
    }
    
    NSError *error;
    NSString *directoryName = PRODiskCacheDirectoryName(PRODiskCacheCurrentVersion());
    NSURL *cacheDirectoryURL = [NSURL fileURLWithPathComponents:@[directoryURLs[0], directoryName]];
    [[NSFileManager defaultManager]createDirectoryAtURL:cacheDirectoryURL
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:&error];
    if (![[NSFileManager defaultManager]fileExistsAtPath:[cacheDirectoryURL path]]) {
        NSLog(@"%@", [error localizedDescription]);
        return nil;
    }
    
    return cacheDirectoryURL;
}

- (void)loadCacheState
{
    NSError *error;
    NSArray *propertyKeys = @[NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey];
    NSArray *fileURLs = [[NSFileManager defaultManager]contentsOfDirectoryAtURL:_cacheDirectoryURL
                                                     includingPropertiesForKeys:propertyKeys
                                                                        options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                          error:&error];
    if (!fileURLs) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    
    for (NSURL *fileURL in fileURLs) {
        error = nil;
        NSString *key = [self keyForFileURL:fileURL];
        NSDictionary *properties = [fileURL resourceValuesForKeys:propertyKeys
                                                            error:&error];
        if (properties) {
            NSDate *read = properties[NSURLContentModificationDateKey];
            if (read && key) {
                _reads[key] = read;
            }
            NSNumber *bytes = properties[NSURLTotalFileAllocatedSizeKey];
            if (bytes && key) {
                _sizes[key] = bytes;
                _currentDiskUsage += bytes.unsignedIntegerValue;
            }
        } else {
             NSLog(@"%@", [error localizedDescription]);
        }
    }
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
