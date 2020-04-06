//
//  DelegateM.h
//  ZHExample
//
//  Created by Zheng on 2020/4/7.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DelegateM;

NS_ASSUME_NONNULL_BEGIN


@protocol ZHDelegate <NSObject>

@required
- (void)delegateMDidClick:(DelegateM *)delegateM;

@optional
- (void)delegateMDidClick1:(DelegateM *)delegateM;

@end

@interface DelegateM : NSObject
@property (nonatomic,weak) id <ZHDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
