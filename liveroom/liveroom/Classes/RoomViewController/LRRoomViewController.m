//
//  LRRoomViewController.m
//  liveroom
//
//  Created by 杜洁鹏 on 2019/4/3.
//  Copyright © 2019 Easemob. All rights reserved.
//

#import "LRRoomViewController.h"
#import "LRSpeakViewController.h"
#import "LRChatViewController.h"
#import "LRVoiceRoomHeader.h"
#import "LRVoiceRoomTabbar.h"
#import "LRRoomModel.h"
#import "Headers.h"
#import "LRRoomInfoViewController.h"
#import "LRRoomSettingViewController.h"
#import "UIViewController+LRAlert.h"

#import "LRChatHelper.h"
#import "LRSpeakHelper.h"
#import <AVFoundation/AVFoundation.h>

#import "LRSpeakerCommunicationViewController.h"
#import "LRSpeakerHostViewController.h"
#import "LRSpeakerMonopolyViewController.h"
#import "LRSpeakerPentakillController.h"
#import "LRSpeakerPentakillCell.h"

#define kPadding 15
#define kHeaderViewHeight 45
#define kInputViewHeight 64

@interface LRRoomViewController () <LRVoiceRoomTabbarDelgate, LRSpeakHelperDelegate, LRChatHelperDelegate> {
    BOOL _chatJoined;
    BOOL _conferenceJoined;
    BOOL _chatLeave;
    BOOL _conferenceLeave;
}
@property (nonatomic, assign) LRUserRoleType type;
@property (nonatomic, strong) LRVoiceRoomHeader *headerView;
@property (nonatomic, strong) LRSpeakViewController *speakerVC;
@property (nonatomic, strong) LRChatViewController *chatVC;
@property (nonatomic, strong) LRVoiceRoomTabbar *inputBar;
@property (nonatomic, strong) LRRoomModel *roomModel;
@property (nonatomic, strong) NSString *password;

@property (nonatomic, strong) UIButton *applyOnSpeakBtn;
@property (nonatomic, strong) NSMutableArray *itemAry;
@property (nonatomic, assign) BOOL isSelect;
@property (nonatomic, strong) NSString *errorInfo;
@property (nonatomic, strong) NSString *roomErrorInfo;
@property (nonatomic, strong) NSMutableArray *requestList;
@property (nonatomic) BOOL isAlertShow;
@property (nonatomic) BOOL isShareAlertShow;

@property (nonatomic, weak) NSString *requestUserIdentity;//请求上麦用户身份

@end

@implementation LRRoomViewController

- (instancetype)initWithUserType:(LRUserRoleType)aType
                       roomModel:(LRRoomModel *)aRoomModel
                        password:(NSString *)aPassword {
    if (self = [super init]) {
        _type = aType;
        _roomModel = aRoomModel;
        _password = aPassword;
        self.speakerVC.roomModel = _roomModel;
        self.chatVC.roomModel = _roomModel;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self regieterNotifiers];
    [self _setupSubViews];
    [self _updateHeaderView];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chatTapAction:)];
    [self.chatVC.view addGestureRecognizer:tap];
    [self joinChatAndConferenceRoom];
}

- (void)regieterNotifiers {
    [LRSpeakHelper.sharedInstance addDeelgate:self delegateQueue:nil];
    [LRChatHelper.sharedInstance addDeelgate:self delegateQueue:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(parseRequestNoti:)
                                                 name:LR_Receive_OnSpeak_Request_Notification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveRequestReject:)
                                                 name:LR_Receive_OnSpeak_Reject_Notification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveRequestAgreed:)
                                                 name:LR_UI_ChangeRoleToSpeaker_Notification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeToAudience:)
                                                 name:LR_UI_ChangeRoleToAudience_Notification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(chatroomDidDestory:)
                                                 name:LR_Receive_Conference_Destory_Notification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLoginOtherDevice:)
                                                 name:LR_Did_Login_Other_Device_Notification
                                               object:nil];
    
}

