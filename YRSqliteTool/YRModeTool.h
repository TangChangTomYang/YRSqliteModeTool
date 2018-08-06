//
//  YRModeTool.h
//  YRSqliteTool
//
//  Created by yangrui on 2018/8/4.
//  Copyright © 2018年 yangrui. All rights reserved.
// 数据库只支持4种数据: integer blob real txt(整型 二进制 浮点型 字符串)
// 因此,我们获取出来的数据也只有4种

#import <Foundation/Foundation.h>
#import "YRSqliteModeProtocol.h"
#define kPrimaryKeyName @"YRID"  // 主键的名字

@interface YRModeTool : NSObject

/** 根据一个类获取一个数据库的表明*/
+(NSString *)tableName:(Class)cls;

/** 根据一个类获取一个数据库的临时表名*/
+(NSString *)tempTableName:(Class)cls;

/** 默认情况下创建表的主键字段信息
 所有表主键都一样是: YRID integer primary key autoincrement
 */
+(NSString *)defaultPrimaryKeyColumn;



/** 根据一个类 获取 数据库的字段名与类型的字符串*/
+(NSString *)columnNameAndSqliteTypeStr:(Class)cls;

/** 获取指定Class的所有成员变量名和对应的类型(sqliteType)*/
+(NSMutableDictionary *)classIvarNameSqliteTypeDic:(Class)cls;

/** 排序后的所有字段名*/
+(NSMutableArray *)sortedColumnNames:(Class)cls;

/** 将对象模型转换成 字典*/
+(NSMutableDictionary *)ivarNameValueDicOfMode:(id)mode;


@end
