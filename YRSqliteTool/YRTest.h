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
//@property(nonatomic, strong)NSData *data;


@end