//添加狼人进数组
- (void)addWereWolfArry:(NSString *)user {
    [LRSpeakHelper.sharedInstance.identityDic addObject:user];
    for(NSString *str in LRSpeakHelper.sharedInstance.identityDic){
        NSLog(@"\n------>array:   %@",str);
    }
    NSString *str = [LRSpeakHelper.sharedInstance.identityDic componentsJoinedByString:@","];
    [EMClient.sharedClient.conferenceManager setConferenceAttribute:@"identityDic" value:str completion:^(EMError *aError){}];
}

// 收到上麦申请
- (void)parseRequestNoti:(NSNotification *)aNoti  {
    NSDictionary *dict = aNoti.object;
    NSString *username = dict[@"from"];
    NSString *confid = dict[@"confid"];
    _requestUserIdentity = dict[@"requestUserIdentity"];
    if (![confid isEqualToString:self.roomModel.conferenceId]) {
        return;
    }
    
    LRRoomOptions *options = [LRRoomOptions sharedOptions];
    if (options.isAllowApplyAsSpeaker) {
        [LRSpeakHelper.sharedInstance setupUserToSpeaker:username
                                              completion:^(BOOL success, NSString *username)
         {
             if (!success) {
                 [LRSpeakHelper.sharedInstance forbidUserOnSpeaker:username];
             }
         }];
    }else {
        if (username) {
            if (!_requestList) {
                _requestList = [NSMutableArray array];
            }
            @synchronized (self.requestList) {
                [_requestList addObject:username];
            }
            [self showRequestInfoFromRequestList];
        }
    }
}

- (void)showRequestInfoFromRequestList {
    if (_isAlertShow) {
        return;
    }
    if (_requestList.count == 0) {
        return;
    }
    
    if (self.speakerVC.memberList.count >= 6) {
        [self rejectAllRequestMember];
        return ;
    }
    
    __weak typeof(self) weakSelf = self;
    NSString *username = _requestList.firstObject;
    NSString *info = [NSString stringWithFormat:@"%@ 申请上麦，同意么?", username];
    LRAlertController *alert = [LRAlertController showTipsAlertWithTitle:@"收到上麦申请" info:info];
    LRAlertAction *agreed = [LRAlertAction alertActionTitle:@"同意" callback:^(LRAlertController * _Nonnull alertController) {
        if(weakSelf.requestUserIdentity){
            if([weakSelf.requestUserIdentity isEqualToString:@"pentakill"]){
                [weakSelf addWereWolfArry:username];
                weakSelf.requestUserIdentity = nil;
            }else if([weakSelf.requestUserIdentity isEqualToString:@"villager"]){
                //村民身份也要发通知，刷新身份图标
                NSString *str = [LRSpeakHelper.sharedInstance.identityDic componentsJoinedByString:@","];
                [EMClient.sharedClient.conferenceManager setConferenceAttribute:@"identityDic" value:str completion:^(EMError *aError){}];
                weakSelf.requestUserIdentity = nil;
            }
        }
        weakSelf.isAlertShow = NO;
        [LRSpeakHelper.sharedInstance setupUserToSpeaker:username
                                              completion:^(BOOL success, NSString * _Nonnull username) {}];
        [weakSelf.requestList removeObjectAtIndex:0];
        [weakSelf showRequestInfoFromRequestList];
    }];
    
    LRAlertAction *reject = [LRAlertAction alertActionTitle:@"拒绝" callback:^(LRAlertController * _Nonnull alertController) {
        weakSelf.isAlertShow = NO;
        [LRSpeakHelper.sharedInstance forbidUserOnSpeaker:username];
        [weakSelf.requestList removeObjectAtIndex:0];
        [weakSelf showRequestInfoFromRequestList];
    }];
    [alert addAction:agreed];
    [alert addAction:reject];
    _isAlertShow = YES;
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)rejectAllRequestMember {
    @synchronized (self.requestList) {
        for (NSString *username in self.requestList) {
            [LRSpeakHelper.sharedInstance forbidUserOnSpeaker:username];
        }
        [self.requestList removeAllObjects];
    }
}

// 上麦申请被同意
- (void)receiveRequestAgreed:(NSNotification *)aNoti {
    self.applyOnSpeakBtn.hidden = YES;
    self.applyOnSpeakBtn.selected = NO;
}

