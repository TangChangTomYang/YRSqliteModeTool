//
//  YRTableTool.h
//  YRSqliteTool
//
//  Created by yangrui on 2018/8/4.
//  Copyright © 2018年 yangrui. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YRTableTool : NSObject
/** 获取指定表的所有字段名和数据库中的类型*/
+(NSMutableDictionary *)tableColumnNameTypeDic:(Class)cls uid:(NSString *)uid;

+(NSMutableArray *)sortedColumnNames:(Class)cls uid:(NSString *)uid;

/** 判断表格是否存在*/
+(BOOL)isTableExists:(Class)cls uid:(NSString *)uid;

@end
