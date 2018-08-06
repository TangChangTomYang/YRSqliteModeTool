//
//  YRSqliteTool.h
//  YRSqliteTool
//
//  Created by yangrui on 2018/8/3.
//  Copyright © 2018年 yangrui. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YRSqliteTool : NSObject

#pragma mark- sql 执行语句 增 删 改
/**
 sql: 需要执行的(增 删 改)sql语句
 uid: 决定数据库的名字 dbName = uid.length>0 ? uid.sqlite : common.sqlite
 */
+(BOOL)dealSql:(NSString *)sql uid:(NSString *)uid;
/**
 sqlArr: 需要执行的(增 删 改)sql语句数组
 uid: 决定数据库的名字 dbName = uid.length>0 ? uid.sqlite : common.sqlite
 */
+(BOOL)dealSqlArr:(NSArray<NSString *> *)sqlArr uid:(NSString *)uid;


#pragma mark- sql 查询语句
/**
 sql: 执行查询的sql 语句
 uid: 决定数据库的名字 dbName = uid.length>0 ? uid.sqlite : common.sqlite
 */
+(NSMutableArray<NSMutableDictionary *> *)querySql:(NSString *)sql uid:(NSString *)uid;
/**
 sqlArr: 执行查询的sql 语句数组
 uid: 决定数据库的名字 dbName = uid.length>0 ? uid.sqlite : common.sqlite
 */
+(NSMutableArray<NSMutableArray *> *)querySqlArr:(NSArray<NSString *> *)sqlArr uid:(NSString *)uid;

@end
