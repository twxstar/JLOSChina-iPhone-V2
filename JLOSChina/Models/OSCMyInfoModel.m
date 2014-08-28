//
//  RCLoginModel.m
//  RubyChina
//
//  Created by jimneylee on 13-7-25.
//  Copyright (c) 2013年 jimneylee. All rights reserved.
//

#import "OSCMyInfoModel.h"
#import "OSCAPIClient.h"

@interface OSCMyInfoModel()

@end
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation OSCMyInfoModel

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - LifeCycle

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init
{
    self = [super init];
    if (self) {
        self.itemElementNamesArray = @[XML_USER];
    }
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)loadMyInfoWithBlock:(void(^)(OSCUserFullEntity* entity, OSCErrorEntity* errorEntity))block
{
    self.returnBlock = block;
    
    [self getParams:nil errorBlock:^(OSCErrorEntity *errorEntity) {
        if (!errorEntity || ERROR_CODE_SUCCESS_200 == errorEntity.errorCode) {
            block(self.userEntity, errorEntity);
        }
        else {
            block(nil, errorEntity);
        }
    }];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Override

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString*)relativePath
{
    return [OSCAPIClient relativePathForMyInfo];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)parseDataDictionary
{
    NSMutableDictionary* dic = self.dataDictionary[XML_USER];
    // TODO: dirty code: set uid -> authorid, name -> author
    if (dic[@"uid"]) {
        [dic setObject:dic[@"uid"] forKey:@"authorid"];
    }
    if (dic[@"name"]) {
        [dic setObject:dic[@"name"] forKey:@"author"];
    }
    self.userEntity = [OSCUserFullEntity entityWithDictionary:dic];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didFinishLoad
{
    if (!self.errorEntity || ERROR_CODE_SUCCESS_200 == self.errorEntity.errorCode) {
        self.returnBlock(self.userEntity, self.errorEntity);
    }
    else {
        self.returnBlock(nil, self.errorEntity);
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didFailLoad
{
    self.returnBlock(nil, self.errorEntity);
}

@end