// 上麦申请被拒绝
- (void)receiveRequestReject:(NSNotification *)aNoti {
    NSDictionary *dict = aNoti.object;
    NSString *confid = dict[@"confid"];
    if (![confid isEqualToString:self.roomModel.conferenceId]) {
        return;
    }
    self.applyOnSpeakBtn.selected = NO;
    self.applyOnSpeakBtn.hidden = NO;
    [self showTipsAlertWithTitle:@"提示 Tip" info:@"申请上麦被拒绝"];
    [LRSpeakHelper setupIdentity:@""];//重置身份为观众
}

- (void)didLoginOtherDevice:(NSNotification *)aNoti {
    [self closeWindowAction];
}

- (void)changeToAudience:(NSNotification *)aNoti {
    self.applyOnSpeakBtn.hidden = NO;
    self.applyOnSpeakBtn.selected = NO;
}

- (void)chatroomDidDestory:(NSNotification *)aNoti {
    NSString *confId = (NSString *)aNoti.object;
    if ([confId isEqualToString:self.roomModel.conferenceId]) {
        [self showHint:@"房间被销毁"];
        [self closeWindowAction];
    }
}

#pragma mark - subviews
- (void)_setupSubViews {
    self.headerView = [[LRVoiceRoomHeader alloc] initWithTitle:_roomModel.roomname
                                                          info:_roomModel.roomId];
    self.headerView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.headerView];
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(kPadding);
        make.top.equalTo(self.view).offset(LRSafeAreaTopHeight);
        make.right.equalTo(self.view).offset(-kPadding);
        make.height.equalTo(@kHeaderViewHeight);
    }];
    
    [self.view addSubview:self.speakerVC.view];
    [self addChildViewController:self.speakerVC];
    
    [self.view addSubview:self.chatVC.view];
    [self addChildViewController:self.chatVC];
    
    [self.view addSubview:self.inputBar];
    // 房间tableview位置
    [self.speakerVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom).offset(5);
        make.left.equalTo(self.headerView);
        make.right.equalTo(self.headerView);
        make.height.equalTo(@((LRWindowHeight - LRSafeAreaTopHeight - kHeaderViewHeight - kInputViewHeight - LRSafeAreaBottomHeight) / 2 + 140));
    }];
    
    [self.chatVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.speakerVC.view);
        make.right.equalTo(self.speakerVC.view);
        make.bottom.equalTo(self.inputBar.mas_top);
        make.height.equalTo(@((LRWindowHeight - LRSafeAreaTopHeight - kHeaderViewHeight - kInputViewHeight - LRSafeAreaBottomHeight) / 2 - 90 - 60));
    }];
    
    [self.inputBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.chatVC.view.mas_bottom);
        make.left.equalTo(self.chatVC.view);
        make.right.equalTo(self.chatVC.view);
        make.height.equalTo(@kInputViewHeight);
        make.bottom.equalTo(self.view).offset(-LRSafeAreaBottomHeight);
    }];
    
    if (!self.isOwner) {
        [self.view addSubview:self.applyOnSpeakBtn];
        [self.applyOnSpeakBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.equalTo(@46);
            make.bottom.equalTo(self.chatVC.view);
            make.right.equalTo(self.chatVC.view);
        }];
    }
}

