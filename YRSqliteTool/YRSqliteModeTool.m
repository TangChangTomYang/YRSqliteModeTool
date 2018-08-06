//
//  YRSqliteModeTool.m
//  YRSqliteTool
//
//  Created by yangrui on 2018/8/4.
//  Copyright © 2018年 yangrui. All rights reserved.
//

#import "YRSqliteModeTool.h"

#import "YRModeTool.h"
#import "YRSqliteTool.h"
#import "YRTableTool.h"

@implementation YRSqliteModeTool


/** 根据一个类创建一张表*/
+(BOOL)createTable:(Class)cls uid:(NSString *)uid{
    
    NSString *tableName = [YRModeTool tableName:cls];
    NSString *primaryKey = [YRModeTool defaultPrimaryKeyColumn];
    NSString *columnNameTypeStr = [YRModeTool columnNameAndSqliteTypeStr:cls];
    NSString *createTableSql = [NSString stringWithFormat:@"create table if not exists %@(%@,%@);",tableName,primaryKey, columnNameTypeStr];
    return [YRSqliteTool dealSql:createTableSql uid:uid];
}

/** 判断模型是否需要更新数据库的表*/
+(BOOL)isModeNeedUpdateTable:(Class)cls uid:(NSString *)uid{
    
   NSArray *newNames = [YRModeTool sortedColumnNames:cls];
   NSArray *oldNames = [YRTableTool sortedColumnNames:cls uid:uid];

    if(newNames.count != oldNames.count){
        return YES;
    }
    
    // 判断字段名是否 一致
    for(int i = 0 ; i < newNames.count ; i++){
        NSString *newName = newNames[i];
        NSString *oldName = oldNames[i];
        
        if(![newName isEqualToString:oldName]){
            return YES;
        }
    }
    
    //字段名一致,判断字段类型是否一致
    NSMutableDictionary *newNameTypeDic = [YRModeTool classIvarNameSqliteTypeDic:cls];
    NSMutableDictionary *oldNameTypeDic = [YRTableTool tableColumnNameTypeDic:cls uid:uid];
    for (int a = 0; a < newNames.count; a ++) {
        NSString *name = newNames[a];
        if (![newNameTypeDic[name] isEqualToString:oldNameTypeDic[name]]) {
            return YES;
        }
    }
    
    
    return NO;
}

