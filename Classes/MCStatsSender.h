//
//  MCStatsSender.h
//  MCStatsSender
//
//  Created by Baglan on 10/25/12.
//  Copyright (c) 2012 MobileCreators. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCStatsSender : NSObject

+ (void)setServiceURL:(NSURL *)url;
+ (void)sendData:(NSDictionary *)data;
+ (void)sendAction:(NSString *)action withData:(NSDictionary *)data;
+ (void)sendAction:(NSString *)action;

@end
