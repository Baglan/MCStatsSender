//
//  ViewController.m
//  MCStatsSender
//
//  Created by Baglan on 10/25/12.
//  Copyright (c) 2012 MobileCreators. All rights reserved.
//

#import "ViewController.h"
#import "MCStatsSender.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [MCStatsSender setServiceURL:[NSURL URLWithString:@"http://some.url/stats.php"]];
    [MCStatsSender sendAction:@"started"];
}

@end
