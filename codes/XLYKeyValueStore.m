//
//  XLYKeyValueStore.m
//  XLYKeyValueStore
//
//  Created by 王凯 on 14/12/12.
//  Copyright (c) 2014年 kaizei. All rights reserved.
//

#import "XLYKeyValueStore.h"
#import <CoreData/CoreData.h>

static NSString * const kXLYKeyValueStoreEntityName = @"XLYKeyValueStoreItem";
static NSString * const kXLYKeyValueStoreEntityTableAttributeName = @"table";
static NSString * const kXLYKeyValueStoreEntityKeyAttributeName = @"key";
static NSString * const kXLYKeyValueStoreEntityObjectAttributeName = @"object";
static NSString * const kXLYKeyValueStoreEntityModifyDateAttributeName = @"modifyDate";
static NSString * const kXLYKeyValueStoreDefaultTableName = @"__DEFAULT_TABLE__";

@interface XLYKeyValueStoreItem ()

@property (nonatomic, copy) NSString *table;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, strong) id object;
@property (nonatomic, copy) NSDate *modifyDate;

@end

@implementation XLYKeyValueStoreItem

- (NSString *)description
{
  return [NSString stringWithFormat:@"%@ = %@, %@ = %@, %@ = %@, %@ = %@,",
          kXLYKeyValueStoreEntityTableAttributeName, self.table,
          kXLYKeyValueStoreEntityKeyAttributeName, self.key,
          kXLYKeyValueStoreEntityObjectAttributeName, self.object,
          kXLYKeyValueStoreEntityModifyDateAttributeName, self.modifyDate];
}

@end


@interface XLYKeyValueStore ()

@property (nonatomic, strong) NSManagedObjectContext *context;

@property (nonatomic, copy) NSString *currentSuiteName;

@end

@implementation XLYKeyValueStore

+ (instancetype)defaultStore
{
  static id store;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSString *libraryDirectory = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    NSString *storeDir = [libraryDirectory stringByAppendingPathComponent:@"XLYKeyValueStore"];
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:storeDir withIntermediateDirectories:YES attributes:nil error:&error];
    NSAssert(!error, @"%@", error);
    NSString *defaultStorePath = [storeDir stringByAppendingPathComponent:@"XLYKeyValueStore.data"];
    store = [[self alloc] initWithStorePath:defaultStorePath];
  });
  return store;
}

+(instancetype)defaultInMemoryStore
{
  static id store;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    store = [[self alloc] initWithStorePath:nil];
  });
  return store;
}

- (instancetype)initWithStorePath:(NSString *)path
{
  if (self = [super init]) {
    NSDictionary *propertyInfos = @{kXLYKeyValueStoreEntityTableAttributeName:@(NSStringAttributeType),
                                    kXLYKeyValueStoreEntityKeyAttributeName:@(NSStringAttributeType),
                                    kXLYKeyValueStoreEntityObjectAttributeName:@(NSTransformableAttributeType),
                                    kXLYKeyValueStoreEntityModifyDateAttributeName:@(NSDateAttributeType)};
    NSMutableArray *properties = [NSMutableArray arrayWithCapacity:propertyInfos.count];
    for (NSString *propertyName in propertyInfos) {
      NSAttributeDescription *property = [[NSAttributeDescription alloc] init];
      property.name = propertyName;
      property.attributeType = (NSAttributeType)[propertyInfos[propertyName] integerValue];
      [properties addObject:property];
    }
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    entity.name = kXLYKeyValueStoreEntityName;
    entity.properties = properties;
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] init];
    [model setEntities:@[entity]];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSError *error;
    if (path) {
      [coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                configuration:nil
                                          URL:[NSURL fileURLWithPath:path]
                                      options:@{NSMigratePersistentStoresAutomaticallyOption:@YES,
                                                NSInferMappingModelAutomaticallyOption:@YES}
                                        error:&error];
    } else {
      [coordinator addPersistentStoreWithType:NSInMemoryStoreType
                                configuration:nil
                                          URL:nil
                                      options:nil
                                        error:&error];
    }
    NSAssert(!error, @"create store with error: %@.", error);
    if (error) {
      return nil;
    }
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = coordinator;
    context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    if (path) {
      NSManagedObjectContext *parentContext = context;
      context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
      context.parentContext = parentContext;
      context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    }
    _context = context;
  }
  return self;
}

- (NSFetchRequest *)requestWithKey:(NSString *)key table:(NSString *)tableName
{
  NSAssert(key, @"'key' must not be nil.");
  tableName = tableName ? tableName : kXLYKeyValueStoreDefaultTableName;
  NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:kXLYKeyValueStoreEntityName];
  request.predicate = [NSPredicate predicateWithFormat:@"(%K = %@) && (%K = %@)",
                       kXLYKeyValueStoreEntityKeyAttributeName, key,
                       kXLYKeyValueStoreEntityTableAttributeName,tableName];
  return request;
}

