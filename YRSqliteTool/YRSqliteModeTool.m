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
    if (tableName.length == 0 ||
        primaryKey.length == 0 ||
        columnNameTypeStr.length == 0) {
        return NO;
    }
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
   

    NSMutableArray<NSString *>*sqlArrM = [NSMutableArray array];
    
    //1. 创建临时表
    NSString *tempTableName = [YRModeTool tempTableName:cls];
    if(tempTableName.length == 0){
        return NO;
    }
    
    NSString *columnInfo = [YRModeTool columnNameAndSqliteTypeStr:cls];
    if (columnInfo.length == 0) {
        return NO;
    }
    #ifdef DEBUG
    NSLog(@"正在更新 数据库表结构: %@ ...",cls);
    #endif
    NSString *createTempTableSql = [NSString stringWithFormat:@"create table if not exists %@(%@,%@);",tempTableName,[YRModeTool defaultPrimaryKeyColumn],columnInfo ];
    
    [sqlArrM addObject:createTempTableSql];
    
    //2.根据主键插入数据到临时表
    NSString *tableName = [YRModeTool tableName:cls];
    if(tableName.length == 0){
        return NO;
    }
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
        
        //1. 先检查是否有需要替换的字段
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
                    return NO;
                    #endif
                }
            }
        }
        else{
            
            if([oldNameArr containsObject:newName]){ // 上次替换过了次字段,这次就不替换了 直接导数据
                oldName = newName;
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
                        return NO;
                        #endif
                    }
                }
            }
            else{
                if(needChangeOldName.length > 0){
                    #ifdef DEBUG
                    // 需要有版本映射关系
                    NSLog(@"警告!!! 在数据库修改字段名时,新字段:%@, 没找到对应的旧字段: %@  请确认,数据可能丢失",newName,oldName);
                    return NO;
                    #endif
                }
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
            NSLog(@"%@,%@ 更新数据迁移表  失败",cls, uid);
        }
        else{
           NSLog(@"%@,%@ 更新数据迁移表  成功",cls, uid);
        }
    #endif
    return rst;
}


/** 查询所有的记录 */
+(NSMutableArray *)queryModeInTable:(Class)cls uid:(NSString *)uid{
    
   return [self queryModeInTable:cls columnName:nil relation:0 value:nil uid:uid];
}

/** 查询数据中满足条件的记录*/
+(NSMutableArray *)queryModeInTable:(Class)cls columnName:(NSString *)columnName  relation:(YRSqliteRelation)relation value:(id)value  uid:(NSString *)uid{
    if (columnName.length ==  0 && value == nil) {
        return  [self queryModeInTable:cls columnNameArr:nil relationArr:nil valueArr:nil uid:uid];
    }
    
    if (columnName.length >  0 && value ) {
        return  [self queryModeInTable:cls columnNameArr:@[columnName] relationArr:@[@(relation)] valueArr:@[value] uid:uid];
    }
    return nil;
    
   
}

+(NSMutableArray *)queryModeInTable:(Class)cls columnNameArr:(NSArray<NSString *> *)columnNameArr  relationArr:(NSArray<NSNumber *> *)relationArr  valueArr:(NSArray *)valueArr uid:(NSString *)uid{
    
    BOOL rst = [self prepareAccessTable:cls uid:uid];
    if (rst == NO) {
        return nil;
    }
    
    
    if (!(columnNameArr.count == relationArr.count  && relationArr.count == valueArr.count)) {
        return nil;
    }
    
    NSString *tableName = [YRModeTool tableName:cls];
    if (tableName.length == 0) {
        return nil;
    }
    
    NSMutableArray<NSString *> *columnRelationArrM = [NSMutableArray array];
    NSDictionary *relationDic  = [self relationDic];
    for(int i= 0 ; i < columnNameArr.count ; i++){
        NSString *name = columnNameArr[i];
        NSString *relationStr = relationDic[relationArr[i]];
        id value = valueArr[i];
        NSString *columnRelation = [NSString stringWithFormat:@"%@ %@ '%@'",name,relationStr,value ];
        [columnRelationArrM addObject:columnRelation];
    }
    
    NSString *querySql = nil;
    if (columnRelationArrM.count == 0) {
        querySql = [NSString stringWithFormat:@"select * from %@;",tableName];
    }
    
    if (columnRelationArrM.count == 1) {
        
         querySql = [NSString stringWithFormat:@"select * from %@ where %@;",tableName,columnRelationArrM.firstObject  ];
    }
    
    if (columnRelationArrM.count > 1) {
        querySql =  [NSString stringWithFormat:@"select * from %@ where %@;",tableName,[columnRelationArrM componentsJoinedByString:@" and "]];
    }
    
    NSMutableArray<NSMutableDictionary *> *dicArrM = [YRSqliteTool querySql:querySql uid:uid];
    if (dicArrM.count > 0) {
        NSMutableArray *modeArrM = [NSMutableArray array];
        for(NSDictionary *dic in dicArrM){
          [modeArrM addObject:  [YRModeTool modeOfClass:cls fromDic:dic]];
        }
        return modeArrM;
        
    }
   return nil ;
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
    BOOL rst = [self prepareAccessTableArr:clsArrM uid:uid];
    if (rst == NO) {
        return NO;
    }
    
    //3. 更新或插入所有的数据 (一条一条 防止前后 同一条记录)
    for (id mode in modeArr) {
        NSString *updateOrInserSql = [self fetchUpdateOrInsertSql:mode uid:uid];
        if (updateOrInserSql.length == 0) {
            return NO;
        }
        BOOL rst =  [YRSqliteTool dealSql:updateOrInserSql uid:uid];
        if (rst == NO) {
            return NO;
        }
    }
    return YES;
}

