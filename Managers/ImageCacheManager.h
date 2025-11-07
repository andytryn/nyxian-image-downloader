//
// ImageCacheManager.h
// File
//
// Created by Anonym on 07.11.25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifndef IMAGECACHEMANAGER_H
#define IMAGECACHEMANAGER_H

@interface ImageCacheManager : NSObject

+ (instancetype)sharedManager;

- (NSString *)cacheKeyForURL:(NSString *)urlString;
- (NSString *)cachePathForURL:(NSString *)urlString;
- (BOOL)hasCachedImageForURL:(NSString *)urlString;
- (UIImage *)cachedImageForURL:(NSString *)urlString;
- (void)cacheImage:(UIImage *)image forURL:(NSString *)urlString;
- (void)saveImageData:(NSData *)imageData forURL:(NSString *)urlString completion:(void (^)(BOOL success, NSString *cachePath))completion;
- (void)clearCache;
- (NSString *)getCacheDirectory;

@end

#endif /* IMAGECACHEMANAGER_H */

