/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"

typedef NS_ENUM(NSInteger, DataCacheType) {
    /**
     * The data wasn't available the DataCache caches, but was downloaded from the web.
     */
    DataCacheTypeNone,
    /**
     * The data was obtained from the disk cache.
     */
    DataCacheTypeDisk,
    /**
     * The data was obtained from the memory cache.
     */
    DataCacheTypeMemory
};

typedef void(^DataCacheQueryCompletedBlock)(NSData *data, DataCacheType cacheType);

typedef void(^DataCacheCheckCacheCompletionBlock)(BOOL isInCache);

typedef void(^DataCacheCalculateSizeBlock)(NSUInteger fileCount, NSUInteger totalSize);

/**
 * DataCache maintains a memory cache and an optional disk cache. Disk cache write operations are performed
 * asynchronous so it doesn’t add unnecessary latency to the UI.
 */
@interface DataCache : NSObject

/**
 * The maximum "total cost" of the in-memory image cache. The cost function is the number of pixels held in memory.
 */
@property (assign, nonatomic) NSUInteger maxMemoryCost;

/**
 * The maximum length of time to keep an image in the cache, in seconds
 */
@property (assign, nonatomic) NSInteger maxCacheAge;

/**
 * The maximum size of the cache, in bytes.
 */
@property (assign, nonatomic) NSUInteger maxCacheSize;

/**
 * Returns global shared cache instance
 *
 * @return DataCache global instance
 */
+ (DataCache *)sharedDataCache;

/**
 * Init a new cache store with a specific namespace
 *
 * @param ns The namespace to use for this cache store
 */
- (id)initWithNamespace:(NSString *)ns;

/**
 * Add a read-only cache path to search for images pre-cached by DataCache
 * Useful if you want to bundle pre-loaded images with your app
 *
 * @param path The path to use for this read-only cache path
 */
- (void)addReadOnlyCachePath:(NSString *)path;

/**
 * Store data into memory and disk cache at the given key.
 *
 * @param image The image to store
 * @param key   The unique image cache key, usually it's image absolute URL
 */
- (void)storeData:(NSData *)data forKey:(NSString *)key;

/**
 * Store data into memory and optionally disk cache at the given key.
 *
 * @param image  The image to store
 * @param key    The unique image cache key, usually it's image absolute URL
 * @param toDisk Store the data to disk cache if YES
 */
- (void)storeData:(NSData *)data forKey:(NSString *)key toDisk:(BOOL)toDisk;

/**
 * Store an image into memory and optionally disk cache at the given key.
 *
 * @param image       The image to store
 * @param recalculate BOOL indicates if imageData can be used or a new data should be constructed from the UIImage
 * @param imageData   The image data as returned by the server, this representation will be used for disk storage
 *                    instead of converting the given image object into a storable/compressed image format in order
 *                    to save quality and CPU
 * @param key         The unique image cache key, usually it's image absolute URL
 * @param toDisk      Store the image to disk cache if YES
 */
- (void)storeData:(NSData *)data recalculateFromData:(BOOL)recalculate forKey:(NSString *)key toDisk:(BOOL)toDisk;

/**
 * Query the disk cache asynchronously.
 *
 * @param key The unique key used to store the wanted image
 */
- (void)queryDiskCacheForKey:(NSString *)key done:(DataCacheQueryCompletedBlock)doneBlock;

/**
 * Query the memory cache synchronously.
 *
 * @param key The unique key used to store the wanted image
 */
- (NSData *)dataFromMemoryCacheForKey:(NSString *)key;

/**
 * Query the disk cache synchronously after checking the memory cache.
 *
 * @param key The unique key used to store the wanted image
 */
- (NSData *)dataFromDiskCacheForKey:(NSString *)key;

/**
 * Remove the image from memory and disk cache synchronously
 *
 * @param key The unique image cache key
 */
- (void)removeDataForKey:(NSString *)key;


/**
 * Remove the image from memory and disk cache synchronously
 *
 * @param key             The unique image cache key
 * @param completion      An block that should be executed after the image has been removed (optional)
 */
- (void)removeDataForKey:(NSString *)key withCompletion:(SDWebImageNoParamsBlock)completion;

/**
 * Remove the image from memory and optionally disk cache synchronously
 *
 * @param key      The unique image cache key
 * @param fromDisk Also remove cache entry from disk if YES
 */
- (void)removeDataForKey:(NSString *)key fromDisk:(BOOL)fromDisk;

/**
 * Remove the image from memory and optionally disk cache synchronously
 *
 * @param key             The unique image cache key
 * @param fromDisk        Also remove cache entry from disk if YES
 * @param completion      An block that should be executed after the image has been removed (optional)
 */
- (void)removeDataForKey:(NSString *)key fromDisk:(BOOL)fromDisk withCompletion:(SDWebImageNoParamsBlock)completion;

/**
 * Clear all memory cached images
 */
- (void)clearMemory;

/**
 * Clear all disk cached images. Non-blocking method - returns immediately.
 * @param completion    An block that should be executed after cache expiration completes (optional)
 */
- (void)clearDiskOnCompletion:(SDWebImageNoParamsBlock)completion;

/**
 * Clear all disk cached images
 * @see clearDiskOnCompletion:
 */
- (void)clearDisk;

/**
 * Remove all expired cached image from disk. Non-blocking method - returns immediately.
 * @param completionBlock An block that should be executed after cache expiration completes (optional)
 */
- (void)cleanDiskWithCompletionBlock:(SDWebImageNoParamsBlock)completionBlock;

/**
 * Remove all expired cached image from disk
 * @see cleanDiskWithCompletionBlock:
 */
- (void)cleanDisk;

/**
 * Get the size used by the disk cache
 */
- (NSUInteger)getSize;

/**
 * Get the number of images in the disk cache
 */
- (NSUInteger)getDiskCount;

/**
 * Asynchronously calculate the disk cache's size.
 */
- (void)calculateSizeWithCompletionBlock:(DataCacheCalculateSizeBlock)completionBlock;

/**
 *  Async check if image exists in disk cache already (does not load the image)
 *
 *  @param key             the key describing the url
 *  @param completionBlock the block to be executed when the check is done.
 *  @note the completion block will be always executed on the main queue
 */
- (void)diskDataExistsWithKey:(NSString *)key completion:(DataCacheCheckCacheCompletionBlock)completionBlock;

/**
 *  Check if image exists in disk cache already (does not load the image)
 *
 *  @param key the key describing the url
 *
 *  @return YES if an image exists for the given key
 */
- (BOOL)diskDataExistsWithKey:(NSString *)key;

/**
 *  Get the cache path for a certain key (needs the cache path root folder)
 *
 *  @param key  the key (can be obtained from url using cacheKeyForURL)
 *  @param path the cach path root folder
 *
 *  @return the cache path
 */
- (NSString *)cachePathForKey:(NSString *)key inPath:(NSString *)path;

/**
 *  Get the default cache path for a certain key
 *
 *  @param key the key (can be obtained from url using cacheKeyForURL)
 *
 *  @return the default cache path
 */
- (NSString *)defaultCachePathForKey:(NSString *)key;

@end