+(BOOL)deleteMode:(id)mode uid:(NSString *)uid{
    
    return  [self deleteModeArr:@[mode] uid:uid];
}

+(BOOL)deleteModeArr:(NSArray *)modeArr uid:(NSString *)uid{
    //1. 取出所有的类
    NSMutableArray *clsArrM = [NSMutableArray array];
    for (id mode in modeArr) {
        Class cls = [mode class];
        if (![clsArrM containsObject:cls]) {
            [clsArrM addObject:cls];
        }
    }
    
    //2. 更新所有的表 if need
    BOOL rst = [self prepareAccessTableArr:clsArrM uid:uid];
    if (rst == NO) {
        return NO;
    }
    
    //delete from table where pri = 'pri'
    NSMutableArray *deleteSqlArrM = [NSMutableArray array];
    for (id mode  in modeArr) {
        Class cls = [mode class];
        NSString *tableName = [YRModeTool tableName:cls];
        if (tableName.length == 0) {
            return NO;
        }
        NSString *modifyPrimaryKey = [cls modifyPrimaryKey];
        id value = [mode valueForKeyPath:modifyPrimaryKey];
        if (value == nil) {
            return NO;
        }
        NSString *deleteSql = [NSString stringWithFormat:@"delete from %@ where %@ = '%@'",tableName,modifyPrimaryKey,value ];
        [deleteSqlArrM addObject:deleteSql];
    }
    
   return  [YRSqliteTool dealSqlArr:deleteSqlArrM uid:uid];

}

+(BOOL)deleteModeInTabel:(Class)cls uid:(NSString *)uid{
    return [self deleteModeInTabel:cls columnName:nil relation:0 value:nil uid:uid];
}

+(BOOL)deleteModeInTabel:(Class)cls columnName:(NSString *)columnName  relation:(YRSqliteRelation)relation  value:(id)value uid:(NSString *)uid{
    if (columnName.length ==  0 && value == nil) {
       return  [self deleteModeInTabel:cls columnNameArr:nil relationArr:nil valueArr:nil uid:uid];
    }
    
    if (columnName.length >  0 && value ) {
        return  [self deleteModeInTabel:cls columnNameArr:@[columnName] relationArr:@[@(relation)] valueArr:@[value] uid:uid];
    }
   return NO;
}

+(BOOL)deleteModeInTabel:(Class)cls columnNameArr:(NSArray<NSString *> *)columnNameArr  relationArr:(NSArray<NSNumber *> *)relationArr  valueArr:(NSArray *)valueArr uid:(NSString *)uid{
    
    //1. 更新所有的表 if need
    BOOL rst = [self prepareAccessTable:cls uid:uid];
    if (rst == NO) {
        return NO;
    }
    
    if (!(columnNameArr.count == relationArr.count  && relationArr.count == valueArr.count)) {
        return NO;
    }
    
    NSString *tableName = [YRModeTool tableName:cls];
    if (tableName.length == 0) {
        return NO;
    }
    
    NSMutableArray<NSString *> *columnRelationArrM = [NSMutableArray array];
    NSDictionary *relationDic  = [self relationDic];
    for(int i= 0 ; i < columnNameArr.count ; i++){
        NSString *name = columnNameArr[i];
        NSString *relationStr = relationDic[relationArr[i]];
        id value = valueArr[i];
        NSString *columnRelation = [NSString stringWithFormat:@"%@ %@ '%@'",name,relationStr,value ];
        [columnRelationArrM addObject:columnRelation];
    }
    

    
    NSString *deleteSql = nil;
    if (columnRelationArrM.count == 0) {
      deleteSql =  [NSString stringWithFormat:@"delete from %@;",tableName];
    }
    
    if (columnRelationArrM.count == 1) {
        deleteSql =  [NSString stringWithFormat:@"delete from %@ where %@;",tableName,columnRelationArrM.firstObject];
    }
    
    if (columnRelationArrM.count > 1) {
        deleteSql =  [NSString stringWithFormat:@"delete from %@ where %@;",tableName,[columnRelationArrM componentsJoinedByString:@" and "]];
    }
    
   return  [YRSqliteTool dealSql:deleteSql uid:uid];
}


