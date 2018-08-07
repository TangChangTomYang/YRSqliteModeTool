//
//  YRModeTool.m
//  YRSqliteTool
//
//  Created by yangrui on 2018/8/4.
//  Copyright © 2018年 yangrui. All rights reserved.
//

#import "YRModeTool.h"
#import <objc/runtime.h>

#import <UIKit/UIKit.h>

@implementation YRModeTool

/** 根据一个类获取一个数据库的表名*/
+(NSString *)tableName:(Class)cls{
    #ifdef DEBUG
    if(![cls  respondsToSelector:@selector(modifyPrimaryKey)]){
        NSLog(@"警告!!! %@ 类必须遵守YRSqliteModeProtocol协议,实现 +(NSString *)modifyPrimaryKey 方法",cls);
       return  nil;
    }
    #endif
    return  NSStringFromClass(cls);
}

/** 根据一个类获取一个数据库的临时表名*/
+(NSString *)tempTableName:(Class)cls{
    #ifdef DEBUG
    if(![cls  respondsToSelector:@selector(modifyPrimaryKey)]){
        NSLog(@"警告!!! %@ 类必须遵守YRSqliteModeProtocol协议,实现 +(NSString *)modifyPrimaryKey 方法",cls);
        return  nil;
    }
    #endif
    return  [NSString stringWithFormat:@"%@_temp",NSStringFromClass(cls)];
}

/** 默认情况下创建表的主键字段信息
 所有表主键都一样是: YRID integer primary key autoincrement
 */
+(NSString *)defaultPrimaryKeyColumn{
   return [NSString stringWithFormat:@"%@ integer primary key autoincrement",kPrimaryKeyName ];

}


/** 将对象模型转换成 字典*/
+(NSMutableDictionary *)ivarNameValueDicOfMode:(id)mode{
    NSMutableDictionary *dicM = [NSMutableDictionary dictionary];
    
    Class cls = [mode class];
    NSDictionary *nameSqliteTypeDic = [self classIvarNameSqliteTypeDic:cls];
    NSArray *allNameArr = nameSqliteTypeDic.allKeys;
    NSDictionary *defaultValueDic = [self sqliteTypeDefaultValueDic];
    
    for (NSString *name  in allNameArr) {
        id value = [mode valueForKeyPath:name];
        if (value == nil) {
            NSString *sqliteType = nameSqliteTypeDic[name];
            value = defaultValueDic[sqliteType];
        }
        dicM[name] = value;
    }
    return dicM;
}

/** 根据一个类 获取 数据库的字段名与类型的字符串 ,比如: name,text */
+(NSString *)columnNameAndSqliteTypeStr:(Class)cls{
    NSMutableDictionary *nameSqliteTypeDicM = [self classIvarNameSqliteTypeDic:cls];
    
    NSMutableArray<NSString *> *nameSqliteTypeArrM = [NSMutableArray array];
    [nameSqliteTypeDicM enumerateKeysAndObjectsUsingBlock:^(NSString  *name, NSString *sqliteType, BOOL * _Nonnull stop) {
        [nameSqliteTypeArrM addObject:[NSString stringWithFormat:@"%@ %@",name, sqliteType]];
    }];
    return  [nameSqliteTypeArrM componentsJoinedByString:@","];
    
}

/** 排序后的所有字段名*/
+(NSMutableArray *)sortedColumnNames:(Class)cls{
    NSMutableDictionary *dicM =  [self classIvarNameSqliteTypeDic:cls];
    NSMutableArray *nameArrM = [dicM allKeys].mutableCopy;
    [ nameArrM sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
      return   [obj1 compare:obj2];
    }];
    return nameArrM;
}

/** 获取指定Class的所有成员变量名和对应的类型(sqliteType)*/
+(NSMutableDictionary *)classIvarNameSqliteTypeDic:(Class)cls{
    
    NSMutableDictionary *nameTypeDicM =  [self classIvarNameTypeDic:cls];
    NSDictionary *sqliteMapDic = [self runtimeTypeMapSqliteTypeDic];
    
    [nameTypeDicM enumerateKeysAndObjectsUsingBlock:^(NSString *ivarName, NSString *ivarType, BOOL * _Nonnull stop) {
        NSString *type = sqliteMapDic[ivarType];
        nameTypeDicM[ivarName] = type;
    }];
    
    return nameTypeDicM;
}

