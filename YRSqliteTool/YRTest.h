//
//  YRTest.h
//  YRSqliteTool
//
//  Created by yangrui on 2018/8/4.
//  Copyright © 2018年 yangrui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YRSqliteModeProtocol.h"

@interface YRTest : NSObject<YRSqliteModeProtocol>



@property(nonatomic, assign)int num;
@property(nonatomic, assign)int  age122;
@property(nonatomic, assign)float height1;
@property(nonatomic, assign)BOOL isMan1;
@property(nonatomic, strong)NSString *name;


// 以下几种数据需要 兼容
//@property(nonatomic, strong)id<YRSqliteModeProtocol> obj;
//@property(nonatomic, strong)NSArray<id<YRSqliteModeProtocol>> *objArr;
//@property(nonatomic, strong)NSMutableArray<id<YRSqliteModeProtocol>> *objArrM;

//因为我们采用的是 动态拼接 sql 语句 ,比如: select * from table where name = '张三' ,因此 字符串中是不能存在有 ' 单引号的,  比如: name = abc'adf
//这样是有 sql 注入式 攻击的问题



@end
