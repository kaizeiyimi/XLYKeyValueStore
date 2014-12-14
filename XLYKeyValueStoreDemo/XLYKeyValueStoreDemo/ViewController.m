//
//  ViewController.m
//  XLYKeyValueStoreDemo
//
//  Created by 王凯 on 14/12/12.
//  Copyright (c) 2014年 kaizei. All rights reserved.
//

#import "ViewController.h"

#import "XLYKeyValueStore.h"
#import <CoreData/CoreData.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *path = [documentDir stringByAppendingPathComponent:@"store"];

    XLYKeyValueStore *store = [[XLYKeyValueStore alloc] initWithStorePath:path];
    [store setObject:[NSURL URLWithString:@"http://www.baidu.com/"] forKey:@"baidu" inTable:@"URL"];
    id object = [store stringArrayForKey:@"baidu" inTable:@"URL"];
    NSLog(@"%@", object);   //should be an array of one URL.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
