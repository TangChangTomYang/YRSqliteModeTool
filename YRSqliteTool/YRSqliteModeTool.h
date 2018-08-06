//
//  YRSqliteModeTool.h
//  YRSqliteTool
//
//  Created by yangrui on 2018/8/4.
//  Copyright © 2018年 yangrui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YRModeTool.h"
#import "YRSqliteTool.h"

typedef enum {
    YRSqliteRelation_equal, // 等于
    YRSqliteRelation_notEqual, // 不等于
    YRSqliteRelation_lessThan, //小于
    YRSqliteRelation_lessEqual, //小于等于
    YRSqliteRelation_GreaterThan,//大于
    YRSqliteRelation_GreaterEqual,//大于等于
}YRSqliteRelation;

@interface YRSqliteModeTool : NSObject
#pragma mark- sqlite table 相关
/** 根据一个类创建一张表
 cls: 必须是 继承自 */
+(BOOL)createTable:(Class)cls uid:(NSString *)uid;

/** 判断模型是否需要更新数据库的表*/
+(BOOL)isModeNeedUpdateTable:(Class)cls uid:(NSString *)uid;

/** 更新 cls 对应的数据库的表
 注意: 只有数据库的表结构(字段名 字段类型)发生变化才会迁移数据*/
+(BOOL)updateTable:(Class)cls uid:(NSString *)uid;


#pragma mark- sqlite 增 查 删 改 相关
+(BOOL)saveOrUpdateMode:(id)mode uid:(NSString *)uid;
+(BOOL)saveOrUpdateModeArr:(NSArray *)modeArr uid:(NSString *)uid;


+(NSMutableArray<NSMutableDictionary *> *)queryTable:(Class)cls uid:(NSString *)uid;

+(NSMutableArray<NSMutableDictionary *> *)queryTable:(Class)cls columnName:(NSString *)columnName  relation:(YRSqliteRelation)relation  value:(id)value uid:(NSString *)uid;

@end
