//
//  YRTest.m
//  YRSqliteTool
//
//  Created by yangrui on 2018/8/4.
//  Copyright © 2018年 yangrui. All rights reserved.
//

#import "YRTest.h"

@implementation YRTest



/** 数据库记录 增 删 改 时,记录的查询主键 */
+(NSString *)modifyPrimaryKey{
    return @"num";
}


+(NSArray<NSString *> *)ignoreNames{
    return @[@"rect", @"size",@"point"];
}


///** 需要交换的 字典, newName : oldName */
//+(NSDictionary<NSString *, NSString *> *)newName2OldNameDic{
//    
//    // 这里需要引入版本控制
//    // 比如1.0 -> 2.0 数据库的变化
//    // 1.0 -> 3.0 数据库的变化
//    
//    return   @{@"age":@"age1", @"stu_name":@"name"};
//}


@end
