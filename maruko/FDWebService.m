//
//  FDWebService.m
//  maruko
//
//  Created by 王澍宇 on 16/2/22.
//  Copyright © 2016年 Shuyu. All rights reserved.
//

#import "FDWebService.h"

@implementation FDWebService

+ (void)commonRequestWithAPI:(NSString *)api Method:(NSString *)method Parms:(NSDictionary *)parms Block:(void (^)(BOOL, NSDictionary *))block {
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    
    [[FDNetworkEngine sharedEngine] addSessionTaskWithAPI:api Method:method Parms:[parms copy] Callback:^(NSDictionary *reseponseDic, NSError *error) {
        
        [FDWebService commonActionWithReseponseDic:reseponseDic Error:error Block:block];
        
    }];
}

+ (void)commonActionWithReseponseDic:(NSDictionary *)reseponseDic Error:(NSError *)error Block:(void (^)(BOOL, NSDictionary *))block {
    
    BOOL isSuccess = error ? NO : YES;
    
    NSString *message = error ? error.domain : reseponseDic[@"msg"];
    
    if (isSuccess) {
        [SVProgressHUD showSuccessWithStatus:message];
    } else {
        [SVProgressHUD showErrorWithStatus:message];
    }
    
    NSDictionary *resultDic = reseponseDic[kResultsKey];
    
    if (block) {
        block(isSuccess, isSuccess ? resultDic : nil);
    }
}

@end