- (void)_updateHeaderView {
    self.itemAry = [NSMutableArray array];
    if (_type == LRUserType_Admin) {
        NSString *imageName;
        if ([LRRoomOptions sharedOptions].isAutomaticallyTurnOnMusic) {
            imageName = @"musicalpause";
            self.isSelect = YES;
        } else {
            imageName = @"musicalplay";
            self.isSelect = NO;
        }
        //狼人杀模式没有音乐播放，该换音效自动切换
        if(_roomModel.roomType != 4){
            [self.itemAry addObject:[LRVoiceRoomHeaderItem
                                     itemWithImageName:imageName
                                     target:self
                                     action:@selector(musicPlayAction)]];
        }
        
        [self.itemAry addObject:[LRVoiceRoomHeaderItem
                                 itemWithImage:[UIImage imageNamed:@"members"]
                                 target:self
                                 action:@selector(memberListAction)]];
        
        [self.itemAry addObject:[LRVoiceRoomHeaderItem
                                 itemWithImage:[UIImage imageNamed:@"share-1"]
                                 target:self
                                 action:@selector(shareAction)]];
        
        [self.itemAry addObject:[LRVoiceRoomHeaderItem
                                 itemWithImage:[UIImage imageNamed:@"setting"]
                                 target:self
                                 action:@selector(settingsAction)]];
        
        [self.itemAry addObject:[LRVoiceRoomHeaderItem
                                 itemWithImage:[UIImage imageNamed:@"closed"]
                                 target:self
                                 action:@selector(closeWindowAction)]];
    }else {
        [self.itemAry addObject:[LRVoiceRoomHeaderItem
                                 itemWithImage:[UIImage imageNamed:@"members"]
                                 target:self
                                 action:@selector(memberListAction)]];
        
        [self.itemAry addObject:[LRVoiceRoomHeaderItem
                                 itemWithImage:[UIImage imageNamed:@"share-1"]
                                 target:self
                                 action:@selector(shareAction)]];
        
        [self.itemAry addObject:[LRVoiceRoomHeaderItem
                                 itemWithImage:[UIImage imageNamed:@"setting"]
                                 target:self
                                 action:@selector(settingsAction)]];
        
        [self.itemAry addObject:[LRVoiceRoomHeaderItem
                                 itemWithImage:[UIImage imageNamed:@"closed"]
                                 target:self
                                 action:@selector(closeWindowAction)]];
    }
    
    [self.headerView setActionList:self.itemAry];
}

