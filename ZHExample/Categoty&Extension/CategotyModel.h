//
//  CategotyModel.h
//  ZHExample
//
//  Created by Zheng on 2020/4/5.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CategotyModel : NSObject
@end

@interface CategotyModel (ZH)
@property(nonatomic, copy) NSString *zh_name;
@property (nonatomic,copy) void (^block)(BOOL isSuccess);
- (void)zh_testLog;
@end

NS_ASSUME_NONNULL_END
