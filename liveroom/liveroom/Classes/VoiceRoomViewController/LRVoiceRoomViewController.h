//
//  LRVoiceRoomViewController.h
//  liveroom
//
//  Created by 杜洁鹏 on 2019/4/3.
//  Copyright © 2019 Easemob. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    LRUserType_Admin,
    LRUserType_Speaker,
    LRUserType_Audiance,
} LRUserRoleType;

@interface LRVoiceRoomViewController : UIViewController
- (instancetype)initWithUserType:(LRUserRoleType)aType
                        roomName:(NSString *)aRoomName;
@end

NS_ASSUME_NONNULL_END