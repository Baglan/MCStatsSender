//
//  MCStatsSender.m
//  MCStatsSender
//
//  Created by Baglan on 10/25/12.
//  Copyright (c) 2012 MobileCreators. All rights reserved.
//

#define MCSTATSSENDER_UNIQUE_ID_KEY         @"MCStatsSender_uniqueId"
#define MCSTATSSENDER_UNIQUE_ID_HEADER_KEY  @"X-MCSTATSSENDER_UNIQUEID"
#define MCSTATSSENDER_DEVICE_KEY            @"X-MCSTATSSENDER_DEVICE"
#define MCSTATSSENDER_SYSTEM_KEY            @"X-MCSTATSSENDER_SYSTEM"
#define MCSTATSSENDER_PRODUCT_KEY           @"X-MCSTATSSENDER_PRODUCT"
#define MCSTATSSENDER_SCREEN_SIZE_KEY       @"X-MCSTATSSENDER_SCREEN_SIZE"
#define MCSTATSSENDER_MACHINE_NAME_KEY      @"X-MCSTATSSENDER_MACHINE_NAME"
#define MCSTATSSENDER_REACHABILITY_KEY      @"X-MCSTATSSENDER_REACHABILITY"
#define MCSTATSSENDER_COMPROMIZED_KEY       @"X-MCSTATSSENDER_COMPROMIZED"

#import "MCStatsSender.h"
#import <sys/utsname.h>
#import "Reachability.h"

// BEGIN: Piracy check definitions

#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <TargetConditionals.h>

/* The encryption info struct and constants are missing from the iPhoneSimulator SDK, but not from the iPhoneOS or
 * Mac OS X SDKs. Since one doesn't ever ship a Simulator binary, we'll just provide the definitions here. */
#if TARGET_IPHONE_SIMULATOR && !defined(LC_ENCRYPTION_INFO)
#define LC_ENCRYPTION_INFO 0x21
struct encryption_info_command {
    uint32_t cmd;
    uint32_t cmdsize;
    uint32_t cryptoff;
    uint32_t cryptsize;
    uint32_t cryptid;
};
#endif

int main (int argc, char *argv[]);

// END: Piracy check definitions

@interface MCStatsSender () {
    NSString * _uniqieID;
    __strong NSURL *_serviceURL;
    NSString * _product;
    NSString * _system;
    NSString * _device;
    NSString * _screenSize;
    NSString * _machineName;
    BOOL _compromized;
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

- (NSString *)machineName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}


- (BOOL)isCompromized
{
    const struct mach_header *header;
    Dl_info dlinfo;
    
    /* Fetch the dlinfo for main() */
    if (dladdr(main, &dlinfo) == 0 || dlinfo.dli_fbase == NULL) {
        NSLog(@"Could not find main() symbol (very odd)");
        return NO;
    }
    header = dlinfo.dli_fbase;
    
    /* Compute the image size and search for a UUID */
    struct load_command *cmd = (struct load_command *) (header+1);
    
    for (uint32_t i = 0; cmd != NULL && i < header->ncmds; i++) {
        /* Encryption info segment */
        if (cmd->cmd == LC_ENCRYPTION_INFO) {
            struct encryption_info_command *crypt_cmd = (struct encryption_info_command *) cmd;
            /* Check if binary encryption is enabled */
            if (crypt_cmd->cryptid < 1) {
                /* Disabled, probably pirated */
                return NO;
            }
            
            /* Probably not pirated? */
            return YES;
        }
        
        cmd = (struct load_command *) ((uint8_t *) cmd + cmd->cmdsize);
    }
    
    /* Encryption info not found */
    return NO;
}

/**
 * Code taken from http://oleb.net/blog/2011/09/how-to-replace-the-udid/
 */
- (NSString *)createUUID
{
    NSString * uuidString = nil;
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    if (uuid) {
        uuidString = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
        CFRelease(uuid);
    }
    return uuidString;
}

- (NSString *)reachabilityStatus
{
    Reachability * reachability = [Reachability reachabilityForInternetConnection];
    return reachability.isReachableViaWiFi ? @"WiFi" : (reachability.isReachableViaWWAN ? @"WWAN" : @"NO");
}

- (id)init
{
    self = [super init];
    if (self) {
        
        // Read/generate unique ID
        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
        _uniqieID = [userDefaults objectForKey:MCSTATSSENDER_UNIQUE_ID_KEY];
        if (!_uniqieID) {
            _uniqieID = [self createUUID];
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
        _screenSize = [NSString stringWithFormat:@"%.0f x %.0f x %.1f", screenSize.width, screenSize.height, [UIScreen mainScreen].scale];
        
        // Machine name
        _machineName = [self machineName];
        
        // Compromized
        _compromized = [self isCompromized];
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
    
    [request setValue:_machineName forHTTPHeaderField:MCSTATSSENDER_MACHINE_NAME_KEY];
    [request setValue:(_compromized ? @"YES" : @"NO") forHTTPHeaderField:MCSTATSSENDER_COMPROMIZED_KEY];
    [request setValue:[self reachabilityStatus] forHTTPHeaderField:MCSTATSSENDER_REACHABILITY_KEY];
    
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
