//
//  MCStatsSender.m
//  MCStatsSender
//
//  Created by Baglan on 10/25/12.
//  Copyright (c) 2012 MobileCreators. All rights reserved.
//

#import "MCStatsSender.h"

#define MCSTATSSENDER_UNIQUE_ID_KEY         @"MCStatsSender_uniqueId"
#define MCSTATSSENDER_UNIQUE_ID_HEADER_KEY  @"X-MCSTATSSENDER_UNIQUEID"
#define MCSTATSSENDER_DEVICE_KEY            @"X-MCSTATSSENDER_DEVICE"
#define MCSTATSSENDER_SYSTEM_KEY            @"X-MCSTATSSENDER_SYSTEM"
#define MCSTATSSENDER_PRODUCT_KEY           @"X-MCSTATSSENDER_PRODUCT"
#define MCSTATSSENDER_SCREEN_SIZE_KEY       @"X-MCSTATSSENDER_SCREEN_SIZE"

@interface MCStatsSender () {
    NSString * _uniqieID;
    __strong NSURL *_serviceURL;
    NSString * _product;
    NSString * _system;
    NSString * _device;
    NSString * _screenSize;
}

@property (nonatomic, retain) NSURL * serviceURL;

@end

@implementation MCStatsSender

// Singleton
// Taken from http://lukeredpath.co.uk/blog/a-note-on-objective-c-singletons.html
+ (MCStatsSender *)sharedInstance
{
    __strong static id _sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (id)init
{
    self = [super init];
    if (self) {
        
        // Read/generate unique ID
        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
        _uniqieID = [userDefaults objectForKey:MCSTATSSENDER_UNIQUE_ID_KEY];
        if (!_uniqieID) {
            _uniqieID = [[NSProcessInfo processInfo] globallyUniqueString];
            [userDefaults setObject:_uniqieID forKey:MCSTATSSENDER_UNIQUE_ID_KEY];
            [userDefaults synchronize];
        }
        
        // Product
        NSDictionary * bundleInfo = [[NSBundle mainBundle] infoDictionary];
        NSString * version = [bundleInfo objectForKey:(NSString *)kCFBundleVersionKey];
        NSString * name = [bundleInfo objectForKey:(NSString *)kCFBundleNameKey];
        _product = [NSString stringWithFormat:@"%@ %@", name, version];
        
        // System
        NSString * systemName = [[UIDevice currentDevice] systemName];
        NSString * systemVersion = [[UIDevice currentDevice] systemVersion];
        _system = [NSString stringWithFormat:@"%@ %@", systemName, systemVersion];
        
        // Device
        _device = [UIDevice currentDevice].model;
        
        // Screen size
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        _screenSize = [NSString stringWithFormat:@"%f x %f", screenSize.width, screenSize.height];
    }
    return self;
}

#pragma mark -
#pragma mark The "meat"

- (void)sendData:(NSDictionary *)data
{
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:_serviceURL];
    [request setHTTPMethod:@"POST"];
    
    [request setValue:_uniqieID forHTTPHeaderField:MCSTATSSENDER_UNIQUE_ID_HEADER_KEY];
    [request setValue:_product forHTTPHeaderField:MCSTATSSENDER_PRODUCT_KEY];
    [request setValue:_system forHTTPHeaderField:MCSTATSSENDER_SYSTEM_KEY];
    [request setValue:_device forHTTPHeaderField:MCSTATSSENDER_DEVICE_KEY];
    [request setValue:_screenSize forHTTPHeaderField:MCSTATSSENDER_SCREEN_SIZE_KEY];
    
    NSData * actionData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
    [request setHTTPBody:actionData];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:nil];
}

#pragma mark -
#pragma mark Public interface

+ (void)setServiceURL:(NSURL *)url
{
    [self sharedInstance].serviceURL = url;
}

+ (void)sendData:(NSDictionary *)data
{
    [[self sharedInstance] sendData:data];
}

+ (void)sendAction:(NSString *)action withData:(NSDictionary *)data
{
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionaryWithDictionary:data];
    dictionary[@"action"] = action;
    [self sendData:dictionary];
}

+ (void)sendAction:(NSString *)action
{
    [self sendData:@{@"action": action}];
}

@end
