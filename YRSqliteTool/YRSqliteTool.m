//
//  YRSqliteTool.m
//  YRSqliteTool
//
//  Created by yangrui on 2018/8/3.
//  Copyright © 2018年 yangrui. All rights reserved.
//

#import "YRSqliteTool.h"
#import "sqlite3.h"
//数据库存储的文件夹
//#define DatabaseCachePath (NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject)

#define DatabaseCachePath @"/Users/yang/Desktop"
@interface YRSqliteTool()
@end


@implementation YRSqliteTool
// 数据库
static sqlite3 *_db = nil;

/**
 sql: 需要执行的(增 删 改)sql语句
 uid: 决定数据库的名字 dbName = uid.length>0 ? uid.sqlite : common.sqlite
*/
+(BOOL)dealSql:(NSString *)sql uid:(NSString *)uid{
    
    if(sql.length == 0){
        #ifdef DEBUG
        NSLog(@"dealSql sql 不能为空");
        #endif
        return NO;
    }
    
  return  [self dealSqlArr:@[sql] uid:uid];
}


/**
 sqlArr: 需要执行的(增 删 改)sql语句数组
 uid: 决定数据库的名字 dbName = uid.length>0 ? uid.sqlite : common.sqlite
 */
+(BOOL)dealSqlArr:(NSArray<NSString *> *)sqlArr uid:(NSString *)uid{
    @synchronized([self class]){
        //1. 打开数据库
        if(![self openDb_uid:uid]){
            #ifdef DEBUG
                NSLog(@"dealSql 打开数据库失败uid: %@",uid);
            #endif
            return NO;
        }
       // 开启事物
        [self beginTransaction];
        for(int i = 0 ; i < sqlArr.count; i ++){
            NSString *sql = sqlArr[i];
            //2. 执行DML 语句
            if ([self dealSql:sql withinDb:_db] == NO) {
                //回滚
                [self rollbackTransaction];
                return NO;
            }
        }
        // 关闭事物
        [self commitTransaction];
       //3. 关闭数据库
        [self closeDb];
        return YES;
    }
}


/**
 sql: 执行查询的sql 语句
 uid: 决定数据库的名字 dbName = uid.length>0 ? uid.sqlite : common.sqlite
 */
+(NSMutableArray<NSMutableDictionary *> *)querySql:(NSString *)sql uid:(NSString *)uid{
    
    if (sql.length == 0) {
        return nil;
    }
    return  [self querySqlArr:@[sql] uid:uid].firstObject;
}



/**
 sqlArr: 执行查询的sql 语句数组
 uid: 决定数据库的名字 dbName = uid.length>0 ? uid.sqlite : common.sqlite
 */
+(NSMutableArray<NSMutableArray *> *)querySqlArr:(NSArray<NSString *> *)sqlArr uid:(NSString *)uid{
    @synchronized([self class]){
        //1. 打开数据库
        if(![self openDb_uid:uid]){
            #ifdef DEBUG
            NSLog(@"querySql 打开数据库失败uid: %@",uid);
            #endif
            return nil;
        }
        
        NSMutableArray *arrMArrM = [NSMutableArray array];
        for(int i = 0 ; i < sqlArr.count; i ++){
            //2. 执行DQL 语句
            NSString *sql = sqlArr[i];
            NSMutableArray<NSMutableDictionary *> *arrM = [self querySql:sql withinDb:_db];
            if(arrM.count > 0){
                [arrMArrM addObject: arrM];
            }
            
        }
        
        //3. 关闭数据库
        [self closeDb];
        return arrMArrM;
    }
    
}


#pragma mark- 私有方法
/** 打开数据库*/
+(BOOL)openDb_uid:(NSString *)uid{
    NSString *dataBaseName = (uid.length > 0) ? [NSString stringWithFormat:@"%@.sqlite",uid] : @"common.sqlite";
    NSString *dataBasePath = [DatabaseCachePath stringByAppendingPathComponent:dataBaseName];
    return (sqlite3_open(dataBasePath.UTF8String, &_db) == SQLITE_OK);
}

