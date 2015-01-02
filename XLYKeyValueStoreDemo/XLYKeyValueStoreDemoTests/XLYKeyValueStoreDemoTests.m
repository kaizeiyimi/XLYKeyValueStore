//
//  XLYKeyValueStoreDemoTests.m
//  XLYKeyValueStoreDemoTests
//
//  Created by 王凯 on 14/12/12.
//  Copyright (c) 2014年 kaizei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "XLYKeyValueStore.h"

#pragma mark - transformableObject
@interface XLYTestTransformableObject : NSObject <NSCoding>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSNumber *identity;

@end

@implementation XLYTestTransformableObject

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self.name = [aDecoder decodeObjectForKey:@"name"];
    self.identity = [aDecoder decodeObjectForKey:@"identity"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.identity forKey:@"identity"];
}

@end


#pragma mark - test
@interface XLYKeyValueStoreDemoTests : XCTestCase

@end

@implementation XLYKeyValueStoreDemoTests

static XLYKeyValueStore *store = nil;

+ (void)setUp
{
    [super setUp];
    NSString *documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *path = [documentDir stringByAppendingPathComponent:@"testStore"];
    store = [[XLYKeyValueStore alloc] initWithStorePath:path];
}

+ (void)tearDown
{
    [super tearDown];
    store = nil;
    NSString *documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *path = [documentDir stringByAppendingPathComponent:@"testStore"];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (void)testSetTransformableObject {
    XLYTestTransformableObject *object = [XLYTestTransformableObject new];
    object.name = @"kaizei";
    object.identity = @1;
    [store setObject:object forKey:@"kaizei" inTable:@"user"];
    object = [store objectForKey:@"kaizei" inTable:@"user"];
    XCTAssert([object isKindOfClass:[XLYTestTransformableObject class]], @"object must be of 'XLYTestObject' class.");
    XCTAssertEqualObjects(object.name, @"kaizei");
    XCTAssertEqualObjects(object.identity, @1);
    object = [store storedItemForKey:@"kaizei" inTable:@"user"].object;
    XCTAssert([object isKindOfClass:[XLYTestTransformableObject class]], @"object must be of 'XLYTestObject' class.");
    XCTAssertEqualObjects(object.name, @"kaizei");
    XCTAssertEqualObjects(object.identity, @1);
}

- (void)testSetNumber {
    [store setInteger:100 forKey:@"id" inTable:@"index"];
    NSInteger value = [store integerForKey:@"id" inTable:@"index"];
    XCTAssertEqual(value, 100);
    value = [store integerForKey:@"id" inTable:nil];
    XCTAssertEqual(value, 0);
    NSString *string = [store stringForKey:@"id" inTable:@"index"];
    XCTAssertEqualObjects(string, @"100");
}

- (void)testString {
    NSNumber *number = @102;
    [store setObject:number forKey:@"id" inTable:@"string"];
    number = [store objectForKey:@"id" inTable:@"string"];
    XCTAssertEqualObjects(number, @102);
    NSInteger integerValue = [store integerForKey:@"id" inTable:@"string"];
    XCTAssertEqual(integerValue, 102);
    float floatValue = [store floatForKey:@"id" inTable:@"string"];
    XCTAssertEqualWithAccuracy(floatValue, 102, 1e-5);
    double doubleValue = [store doubleForKey:@"id" inTable:@"string"];
    XCTAssertEqualWithAccuracy(doubleValue, 102, 1e-10);
    NSString *stringValue = [store stringForKey:@"id" inTable:@"string"];
    XCTAssertEqualObjects(stringValue, @"102");
    NSArray *stringArray = [store stringArrayForKey:@"id" inTable:@"string"];
    XCTAssert(!stringArray);
    NSArray *numberArray = [store arrayForKey:@"id" inTable:@"string"];
    XCTAssert(!numberArray);
    
    NSArray *array = @[@"a",@"b"];
    [store setObject:array forKey:@"array" inTable:@"string"];
    NSArray *array2 = [store objectForKey:@"array" inTable:@"string"];
    XCTAssertEqualObjects(array, array2);
}

- (void)testData {
    NSString *string = @"hello world";
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    [store setObject:data forKey:@"string" inTable:@"data"];
    data = [store objectForKey:@"string" inTable:@"data"];
    string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(string, @"hello world");
}

- (void)testDictionary {
    NSDictionary *dict = @{@"name":@"kaizei"};
    [store setObject:dict forKey:@"kaizei" inTable:@"dict"];
    dict = [store dictionaryForKey:@"kaizei" inTable:@"dict"];
    XCTAssertEqualObjects(dict.allKeys, @[@"name"]);
    XCTAssertEqualObjects(dict.allValues, @[@"kaizei"]);
    dict = [store objectForKey:@"kaizei" inTable:@"dict"];
    XCTAssertEqualObjects(dict, @{@"name":@"kaizei"});
}

- (void)testURL {
    NSURL *url = [NSURL URLWithString:@"http://www.google.com"];
    [store setURL:url forKey:@"google" inTable:@"URL"];
    NSURL *theUrl = [store URLForKey:@"google" inTable:@"URL"];
    XCTAssertEqualObjects(url, theUrl);
    theUrl = [store objectForKey:@"google" inTable:@"URL"];
    XCTAssertEqualObjects(url, theUrl);
}

- (void)testRemove {
    NSString *string = @"hello world";
    [store setObject:string forKey:@"basic" inTable:@"remove"];
    string = [store objectForKey:@"basic" inTable:@"remove"];
    XCTAssertEqualObjects(string, @"hello world");
    [store removeObjectForKey:@"basic" inTable:@"remove"];
    string = [store objectForKey:@"basic" inTable:@"remove"];
    XCTAssertNil(string);
}

@end
