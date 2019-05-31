//
//  LRRoomModel.m
//  Tigercrew
//
//  Created by easemob-DN0164 on 2019/4/1.
//  Copyright © 2019年 Easemob. All rights reserved.
//

#import "LRRoomModel.h"

@implementation LRRoomModel

+ (instancetype)roomWithDict:(NSDictionary *)dict
{
    LRRoomModel *model = [[LRRoomModel alloc] init];
    model.roomname = dict[@"roomName"];
    model.roomId = dict[@"roomId"];
    model.conferenceId = dict[@"rtcConfrId"];
    model.owner = dict[@"ownerName"];
    model.maxCount = [dict[@"rtcConfrAudienceLimit"] intValue];
    model.createTime =  dict[@"rtcConfrCreateTime"];
    model.allowAudienceOnSpeaker = [dict[@"allowAudienceTalk"] boolValue];
    model.conferencePassword = [dict[@"rtcConfrPassword"] intValue];
    model.roomType = LRRoomType_Communication; // 默认值
    return model;
}

@end