/** 关闭数据库 */
+(BOOL)closeDb{
    return  (sqlite3_close(_db) == SQLITE_OK);
}

/** 开启事物 */
+(void)beginTransaction{
    [self dealSql:@"begin transaction" withinDb:_db];
}

/** 提交事物 */
+(void)commitTransaction{
    [self dealSql:@"commit transaction" withinDb:_db];
}

/** 回滚事物 */
+(void)rollbackTransaction{
    [self dealSql:@"rollback transaction" withinDb:_db];
}


/** 在指定的数据库中执行 增 删 改 语句
 sql: 执行增 删 改的sql 语句
 db: 已经打开的数据库 */
+(BOOL)dealSql:(NSString *)sql withinDb:(sqlite3 *)db{
    int rst = sqlite3_exec(db, sql.UTF8String, nil, nil, nil);
    if (rst != SQLITE_OK) {
        #ifdef DEBUG
        NSLog(@"dealSql 执行sql: %@ 失败",sql);
        #endif
        return NO;
    }
    return YES;
}



/** 在指定的数据库中执行查询语句
 sql: 执行查询的sql 语句
 db: 已经打开的数据库 */
+(NSMutableArray<NSMutableDictionary *> *)querySql:(NSString *)sql withinDb:(sqlite3 *)db{
    
    if(sql.length == 0){
        #ifdef DEBUG
        NSLog(@"querySql:withinDb: sql 不能为空");
        #endif
        return nil;
    }
    
    /**
     参数1:打开的数据库
     参数2:需要查询的sql 语句
     参数3:餐数2取出多少字节长度, -1 表示自动计算SQL语句长度
     参数4:准备语句
     餐数5:通过餐数3取出餐数2长度后剩余的字符串
     */
    //1. 创建准备语句
    sqlite3_stmt *ppStmt = nil;
    if (sqlite3_prepare_v2(db, sql.UTF8String, -1, &ppStmt, nil) != SQLITE_OK) {
        #ifdef DEBUG
        NSLog(@"querySql 准备sql 失败: %@",sql);
        #endif
        return nil;
    };
    
    
    //2. 执行查询sql
    NSMutableArray *arrM = [NSMutableArray array];
    while (sqlite3_step(ppStmt) == SQLITE_ROW) {
        NSMutableDictionary *dicM = [NSMutableDictionary dictionary];
        
        // 一行记录有几列
        int columnCount = sqlite3_column_count(ppStmt);
        for (int i = 0; i < columnCount; i++) {
            // 获取列名
            NSString *name = [NSString stringWithUTF8String:sqlite3_column_name(ppStmt, i)];
            
            // 获取列的类型
            int type = sqlite3_column_type(ppStmt, i);
            switch (type) {// 获取列值
                case SQLITE_INTEGER:{
                    dicM[name] = @(sqlite3_column_int64(ppStmt, i));
                }break;// 整型取值
                case SQLITE_FLOAT:{
                    dicM[name] = @(sqlite3_column_double(ppStmt, i));
                    
                }break;// float 取值
                case SQLITE_BLOB:{
                    id data = CFBridgingRelease(sqlite3_column_blob(ppStmt, i));
                    if (data != nil) {
                        dicM[name] = data;
                    }
                    else{
                        dicM[name] = [NSData data];
                    }
                    
                }break;//二进制取值
                case SQLITE3_TEXT:{
                    
                    NSString *txt = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(ppStmt, i)];
                    if (txt != nil) {
                        dicM[name] = txt;
                    }
                    else{
                        dicM[name] = @"";
                    }

                    
                }break;//字符串取值
                case SQLITE_NULL:{
                    
                }break;// 空值
                default:{}break;
            }
        }
        // 一行记录
        [arrM addObject:dicM];
    }
    
    //3. 释放资源
    sqlite3_finalize(ppStmt);
    return arrM;
    
}
@end