#pragma mark - actions
//加入房间
- (void)joinChatAndConferenceRoom {
    __weak typeof(self) weakSelf = self;
    [self showHudInView:self.view hint:@"正在加入房间..."];
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("com.easemob.liveroom", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_async(group, queue, ^{
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [LRChatHelper.sharedInstance joinChatroomWithCompletion:^(NSString * _Nonnull errorInfo, BOOL success)
         {
             self->_chatJoined = success;
             self->_roomErrorInfo = errorInfo;
             dispatch_semaphore_signal(semaphore);
         }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    });
    
    dispatch_group_async(group, queue, ^{
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [LRSpeakHelper.sharedInstance joinSpeakRoomWithConferenceId:weakSelf.roomModel.conferenceId
                                                           password:weakSelf.password
                                                         completion:^(NSString * _Nonnull errorInfo, BOOL success)
         {
             self->_conferenceJoined = success;
             self->_errorInfo = errorInfo;
             dispatch_semaphore_signal(semaphore);
         }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    });
    
    dispatch_group_notify(group, queue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf hideHud];
            if (!self->_chatJoined) {
                [LRSpeakHelper.sharedInstance leaveSpeakRoomWithRoomId:weakSelf.roomModel.conferenceId completion:nil];
            }
            
            if (!self->_conferenceJoined) {
                [LRChatHelper.sharedInstance leaveChatroomWithCompletion:nil];
            }
            
            if (!self->_conferenceJoined || !self->_chatJoined) {
                if ([self->_roomErrorInfo containsString:@"do not find"]) {
                    [self showHint:@"房间不存在"];
                }
                [self closeWindowAction];
                return ;
            }
            
            if (self.isOwner) { // 群主自动上麦
                //[LRSpeakHelper.sharedInstance setupRoomType:self.roomModel.roomType];
                [LRSpeakHelper.sharedInstance setupMySelfToSpeaker];
                
                if(self.roomModel.roomType == LRRoomType_Pentakill){
                    //狼人杀模式设置当前时钟状态
                    [EMClient.sharedClient.conferenceManager setConferenceAttribute:@"clockStatus" value:@"LRTerminator_dayTime" completion:^(EMError *aError){}];
                    //房主是狼人，房主加入数组
                    if([[LRSpeakHelper instanceIdentity] isEqualToString:@"pentakill"]){
                        [LRSpeakHelper.sharedInstance.identityDic addObject:kCurrentUsername];
                    }
                    for(NSString *str in LRSpeakHelper.sharedInstance.identityDic){
                        NSLog(@"\n------>array:   %@",str);
                    }
                    //进入房间的用户添加狼人主播空数组进服务端
                    NSString *str = [LRSpeakHelper.sharedInstance.identityDic componentsJoinedByString:@","];
                    [EMClient.sharedClient.conferenceManager setConferenceAttribute:@"identityDic" value:str completion:^(EMError *aError){}];
                }
                
                // 如果是主持模式，管理员直接持麦
                if (self.roomModel.roomType == LRRoomType_Host) {
                    [LRSpeakHelper.sharedInstance setupSpeakerMicOn:kCurrentUsername];
                }
                if ([LRRoomOptions sharedOptions].isAutomaticallyTurnOnMusic) {
                    [LRSpeakHelper.sharedInstance setAudioPlay:YES];
                }
            }
            [LRChatHelper.sharedInstance sendMessageFromNoti:@"我来了"];
        });
    });
}
//房间成员列表
- (void)memberListAction {
    LRRoomInfoViewController *membersVC = [[LRRoomInfoViewController alloc] init];
    membersVC.model = self.roomModel;
    [self presentViewController:membersVC animated:YES completion:^{
        
    }];
}
//音乐播放
- (void)musicPlayAction{
    if (self.isOwner) {
        UIButton *button = [self.itemAry firstObject];
        if (self.isSelect) {
            [LRChatHelper.sharedInstance sendMessageFromNoti:@"停止歌曲"];
            [self musicPlayButton:button ImageName:@"musicalplay" select:NO setAudioPlay:NO];
        } else {
            [LRChatHelper.sharedInstance sendMessageFromNoti:@"开始歌曲"];
            [self musicPlayButton:button ImageName:@"musicalpause" select:YES setAudioPlay:YES];
        }
    }
}
//音乐播放按钮
- (void)musicPlayButton:(UIButton *)button
              ImageName:(NSString *)imageName
                 select:(BOOL)isSelect
           setAudioPlay:(BOOL)isPlay
{
    [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    self.isSelect = isSelect;
    [[LRSpeakHelper sharedInstance] setAudioPlay:isPlay];
}
//分享
- (void)shareAction {
    _isShareAlertShow = YES;
    //是模态视图
    NSString *str = [NSString stringWithFormat:@"房间: %@\n房主: %@\n密码: %@\n下载地址: %@", self.roomModel.roomname, self.roomModel.owner, _password ,@"https://www.easemob.com"];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = str;
    
    [self showTipsAlertWithTitle:@"内容已复制" info:@"已将房间信息复制到粘贴板，\n请您直接粘贴到要分享的软件中。"];
}
//房间设置
- (void)settingsAction {
    LRRoomSettingViewController *settingVC = [[LRRoomSettingViewController alloc] init];
    settingVC.rommPassword = _password;
    settingVC.speakerLimited = 6;
    settingVC.model = _roomModel;
    [self presentViewController:settingVC animated:YES completion:nil];
}
//房间关闭
- (void)closeWindowAction {
    if(_conferenceJoined && _chatJoined) {
        [LRChatHelper.sharedInstance sendMessageFromNoti:@"我走了"];
    }
    if (self.isOwner)
    {
        NSString *url = @"http://tcapp.easemob.com/app/huangcl/delete/talk/room/";
        url = [url stringByAppendingString:self.roomModel.roomId];
        [LRRequestManager.sharedInstance requestWithMethod:@"DELETE"
                                                 urlString:url
                                                parameters:nil
                                                     token:nil
                                                completion:^(NSDictionary * _Nonnull result, NSError * _Nonnull error)
         {
             [LRSpeakHelper.sharedInstance destoryInstance];//释放helper单例
             
             [[NSNotificationCenter defaultCenter] postNotificationName:LR_NOTIFICATION_ROOM_LIST_DIDCHANGEED object:nil];
         }];
    }
    if(self.roomModel.roomType == LRRoomType_Pentakill){
        [LRSpeakHelper setupIdentity:@""];//房主&成员退 出房间重置自己本地狼人杀身份
        [LRSpeakHelper setupClockStatus:@""];//房主&成员 退出房间重置自己本地时钟
    }
    [LRSpeakHelper.sharedInstance leaveSpeakRoomWithRoomId:self.roomModel.conferenceId completion:nil];
    [LRChatHelper.sharedInstance leaveChatroomWithCompletion:nil];
    if ([LRRoomOptions sharedOptions].isAutomaticallyTurnOnMusic) {
        [EMClient.sharedClient.conferenceManager stopAudioMixing];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)chatTapAction:(UITapGestureRecognizer *)tapGr {
    [self.view endEditing:YES];
}

#pragma mark - LRVoiceRoomTabbarDelgate
- (void)inputViewHeightDidChanged:(CGFloat)aChangeHeight
                         duration:(CGFloat)aDuration
                             show:(BOOL)isKeyboardShow{
    CGFloat height = self.view.bounds.size.height - aChangeHeight;
    
    if (isKeyboardShow) {
        [UIView animateWithDuration:aDuration animations:^{
            self.headerView.alpha = 0;
            self.speakerVC.view.alpha = 0;
            [self.chatVC.view mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.equalTo(@((LRWindowHeight - LRSafeAreaTopHeight - kHeaderViewHeight - kInputViewHeight - LRSafeAreaBottomHeight) / 2 + 30));
            }];
        }];
    } else {
        [UIView animateWithDuration:aDuration animations:^{
            self.headerView.alpha = 1;
            self.speakerVC.view.alpha = 1;
            [self.chatVC.view mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.equalTo(@((LRWindowHeight - LRSafeAreaTopHeight - kHeaderViewHeight - kInputViewHeight - LRSafeAreaBottomHeight) / 2 - 90 - 60));
            }];
        }];
    }
    
    [self.inputBar mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.chatVC.view);
        make.right.equalTo(self.chatVC.view);
        make.height.equalTo(@kInputViewHeight);
        make.bottom.equalTo(self.view).offset(isKeyboardShow ? -height : -height - LRSafeAreaBottomHeight);
    }];
    
    [self.view layoutIfNeeded];
    [[NSNotificationCenter defaultCenter] postNotificationName:LR_ChatView_Tableview_Roll_Notification object:nil];
}