/** 更新 cls 对应的数据库的表*/
+(BOOL)updateTable:(Class)cls uid:(NSString *)uid{
    
    if(![self isModeNeedUpdateTable:cls uid:uid] ) {
        return YES;
    }
    #ifdef DEBUG
        NSLog(@"正在更新 数据库表: %@ ...",cls);
    #endif

    NSMutableArray<NSString *>*sqlArrM = [NSMutableArray array];
    
    //1. 创建临时表
    NSString *tempTableName = [YRModeTool tempTableName:cls];
    NSString *createTempTableSql = [NSString stringWithFormat:@"create table if not exists %@(%@,%@);",tempTableName,[YRModeTool defaultPrimaryKeyColumn], [YRModeTool columnNameAndSqliteTypeStr:cls]];
    [sqlArrM addObject:createTempTableSql];
    
    //2.根据主键插入数据到临时表
    NSString *tableName = [YRModeTool tableName:cls];
    NSString *primaryKey = kPrimaryKeyName;
    NSString *inserPrimarySql = [NSString stringWithFormat:@"insert into %@(%@) select %@ from %@;",tempTableName,primaryKey,primaryKey,tableName];
    [sqlArrM addObject:inserPrimarySql];
    
    //3.根据主键把其他的所有数据插入临时表中
    NSArray *newNameArr = [YRModeTool sortedColumnNames:cls];
    NSArray *oldNameArr = [YRTableTool sortedColumnNames:cls uid:uid];
    NSMutableDictionary *modeNameTypeDic = [YRModeTool classIvarNameSqliteTypeDic:cls];
    NSMutableDictionary *tableNameTypeDic = [YRTableTool tableColumnNameTypeDic:cls uid:uid];
    
    // 需要更换名字的字段
    NSDictionary *changeNameDic = nil;
    if ([cls  respondsToSelector:@selector(newName2OldNameDic)]) {
        changeNameDic = [cls newName2OldNameDic];
    }
    
    for(NSString *newName in newNameArr){
        
        NSString *oldName = newName;
        NSString *needChangeOldName = changeNameDic[newName];
        if (needChangeOldName.length > 0) {
            oldName = needChangeOldName;
        }
        
        if([oldNameArr containsObject:oldName] ){
            
            NSString *newNameType = modeNameTypeDic[newName];
            NSString *oldNameType = tableNameTypeDic[oldName];
            if([newNameType isEqualToString:oldNameType]){
                
                NSString *updateColumnSql = [NSString stringWithFormat:@"update %@ set %@ = (select %@ from %@ where %@.%@ = %@.%@);",tempTableName, newName, oldName, tableName,  tempTableName,primaryKey ,  tableName,primaryKey];
                [sqlArrM addObject:updateColumnSql];
            }
            else{// 字段名有变化 字段类型没匹配上
                if(needChangeOldName.length > 0){
                    #ifdef DEBUG
                        // 需要有版本映射关系
                        NSLog(@"警告!!! 在数据库修改字段名时, 旧字段名: %@ 新字段:%@, 类型不匹配, 旧类型: %@ 新类型: %@ 请确认, 数据可能丢失",oldName ,newName,oldNameType,newNameType  );
                    #endif
                }
          }
        }
        else{
            
            if(needChangeOldName.length > 0){
                #ifdef DEBUG
                    // 需要有版本映射关系
                    NSLog(@"警告!!! 在数据库修改字段名时,新字段:%@, 没找到对应的旧字段: %@  请确认,数据可能丢失",newName,oldName);
                #endif
            }
        }
      
    }
    
    //4.删除旧表
    NSString *deleteTableSql = [NSString stringWithFormat:@"drop table if exists %@;",tableName];
    [sqlArrM addObject:deleteTableSql];
    
    //5.将临时表名 更新会 正式表名
    NSString *renameTableName = [NSString stringWithFormat:@"alter table %@ rename to %@;",tempTableName, tableName];
    [sqlArrM addObject:renameTableName];
    
    BOOL rst = [YRSqliteTool dealSqlArr:sqlArrM uid:uid];
    #ifdef DEBUG
        if (rst == NO ) {
            NSLog(@"%@,%@ 更新数据迁移表失败",cls, uid);
        }
    #endif
    return rst;
}


/** 查询所有的记录 */
+(NSMutableArray<NSMutableDictionary *> *)queryTable:(Class)cls uid:(NSString *)uid{
  return   [self queryTable:cls columnName:nil relation:0 value:nil uid:uid];
}


/** 查询数据中满足条件的记录*/
+(NSMutableArray<NSMutableDictionary *> *)queryTable:(Class)cls
                                          columnName:(NSString *)columnName
                                            relation:(YRSqliteRelation)relation
                                               value:(id)value
                                                 uid:(NSString *)uid{
   
    
    BOOL rst = [self prepareAccessTable:cls uid:uid];
    if (rst == NO) {
        return nil;
    }
    NSString *tableName = [YRModeTool tableName:cls];
    NSString *relationStr = [self relationDic][@(relation)];
    NSString *querySql = nil;
    if(columnName.length > 0 && value != nil){
        querySql = [NSString stringWithFormat:@"select * from %@ where %@ %@ '%@';",tableName,columnName,relationStr, value  ];
    }
    else{
        querySql = [NSString stringWithFormat:@"select * from %@;",tableName];
    }
    
   return [YRSqliteTool querySql:querySql uid:uid];
}


+(BOOL)saveOrUpdateMode:(id)mode uid:(NSString *)uid{
    
   return  [self saveOrUpdateModeArr:@[mode] uid:uid];
}

+(BOOL)saveOrUpdateModeArr:(NSArray *)modeArr uid:(NSString *)uid{
    
    //1. 取出所有的类
    NSMutableArray *clsArrM = [NSMutableArray array];
    for (id mode in modeArr) {
        Class cls = [mode class];
        if (![clsArrM containsObject:cls]) {
            [clsArrM addObject:cls];
        }
    }
    
    //2. 更新所有的表 if need
    for (Class cls in clsArrM) {
        BOOL rst = [self prepareAccessTable:cls uid:uid];
        if (rst == NO) {
            return NO;
        }
    }
    
    //3. 更新或插入所有的数据 (一条一条 防止前后 同一条记录)
    for (id mode in modeArr) {
        NSString *updateOrInserSql = [self updateOrInsertSql:mode uid:uid];;
        BOOL rst =  [YRSqliteTool dealSql:updateOrInserSql uid:uid];
        if (rst == NO) {
            return NO;
        }
    }
    return YES;
}


