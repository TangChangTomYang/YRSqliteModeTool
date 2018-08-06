//
//  YRTableTool.m
//  YRSqliteTool
//
//  Created by yangrui on 2018/8/4.
//  Copyright © 2018年 yangrui. All rights reserved.
//

#import "YRTableTool.h"
#import "YRModeTool.h"
#import "YRSqliteTool.h"

@implementation YRTableTool



/** 获取指定表的所有字段名和数据库中的类型*/
+(NSMutableDictionary *)tableColumnNameTypeDic:(Class)cls uid:(NSString *)uid{
    #ifdef DEBUG
    if(![cls  respondsToSelector:@selector(modifyPrimaryKey)]){
        NSLog(@"警告!!! %@ 类必须遵守YRSqliteModeProtocol协议,实现 +(NSString *)modifyPrimaryKey 方法",cls);
    }
    #endif
    
    //1. 获取创建 Class 对应的数据库的表的sql 语句
    NSString *createTableSql = [self fetchCreatTableSql:cls uid:uid];
    //2.截取 column内容, 只要 "( )" 中的内容
    NSString *columnInfoStr = [[createTableSql componentsSeparatedByString:@"("] lastObject];
    columnInfoStr = [columnInfoStr stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@")"]];
    
    //3. 列数组(名字 类型)
    NSArray *columnArr = [columnInfoStr componentsSeparatedByString:@","];
    
    // 4.
    NSMutableDictionary *nameTypeDicM = [NSMutableDictionary dictionary];
    for (int i = 0; i < columnArr.count; i ++) {
        NSString *column = columnArr[i];
        if ([column containsString:@"primary"]) {
            continue;
        }
        NSArray *nameType = [column componentsSeparatedByString:@" "];
        NSString *name = [nameType firstObject];
        NSString *type = [nameType lastObject];
        
        nameTypeDicM[name] = type;
    }
   
    return nameTypeDicM;
}

/** 获取数据库表名==cls所有字段的名字 */
+(NSMutableArray *)sortedColumnNames:(Class)cls uid:(NSString *)uid{
    
    NSMutableDictionary *nameTypeDicM = [self tableColumnNameTypeDic:cls uid:uid];
    NSMutableArray *nameArrM = [nameTypeDicM.allKeys mutableCopy];
    //名字排序
    [nameArrM sortUsingComparator:^NSComparisonResult(NSString  *obj1, NSString  *obj2) {
        return [obj1 compare:obj2];
    }];
    
    return nameArrM;
}


/** 判断表格是否存在*/
+(BOOL)isTableExists:(Class)cls uid:(NSString *)uid{
     NSString *createTableSql = [self fetchCreatTableSql:cls uid:uid];
    //CREATE TABLE "YRTest"(YRID integer primary key autoincrement,age real,data blob,stu_name text,img blob,height integer,url text)
    return (createTableSql.length > 0);
}

#pragma mark- 私有方法
+(NSString *)fetchCreatTableSql:(Class)cls uid:(NSString *)uid{
    #ifdef DEBUG
    if(![cls  respondsToSelector:@selector(modifyPrimaryKey)]){
        NSLog(@"警告!!! %@ 类必须遵守YRSqliteModeProtocol协议,实现 +(NSString *)modifyPrimaryKey 方法",cls);
    }
    #endif
   
    // 获取Class 对应的数据库的表
    NSString *tableName = [YRModeTool tableName:cls];
    //查询创建 .tableName 对应的数据库表 的sql 语句,里面包含了 字段名和字段类型等信息
    //因为数据库创建表的sql 语句都存储在sqlite_master 这张隐藏的表里面
    NSString *queryCreateTableSql =  [NSString stringWithFormat: @"select sql from sqlite_master where type = 'table' and name = '%@';", tableName];
    /*key 是sql ,value 是创建 表时的sql 语句
     @{@"sql":@"CREATE TABLE YRTest(YRID integer primary key autoincrement,age integer,dic text,,name text)";}
     */
    NSMutableDictionary *resultDicM = [[YRSqliteTool querySql:queryCreateTableSql uid:uid] firstObject];
    NSString *createTableSql = resultDicM[@"sql"];
    return createTableSql;
}

@end






















