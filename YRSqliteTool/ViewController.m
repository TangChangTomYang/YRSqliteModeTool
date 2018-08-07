//
//  ViewController.m
//  YRSqliteTool
//
//  Created by yangrui on 2018/8/3.
//  Copyright © 2018年 yangrui. All rights reserved.
//

#import "ViewController.h"
#import "YRTest.h"
#import "YRSqliteModeTool.h"

#import "YRTableTool.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSNumber *num1 = @(0.0);
    NSNumber *num2 = @(0);
    NSString *str1 = @"";
    NSData *data1  = [NSData data];
    NSData *data2  = [NSData data];
    if ([data1 isEqual:data2]) {
        NSLog(@"相同");
    }
    else{
        NSLog(@"不同");
    }
    if ([num1 isEqual:num2]) {
        NSLog(@"相同");
    }
    else{
        NSLog(@"不同");
    }
    
    // Do any additional setup after loading the view, typically from a nib.
    
    
    NSMutableDictionary *diM ;
    [diM setValue:nil forKey:@"dsf"];
}


-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    YRTest *testMode = [YRTest new];
    testMode.name = @"wangwu";
    testMode.num = 22;
    testMode.age122 = 20;
    testMode.height1 = 1.78;
    testMode.isMan1 = YES;
//    testMode.data = nil;
   BOOL isSave = [YRSqliteModeTool saveOrUpdateMode:testMode uid:@"yangrui"];
     NSLog(@"isSave: %d",isSave);
  
//    BOOL exists = [YRTableTool isTableExists:[YRTest class] uid:@"yangrui"];
//    NSLog(@"exists: %d",exists);
    
//    BOOL result = [YRSqliteModeTool createTable:[YRTest class] uid:@"yangrui"];
//    NSLog(@"result: %d",result);
    
     BOOL rst =[YRSqliteModeTool updateTable:[YRTest class] uid:@"yangrui"];
     NSLog(@"rst: %d",rst);
//
//    NSMutableArray *arrM0 = [YRModeTool sortedColumnNames:[YRTest class]];
//    NSLog(@"arrM0: %@",arrM0);
//
//    NSMutableArray *arrM = [YRTableTool sortedColumnNames:[YRTest class] uid:@"yangrui"];
//    NSLog(@"arrM: %@",arrM);
//
//    BOOL isNeed = [YRSqliteModeTool isModeNeedUpdateTable:[YRTest class] uid:@"yangrui"];
//
//    NSLog(@"isNeed: %d",isNeed);
}

@end