#pragma mark- 私有方法


+(NSString *)updateOrInsertSql:(id)mode uid:(NSString *)uid{
    Class cls = [mode class];
    NSString *updateOrInserSql = nil;
    
    //3. 判断记录是否存在,存在执行更新,不存在执行插入语句
    NSMutableArray<NSMutableDictionary *> *dicArrM =  [self queryTable:cls uid:uid];
    NSString *tableName = [YRModeTool tableName:cls];
    
    //4. update 表明 set 字段1=字段1值, 字段二=字段2值 ... where 字段=字段值
    NSDictionary *nameValueDic = [YRModeTool ivarNameValueDicOfMode:mode];
    NSString *primaryKey = [cls modifyPrimaryKey];
    BOOL isNeedUpdate = NO;
    for (NSDictionary *dic in dicArrM) {
        if ([dic[primaryKey] isEqual: nameValueDic[primaryKey]]) {
            isNeedUpdate = YES;
            break;
        }
    }
    
    if (isNeedUpdate) {
        NSMutableArray *setArrM = [NSMutableArray array];
        [nameValueDic enumerateKeysAndObjectsUsingBlock:^(NSString *name, id value, BOOL * _Nonnull stop) {
            [setArrM addObject:[NSString stringWithFormat:@"%@='%@'",name,value]]; ;
        }];
        NSString *setStr = [setArrM componentsJoinedByString:@","];
        
        
        NSString *updateSql = [NSString stringWithFormat:@"update %@ set %@ where %@='%@';",tableName,setStr,primaryKey,nameValueDic[primaryKey]];
        updateOrInserSql = updateSql;
    }
    else{
        // 插入
        //insert into 表明(字段1,字段2..) values ('值1', '值2' ...)
        NSMutableArray *nameArrM = [NSMutableArray array];
        NSMutableArray *valueArrM = [NSMutableArray array];
        [nameValueDic enumerateKeysAndObjectsUsingBlock:^(NSString *name, id value, BOOL * _Nonnull stop) {
            [nameArrM addObject:name];
            [valueArrM addObject:value];
        }];
        
        NSString *namesStr = [NSString stringWithFormat:@"(%@)",[nameArrM componentsJoinedByString:@","]];
        NSString *valuesStr = [NSString stringWithFormat:@"('%@')",[valueArrM componentsJoinedByString:@"','"]];
        NSString *insertSql = [NSString stringWithFormat:@"insert into %@ %@ values %@;",tableName, namesStr, valuesStr];
        updateOrInserSql = insertSql;
    }
    return updateOrInserSql;
}
/** 对 数据库进行 增 查 删 改 前 要对数据库的表状态进行 确认*/
+(BOOL)prepareAccessTable:(Class)cls  uid:(NSString *)uid{
    
    //1. 判断表格是否存在,不存在就创建
    if (![YRTableTool isTableExists:cls uid:uid]) {
        BOOL rst = [self createTable:cls uid:uid];
        if(rst == NO){
            return NO;
        }
    }
    
    //2. 检测表格是否需要更新,需要就更新
    if(![self isModeNeedUpdateTable:cls uid:uid]){
        BOOL rst2 =  [self updateTable:cls uid:uid];
        if(rst2 == NO){
            return NO;
        }
    }
    return YES;
}



+(NSDictionary<NSNumber *, NSString *> *)relationDic{
    return  @{ @(YRSqliteRelation_equal):@"=", // 等于
               @(YRSqliteRelation_notEqual):@"!=", // 不等于
               @(YRSqliteRelation_lessThan):@"<", //小于
               @(YRSqliteRelation_lessEqual):@"<=", //小于等于
               @(YRSqliteRelation_GreaterThan):@">",//大于
               @(YRSqliteRelation_GreaterEqual):@">="//大于等于
               
               };
}


@end