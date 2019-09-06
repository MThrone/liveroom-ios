//
//  LRTypes.h
//  liveroom
//
//  Created by 杜洁鹏 on 2019/4/22.
//  Copyright © 2019 Easemob. All rights reserved.
//

#ifndef LRTypes_h
#define LRTypes_h


// 会议模式
typedef enum : NSUInteger {
    LRRoomType_Communication = 1,          // 自由麦模式
    LRRoomType_Host,                       // 主持模式
    LRRoomType_Monopoly,                   // 抢麦模式
    LRRoomType_Pentakill              // 狼人杀模式
} LRRoomType;

// 角色
typedef enum : NSUInteger {
    LRUserType_Admin,
    LRUserType_Speaker,
    LRUserType_Audiance,
} LRUserRoleType;

//狼人杀模式下的白天黑夜状态
//当前房间时间钟的昼夜
typedef enum : NSInteger {
    LRTerminator_dayTime = 1,  //白天
    LRTerminator_night     //晚上
} LRTerminator;

#endif /* LRTypes_h */
