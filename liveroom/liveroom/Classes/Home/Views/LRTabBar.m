//
//  LRTabBarView.m
//  liveroom
//
//  Created by easemob-DN0164 on 2019/4/7.
//  Copyright © 2019年 Easemob. All rights reserved.
//

#import "LRTabBar.h"

#define LRTabBarHeight 49
@interface LRTabBar ()
@property (nonatomic, strong) UIView *chatRoomView;
@property (nonatomic, strong) UILabel *chatRoomTitleLabel;
@property (nonatomic, strong) UILabel *chatRoomDetailsLabel;

@property (nonatomic, strong) UIView *addView;
@property (nonatomic, strong) UIImageView *addImageView;

@property (nonatomic, strong) UIView *settingView;
@property (nonatomic, strong) UILabel *settingTitleLabel;
@property (nonatomic, strong) UILabel *settingDetailsLabel;
@end

@implementation LRTabBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _setupSubviews];
    }
    return self;
}

- (void)_setupSubviews
{
    // chatRoomView
    self.chatRoomView = [[UIView alloc] init];
    self.chatRoomView.tag = 100;
    self.chatRoomView.backgroundColor = LRColor_PureBlackColor;
    [self addSubview:self.chatRoomView];
    [self.chatRoomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self);
        make.left.equalTo(self);
        make.width.equalTo(@((LRWindowWidth - LRTabBarHeight) * 0.5));
        make.height.equalTo(@(LRTabBarHeight));
    }];
    UITapGestureRecognizer *chatRoomViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chatRoomViewTapAction:)];
    [self.chatRoomView addGestureRecognizer:chatRoomViewTap];
    
    self.chatRoomTitleLabel = [[UILabel alloc] init];
    self.chatRoomTitleLabel.font = [UIFont systemFontOfSize:14];
    self.chatRoomTitleLabel.textAlignment = NSTextAlignmentCenter;
    [self.chatRoomTitleLabel setText:@"房间"];
    [self.chatRoomTitleLabel setTextColor:[UIColor whiteColor]];
    [self.chatRoomView addSubview:self.chatRoomTitleLabel];
    [self.chatRoomTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.chatRoomView).offset(5);
        make.centerX.equalTo(self.chatRoomView);
        make.width.equalTo(@60);
        make.height.equalTo(@20);
    }];
    
    self.chatRoomDetailsLabel = [[UILabel alloc] init];
    self.chatRoomDetailsLabel.font = [UIFont systemFontOfSize:14];
    self.chatRoomDetailsLabel.textAlignment = NSTextAlignmentCenter;
    [self.chatRoomDetailsLabel setText:@"VoiceChatRoom"];
    [self.chatRoomDetailsLabel setTextColor:[UIColor whiteColor]];
    [self.chatRoomView addSubview:self.chatRoomDetailsLabel];
    [self.chatRoomDetailsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.chatRoomView.mas_bottom).offset(-5);
        make.centerX.equalTo(self.chatRoomView);
        make.width.equalTo(@((LRWindowWidth - LRTabBarHeight) * 0.5 - 10));
        make.height.equalTo(@20);
    }];
    
    // addView
    self.addView = [[UIView alloc] init];
    self.addView.tag = 101;
    [self addSubview:self.addView];
    [self.addView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self);
        make.left.equalTo(self.chatRoomView.mas_right);
        make.width.equalTo(@(LRTabBarHeight));
        make.height.equalTo(@(LRTabBarHeight));
    }];
    UITapGestureRecognizer *addViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addViewTapAction:)];
    [self.addView addGestureRecognizer:addViewTap];
    
    self.addImageView = [[UIImageView alloc] init];
    self.addImageView.image = [UIImage imageNamed:@"creat"];
    [self.addView addSubview:self.addImageView];
    [self.addImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.addView);
        make.width.equalTo(@(LRTabBarHeight));
        make.height.equalTo(@(LRTabBarHeight));
    }];
    
    // settingView
    self.settingView = [[UIView alloc] init];
    self.settingView.tag = 102;
    self.settingView.backgroundColor = LRColor_PureBlackColor;
    [self addSubview:self.settingView];
    [self.settingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self);
        make.left.equalTo(self.addView.mas_right);
        make.width.equalTo(@((LRWindowWidth - LRTabBarHeight) * 0.5));
        make.height.equalTo(@(self.frame.size.height));
    }];
    UITapGestureRecognizer *settingViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(settingViewTapAction:)];
    [self.settingView addGestureRecognizer:settingViewTap];
    
    self.settingTitleLabel = [[UILabel alloc] init];
    self.settingTitleLabel.font = [UIFont systemFontOfSize:14];
    self.settingTitleLabel.textAlignment = NSTextAlignmentCenter;
    [self.settingTitleLabel setText:@"设置"];
    [self.settingTitleLabel setTextColor:[UIColor whiteColor]];
    [self.settingView addSubview:self.settingTitleLabel];
    [self.settingTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.settingView).offset(5);
        make.centerX.equalTo(self.settingView);
        make.width.equalTo(@60);
        make.height.equalTo(@20);
    }];
    
    self.settingDetailsLabel = [[UILabel alloc] init];
    self.settingDetailsLabel.font = [UIFont systemFontOfSize:14];
    self.settingDetailsLabel.textAlignment = NSTextAlignmentCenter;
    [self.settingDetailsLabel setText:@"Setting"];
    [self.settingDetailsLabel setTextColor:[UIColor whiteColor]];
    [self.settingView addSubview:self.settingDetailsLabel];
    [self.settingDetailsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.settingView.mas_bottom).offset(-5);
        make.centerX.equalTo(self.settingView);
        make.width.equalTo(@((LRWindowWidth - LRTabBarHeight) * 0.5 - 10));
        make.height.equalTo(@20);
    }];
    
}

#pragma mark - UITapGestureRecognizer
- (void)chatRoomViewTapAction:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(tabBar:clickViewAction:)]) {
        [self.delegate tabBar:self clickViewAction:tap.view.tag];
    }
}

- (void)addViewTapAction:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(tabBar:clickViewAction:)]) {
        [self.delegate tabBar:self clickViewAction:tap.view.tag];
    }
}

- (void)settingViewTapAction:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(tabBar:clickViewAction:)]) {
        [self.delegate tabBar:self clickViewAction:tap.view.tag];
    }
}

@end