#pragma mark - query and save dict
- (NSDictionary *)storedItemInfoForKey:(NSString *)key table:(NSString *)tableName
{
  NSFetchRequest *request = [self requestWithKey:key table:tableName];
  request.resultType = NSDictionaryResultType;
  __block NSError *error;
  __block NSDictionary *result;
  [self.context performBlockAndWait:^{
    result = [self.context executeFetchRequest:request error:&error].firstObject;
  }];
  NSAssert(!error, @"query stored info failed with 'key':%@, 'table':%@", key, tableName);
  return result;
}

- (void)storeItemInfo:(NSDictionary *)info
{
  NSFetchRequest *request = [self requestWithKey:info[kXLYKeyValueStoreEntityKeyAttributeName]
                                           table:info[kXLYKeyValueStoreEntityTableAttributeName]];
  __block NSError *error;
  [self.context performBlockAndWait:^{
    NSManagedObject *item = [self.context executeFetchRequest:request error:&error].firstObject;
    if (!error) {
      item = item ? item : [NSEntityDescription insertNewObjectForEntityForName:kXLYKeyValueStoreEntityName inManagedObjectContext:self.context];
      for (NSString *key in info) {
        [item setValue:info[key] forKey:key];
      }
      [self.context save:&error];
      if (!error) {
        [self.context.parentContext performBlock:^{
          [self.context.parentContext save:&error];
        }];
      }
    }
  }];
  NSAssert(!error, @"save info failed. %@.", error);
}

#pragma mark - stored XLYKeyValueStoreItem
- (XLYKeyValueStoreItem *)storedItemForKey:(NSString *)key inTable:(NSString *)tableName
{
  NSDictionary *info = [self storedItemInfoForKey:key table:tableName];
  if (!info) {
    return nil;
  }
  XLYKeyValueStoreItem *item = [XLYKeyValueStoreItem new];
  for (NSString *key in info) {
    [item setValue:info[key] forKey:key];
  }
  return item;
}

#pragma mark - core methods
- (id)objectForKey:(NSString *)key inTable:(NSString *)tableName
{
  return [self storedItemInfoForKey:key table:tableName][kXLYKeyValueStoreEntityObjectAttributeName];
}

- (void)setObject:(id)value forKey:(NSString *)key inTable:(NSString *)tableName
{
  NSAssert([value conformsToProtocol:@protocol(NSCoding)], @"value must conform to 'NSCoding' to be saved.");
  tableName = tableName ? tableName : kXLYKeyValueStoreDefaultTableName;
  [self storeItemInfo:@{kXLYKeyValueStoreEntityKeyAttributeName:key,
                        kXLYKeyValueStoreEntityObjectAttributeName:value,
                        kXLYKeyValueStoreEntityTableAttributeName:tableName,
                        kXLYKeyValueStoreEntityModifyDateAttributeName:[NSDate date]}];
}

- (void)removeObjectForKey:(NSString *)key inTable:(NSString *)tableName
{
  NSFetchRequest *request = [self requestWithKey:key table:tableName];
  __block NSError *error;
  [self.context performBlockAndWait:^{
    NSArray *result = [self.context executeFetchRequest:request error:&error];
    for (NSManagedObject *object in result) {
      [self.context deleteObject:object];
    }
    [self.context save:&error];
    if (!error) {
      [self.context.parentContext performBlock:^{
        [self.context.parentContext save:&error];
      }];
    }
  }];
  NSAssert(!error, @"remove saved info failed. %@.", error);
}

#pragma mark - helper get methods
- (NSString *)stringForKey:(NSString *)key inTable:(NSString *)tableName
{
  id object = [self objectForKey:key inTable:tableName];
  if ([object isKindOfClass:[NSString class]]) {
    return object;
  } else if ([object isKindOfClass:[NSNumber class]]) {
    return [object stringValue];
  }
  NSAssert(!object, @"'%@' should get 'nil' or 'NSString' or 'NSNumber'", NSStringFromSelector(_cmd));
  return nil;
}

- (NSArray *)stringArrayForKey:(NSString *)key inTable:(NSString *)tableName
{
  id object = [self objectForKey:key inTable:tableName];
  if ([object isKindOfClass:[NSArray class]]) {
    for (id value in object) {
      if (![value isKindOfClass:[NSString class]]) {
        NSAssert(NO, @"value in stringArray should alwasy be 'NSString'.");
        return nil;
      }
    }
    return object;
  }
  NSAssert(!object, @"'%@' should get 'nil' or 'NSArray'.", NSStringFromSelector(_cmd));
  return nil;
}

