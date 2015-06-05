//
//  ViewController.m
//  XLYKeyValueStoreDemo
//
//  Created by 王凯 on 14/12/12.
//  Copyright (c) 2014年 kaizei. All rights reserved.
//

#import "ViewController.h"

#import <CoreData/CoreData.h>
#import "XLYKeyValueStore.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  NSString *documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
  NSString *path = [documentDir stringByAppendingPathComponent:@"store"];
  
  XLYKeyValueStore *store = [[XLYKeyValueStore alloc] initWithStorePath:path];
  
  id object = [store URLForKey:@"google" inTable:@"URL"];
  NSLog(@" before set: %@", object);
  
  [store setObject:[NSURL URLWithString:@"https://www.google.com/"] forKey:@"google" inTable:@"URL"];
  
  object = [store URLForKey:@"google" inTable:@"URL"];
  NSLog(@"after set: %@", object);
  
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
