//
//  XLYKeyValueStore.h
//  XLYKeyValueStore
//
//  Created by 王凯 on 14/12/12.
//  Copyright (c) 2014年 kaizei. All rights reserved.
//

#import <Foundation/Foundation.h>

///this class is used to record the stored info. attributes of 'table', 'key', 'object' and 'modifyDate' are included.
@interface XLYKeyValueStoreItem : NSObject

@property (nonatomic, copy, readonly) NSString *table;
@property (nonatomic, copy, readonly) NSString *key;
@property (nonatomic, strong, readonly) id object;
@property (nonatomic, copy, readonly) NSDate *modifyDate;

@end

/* 
    almost copy the NSUserDefault API.
 */
@interface XLYKeyValueStore : NSObject

+ (instancetype)defaultStore;

- (instancetype)initWithStorePath:(NSString *)path NS_DESIGNATED_INITIALIZER  NS_AVAILABLE(10_7,  5_0);

///you can get the full information with this method.
- (XLYKeyValueStoreItem *)storedItemForKey:(NSString *)key inTable:(NSString *)tableName;

- (id)objectForKey:(NSString *)key inTable:(NSString *)tableName;
///object must confirm to '<NSCoding>'. property list types already confirm it.
- (void)setObject:(id)value forKey:(NSString *)key inTable:(NSString *)tableName;
- (void)removeObjectForKey:(NSString *)key inTable:(NSString *)tableName;

- (NSString *)stringForKey:(NSString *)key inTable:(NSString *)tableName;
- (NSArray *)stringArrayForKey:(NSString *)key inTable:(NSString *)tableName;
- (NSArray *)arrayForKey:(NSString *)key inTable:(NSString *)tableName;
- (NSDictionary *)dictionaryForKey:(NSString *)key inTable:(NSString *)tableName;
- (NSData *)dataForKey:(NSString *)key inTable:(NSString *)tableName;

- (NSURL *)URLForKey:(NSString *)key inTable:(NSString *)tableName;
- (NSInteger)integerForKey:(NSString *)key inTable:(NSString *)tableName;
- (float)floatForKey:(NSString *)key inTable:(NSString *)tableName;
- (double)doubleForKey:(NSString *)key inTable:(NSString *)tableName;
- (BOOL)boolForKey:(NSString *)key inTable:(NSString *)tableName;

- (void)setURL:(NSURL *)url forKey:(NSString *)key inTable:(NSString *)tableName;
- (void)setInteger:(NSInteger)value forKey:(NSString *)key inTable:(NSString *)tableName;
- (void)setFloat:(float)value forKey:(NSString *)key inTable:(NSString *)tableName;
- (void)setDouble:(double)value forKey:(NSString *)key inTable:(NSString *)tableName;
- (void)setBool:(BOOL)value forKey:(NSString *)key inTable:(NSString *)tableName;

@end