#pragma mark- 私有方法
+(NSString *)fetchUpdateOrInsertSql:(id)mode uid:(NSString *)uid{
    Class cls = [mode class];
    NSString *updateOrInserColumnSql = nil;
    
    //3. 判断记录是否存在,存在执行更新,不存在执行插入语句
    NSArray  *modeArr  =  [self queryModeInTable:cls uid:uid];
    NSString *tableName = [YRModeTool tableName:cls];
    
    //4. update 表明 set 字段1=字段1值, 字段二=字段2值 ... where 字段=字段值
    NSDictionary *nameValueDic = [YRModeTool ivarNameValueDicOfMode:mode];
    NSString *primaryKey = [cls modifyPrimaryKey];
    BOOL isNeedUpdate = NO;
    for (id m in modeArr) {
        id value = [m valueForKeyPath:primaryKey];
        if (value && [value isEqual: nameValueDic[primaryKey]]) {
            isNeedUpdate = YES;
            break;
        }
    }
    
    __block BOOL isSqlOk = YES;
    if (isNeedUpdate) { // 更新
        
        NSMutableArray *setArrM = [NSMutableArray array];
        [nameValueDic enumerateKeysAndObjectsUsingBlock:^(NSString *name, id value, BOOL * _Nonnull stop) {
        
            if([value isKindOfClass:[NSString class]] && [((NSString *)value) containsString:@"'"]){
                // 
                #ifdef DEBUG
                NSLog(@"更新sql, %@ 类 的 %@ 字段 : \"%@\" 时,发现包含非法字符单引号 (')",cls,name,value);
                #endif
                isSqlOk = NO;
                *stop = YES;
            }
        
            
            [setArrM addObject:[NSString stringWithFormat:@"%@='%@'",name,value]]; ;
        }];
        
        if (isSqlOk == NO) {
            // 字符串中包含了不能包含的 单引号 '
            return nil;
        }
        NSString *setStr = [setArrM componentsJoinedByString:@","];
        
        
        NSString *updateSql = [NSString stringWithFormat:@"update %@ set %@ where %@='%@';",tableName,setStr,primaryKey,nameValueDic[primaryKey]];
        updateOrInserColumnSql = updateSql;
    }
    else{
        // 插入
        //insert into 表明(字段1,字段2..) values ('值1', '值2' ...)
        NSMutableArray *nameArrM = [NSMutableArray array];
        NSMutableArray *valueArrM = [NSMutableArray array];
        [nameValueDic enumerateKeysAndObjectsUsingBlock:^(NSString *name, id value, BOOL * _Nonnull stop) {
            
            if([value isKindOfClass:[NSString class]] && [((NSString *)value) containsString:@"'"]){
                #ifdef DEBUG
                NSLog(@"插入sql, %@ 类 的 %@ 字段 : \"%@\" 时,发现包含非法字符单引号 (')",cls,name,value);
                #endif
                isSqlOk = NO;
                *stop = YES;
            }
            [nameArrM addObject:name];
            [valueArrM addObject:value];
            
            
        }];
        
        if (isSqlOk == NO) {
            // 字符串中包含了不能包含的 单引号 '
            return nil;
        }
        NSString *namesStr = [NSString stringWithFormat:@"(%@)",[nameArrM componentsJoinedByString:@","]];
        NSString *valuesStr = [NSString stringWithFormat:@"('%@')",[valueArrM componentsJoinedByString:@"','"]];
        NSString *insertSql = [NSString stringWithFormat:@"insert into %@ %@ values %@;",tableName, namesStr, valuesStr];
        updateOrInserColumnSql = insertSql;
    }
    return updateOrInserColumnSql;
}
/** 对 数据库进行 增 查 删 改 前 要对数据库的表状态进行 确认*/
+(BOOL)prepareAccessTableArr:(NSArray<Class> *)tableArr  uid:(NSString *)uid{
    
    for (Class cls in tableArr) {
        BOOL rst = [self prepareAccessTable:cls uid:uid];
        if (rst == NO) {
            return NO;
        }
    }
    return YES;
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
    if([self isModeNeedUpdateTable:cls uid:uid]){
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
