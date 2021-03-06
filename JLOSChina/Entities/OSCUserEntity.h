//
//  RCUserEntity.h
//  JLOSChina
//
//  Created by jimneylee on 13-12-10.
//  Copyright (c) 2013年 jimneylee. All rights reserved.
//

#import "JLNimbusEntity.h"

@interface OSCUserEntity : JLNimbusEntity

@property (nonatomic, copy) NSString *authorId;
@property (nonatomic, copy) NSString *authorName;
@property (nonatomic, copy) NSString *avatarUrl;

@end
