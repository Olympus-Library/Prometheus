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
#import "PrometheusInternal.h"

#if TARGET_OS_IPHONE
@import UIKit;
#endif


#pragma mark Type Definitions

typedef NS_ENUM(NSUInteger, PRODiskCacheVersion) {
    PRODiskCacheVersionNotFound     = 0,
    PRODiskCacheVersionOne          = 1
};


#pragma mark - Constants and Functions

static const float PROMaxPressureFactor                 = 0.875;
static const NSTimeInterval PROGarbageCollectInterval   = 180.0;

NSString * const PRODiskCacheDefaultDiskPath = @"";
static NSString * const PRODiskCacheDirectoryPrefix = @"PRODiskCache";
static NSString * const PRODiskCacheDirectoryComponentSeparator = @"-";
static NSString * const PRODiskCacheSharedQueueName = @"com.prometheus.PRODiskCache.cache";
static NSString * const PRODiskCacheSharedGCQueueName = @"com.prometheus.PRODiskCache.gc";

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

@property (NS_NONATOMIC_IOSONLY) NSURL *cacheDirectoryURL;
@property (NS_NONATOMIC_IOSONLY) dispatch_queue_t queue;
@property (NS_NONATOMIC_IOSONLY) dispatch_semaphore_t semaphore;
@property (NS_NONATOMIC_IOSONLY) NSMutableDictionary *sizes;
@property (NS_NONATOMIC_IOSONLY) NSMutableDictionary *reads;
@property (NS_NONATOMIC_IOSONLY) NSString *diskPath;
@property (assign) NSUInteger maxMemoryPressure;
@property (assign) NSUInteger currentDiskUsage;
@property (assign) NSUInteger diskCapacity;

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

+ (dispatch_queue_t)sharedGCQueue
{
    static dispatch_queue_t sharedQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedQueue = dispatch_queue_create([PRODiskCacheSharedGCQueueName UTF8String], DISPATCH_QUEUE_SERIAL);
    });
    return sharedQueue;
}

#pragma mark Creating a Disk Cache

- (instancetype)initWithDiskCapacity:(NSUInteger)diskCapacity
                            diskPath:(NSString *)diskPath
{
    if (self = [super init]) {
        self.diskPath = diskPath;
        self.diskCapacity = diskCapacity;
        self.reads = [NSMutableDictionary new];
        self.queue = [PRODiskCache sharedQueue];
        self.maxMemoryPressure = PROMaxPressureFactor * self.diskCapacity;
        
        __weak PRODiskCache *weak = self;
        dispatch_async([PRODiskCache sharedQueue], ^{
            PRODiskCache *strong = weak;
            strong.cacheDirectoryURL = [strong createDirectory:diskPath];
            if (strong.cacheDirectoryURL) {
                [strong load];
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

- (NSURL *)createDirectory:(NSString *)diskPath
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

- (void)load
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
                self.reads[key] = read;
            }
            NSNumber *bytes = properties[NSURLTotalFileAllocatedSizeKey];
            if (bytes && key) {
                self.sizes[key] = bytes;
                self.currentDiskUsage += bytes.unsignedIntegerValue;
            }
        } else {
             NSLog(@"%@", [error localizedDescription]);
        }
    }
}

#pragma mark Garbage Collection

- (void)garbageCollect
{
    NSDate *date = [NSDate date];
    
    __weak PRODiskCache *weak = self;
    dispatch_async(self.queue, ^{
        PRODiskCache *strong = weak;
        [strong garbageCollectWithDate:date];
    });
}

- (void)garbageCollectWithDate:(NSDate *)date
{
    
}

#pragma mark Updating File State

- (void)setReadDate:(NSDate *)date forURL:(NSURL *)fileURL
{
    if (!date || fileURL) {
        return;
    }
    
    BOOL success = [[NSFileManager defaultManager]setAttributes:@{ NSFileModificationDate : date }
                                                   ofItemAtPath:[fileURL path]
                                                          error:nil];
    if (success) {
        NSString *key = [self keyForFileURL:fileURL];
        if (key) {
            [self lock:^{
                self.reads[key] = date;
            }];
        }
    }
}

#pragma mark Getting and Storing Cached Objects

- (void)cachedDataForKey:(NSString *)key
              completion:(PROCacheReadWriteCompletion)completion
{
    key = [key copy];
    
    __weak PRODiskCache *weak = self;
    
    if (!completion) {
        return;
    } else if (!key) {
        completion(weak, key, nil);
        return;
    }
    
    dispatch_async(self.queue, ^{
        PRODiskCache *strong = weak;
        PROCachedData *data = [strong cachedDataForKey:key];
        completion(weak, key, data);
    });
}

- (void)storeCachedData:(PROCachedData *)data
                 forKey:(NSString *)key
             completion:(PROCacheReadWriteCompletion)completion
{
    key = [key copy];
    
    __weak PRODiskCache *weak = self;
    
    if (!key) {
        if (completion) {
            completion(weak, key, nil);
        }
        return;
    }
    
    dispatch_async(self.queue, ^{
        PRODiskCache *strong = weak;
        BOOL success = [strong storeCachedData:data forKey:key];
        completion(weak, key, success ? data : nil);
    });
}

- (PROCachedData *)cachedDataForKey:(NSString *)key
{
    if (!key) {
        return nil;
    }
    
    NSDate *date = [NSDate date];
    
    NSURL *fileURL = [self fileURLForKey:key];
    if ([[NSFileManager defaultManager]fileExistsAtPath:[fileURL path]]) {
        @try {
            PROCachedData *data = [NSKeyedUnarchiver unarchiveObjectWithFile:fileURL.path];
            [self setReadDate:date forURL:fileURL];
            return data;
        }
        @catch (NSException *exception) {
            [[NSFileManager defaultManager]removeItemAtURL:fileURL error:nil];
        }
    }
    return nil;
}

- (BOOL)storeCachedData:(PROCachedData *)data forKey:(NSString *)key
{
    key = [key copy];
    
    if (!key || !data) {
        return NO;
    }
    
    NSDate *date = [NSDate date];
    
    NSURL *fileURL = [self fileURLForKey:key];
    
    BOOL success = [NSKeyedArchiver archiveRootObject:data toFile:fileURL.path];
    if (success) {
        [self setReadDate:date forURL:fileURL];
        
        NSDictionary *values = [fileURL resourceValuesForKeys:@[ NSURLTotalFileAllocatedSizeKey ] error:nil];
        NSNumber *size = values[NSURLTotalFileAllocatedSizeKey];
        if (size) {
            NSNumber *previous = self.sizes[key];
            self.currentDiskUsage -= [previous unsignedIntegerValue];
            
            self.sizes[key] = size;
            self.currentDiskUsage += [size unsignedIntegerValue];
        }
        
        if (self.currentDiskUsage >= self.maxMemoryPressure) {
            [self garbageCollect];
        }
    }
    
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

#pragma mark Locking

- (void)lock:(void (^)(void))block
{
    if (!block) {
        return;
    }
    
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    block();
    dispatch_semaphore_signal(self.semaphore);
}

@end