#pragma mark - LRChatHelperDelegate
- (void)didExitChatroom:(NSString *)aReason
{
    [LRSpeakHelper.sharedInstance leaveSpeakRoomWithRoomId:self.roomModel.conferenceId completion:nil];
    [self showHint:aReason];
    if (_isShareAlertShow) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
//红心喜欢
- (void)likeAction {
    [_chatVC sendLike];
}
//礼物
- (void)giftAction {
    [_chatVC sendGift];
}
//发送房间消息
- (void)sendAction:(NSString *)aText {
    [self.chatVC sendText:aText];
}

//观众上麦时选择身份
- (void)identityTap
{
    LRAlertController *alert = [LRAlertController showIdentityAlertWithTitle:@"选择上麦身份" info:@"提交上麦参与体验.\n需要先选择上麦后的身份。\n您可以选择狼人或者村民，进行点击确认。"];
    LRAlertAction *werewolf = [LRAlertAction alertActionTitle:@"狼人 Werewolf" callback:^(LRAlertController *_Nonnull alertController)
                               {
                                   [LRSpeakHelper setupIdentity:@"pentakill"];
                                   self.applyOnSpeakBtn.selected = YES;
                                   [self applyOnSpeakHandle];
                               }];
    LRAlertAction *villager = [LRAlertAction alertActionTitle:@"村民 Villager" callback:^(LRAlertController *_Nonnull alertController)
                               {
                                   [LRSpeakHelper setupIdentity:@"villager"];
                                   self.applyOnSpeakBtn.selected = YES;
                                   [self applyOnSpeakHandle];
                               }];
    [alert addAction:werewolf];
    [alert addAction:villager];
    
    [self presentViewController:alert animated:YES completion:nil];
}

//申请上麦验证
- (void)applyOnSpeak:(UIButton *)btn {
    //狼人杀模式夜晚状态并且非狼人角色不能申请上麦
    if(self.roomModel.roomType == LRRoomType_Pentakill && [[LRSpeakHelper instanceClockStatus] isEqualToString:@"LRTerminator_night"] && ![[LRSpeakHelper instanceIdentity] isEqualToString:@"pentakill"]){
        LRAlertController *alert = [LRAlertController showTipsAlertWithTitle:@"提示" info:@"现在是夜晚状态，\n请等待房主切换至白天状态再申请上麦！"];
        LRAlertAction *confirm = [LRAlertAction alertActionTitle:@"确认" callback:^(LRAlertController *_Nonnull          alertContoller){
            
        }];
        [alert addAction:confirm];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    if (self.applyOnSpeakBtn.selected == YES) {
        return;
    }
    
    if (self.speakerVC.memberList.count >= 6) {
        [self showErrorAlertWithTitle:@"申请失败" info:@"当前主播数量已满"];
        return;
    }
    
    if(self.roomModel.roomType == LRRoomType_Pentakill){
        [self identityTap];    //狼人杀模式选择上麦身份
    }else {
        self.applyOnSpeakBtn.selected = YES;
        [self applyOnSpeakHandle];  //非狼人杀模式直接申请
    }
    
}
//申请上麦操作
- (void)applyOnSpeakHandle {
    __weak typeof(self) weakSelf = self;
    [LRSpeakHelper.sharedInstance requestOnSpeaker:weakSelf.roomModel completion:^(NSString * _Nonnull errorInfo, BOOL success)
     {
         if (!success) {
             weakSelf.applyOnSpeakBtn.selected = NO;
             [weakSelf showErrorAlertWithTitle:@"错误 Error" info:errorInfo];
         }
     }];
}

#pragma mark - getter

- (BOOL)isOwner {
    return [self.roomModel.owner isEqualToString:kCurrentUsername];
}

- (UIButton *)applyOnSpeakBtn {
    if (!_applyOnSpeakBtn) {
        _applyOnSpeakBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _applyOnSpeakBtn.backgroundColor = [UIColor whiteColor];
        [_applyOnSpeakBtn setImage:[UIImage imageNamed:@"mic"] forState:UIControlStateNormal];
        [_applyOnSpeakBtn setImage:[UIImage imageNamed:@"unmic"] forState:UIControlStateSelected];
        _applyOnSpeakBtn.layer.masksToBounds = YES;
        _applyOnSpeakBtn.layer.cornerRadius = 23;
        [_applyOnSpeakBtn addTarget:self action:@selector(applyOnSpeak:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _applyOnSpeakBtn;
}

- (LRSpeakViewController *)speakerVC {
    if (!_speakerVC) {
        if (_roomModel.roomType == LRRoomType_Communication) {
            _speakerVC = [[LRSpeakerCommunicationViewController alloc] init];
        } else if (_roomModel.roomType == LRRoomType_Host) {
            _speakerVC = [[LRSpeakerHostViewController alloc] init];
        } else if (_roomModel.roomType == LRRoomType_Monopoly) {
            _speakerVC = [[LRSpeakerMonopolyViewController alloc] init];
        } else if (_roomModel.roomType == LRRoomType_Pentakill) {
            _speakerVC = [[LRSpeakerPentakillController alloc] init];
        }
    }
    return _speakerVC;
}

- (LRChatViewController *)chatVC {
    if (!_chatVC) {
        _chatVC = [[LRChatViewController alloc] init];
    }
    return _chatVC;
}

- (LRVoiceRoomTabbar *)inputBar {
    if (!_inputBar) {
        _inputBar = [[LRVoiceRoomTabbar alloc] init];
        _inputBar.delegate = self;
    }
    return _inputBar;
}

- (void)dealloc
{
    NSLog(@" ---- lrRoVC - dealloc");
    [LRSpeakHelper.sharedInstance removeDelegate:self];
    [LRChatHelper.sharedInstance removeDelegate:self];
}

@end