- (NSArray *)arrayForKey:(NSString *)key inTable:(NSString *)tableName
{
  id object = [self objectForKey:key inTable:tableName];
  NSAssert(!object || [object isKindOfClass:NSArray.class], @"'%@' should get 'nil' or 'NSArray'.", NSStringFromSelector(_cmd));
  return [object isKindOfClass:[NSArray class]] ? object : nil;
}

- (NSDictionary *)dictionaryForKey:(NSString *)key inTable:(NSString *)tableName
{
  id object = [self objectForKey:key inTable:tableName];
  NSAssert(!object || [object isKindOfClass:NSDictionary.class], @"'%@' should get 'nil' or 'NSDictionary'.", NSStringFromSelector(_cmd));
  return [object isKindOfClass:[NSDictionary class]] ? object : nil;
}

- (NSData *)dataForKey:(NSString *)key inTable:(NSString *)tableName
{
  id object = [self objectForKey:key inTable:tableName];
  NSAssert(!object || [object isKindOfClass:NSData.class], @"'%@' should get 'nil' or 'NSData'.", NSStringFromSelector(_cmd));
  return [object isKindOfClass:[NSData class]] ? object : nil;
}

- (NSInteger)integerForKey:(NSString *)key inTable:(NSString *)tableName
{
  id object = [self objectForKey:key inTable:tableName];
  NSAssert(!object || [object respondsToSelector:@selector(integerValue)], @"'%@' should get 'nil' or can responds to '%@'.", NSStringFromSelector(_cmd), NSStringFromSelector(@selector(integerValue)));
  return [object respondsToSelector:@selector(integerValue)] ? [object integerValue] : 0;
}

- (float)floatForKey:(NSString *)key inTable:(NSString *)tableName
{
  id object = [self objectForKey:key inTable:tableName];
  NSAssert(!object || [object respondsToSelector:@selector(floatValue)], @"'%@' should get 'nil' or can responds to '%@'.", NSStringFromSelector(_cmd), NSStringFromSelector(@selector(floatValue)));
  return [object respondsToSelector:@selector(floatValue)] ? [object floatValue] : 0;
}

- (double)doubleForKey:(NSString *)key inTable:(NSString *)tableName
{
  id object = [self objectForKey:key inTable:tableName];
  NSAssert(!object || [object respondsToSelector:@selector(doubleValue)], @"'%@' should get 'nil' or can responds to '%@'.", NSStringFromSelector(_cmd), NSStringFromSelector(@selector(doubleValue)));
  return [object respondsToSelector:@selector(doubleValue)] ? [object doubleValue] : 0;
}

- (BOOL)boolForKey:(NSString *)key inTable:(NSString *)tableName
{
  id object = [self objectForKey:key inTable:tableName];
  NSAssert(!object || [object respondsToSelector:@selector(boolValue)], @"'%@' should get 'nil' or can responds to '%@'.", NSStringFromSelector(_cmd), NSStringFromSelector(@selector(boolValue)));
  return [object respondsToSelector:@selector(boolValue)] ? [object boolValue] : NO;
}

- (NSURL *)URLForKey:(NSString *)key inTable:(NSString *)tableName
{
  id object = [self objectForKey:key inTable:tableName];
  NSAssert(!object || [object isKindOfClass:NSURL.class], @"'%@' should get 'nil' or 'NSURL'.", NSStringFromSelector(_cmd));
  return [object isKindOfClass:[NSURL class]] ? object : nil;
}

#pragma mark - helper set methods
- (void)setInteger:(NSInteger)value forKey:(NSString *)key inTable:(NSString *)tableName
{
  [self setObject:@(value) forKey:key inTable:tableName];
}

- (void)setFloat:(float)value forKey:(NSString *)key inTable:(NSString *)tableName
{
  [self setObject:@(value) forKey:key inTable:tableName];
}

- (void)setDouble:(double)value forKey:(NSString *)key inTable:(NSString *)tableName
{
  [self setObject:@(value) forKey:key inTable:tableName];
}

- (void)setBool:(BOOL)value forKey:(NSString *)key inTable:(NSString *)tableName
{
  [self setObject:@(value) forKey:key inTable:tableName];
}

- (void)setURL:(NSURL *)url forKey:(NSString *)key inTable:(NSString *)tableName
{
  NSAssert([url isKindOfClass:[NSURL class]], @"‘url’ must be of 'NSURL' class");
  [self setObject:url forKey:key inTable:tableName];
}

@end
