//
//  UIView+LRCategory.h
//  Tigercrew
//
//  Created by 杜洁鹏 on 2019/4/3.
//  Copyright © 2019 Easemob. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    LRStrokeRed,
    LRStrokeBlue,
    LRStrokeGreen,
    LRStrokeWhite,
    LRStrokeLowBlack,
    LRStrokePureBlack
} LRStrokeColor;

@interface UIView (Stroke)
- (void)strokeWithColor:(LRStrokeColor)aColor;
- (void)cellWithContentView:(UIView *)contentView StrokeWithColor:(UIColor *)aColor borderWidth:(CGFloat)width;
- (void)disableStroke;
@end

typedef enum : NSUInteger {
    LRTextInputType,
    LRTextNormalType
} LRTextType;

@interface UITextField (Type)
- (void)setupTextField;
@end


NS_ASSUME_NONNULL_END