#pragma mark- 私有方法
/** 获取指定Class的所有成员变量名和对应的类型(runtimeType)*/
+(NSMutableDictionary *)classIvarNameTypeDic:(Class)cls{
    
    #ifdef DEBUG
    if(![cls  respondsToSelector:@selector(modifyPrimaryKey)]){
         NSLog(@"警告!!! %@ 类必须遵守YRSqliteModeProtocol协议,实现 +(NSString *)modifyPrimaryKey 方法",cls);
        return nil;
    }
    // 支持的所有数据类型
    NSArray<NSString *> *suportRuntimeTypeArr = [self runtimeTypeMapSqliteTypeDic].allKeys;
    // 调试阶段 字段名 重复检查 start
    NSMutableArray *testNameArrM = [NSMutableArray array];
    [testNameArrM addObject:[kPrimaryKeyName lowercaseString]];
    #endif

    //1. 获取这个类里面的所有的成员变量和对应的类型(运行时类型)
    unsigned int count = 0;
    Ivar *ivarList =  class_copyIvarList(cls, &count);
    
    //2. 获取所有的成员变量名 -> type 的字典
    NSMutableDictionary *dicM = [NSMutableDictionary dictionary];
    NSArray *ignoreNames = nil;
    if ([cls respondsToSelector:@selector(ignoreNames)]) {
        ignoreNames = [cls ignoreNames];
    }
    
    
    
    for(int i = 0 ; i < count ; i++){
        Ivar ivar = ivarList[i];
        // 获取成员变量名
        NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivar)];
        if([ivarName hasPrefix:@"_"]){
            ivarName = [ivarName substringFromIndex:1];
        }
        
        #ifdef DEBUG
            // 调试阶段 字段名 重复检查 end
            BOOL isNameDuplicateDefinition = NO;
            NSString *lowercaseIvarName = [ivarName lowercaseString];
            for (NSString *testName in testNameArrM) {
                if([testName isEqualToString:lowercaseIvarName]){
                    isNameDuplicateDefinition = YES;
                    NSLog(@"警告!!! %@ 类的 %@ 成员变量 重复定义,数据可能丢失",cls,ivarName);
                    return nil;
                }
            }
            if(isNameDuplicateDefinition == NO){
                [testNameArrM addObject:lowercaseIvarName];
            }
        #endif
        
        
        // 过滤需要或略的
        if ([ignoreNames containsObject:ivarName]) {
            continue;
        }
        
        // 获取成员变量类型
        NSString *ivarType = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
        // 如果类型中收尾有@ \" 就去除掉
        ivarType = [ivarType stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"@\""]];
        #ifdef DEBUG
            if(![suportRuntimeTypeArr containsObject:ivarType]){
                NSLog(@"警告!!! %@ 类中 包含不支持的数据类型: %@",cls,ivarType);
                return nil;
            }
        #endif
        dicM[ivarName] = ivarType;
    }
    
    #ifdef DEBUG
    if ([cls  respondsToSelector:@selector(modifyPrimaryKey)]) {
        NSString *modifyPriKey = [cls modifyPrimaryKey];
        if (![testNameArrM containsObject:modifyPriKey]) {
            NSLog(@"警告!!! %@ 类,+(NSString *)modifyPrimaryKey 方法,返回值必须是 %@ 中的一个",cls,[testNameArrM componentsJoinedByString:@","]);
            return nil;
        }
    }
    #endif
    return dicM;
}

/** sqlite类型 -> 默认值 */
+(NSDictionary *)sqliteTypeDefaultValueDic{
  return@{@"real":@(0.0), //double
          @"integer":@(0), //int
          @"blob":[NSData data],
          @"text":@""
          };
}

/** 运行时类型 -> objc 数据库类型 */
+(NSDictionary *)runtimeTypeMapOCTypeDic{
    
    return  @{@"d":@"double", //double
              @"f":@"float", //float
              
              @"i":@"int", //int
              @"q":@"long", //long
              @"Q":@"long long", //long long
              @"B":@"bool", //bool
              
              @"NSData":@"NSData",
              @"NSString":@"NSString"
              };
}


/** 运行时类型 -> sqlite 数据库类型 */
+(NSDictionary *)runtimeTypeMapSqliteTypeDic{
    
    return  @{@"d":@"real", //double
              @"f":@"real", //float
              
              @"i":@"integer", //int
              @"q":@"integer", //long
              @"Q":@"integer", //long long
              @"B":@"integer", //bool
              
              @"NSData":@"blob",
              @"NSString":@"text"
              };
    
    
}









@end
