//
//  YRSqliteModeProtocol.h
//  YRSqliteTool
//
//  Created by yangrui on 2018/8/4.
//  Copyright © 2018年 yangrui. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol YRSqliteModeProtocol <NSObject>

@required
/** 数据库记录 增 删 改 时,记录的查询主键 */
+(NSString *)modifyPrimaryKey;



@optional
/** 需要忽略的字段s*/
+(NSArray<NSString *> *)ignoreNames;


 // 比如1.0 -> 2.0 数据库的变化
 // 1.0 -> 3.0 数据库的变化
 // 更具不同版本数据迁移做不同的映射关系
/** 需要交换的 字典, newName : oldName*/
+(NSDictionary<NSString *, NSString *> *)newName2OldNameDic;
@end
