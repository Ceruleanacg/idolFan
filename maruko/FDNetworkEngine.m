//
//  FDNetworkEngine.m
//  maruko
//
//  Created by 王澍宇 on 16/2/22.
//  Copyright © 2016年 Shuyu. All rights reserved.
//

#import "FDNetworkEngine.h"
#import "Marcos.h"

static FDNetworkEngine *_engine;

@implementation FDNetworkEngine {
    
    NSString *_hostName;
    NSString *_apiVersion;
    
    NSURL *_baseURL;
    
    NSDictionary *_apiDic;
    NSDictionary *_modelMap;
    
    AFHTTPRequestSerializer *_httpRequestSerializer;
    AFJSONRequestSerializer *_jsonRequestSerializer;
    
}

+ (instancetype)sharedEngine {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _engine = [self new];
    });
    
    return _engine;
}

- (instancetype)init {
    if (self = [super init]) {
        NSString *apiConfigPath = [[NSBundle mainBundle] pathForResource:@"api" ofType:@"plist"];
        
        NSDictionary *apiConfigDic = [NSDictionary dictionaryWithContentsOfFile:apiConfigPath];
        
        _apiDic = [apiConfigDic copy];
        
        if (!_apiDic) {
            NSAssert(NO, @"API配置读取失败");
        }
        
#ifdef DEBUG
        _hostName   = _apiDic[@"DEBUG_HOST"];
#else
        _hostName   = _apiDic[@"RELEASE_HOST"];
#endif
        _modelMap   = _apiDic[@"MODEL_MAP"];
        _apiVersion = _apiDic[@"API_VERSION"];
        
        _baseURL    = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/%@", _hostName, _apiVersion]];
        
        _httpRequestSerializer = [AFHTTPRequestSerializer serializer];
        _jsonRequestSerializer = [AFJSONRequestSerializer serializer];
    }
    
    return self;
}

- (void)addSessionTaskWithAPI:(NSString *)api Method:(NSString *)method Parms:(NSDictionary *)parms Callback:(FDRequestCallback)callback {
    
    BOOL isReachable = [self networkReachable];
    
    if (!isReachable) {
        return;
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSString *urlString = [[_baseURL URLByAppendingPathComponent:api] absoluteString];
    
    WeakSelf;
    
    void (^successBlock)(NSURLSessionDataTask *task, id responseObject) = ^(NSURLSessionDataTask *task, id responseObject) {
        
        StrongSelf;
        
        [s_self successActionWithTask:task ResponseObject:responseObject Callback:callback];
        
    };
    
    void (^failureBlock)(NSURLSessionDataTask *task, NSError *error) = ^(NSURLSessionDataTask *task, NSError *error) {
        
        StrongSelf;
        
        [s_self failureActionWithAPI:api Task:task Error:error Callback:callback];
    };
    
    if ([method isEqualToString:@"GET"]) {
        [manager setRequestSerializer:_httpRequestSerializer];
        [manager GET:urlString parameters:[parms copy] success:successBlock failure:failureBlock];
    } else if ([method isEqualToString:@"POST"]) {
        [manager setRequestSerializer:_jsonRequestSerializer];
        [manager POST:urlString parameters:[parms copy] success:successBlock failure:failureBlock];
    } else if ([method isEqualToString:@"DELETE"]) {
        [manager setRequestSerializer:_jsonRequestSerializer];
        [manager DELETE:urlString parameters:[parms copy] success:successBlock failure:failureBlock];
    } else {
        NSAssert(NO, @"Unknown method for api currently!");
    }
}

- (void)successActionWithTask:(NSURLSessionDataTask *)task ResponseObject:(id)responseObject Callback:(FDRequestCallback)callback {
    
    NSDictionary *responseDic = [responseObject copy];
    
    FDStatus status = [responseDic[@"code"] integerValue];
    
    NSString *message = [responseDic[@"msg"] copy];
    
    NSError *error = nil;
    
    if (status == FDStatusError) {
        error = [NSError errorWithDomain:message code:status userInfo:nil];
    }
    
    if (callback) {
        callback(responseDic, error);
    }
}

- (void)failureActionWithAPI:(NSString *)api Task:(NSURLSessionDataTask *)task Error:(NSError *)error Callback:(FDRequestCallback)callback {
    
    NSInteger statusCode = [(NSHTTPURLResponse *)task.response statusCode];
    
    NSError *localError = [NSError errorWithDomain:error.userInfo[NSLocalizedDescriptionKey] code:statusCode userInfo:error.userInfo];
    
    NSLog(@"API: '%@' error with status code %ld , domain : '%@'", api, (long)localError.code, localError.domain);
    
    if (callback) {
        callback(nil, localError);
    }
}


#pragma mark - Helper Method

- (BOOL)networkReachable {
    return [[AFNetworkReachabilityManager sharedManager] isReachable];
}

@end
