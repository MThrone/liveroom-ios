//
//  LRSpeakViewController.h
//  liveroom
//
//  Created by 杜洁鹏 on 2019/4/4.
//  Copyright © 2019 Easemob. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LRTypes.h"

NS_ASSUME_NONNULL_BEGIN

@class LRSpeakerCellModel, LRRoomModel;
@interface LRSpeakViewController : UIViewController
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) LRRoomModel *roomModel;
@end

@interface LRSpeakerCell : UITableViewCell
@property (nonatomic, strong) LRSpeakerCellModel *model;
- (void)updateSubViewUI;
@end

@interface LRSpeakerCellModel : NSObject
@property (nonatomic, strong) NSString *username;

@property (nonatomic) LRRoomType type;
@property (nonatomic) BOOL isOwner; 
@property (nonatomic) BOOL isAdmin;
@property (nonatomic) BOOL isMyself;
@property (nonatomic) BOOL isMute;


@property (nonatomic) BOOL voiceOn;
@property (nonatomic) BOOL talkOn;
@property (nonatomic) BOOL argumentOn;
@property (nonatomic) BOOL unArgumentOn;

@end

NS_ASSUME_NONNULL_END