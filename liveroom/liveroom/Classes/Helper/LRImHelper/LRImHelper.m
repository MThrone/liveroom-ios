//
//  LRImHelper.m
//  liveroom
//
//  Created by 杜洁鹏 on 2019/4/10.
//  Copyright © 2019 Easemob. All rights reserved.
//

#import "LRImHelper.h"
#import "LRGCDMulticastDelegate.h"
#import "Headers.h"

@interface LRImHelper () <EMChatManagerDelegate, EMChatroomManagerDelegate>
{
    LRGCDMulticastDelegate <LRImHelperDelegate> *_delegates;
}
@end

@implementation LRImHelper
+ (LRImHelper *)sharedInstance {
    static LRImHelper *helper_;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper_ = [[LRImHelper alloc] init];
    });
    return helper_;
}

- (instancetype)init {
    if (self = [super init]) {
        _delegates = (LRGCDMulticastDelegate<LRImHelperDelegate> *)[[LRGCDMulticastDelegate alloc] init];
        [self _registerImSDK];
    }
    return self;
}

#pragma mark - private
- (void)_registerImSDK {
    // 1100181024084247#voicechatroom
    EMOptions *options = [EMOptions optionsWithAppkey:@"1100181023201864#voicechatroom"];
    options.enableDnsConfig = NO;
    options.chatPort = 6717;
    options.chatServer = @"39.107.54.56";
    options.restServer = @"a1-hsb.easemob.com";
    options.enableConsoleLog = YES;
    [EMClient.sharedClient initializeSDKWithOptions:options];
}

#pragma mark - getter
- (BOOL)isLoggedIn {
    return EMClient.sharedClient.isAutoLogin;
}

#pragma mark register delegates
- (void)registerIMDelegates {
    [EMClient.sharedClient.chatManager addDelegate:self delegateQueue:nil];
    [EMClient.sharedClient.roomManager addDelegate:self delegateQueue:nil];
}

- (void)addDeelgate:(id<LRImHelperDelegate>)aDelegate delegateQueue:(dispatch_queue_t)aQueue {
    if (!aQueue) {
        aQueue = dispatch_get_main_queue();
    }
    [_delegates addDelegate:aDelegate delegateQueue:aQueue];
}

- (void)removeDelegate:(id<LRImHelperDelegate>)aDelegate {
    [_delegates removeDelegate:aDelegate];
}

#pragma mark - account
- (void)asyncLoginWithUsername:(NSString *)aUsername
                      password:(NSString *)aPassword
                    completion:(void(^)(NSString *errorInfo, BOOL success))aCompletion {
    [EMClient.sharedClient loginWithUsername:aUsername
                                    password:aPassword
                                  completion:^(NSString *aUsername, EMError *aError)
     {
         if (aCompletion) {
             if (!aError)
             {
                 [[EMClient sharedClient].options setIsAutoLogin:YES];
                 aCompletion(nil, YES);
             }else {
                 aCompletion(aError.errorDescription, NO);
             }
         }
     }];
}

- (void)asyncRegisterWithUsername:(NSString *)aUsername
                         password:(NSString *)aPassword
                       completion:(void(^)(NSString *errorInfo, BOOL success))aCompletion {
    [EMClient.sharedClient registerWithUsername:aUsername
                                       password:aPassword
                                     completion:^(NSString *aUsername, EMError *aError)
     {
         if (aCompletion) {
             if (!aError)
             {
                 aCompletion(nil, YES);
             }else {
                 aCompletion(aError.errorDescription, NO);
             }
         }
     }];
}
#pragma mark - chatroom
- (void)joinChatroomWithRoomId:(NSString *)aChatroomId
                    completion:(void(^)(NSString *errorInfo, BOOL success))aCompletion {
    [EMClient.sharedClient.roomManager joinChatroom:aChatroomId
                                         completion:^(EMChatroom *aChatroom, EMError *aError)
     {
         if (aCompletion) {
             if (!aError)
             {
                 aCompletion(nil, YES);
             }else {
                 aCompletion(aError.errorDescription, NO);
             }
         }
     }];
}

- (void)leaveChatroomWithRoomId:(NSString *)aChatroomId
                     completion:(void(^)(NSString *errorInfo, BOOL success))aCompletion {
    [EMClient.sharedClient.roomManager leaveChatroom:aChatroomId
                                          completion:^(EMError *aError)
     {
         if (aCompletion) {
             if (!aError)
             {
                 aCompletion(nil, YES);
             }else {
                 aCompletion(aError.errorDescription, NO);
             }
         }
     }];
}

#pragma mark - message
- (void)sendMessageToChatroom:(NSString *)aChatroomId
                      message:(NSString *)aMessage
                   completion:(void(^)(NSString *errorInfo, BOOL success))aCompletion {
    EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithText:aMessage];
    EMMessage *msg = [[EMMessage alloc] initWithConversationID:aChatroomId
                                                          from:EMClient.sharedClient.currentUsername
                                                            to:aChatroomId
                                                          body:body
                                                           ext:nil];
    msg.chatType = EMChatTypeChatRoom;
    [EMClient.sharedClient.chatManager sendMessage:msg
                                          progress:nil
                                        completion:^(EMMessage *message, EMError *error)
    {
        if (aCompletion) {
            if (!error)
            {
                aCompletion(nil, YES);
            }else {
                aCompletion(error.errorDescription, NO);
            }
        }
    }];
}

- (void)sendLikeToChatroom:(NSString *)aChatroomId
                completion:(void(^)(NSString *errorInfo, BOOL success))aCompletion {
    //TODO: 发送点赞
}

- (void)sendGiftToChatroom:(NSString *)aChatroomId
                completion:(void(^)(NSString *errorInfo, BOOL success))aCompletion {
    //TODO: 发送礼物
}

#pragma mark - EMChatManagerDelegate
- (void)messagesDidReceive:(NSArray *)aMessages {

    for (EMMessage *msg in aMessages) {
        if (msg.chatType != EMChatTypeChatRoom) {
            continue;
        }
        
        if (msg.body.type != EMMessageBodyTypeText) {
            continue;
        }
        
        // TODO: 解析gift， like 事件
        BOOL isLike = YES;
        if (isLike) {
            [_delegates didReceiveRoomLikeActionWithRoomId:msg.conversationId];
            continue;
        }
        
        
        BOOL isGift = YES;
        if (isGift) {
            [_delegates didReceiveRoomGiftActionWithRoomId:msg.conversationId];
            continue;
        }
        
        NSString *msgInfo = ((EMTextMessageBody *)[msg body]).text;
        [_delegates didReceiveRoomMessageWithRoomId:msg.conversationId
                                            message:msgInfo
                                           fromUser:msg.from
                                          timestamp:msg.timestamp];
    }
}

@end