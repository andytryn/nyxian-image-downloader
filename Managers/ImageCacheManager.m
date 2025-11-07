//
// ImageCacheManager.m
// File
//
// Created by Anonym on 07.11.25.
//

#import "ImageCacheManager.h"

@implementation ImageCacheManager

+ (instancetype)sharedManager {
	static ImageCacheManager *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});
	return sharedInstance;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		[self setupCacheDirectory];
	}
	return self;
}

- (void)setupCacheDirectory {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *cacheDir = [self getCacheDirectory];
	
	BOOL isDirectory = NO;
	if (![fileManager fileExistsAtPath:cacheDir isDirectory:&isDirectory]) {
		NSError *error = nil;
		[fileManager createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:&error];
		if (error) {
			NSLog(@"Error creating cache directory: %@", error.localizedDescription);
		}
	}
}

- (NSString *)getCacheDirectory {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *cachesDirectory = [paths objectAtIndex:0];
	NSString *imageCacheDirectory = [cachesDirectory stringByAppendingPathComponent:@"ImageCache"];
	return imageCacheDirectory;
}

- (NSString *)cacheKeyForURL:(NSString *)urlString {
	// Create hash from URL using NSString hash (simple but effective for cache keys)
	// Sanitize URL for filename by replacing invalid characters
	NSString *sanitized = [urlString stringByReplacingOccurrencesOfString:@"://" withString:@"_"];
	sanitized = [sanitized stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
	sanitized = [sanitized stringByReplacingOccurrencesOfString:@"?" withString:@"_"];
	sanitized = [sanitized stringByReplacingOccurrencesOfString:@"&" withString:@"_"];
	sanitized = [sanitized stringByReplacingOccurrencesOfString:@"=" withString:@"_"];
	sanitized = [sanitized stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	
	// Use hash value for uniqueness
	NSUInteger hashValue = [urlString hash];
	NSString *hash = [NSString stringWithFormat:@"%lu", (unsigned long)hashValue];
	
	// Combine sanitized URL with hash for better uniqueness
	return [NSString stringWithFormat:@"%@_%@", hash, sanitized];
}

- (NSString *)cachePathForURL:(NSString *)urlString {
	NSString *cacheKey = [self cacheKeyForURL:urlString];
	NSString *cacheDir = [self getCacheDirectory];
	
	// Try to get extension from URL
	NSString *extension = @"jpg";
	NSURL *url = [NSURL URLWithString:urlString];
	if (url) {
		NSString *pathExtension = url.pathExtension;
		if (pathExtension && pathExtension.length > 0) {
			extension = pathExtension;
		}
	}
	
	NSString *filename = [NSString stringWithFormat:@"%@.%@", cacheKey, extension];
	return [cacheDir stringByAppendingPathComponent:filename];
}

- (BOOL)hasCachedImageForURL:(NSString *)urlString {
	NSString *cachePath = [self cachePathForURL:urlString];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	return [fileManager fileExistsAtPath:cachePath];
}

- (UIImage *)cachedImageForURL:(NSString *)urlString {
	NSString *cachePath = [self cachePathForURL:urlString];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if ([fileManager fileExistsAtPath:cachePath]) {
		UIImage *image = [UIImage imageWithContentsOfFile:cachePath];
		return image;
	}
	
	return nil;
}

- (void)cacheImage:(UIImage *)image forURL:(NSString *)urlString {
	if (!image || !urlString) {
		return;
	}
	
	NSString *cachePath = [self cachePathForURL:urlString];
	NSData *imageData = UIImageJPEGRepresentation(image, 0.9);
	
	if (imageData) {
		[imageData writeToFile:cachePath atomically:YES];
	}
}

- (void)saveImageData:(NSData *)imageData forURL:(NSString *)urlString completion:(void (^)(BOOL success, NSString *cachePath))completion {
	if (!imageData || !urlString) {
		if (completion) {
			completion(NO, nil);
		}
		return;
	}
	
	NSString *cachePath = [self cachePathForURL:urlString];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		BOOL success = [imageData writeToFile:cachePath atomically:YES];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (completion) {
				completion(success, cachePath);
			}
		});
	});
}

- (void)clearCache {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *cacheDir = [self getCacheDirectory];
	
	NSError *error = nil;
	NSArray *files = [fileManager contentsOfDirectoryAtPath:cacheDir error:&error];
	
	if (!error) {
		for (NSString *file in files) {
			NSString *filePath = [cacheDir stringByAppendingPathComponent:file];
			[fileManager removeItemAtPath:filePath error:&error];
		}
	}
}

@end

