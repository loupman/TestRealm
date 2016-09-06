//
//  PLLastestNews.h
//  TestRealm
//
//  Created by Philip.Lee on 9/2/16.
//  Copyright © 2016 Philip.Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

@interface PLFollower :RLMObject

@property (copy, nonatomic) NSString *name;
@property (assign, nonatomic) int age;

@end

RLM_ARRAY_TYPE(PLFollower)

@interface PLStory :RLMObject

@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *gaPrefix;
@property (strong, nonatomic) NSString *image;
@property (assign, nonatomic) int type;
@property (assign, nonatomic) long long uid;

@property (strong,nonatomic) RLMArray<PLFollower> *followers;

@end
